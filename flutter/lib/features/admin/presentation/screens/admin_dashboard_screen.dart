import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/domain/entities.dart';
import '../../../../core/constants/app_constants.dart';

// ═══════════════════════════════════════════════════════════
// ADMIN DASHBOARD — All Admin methods:
// manageUsers, approveOrRejectCourse, managePlatformPayments,
// viewPlatformAnalytics, suspendAccount, deleteAccount
// Analytics.generateReport
// ═══════════════════════════════════════════════════════════
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(adminViewModelProvider);
      vm.watchAllUsers();
      vm.watchPendingCourses();
      vm.watchAllPayments();
      vm.loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    if (!auth.isAdmin) {
      return Scaffold(body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.admin_panel_settings, size: 60, color: AppTheme.error),
          const SizedBox(height: 16),
          const Text('Admin access required.'),
          TextButton(onPressed: () => auth.logout(), child: const Text('Log Out')),
        ])));
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(index: _navIndex, children: [
        _OverviewTab(),
        _UsersTab(),
        _CoursesTab(),
        _PaymentsTab(),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), activeIcon: Icon(Icons.library_books), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.payment_outlined), activeIcon: Icon(Icons.payment), label: 'Payments'),
        ],
      ),
    );
  }
}

// ── Overview (Analytics) Tab ──
class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(adminViewModelProvider);
    final auth = ref.watch(authViewModelProvider);
    final a = vm.analytics;

    return CustomScrollView(slivers: [
      SliverAppBar(
        backgroundColor: Colors.white, floating: true,
        title: const Text('Admin Panel'),
        actions: [
          TextButton(
            onPressed: () async { await auth.logout(); if (context.mounted) context.go('/auth/login'); },
            child: const Text('Log Out', style: TextStyle(color: AppTheme.error))),
        ],
      ),
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(delegate: SliverChildListDelegate([

          // Welcome card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Admin Dashboard', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(auth.user?.name ?? 'Admin',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                const Text('Platform overview & controls',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
              ])),
              const Icon(Icons.admin_panel_settings, color: Colors.white24, size: 60),
            ]),
          ),
          const SizedBox(height: 20),

          // Stats Grid
          if (vm.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (a != null) ...[
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard('Total Users', '${a.totalUsers}', Icons.people, AppTheme.primary),
                _StatCard('Total Courses', '${a.totalCourses}', Icons.library_books, AppTheme.accent),
                _StatCard('Revenue', '\$${a.totalRevenue.toStringAsFixed(0)}', Icons.attach_money, AppTheme.success),
                _StatCard('Enrollments', '${a.totalEnrollments}', Icons.school, AppTheme.error),
              ],
            ),
            const SizedBox(height: 24),

            // Revenue chart
            if (a.revenueByMonth.isNotEmpty) ...[
              const Text('Revenue by Month',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                child: _RevenueChart(data: a.revenueByMonth),
              ),
              const SizedBox(height: 24),
            ],

            // Pending approvals quick link
            if (vm.courses.isNotEmpty) ...[
              const Text('Pending Approvals',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...vm.courses.take(3).map((c) => _PendingCourseCard(course: c)),
              if (vm.courses.length > 3)
                TextButton(
                  onPressed: () {},
                  child: Text('View all ${vm.courses.length} pending courses')),
            ],
          ],
        ])),
      ),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 22)),
      const Spacer(),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
    ]),
  );
}

class _RevenueChart extends StatelessWidget {
  final Map<String, double> data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final spots = entries.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value.value)).toList();

    if (spots.isEmpty) return const Center(child: Text('No revenue data'));

    return LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 24,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i >= 0 && i < entries.length) {
              return Text(entries[i].key.substring(5), style: const TextStyle(fontSize: 10));
            }
            return const Text('');
          },
        )),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(
        spots: spots,
        isCurved: true,
        color: AppTheme.primary,
        barWidth: 3,
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [AppTheme.primary.withOpacity(0.2), Colors.transparent],
            begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        dotData: const FlDotData(show: false),
      )],
    ));
  }
}

class _PendingCourseCard extends ConsumerWidget {
  final CourseEntity course;
  const _PendingCourseCard({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(adminViewModelProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Row(children: [
        const Icon(Icons.pending_actions, color: AppTheme.warning, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(course.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('by ${course.teacherName} • \$${course.price.toStringAsFixed(0)}',
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
        ])),
        IconButton(
          icon: const Icon(Icons.check_circle, color: AppTheme.success),
          onPressed: () async {
            await vm.approveCourse(course.courseId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Course approved ✓'), backgroundColor: AppTheme.success));
            }
          }),
        IconButton(
          icon: const Icon(Icons.cancel, color: AppTheme.error),
          onPressed: () async {
            await vm.rejectCourse(course.courseId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Course rejected'), backgroundColor: AppTheme.error));
            }
          }),
      ]),
    );
  }
}

// ── Users Tab ──
class _UsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(adminViewModelProvider);

