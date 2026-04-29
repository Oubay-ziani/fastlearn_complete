import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/domain/entities.dart';
import '../../../../core/constants/app_constants.dart';

// ═══════════════════════════════════════════════════════════
// TEACHER DASHBOARD — Instructor methods:
// createCourse, addLesson, setCoursePrice, viewEarnings
// manageSessionAvailability
// ═══════════════════════════════════════════════════════════
class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});
  @override
  ConsumerState<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authViewModelProvider).uid;
      if (uid != null) {
        ref.read(courseViewModelProvider).watchTeacherCourses(uid);
        ref.read(sessionViewModelProvider).watchInstructorSessions(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    if (!auth.isInstructor) {
      return Scaffold(body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, size: 60, color: AppTheme.error),
          const SizedBox(height: 16),
          const Text('Access denied. Instructor account required.'),
          TextButton(onPressed: () => auth.logout(), child: const Text('Log Out')),
        ])));
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _CoursesTab(),
          _SessionsTab(),
          _EarningsTab(),
          _TeacherProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), activeIcon: Icon(Icons.library_books), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.video_call_outlined), activeIcon: Icon(Icons.video_call), label: 'Sessions'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/teacher/create-course'),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Course', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : _navIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSessionDialog(context),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Slot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  void _showAddSessionDialog(BuildContext context) {
    DateTime? selectedDate;
    final priceCtrl = TextEditingController(text: '50');
    final durationCtrl = TextEditingController(text: '60');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Session Slot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(selectedDate == null ? 'Pick Date & Time' : selectedDate.toString().substring(0, 16)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.bg, foregroundColor: AppTheme.textDark),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)));
              if (d != null && context.mounted) {
                final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (t != null) selectedDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
              }
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duration (min)', prefixIcon: Icon(Icons.timer_outlined)))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (\$)', prefixIcon: Icon(Icons.attach_money)))),
          ]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (selectedDate == null) return;
              final uid = ref.read(authViewModelProvider).uid ?? '';
              await ref.read(sessionViewModelProvider).createSession(
                instructorId: uid,
                scheduledAt: selectedDate!,
                durationMinutes: int.tryParse(durationCtrl.text) ?? 60,
                price: double.tryParse(priceCtrl.text) ?? 50,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create Session'),
          )),
        ]),
      ),
    );
  }
}

// ── Courses Tab ──
class _CoursesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(courseViewModelProvider);

    return CustomScrollView(slivers: [
      SliverAppBar(
        backgroundColor: Colors.white, floating: true, pinned: false,
        title: const Text('My Courses'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      if (vm.isLoading)
        const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
      else if (vm.courses.isEmpty)
        SliverFillRemaining(
          child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.library_books_outlined, size: 60, color: AppTheme.textGrey),
            const SizedBox(height: 16),
            const Text('No courses yet', style: TextStyle(color: AppTheme.textGrey, fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Course'),
              onPressed: () => context.push('/teacher/create-course'),
            ),
          ])))
      else
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) {
            final course = vm.courses[i];
            return _TeacherCourseCard(course: course);
          }, childCount: vm.courses.length)),
        ),
    ]);
  }
}

class _TeacherCourseCard extends StatelessWidget {
  final CourseEntity course;
  const _TeacherCourseCard({required this.course});

  Color get _statusColor => switch (course.status) {
    AppConstants.statusPublished => AppTheme.success,
    AppConstants.statusPending   => AppTheme.warning,
    AppConstants.statusRejected  => AppTheme.error,
    _ => AppTheme.textGrey,
  };

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
    child: Column(children: [
      ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        leading: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
            borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.play_lesson, color: Colors.white, size: 26)),
        title: Text(course.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6)),
              child: Text(course.status.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor))),
            const SizedBox(width: 8),
            Text('\$${course.price.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ]),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(children: [
          _StatChip(Icons.people_outline, '${course.enrollmentCount}', 'Students'),
          const SizedBox(width: 8),
          _StatChip(Icons.play_circle_outline, '${course.lessonCount}', 'Lessons'),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Lesson', style: TextStyle(fontSize: 12)),
            onPressed: () => context.push('/teacher/course/${course.courseId}/add-lesson'),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit', style: TextStyle(fontSize: 12)),
            onPressed: () => context.push('/teacher/course/${course.courseId}/edit'),
          ),
        ]),
      ),
    ]),
  );
}

