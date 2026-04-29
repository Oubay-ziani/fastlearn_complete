import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/domain/entities.dart';

// ═══════════════════════════════════════════════════════════
// STUDENT DASHBOARD — Student.viewEnrolledCourses
// ═══════════════════════════════════════════════════════════
class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});
  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authViewModelProvider).uid;
      if (uid != null) {
        ref.read(courseViewModelProvider).watchEnrolledIds(uid);
        ref.read(quizViewModelProvider).loadUserResults(uid, '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth   = ref.watch(authViewModelProvider);
    final course = ref.watch(courseViewModelProvider);
    final quiz   = ref.watch(quizViewModelProvider);
    final user   = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('My Dashboard'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Welcome card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF0D47A1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              CircleAvatar(
                radius: 30, backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: user?.profilePicture != null
                    ? NetworkImage(user!.profilePicture!) : null,
                child: user?.profilePicture == null
                    ? Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'S',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hi, ${user?.name.split(' ').first ?? 'Student'}! 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${course.enrollments.length} courses enrolled',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ])),
            ]),
          ),
          const SizedBox(height: 24),

          // Stats row
          Row(children: [
            _DashStat('Enrolled', '${course.enrollments.length}', Icons.book, AppTheme.primary),
            const SizedBox(width: 12),
            _DashStat('Completed',
              '${course.enrollments.where((e) => e.completed).length}',
              Icons.check_circle, AppTheme.success),
            const SizedBox(width: 12),
            _DashStat('Quizzes', '${quiz.results.length}', Icons.quiz, AppTheme.accent),
          ]),
          const SizedBox(height: 28),

          // Continue learning
          const Text('Continue Learning',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          if (course.enrollments.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.divider)),
              child: Column(children: [
                const Icon(Icons.auto_stories_outlined, size: 40, color: AppTheme.textGrey),
                const SizedBox(height: 10),
                const Text('You haven\'t enrolled in any courses yet',
                  style: TextStyle(color: AppTheme.textGrey)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Browse Courses')),
              ]),
            )
          else
            ...course.enrollments.take(3).map((e) => _ProgressCard(enrollment: e)),

          if (course.enrollments.length > 3) ...[
            TextButton(
              onPressed: () => context.push('/student/courses'),
              child: const Text('See all courses →')),
          ],

          const SizedBox(height: 24),

          // Quick actions
          const Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: [
              _QuickAction('My Certificates', Icons.card_membership, AppTheme.accent,
                  () => context.push('/certificates')),
              _QuickAction('Sessions', Icons.video_call, AppTheme.primary,
                  () => context.push('/sessions')),
              _QuickAction('Browse Courses', Icons.explore, AppTheme.success,
                  () => context.go('/home')),
              _QuickAction('Payment History', Icons.receipt_long, Colors.deepPurple,
                  () => context.push('/payments/history')),
            ],
          ),
        ]),
      ),
    );
  }
}

class _DashStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _DashStat(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
    child: Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
    ]),
  ));
}

class _ProgressCard extends ConsumerWidget {
  final EnrollmentEntity enrollment;
  const _ProgressCard({required this.enrollment});

  @override
  Widget build(BuildContext context, WidgetRef ref) => GestureDetector(
    onTap: () => context.push('/course/${enrollment.courseId}'),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF0D47A1)]),
            borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.play_lesson, color: Colors.white, size: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Course: ${enrollment.courseId.substring(0, 8)}...',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 6,
            percent: enrollment.progress / 100,
            backgroundColor: AppTheme.divider,
            progressColor: enrollment.completed ? AppTheme.success : AppTheme.primary,
            padding: EdgeInsets.zero,
            barRadius: const Radius.circular(3),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Text('${enrollment.progress}% complete',
              style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
            const Spacer(),
            if (enrollment.completed)
              const Row(children: [
                Icon(Icons.check_circle, color: AppTheme.success, size: 14),
                SizedBox(width: 4),
                Text('Done!', style: TextStyle(color: AppTheme.success, fontSize: 11,
                  fontWeight: FontWeight.w700)),
              ]),
          ]),
        ])),
        const Icon(Icons.chevron_right, color: AppTheme.textGrey, size: 20),
      ]),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13, color: color))),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
// ENROLLED COURSES SCREEN — Student.viewEnrolledCourses
// ═══════════════════════════════════════════════════════════
class EnrolledCoursesScreen extends ConsumerStatefulWidget {
  const EnrolledCoursesScreen({super.key});
  @override
  ConsumerState<EnrolledCoursesScreen> createState() => _EnrolledCoursesScreenState();
}

class _EnrolledCoursesScreenState extends ConsumerState<EnrolledCoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authViewModelProvider).uid;
      if (uid != null) ref.read(courseViewModelProvider).watchEnrolledIds(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(courseViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('My Courses'),
        backgroundColor: Colors.white,
      ),
      body: vm.enrollments.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.auto_stories_outlined, size: 64, color: AppTheme.textGrey),
              const SizedBox(height: 16),
              const Text('No enrolled courses yet',
                style: TextStyle(fontSize: 16, color: AppTheme.textGrey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Browse Courses')),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.enrollments.length,
              itemBuilder: (_, i) => _ProgressCard(enrollment: vm.enrollments[i]),
            ),
    );
  }
}