    return CustomScrollView(slivers: [
      const SliverAppBar(backgroundColor: Colors.white, floating: true, title: Text('Manage Users')),
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) {
          final user = vm.users[i];
          return _UserCard(user: user);
        }, childCount: vm.users.length)),
      ),
    ]);
  }
}

class _UserCard extends ConsumerWidget {
  final UserEntity user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(adminViewModelProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: !user.isActive ? Border.all(color: AppTheme.error.withOpacity(0.4)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: switch (user.role) {
            AppConstants.roleAdmin      => AppTheme.error,
            AppConstants.roleInstructor => AppTheme.accent,
            _ => AppTheme.primary,
          },
          child: Text(user.name.substring(0,1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        title: Row(children: [
          Expanded(child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600))),
          if (!user.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4)),
              child: const Text('SUSPENDED', style: TextStyle(color: AppTheme.error, fontSize: 9, fontWeight: FontWeight.w700))),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.email, style: const TextStyle(fontSize: 11)),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4)),
              child: Text(user.role.toUpperCase(),
                style: const TextStyle(color: AppTheme.primary, fontSize: 9, fontWeight: FontWeight.w700))),
          ]),
        ]),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            switch (action) {
              case 'suspend':
                await vm.suspendAccount(user.userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.name} suspended'), backgroundColor: AppTheme.warning));
                }
                break;
              case 'restore':
                await vm.restoreAccount(user.userId);
                break;
              case 'delete':
                final confirm = await showDialog<bool>(context: context, builder: (_) =>
                  AlertDialog(
                    title: const Text('Delete Account'),
                    content: Text('Are you sure you want to delete ${user.name}\'s account? This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete')),
                    ]));
                if (confirm == true) await vm.deleteAccount(user.userId);
                break;
              case 'make_instructor':
                await vm.assignRole(user.userId, AppConstants.roleInstructor);
                break;
              case 'make_student':
                await vm.assignRole(user.userId, AppConstants.roleStudent);
                break;
            }
          },
          itemBuilder: (_) => [
            if (user.isActive)
              const PopupMenuItem(value: 'suspend', child: Row(children: [
                Icon(Icons.block, color: AppTheme.warning, size: 18),
                SizedBox(width: 10), Text('Suspend Account')]))
            else
              const PopupMenuItem(value: 'restore', child: Row(children: [
                Icon(Icons.restore, color: AppTheme.success, size: 18),
                SizedBox(width: 10), Text('Restore Account')])),
            if (user.role != AppConstants.roleInstructor)
              const PopupMenuItem(value: 'make_instructor', child: Row(children: [
                Icon(Icons.cast_for_education, color: AppTheme.primary, size: 18),
                SizedBox(width: 10), Text('Make Instructor')])),
            if (user.role != AppConstants.roleStudent)
              const PopupMenuItem(value: 'make_student', child: Row(children: [
                Icon(Icons.school, color: AppTheme.primary, size: 18),
                SizedBox(width: 10), Text('Make Student')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [
              Icon(Icons.delete_forever, color: AppTheme.error, size: 18),
              SizedBox(width: 10), Text('Delete Account', style: TextStyle(color: AppTheme.error))])),
          ],
        ),
      ),
    );
  }
}

// ── Courses Tab ──
class _CoursesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(adminViewModelProvider);
    return CustomScrollView(slivers: [
      const SliverAppBar(backgroundColor: Colors.white, floating: true, title: Text('Pending Courses')),
      if (vm.courses.isEmpty)
        const SliverFillRemaining(
          child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.check_circle_outline, size: 60, color: AppTheme.success),
            SizedBox(height: 16),
            Text('No pending courses', style: TextStyle(color: AppTheme.textGrey, fontSize: 16)),
          ])))
      else
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) =>
            _PendingCourseCard(course: vm.courses[i]),
            childCount: vm.courses.length)),
        ),
    ]);
  }
}

// ── Payments Tab ──
class _PaymentsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(adminViewModelProvider);
    return CustomScrollView(slivers: [
      const SliverAppBar(backgroundColor: Colors.white, floating: true, title: Text('All Payments')),
      if (vm.payments.isEmpty)
        const SliverFillRemaining(
          child: Center(child: Text('No payments yet', style: TextStyle(color: AppTheme.textGrey))))
      else
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) {
            final p = vm.payments[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
              child: Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: (p.status == AppConstants.paymentSuccess
                        ? AppTheme.success : AppTheme.error).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                    p.status == AppConstants.paymentSuccess ? Icons.check_circle : Icons.cancel,
                    color: p.status == AppConstants.paymentSuccess ? AppTheme.success : AppTheme.error)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('User: ${p.userId.substring(0,8)}...',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Text(p.paidAt.toString().substring(0,16),
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('\$${p.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (p.status == AppConstants.paymentSuccess
                          ? AppTheme.success : AppTheme.error).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4)),
                    child: Text(p.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: p.status == AppConstants.paymentSuccess ? AppTheme.success : AppTheme.error))),
                ]),
              ]),
            );
          }, childCount: vm.payments.length)),
        ),
    ]);
  }
}
