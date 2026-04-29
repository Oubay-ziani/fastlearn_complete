import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/entities.dart';

// ═══════════════════════════════════════════════════════════
// BROWSE SCREEN — Full course browsing with search + filter
// ═══════════════════════════════════════════════════════════
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});
  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
      ref.read(courseViewModelProvider).watchPublishedCourses());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(courseViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Browse Courses'),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _ctrl,
              onChanged: vm.search,
              decoration: InputDecoration(
                hintText: 'Search courses, instructors...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () { _ctrl.clear(); vm.search(''); })
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
        ),
      ),
      body: Column(children: [
        // Category chips
        SizedBox(
          height: 48,
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
        ),
        const Divider(height: 1),

        // Results
        Expanded(child: vm.isLoading
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 6,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Shimmer.fromColors(
                    baseColor: AppTheme.shimmerBase,
                    highlightColor: AppTheme.shimmerHigh,
                    child: Container(height: 240, decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(14))))))
            : vm.courses.isEmpty
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.search_off, size: 64, color: AppTheme.textGrey),
                    SizedBox(height: 16),
                    Text('No courses found', style: TextStyle(color: AppTheme.textGrey, fontSize: 16))]))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.courses.length,
                    itemBuilder: (_, i) => _BrowseCourseCard(course: vm.courses[i]))),
      ]),
    );
  }
}

class _BrowseCourseCard extends StatelessWidget {
  final CourseEntity course;
  const _BrowseCourseCard({required this.course});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/course/${course.courseId}'),
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0,4))]),
      child: Row(children: [
        // Thumbnail
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
          child: SizedBox(
            width: 100, height: 100,
            child: course.thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: course.thumbnailUrl!, fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppTheme.shimmerBase),
                    errorWidget: (_, __, ___) => _thumb())
                : _thumb()),
        ),
        Expanded(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(course.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(course.teacherName, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.star, color: AppTheme.accent, size: 12),
              Text(' ${course.rating.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(course.isFree ? 'FREE' : '\$${course.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14,
                  color: course.isFree ? AppTheme.success : AppTheme.textDark)),
            ]),
          ]),
        )),
      ]),
    ),
  );

  Widget _thumb() => Container(
    color: AppTheme.primary,
    child: const Icon(Icons.play_lesson, color: Colors.white38, size: 36));
}