class _StatChip extends StatelessWidget {
  final IconData icon; final String value, label;
  const _StatChip(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: AppTheme.textGrey),
    const SizedBox(width: 4),
    Text('$value $label', style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
  ]);
}

// ── Sessions Tab ──
class _SessionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(sessionViewModelProvider);
    return CustomScrollView(slivers: [
      const SliverAppBar(backgroundColor: Colors.white, floating: true,
        title: Text('My Sessions')),
      if (vm.sessions.isEmpty)
        const SliverFillRemaining(
          child: Center(child: Text('No sessions created yet', style: TextStyle(color: AppTheme.textGrey))))
      else
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) {
            final s = vm.sessions[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
              child: Row(children: [
                Container(width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.video_call, color: AppTheme.accent, size: 26)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.scheduledAt.toString().substring(0, 16),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${s.durationMinutes} min • \$${s.price.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  Text(s.studentId != null ? 'Booked' : 'Available',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: s.studentId != null ? AppTheme.success : AppTheme.primary)),
                ])),
                if (s.studentId == null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                    onPressed: () => ref.read(sessionViewModelProvider).deleteSession(s.sessionId)),
              ]),
            );
          }, childCount: vm.sessions.length)),
        ),
    ]);
  }
}

// ── Earnings Tab ──
class _EarningsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authViewModelProvider);
    final instructor = auth.user as InstructorEntity?;
    final earnings = instructor?.totalEarnings ?? 0.0;

    return CustomScrollView(slivers: [
      const SliverAppBar(backgroundColor: Colors.white, floating: true,
        title: Text('Earnings')),
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverList(delegate: SliverChildListDelegate([
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
              borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text('\$${earnings.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              const Text('70% of course revenue goes to you',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Payout Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const _InfoCard('Payment Schedule', 'Monthly — 1st of each month'),
          const _InfoCard('Minimum Payout', '\$10.00'),
          const _InfoCard('Platform Commission', '30%'),
          const _InfoCard('Your Share', '70%'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.push('/teacher/earnings'),
            child: const Text('View Detailed Earnings'),
          ),
        ])),
      ),
    ]);
  }
}

class _InfoCard extends StatelessWidget {
  final String label, value;
  const _InfoCard(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(10),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppTheme.textGrey)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ]),
  );
}

// ── Profile Tab ──
class _TeacherProfileTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authViewModelProvider);
    final user = auth.user;
    return CustomScrollView(slivers: [
      SliverAppBar(
        backgroundColor: Colors.white, floating: true,
        title: const Text('Profile'),
        actions: [TextButton(
          onPressed: () async { await auth.logout(); if (context.mounted) context.go('/auth/login'); },
          child: const Text('Log Out', style: TextStyle(color: AppTheme.error)))],
      ),
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverList(delegate: SliverChildListDelegate([
          Center(child: Column(children: [
            CircleAvatar(radius: 45, backgroundColor: AppTheme.primary,
              child: Text(user?.name.substring(0,1).toUpperCase() ?? 'T',
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            Text(user?.name ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Instructor', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ])),
          const SizedBox(height: 24),
          ListTile(leading: const Icon(Icons.person_outline, color: AppTheme.primary),
            title: const Text('Edit Profile'), trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile')),
          ListTile(leading: const Icon(Icons.quiz_outlined, color: AppTheme.primary),
            title: const Text('Create Exam'), trailing: const Icon(Icons.chevron_right),
            onTap: () {}),
        ])),
      ),
    ]);
  }
}
