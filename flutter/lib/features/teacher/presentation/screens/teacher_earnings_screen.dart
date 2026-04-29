import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/domain/entities.dart';
import '../../../../core/constants/app_constants.dart';

// ═══════════════════════════════════════════════════════════
// TEACHER EARNINGS SCREEN — Instructor.viewEarnings()
// ═══════════════════════════════════════════════════════════
class TeacherEarningsScreen extends ConsumerStatefulWidget {
  const TeacherEarningsScreen({super.key});
  @override
  ConsumerState<TeacherEarningsScreen> createState() => _TeacherEarningsScreenState();
}

class _TeacherEarningsScreenState extends ConsumerState<TeacherEarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authViewModelProvider).uid;
      if (uid != null) ref.read(paymentViewModelProvider).loadUserPayments(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth     = ref.watch(authViewModelProvider);
    final payVM    = ref.watch(paymentViewModelProvider);
    final instructor = auth.user as InstructorEntity?;
    final earnings = instructor?.totalEarnings ?? 0.0;
    final payments = payVM.payments;

    // Build monthly revenue map
    final monthlyRevenue = <String, double>{};
    for (final p in payments.where((p) => p.status == AppConstants.paymentSuccess)) {
      final key = '${p.paidAt.year}-${p.paidAt.month.toString().padLeft(2, '0')}';
      monthlyRevenue[key] = (monthlyRevenue[key] ?? 0) + (p.amount * 0.7);
    }
    final sortedMonths = monthlyRevenue.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('My Earnings'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Total earnings card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF0D47A1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 20, offset: const Offset(0, 8))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Earnings (Your 70%)',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Text('\$${earnings.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Row(children: [
                _EarningBadge('${payments.where((p) => p.status == AppConstants.paymentSuccess).length}',
                  'Transactions'),
                const SizedBox(width: 20),
                _EarningBadge(
                  '\$${payments.where((p) => p.status == AppConstants.paymentSuccess).fold(0.0, (a, p) => a + p.amount).toStringAsFixed(0)}',
                  'Gross Revenue'),
              ]),
            ]),
          ),
          const SizedBox(height: 28),

          // Monthly chart
          if (sortedMonths.isNotEmpty) ...[
            const Text('Monthly Earnings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: sortedMonths.map((m) => monthlyRevenue[m]!).reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i >= 0 && i < sortedMonths.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(sortedMonths[i].substring(5),
                            style: const TextStyle(fontSize: 10, color: AppTheme.textGrey)));
                      }
                      return const SizedBox.shrink();
                    },
                  )),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: sortedMonths.asMap().entries.map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [BarChartRodData(
                    toY: monthlyRevenue[e.value] ?? 0,
                    color: AppTheme.primary,
                    width: 18,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  )],
                )).toList(),
              )),
            ),
            const SizedBox(height: 28),
          ],

          // Payment list
          const Text('Transaction History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (payVM.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (payments.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No transactions yet', style: TextStyle(color: AppTheme.textGrey))))
          else
            ...payments.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_downward, color: AppTheme.success, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Course sale', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(p.paidAt.toString().substring(0, 10),
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('\$${(p.amount * 0.7).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.success, fontSize: 15)),
                  Text('Gross: \$${p.amount.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 10)),
                ]),
              ]),
            )),
        ]),
      ),
    );
  }
}

class _EarningBadge extends StatelessWidget {
  final String value, label;
  const _EarningBadge(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
  ]);
}

// ═══════════════════════════════════════════════════════════
// ADMIN SUB-SCREENS (referenced by router)
// Full implementations delegating to AdminDashboardScreen tabs
// ═══════════════════════════════════════════════════════════

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
      ref.read(adminViewModelProvider).watchAllUsers());
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(adminViewModelProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Users (${vm.users.length})'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.users.length,
              itemBuilder: (_, i) {
                final user = vm.users[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: switch (user.role) {
                        AppConstants.roleAdmin      => AppTheme.error,
                        AppConstants.roleInstructor => AppTheme.accent,
                        _ => AppTheme.primary,
                      },
                      radius: 22,
                      child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(user.email, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4)),
                        child: Text(user.role.toUpperCase(),
                          style: const TextStyle(color: AppTheme.primary, fontSize: 10,
                            fontWeight: FontWeight.w700))),
                    ])),
                    if (!user.isActive) const Icon(Icons.block, color: AppTheme.error, size: 20),
                  ]),
                );
              }),
    );
  }
}

