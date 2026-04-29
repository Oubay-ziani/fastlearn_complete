import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/entities.dart';

// ═══════════════════════════════════════════════════════════
// HOME SCREEN — Student main hub
// ═══════════════════════════════════════════════════════════
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseVM = ref.read(courseViewModelProvider);
      final authVM   = ref.read(authViewModelProvider);
      courseVM.watchPublishedCourses();
      if (authVM.uid != null) courseVM.watchEnrolledIds(authVM.uid!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth   = ref.watch(authViewModelProvider);
    final course = ref.watch(courseViewModelProvider);

    // Redirect by role
    if (auth.isAdmin)      return _redirect('/admin');
    if (auth.isInstructor) return _redirect('/teacher');

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _HomeTab(courseVM: course, authVM: auth),
          const _SearchTab(),
          const _EnrolledTab(),
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Browse'),
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined), activeIcon: Icon(Icons.book), label: 'My Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _redirect(String path) {
    WidgetsBinding.instance.addPostFrameCallback((_) => context.go(path));
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// ── Home Tab ──
class _HomeTab extends StatelessWidget {
  final dynamic courseVM;
  final dynamic authVM;
  const _HomeTab({required this.courseVM, required this.authVM});

  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
    // App Bar
    SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      title: Row(children: [
        Container(width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
            borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.school, color: Colors.white, size: 18)),
        const SizedBox(width: 10),
        const Text('Fast Learn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
      ]),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        const SizedBox(width: 4),
      ],
    ),

    SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(delegate: SliverChildListDelegate([

        // Greeting
        const Text('Welcome back,', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
        Text(authVM.user?.name ?? 'Learner! 👋',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        const SizedBox(height: 20),

        // Hero Banner
        Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, Color(0xFF0D47A1)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Level Up Your Skills', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Explore 100+ courses across\nall topics', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                onPressed: () => context.push('/browse'),
                child: const Text('Browse Now'),
              ),
            ])),
            const Icon(Icons.rocket_launch, color: Colors.white30, size: 70),
          ]),
        ),
        const SizedBox(height: 28),

        // Categories
        const Text('Categories', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AppConstants.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = AppConstants.categories[i];
              return GestureDetector(
                onTap: () {
                  // Navigate to browse with category filter
                  context.push('/browse');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: i % 3 == 0 ? AppTheme.primary.withOpacity(0.1) :
                           i % 3 == 1 ? AppTheme.accent.withOpacity(0.1) :
                                        AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Text(cat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),

        // Popular Courses
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Popular Courses', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          TextButton(
            onPressed: () => context.push('/browse'),
            child: const Text('See All', style: TextStyle(color: AppTheme.primary)),
          ),
        ]),
        const SizedBox(height: 12),

        if (courseVM.isLoading)
          ..._shimmerCards()
        else if (courseVM.courses.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No courses yet. Check back soon!', style: TextStyle(color: AppTheme.textGrey))))
        else
          ...courseVM.courses.take(5).map<Widget>((c) => _CourseCard(course: c)),

      ])),
    ),
  ]);

  List<Widget> _shimmerCards() => List.generate(3, (_) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Shimmer.fromColors(
      baseColor: AppTheme.shimmerBase,
      highlightColor: AppTheme.shimmerHigh,
      child: Container(height: 240, decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14))),
    ),
  ));
}

// ── Course Card Widget ──
class _CourseCard extends StatelessWidget {
  final CourseEntity course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/course/${course.courseId}'),
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Thumbnail
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          child: course.thumbnailUrl != null
              ? CachedNetworkImage(
                  imageUrl: course.thumbnailUrl!,
                  height: 140, width: double.infinity, fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: AppTheme.shimmerBase,
                    highlightColor: AppTheme.shimmerHigh,
                    child: Container(height: 140, color: Colors.white)),
                  errorWidget: (_, __, ___) => _PlaceholderThumb())
              : _PlaceholderThumb(),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Category chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6)),
              child: Text(course.category,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primary)),
            ),
            const SizedBox(height: 8),
            Text(course.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(course.teacherName, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.star, color: AppTheme.accent, size: 14),
              Text(' ${course.rating.toStringAsFixed(1)} ',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              Text('(${course.ratingCount})', style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
              const Spacer(),
              Text(
                course.isFree ? 'FREE' : '\$${course.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16,
                  color: course.isFree ? AppTheme.success : AppTheme.textDark),
              ),
            ]),
          ]),
        ),
      ]),
    ),
  );
}

class _PlaceholderThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 140, width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary])),
    child: const Icon(Icons.play_lesson, color: Colors.white38, size: 50),
  );
}

// ── Search Tab ──
class _SearchTab extends ConsumerStatefulWidget {
  const _SearchTab();
  @override
  ConsumerState<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<_SearchTab> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(courseViewModelProvider);

