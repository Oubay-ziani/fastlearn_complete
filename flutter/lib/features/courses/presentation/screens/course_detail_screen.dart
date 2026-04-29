import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/domain/entities.dart';

// ═══════════════════════════════════════════════════════════
// COURSE DETAIL SCREEN
// Implements: Student.watchCourses, buyCourse, takeExam
// Instructor flow: shows manage options
// ═══════════════════════════════════════════════════════════
class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});
  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courseViewModelProvider).selectCourse(widget.courseId);
      ref.read(courseViewModelProvider).watchLessons(widget.courseId);
      ref.read(quizViewModelProvider).watchCourseExams(widget.courseId);
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final courseVM  = ref.watch(courseViewModelProvider);
    final authVM    = ref.watch(authViewModelProvider);
    final quizVM    = ref.watch(quizViewModelProvider);
    final course    = courseVM.selectedCourse;
    final user      = authVM.user;
    final enrolled  = user != null && courseVM.isEnrolled(widget.courseId);

    if (courseVM.isLoading || course == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (authVM.isInstructor && course.teacherId == user?.userId)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => context.push('/teacher/course/${widget.courseId}/edit'),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                course.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: course.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppTheme.secondary),
                        errorWidget: (_, __, ___) => _gradient())
                    : _gradient(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.85)])),
                ),
                Positioned(bottom: 16, left: 20, right: 20,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _Chip(course.category),
                    const SizedBox(height: 8),
                    Text(course.title, style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.3)),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.star, color: AppTheme.accent, size: 14),
                      Text(' ${course.rating.toStringAsFixed(1)}  ',
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                      Text('${course.enrollmentCount} students',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ])),
              ]),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabs,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textGrey,
                  indicatorColor: AppTheme.primary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Content'),
                    Tab(text: 'Quizzes'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            // ── Overview Tab ──
            _OverviewTab(course: course),
            // ── Content Tab ──
            _ContentTab(
              lessons: courseVM.lessons,
              enrolled: enrolled,
              courseId: widget.courseId,
              userId: user?.userId ?? '',
            ),
            // ── Quizzes Tab ──
            _QuizzesTab(
              exams: quizVM.exams,
              enrolled: enrolled,
              courseId: widget.courseId,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        course: course,
        enrolled: enrolled,
        courseId: widget.courseId,
        userId: user?.userId ?? '',
        isInstructor: authVM.isInstructor,
        ownsCourse: course.teacherId == user?.userId,
        lessons: courseVM.lessons,
      ),
    );
  }

  Widget _gradient() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary])));
}

// ── Overview Tab ──
class _OverviewTab extends StatelessWidget {
  final CourseEntity course;
  const _OverviewTab({required this.course});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Stats row
      Row(children: [
        _StatItem(Icons.play_lesson_outlined, '${course.lessonCount}', 'Lessons'),
        _StatItem(Icons.people_outline, '${course.enrollmentCount}', 'Students'),
        _StatItem(Icons.star_outline, course.rating.toStringAsFixed(1), 'Rating'),
      ]),
      const SizedBox(height: 24),

      // Instructor
      const Text('Instructor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primary,
          backgroundImage: course.teacherAvatar != null ? NetworkImage(course.teacherAvatar!) : null,
          child: course.teacherAvatar == null
              ? Text(course.teacherName.substring(0,1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              : null,
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(course.teacherName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const Text('Course Instructor', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
        ]),
      ]),
      const SizedBox(height: 24),

      // Description
      const Text('About This Course', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Text(course.description, style: const TextStyle(color: AppTheme.textGrey, height: 1.7, fontSize: 14)),
      const SizedBox(height: 24),

      // What you'll learn
      const Text('What You\'ll Learn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      ...['Practical skills you can apply immediately',
          'Industry-standard best practices',
          'Hands-on projects and exercises',
          'Certificate of completion'].map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
        ]),
      )),
    ]),
  );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _StatItem(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
    child: Column(children: [
      Icon(icon, color: AppTheme.primary, size: 22),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
    ]),
  ));
}