class AdminCoursesScreen extends ConsumerStatefulWidget {
  const AdminCoursesScreen({super.key});
  @override
  ConsumerState<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends ConsumerState<AdminCoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
      ref.read(adminViewModelProvider).watchPendingCourses());
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(adminViewModelProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Pending Courses'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
      ),
      body: vm.courses.isEmpty
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle_outline, size: 60, color: AppTheme.success),
              SizedBox(height: 16),
              Text('No pending courses! All caught up.', style: TextStyle(color: AppTheme.textGrey))]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.courses.length,
              itemBuilder: (_, i) {
                final c = vm.courses[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('by ${c.teacherName}  •  \$${c.price.toStringAsFixed(0)}  •  ${c.lessonCount} lessons',
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(c.description, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                        onPressed: () async {
                          await vm.approveCourse(c.courseId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Course approved ✓'),
                              backgroundColor: AppTheme.success));
                          }
                        },
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: OutlinedButton.icon(
                        icon: const Icon(Icons.close, size: 16, color: AppTheme.error),
                        label: const Text('Reject', style: TextStyle(fontSize: 13, color: AppTheme.error)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error)),
                        onPressed: () async {
                          await vm.rejectCourse(c.courseId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Course rejected'),
                              backgroundColor: AppTheme.error));
                          }
                        },
                      )),
                    ]),
                  ]),
                );
              }),
    );
  }
}

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});
  @override
  ConsumerState<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
      ref.read(adminViewModelProvider).watchAllPayments());
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(adminViewModelProvider);
    final total = vm.payments
        .where((p) => p.status == AppConstants.paymentSuccess)
        .fold(0.0, (a, p) => a + p.amount);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('All Payments'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.success, Color(0xFF27AE60)]),
            borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Platform Revenue', style: TextStyle(color: Colors.white70, fontSize: 12)),
              SizedBox(height: 4),
              Text('(30% of all sales)', style: TextStyle(color: Colors.white60, fontSize: 10)),
            ]),
            Text('\$${(total * 0.30).toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
          ]),
        ),
        Expanded(child: vm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: vm.payments.length,
                itemBuilder: (_, i) {
                  final p = vm.payments[i];
                  final ok = p.status == AppConstants.paymentSuccess;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
                    child: Row(children: [
                      Icon(ok ? Icons.check_circle : Icons.cancel,
                        color: ok ? AppTheme.success : AppTheme.error, size: 28),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('User: ${p.userId.length > 8 ? p.userId.substring(0,8) : p.userId}...',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(p.paidAt.toString().substring(0, 16),
                          style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('\$${p.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(p.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: ok ? AppTheme.success : AppTheme.error)),
                      ]),
                    ]),
                  );
                })),
      ]),
    );
  }
}

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});
  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
      ref.read(adminViewModelProvider).loadAnalytics());
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(adminViewModelProvider);
    final a  = vm.analytics;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Platform Analytics'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
      ),
      body: vm.isLoading || a == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Summary from Analytics.generateReport()
                const Text('Platform Summary',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12, mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _AnalyticCard('Total Users', '${a.totalUsers}', Icons.people, AppTheme.primary),
                    _AnalyticCard('Total Courses', '${a.totalCourses}', Icons.library_books, AppTheme.accent),
                    _AnalyticCard('Revenue', '\$${a.totalRevenue.toStringAsFixed(0)}', Icons.monetization_on, AppTheme.success),
                    _AnalyticCard('Enrollments', '${a.totalEnrollments}', Icons.school, Colors.deepPurple),
                  ],
                ),
                const SizedBox(height: 24),

                // Revenue trend
                if (a.revenueByMonth.isNotEmpty) ...[
                  const Text('Revenue Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: LineChart(_buildLineChart(a.revenueByMonth)),
                  ),
                  const SizedBox(height: 24),
                ],

                // Generated report display
                const Text('Generated Report',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ...a.generateReport().entries.where(
                      (e) => e.value is! Map).map((e) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(e.key, style: const TextStyle(color: AppTheme.textGrey)),
                          Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ]),
                      )),
                  ]),
                ),
              ]),
            ),
    );
  }

  LineChartData _buildLineChart(Map<String, double> data) {
    final entries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final spots = entries.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList();
    if (spots.isEmpty) return LineChartData();

    return LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 22,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i >= 0 && i < entries.length) {
              return Text(entries[i].key.substring(5),
                style: const TextStyle(fontSize: 9, color: AppTheme.textGrey));
            }
            return const SizedBox.shrink();
          },
        )),
      ),
      lineBarsData: [LineChartBarData(
        spots: spots, isCurved: true, color: AppTheme.primary, barWidth: 3,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [AppTheme.primary.withOpacity(0.2), Colors.transparent],
            begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      )],
    );
  }
}

class _AnalyticCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _AnalyticCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 24),
      const Spacer(),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
    ]),
  );
}