    return CustomScrollView(slivers: [
      SliverAppBar(
        floating: true,
        backgroundColor: Colors.white,
        title: const Text('Browse Courses'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _ctrl,
              onChanged: vm.search,
              decoration: InputDecoration(
                hintText: 'Search courses, topics...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear),
                        onPressed: () { _ctrl.clear(); vm.search(''); })
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
            ),
          ),
        ),
      ),

      // Category filter
      SliverToBoxAdapter(child: SizedBox(
        height: 50,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemCount: ['All', ...AppConstants.categories].length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final cats = ['All', ...AppConstants.categories];
            final cat  = cats[i];
            final sel  = vm.selectedCategory == cat;
            return GestureDetector(
              onTap: () => vm.setCategory(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider)),
                child: Text(cat, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : AppTheme.textDark)),
              ),
            );
          },
        ),
      )),

      if (vm.isLoading)
        const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
      else if (vm.courses.isEmpty)
        const SliverFillRemaining(
          child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.textGrey),
            SizedBox(height: 16),
            Text('No courses found', style: TextStyle(color: AppTheme.textGrey, fontSize: 16)),
          ])))
      else
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) => _CourseCard(course: vm.courses[i]),
            childCount: vm.courses.length,
          )),
        ),
    ]);
  }
}

// ── Enrolled Tab ──
class _EnrolledTab extends ConsumerWidget {
  const _EnrolledTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth   = ref.watch(authViewModelProvider);
    final course = ref.watch(courseViewModelProvider);

    return CustomScrollView(slivers: [
      const SliverAppBar(
        backgroundColor: Colors.white, floating: true,
        title: Text('My Learning'),
      ),
      if (course.enrolledIds.isEmpty)
        const SliverFillRemaining(
          child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.book_outlined, size: 64, color: AppTheme.textGrey),
            SizedBox(height: 16),
            Text('No courses enrolled yet', style: TextStyle(color: AppTheme.textGrey, fontSize: 16)),
            SizedBox(height: 8),
            Text('Browse and enroll in courses to start learning',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13), textAlign: TextAlign.center),
          ])))
      else
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) {
            final enrollment = course.enrollments[i];
            return _EnrolledCourseCard(
              enrollment: enrollment,
              onTap: () => context.push('/course/${enrollment.courseId}'),
            );
          }, childCount: course.enrollments.length)),
        ),
    ]);
  }
}

class _EnrolledCourseCard extends StatelessWidget {
  final dynamic enrollment;
  final VoidCallback onTap;
  const _EnrolledCourseCard({required this.enrollment, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Row(children: [
        Container(width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
            borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.play_lesson, color: Colors.white, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Course: ${enrollment.courseId.substring(0, 8)}...',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: enrollment.progress / 100,
            backgroundColor: AppTheme.divider,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
          ),
          const SizedBox(height: 4),
          Text('${enrollment.progress}% complete',
            style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
        ])),
        const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textGrey),
      ]),
    ),
  );
}

// ── Profile Tab (quick access) ──
class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authViewModelProvider);
    final user = auth.user;

    return CustomScrollView(slivers: [
      SliverAppBar(
        backgroundColor: Colors.white, floating: true,
        title: const Text('My Profile'),
        actions: [
          TextButton(
            onPressed: () => auth.logout(),
            child: const Text('Log Out', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverList(delegate: SliverChildListDelegate([
          Center(child: Column(children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: AppTheme.primary,
              backgroundImage: user?.profilePicture != null
                  ? NetworkImage(user!.profilePicture!) : null,
              child: user?.profilePicture == null
                  ? Text(user?.name.substring(0,1).toUpperCase() ?? 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(height: 14),
            Text(user?.name ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text(user?.email ?? '', style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
              child: Text(user?.role.toUpperCase() ?? '',
                style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ])),
          const SizedBox(height: 30),

          _ProfileItem(icon: Icons.person_outline, label: 'Edit Profile', onTap: () => context.push('/profile')),
          _ProfileItem(icon: Icons.book_outlined, label: 'My Courses', onTap: () => context.push('/student/courses')),
          _ProfileItem(icon: Icons.card_membership, label: 'Certificates', onTap: () => context.push('/certificates')),
          _ProfileItem(icon: Icons.payment_outlined, label: 'Payment History', onTap: () => context.push('/payments/history')),
          _ProfileItem(icon: Icons.video_call_outlined, label: 'My Sessions', onTap: () => context.push('/sessions')),
          const Divider(height: 30),
          _ProfileItem(
            icon: Icons.logout,
            label: 'Log Out',
            color: AppTheme.error,
            onTap: () async {
              await auth.logout();
              if (context.mounted) context.go('/auth/login');
            },
          ),
        ])),
      ),
    ]);
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ProfileItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color ?? AppTheme.primary),
    title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color ?? AppTheme.textDark)),
    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textGrey),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}