// ── Content Tab ──
class _ContentTab extends StatelessWidget {
  final List<LessonEntity> lessons;
  final bool enrolled;
  final String courseId, userId;
  const _ContentTab({required this.lessons, required this.enrolled,
      required this.courseId, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.video_library_outlined, size: 60, color: AppTheme.textGrey),
        SizedBox(height: 16),
        Text('No lessons added yet', style: TextStyle(color: AppTheme.textGrey, fontSize: 15)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length,
      itemBuilder: (_, i) {
        final lesson = lessons[i];
        final canAccess = enrolled || lesson.isFree;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: canAccess ? AppTheme.primary.withOpacity(0.1) : AppTheme.bg,
                borderRadius: BorderRadius.circular(10)),
              child: Icon(
                canAccess
                    ? (lesson.videoUrl != null ? Icons.play_circle_filled : Icons.picture_as_pdf)
                    : Icons.lock_outline,
                color: canAccess ? AppTheme.primary : AppTheme.textGrey, size: 24),
            ),
            title: Text(lesson.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time, size: 12, color: AppTheme.textGrey),
                const SizedBox(width: 4),
                Text(lesson.durationFormatted,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                if (lesson.videoUrl != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.videocam_outlined, size: 12, color: AppTheme.textGrey),
                ],
                if (lesson.pdfUrl != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.picture_as_pdf_outlined, size: 12, color: AppTheme.textGrey),
                ],
              ]),
            ]),
            trailing: lesson.isFree
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6)),
                    child: const Text('FREE',
                      style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.w700)))
                : null,
            onTap: canAccess
                ? () => context.push('/course/$courseId/lesson/${lesson.lessonId}')
                : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enroll to access this lesson'))),
          ),
        );
      },
    );
  }
}

// ── Quizzes Tab ──
class _QuizzesTab extends StatelessWidget {
  final List<ExamEntity> exams;
  final bool enrolled;
  final String courseId;
  const _QuizzesTab({required this.exams, required this.enrolled, required this.courseId});

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.quiz_outlined, size: 60, color: AppTheme.textGrey),
        SizedBox(height: 16),
        Text('No quizzes yet', style: TextStyle(color: AppTheme.textGrey, fontSize: 15)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      itemBuilder: (_, i) {
        final exam = exams[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
          child: ListTile(
            leading: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.quiz, color: AppTheme.accent, size: 24)),
            title: Text(exam.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Passing score: ${exam.passingScore}%',
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 12)),
              onPressed: enrolled
                  ? () => context.push('/course/$courseId/quiz/${exam.examId}')
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enroll to take this quiz'))),
              child: const Text('Start'),
            ),
          ),
        );
      },
    );
  }
}

// ── Bottom Bar ──
class _BottomBar extends ConsumerWidget {
  final CourseEntity course;
  final bool enrolled, isInstructor, ownsCourse;
  final String courseId, userId;
  final List<LessonEntity> lessons;
  const _BottomBar({
    required this.course, required this.enrolled,
    required this.courseId, required this.userId,
    required this.isInstructor, required this.ownsCourse,
    required this.lessons,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseVM = ref.watch(courseViewModelProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.divider))),
      child: Row(children: [
        if (!ownsCourse) Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Price', style: TextStyle(color: AppTheme.textGrey, fontSize: 11)),
          Text(
            course.isFree ? 'FREE' : '\$${course.price.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900,
              color: course.isFree ? AppTheme.success : AppTheme.textDark)),
        ]),
        if (!ownsCourse) const SizedBox(width: 16),
        Expanded(child: _buildActionButton(context, ref, courseVM)),
      ]),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, dynamic courseVM) {
    // Instructor who owns the course
    if (isInstructor && ownsCourse) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add Lesson'),
        onPressed: () => context.push('/teacher/course/$courseId/add-lesson'),
      );
    }
    // Already enrolled
    if (enrolled) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow),
        label: const Text('Continue Learning'),
        onPressed: lessons.isNotEmpty
            ? () => context.push('/course/$courseId/lesson/${lessons.first.lessonId}')
            : null,
      );
    }
    // Free course → enroll directly
    if (course.isFree) {
      return ElevatedButton(
        onPressed: userId.isEmpty ? null : () async {
          final ok = await ref.read(courseViewModelProvider).enrollInCourse(userId, courseId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok ? '🎉 Enrolled successfully!' : 'Enrollment failed'),
            backgroundColor: ok ? AppTheme.success : AppTheme.error));
          }
        },
        child: courseVM.isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Enroll for Free'),
      );
    }
    // Paid course → go to payment
    return ElevatedButton(
      onPressed: userId.isEmpty
          ? () => context.push('/auth/login')
          : () => context.push('/course/$courseId/pay'),
      child: Text('Buy Now — \$${course.price.toStringAsFixed(0)}'),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}
