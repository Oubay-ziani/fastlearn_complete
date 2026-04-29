import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/domain/entities.dart';

// ═══════════════════════════════════════════════════════════
// VIDEO PLAYER SCREEN — Student.watchCourses
// Tracks lesson progress via markLessonComplete()
// Supports: Video streaming + PDF viewing in-app
// ═══════════════════════════════════════════════════════════
class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String courseId, lessonId;
  const VideoPlayerScreen({super.key, required this.courseId, required this.lessonId});
  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  VideoPlayerController? _videoCtrl;
  ChewieController?      _chewieCtrl;
  LessonEntity?          _lesson;
  List<LessonEntity>     _allLessons = [];
  bool                   _isLoading  = true;
  bool                   _marked     = false;
  String?                _pdfPath;
  bool                   _showPdf    = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    // Get lessons list
    _allLessons = ref.read(courseViewModelProvider).lessons;

    // Find current lesson
    _lesson = _allLessons.firstWhere(
      (l) => l.lessonId == widget.lessonId,
      orElse: () => _allLessons.first,
    );

    // Init video if available
    if (_lesson?.videoUrl != null) {
      _videoCtrl = VideoPlayerController.networkUrl(
        Uri.parse(_lesson!.videoUrl!));
      await _videoCtrl!.initialize();

      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl!,
        autoPlay: true,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
        aspectRatio: 16 / 9,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primary,
          handleColor: AppTheme.primary,
          bufferedColor: AppTheme.primary.withOpacity(0.3),
          backgroundColor: AppTheme.divider,
        ),
      );

      // Listen for video completion to mark as done
      _videoCtrl!.addListener(() {
        if (_videoCtrl!.value.position >= _videoCtrl!.value.duration &&
            !_marked &&
            _videoCtrl!.value.duration.inSeconds > 0) {
          _markComplete();
        }
      });
    }

    // Download PDF for viewing
    if (_lesson?.pdfUrl != null) {
      try {
        final response = await http.get(Uri.parse(_lesson!.pdfUrl!));
        final dir  = await getTemporaryDirectory();
        final file = File('${dir.path}/lesson_${widget.lessonId}.pdf');
        await file.writeAsBytes(response.bodyBytes);
        setState(() => _pdfPath = file.path);
      } catch (_) {}
    }

    setState(() => _isLoading = false);
  }

  Future<void> _markComplete() async {
    if (_marked) return;
    _marked = true;
    final uid = ref.read(authViewModelProvider).uid ?? '';
    if (uid.isEmpty) return;
    await ref.read(courseViewModelProvider).markLessonComplete(
      uid, widget.courseId, widget.lessonId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Lesson marked as complete!'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 2)));
    }
  }

  void _goToLesson(LessonEntity lesson) {
    _videoCtrl?.pause();
    context.pushReplacement('/course/${widget.courseId}/lesson/${lesson.lessonId}');
  }

  @override
  void dispose() {
    _chewieCtrl?.dispose();
    _videoCtrl?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_lesson?.title ?? 'Lesson',
          style: const TextStyle(color: Colors.white, fontSize: 15),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop()),
        actions: [
          if (_lesson?.pdfUrl != null)
            IconButton(
              icon: Icon(
                _showPdf ? Icons.videocam : Icons.picture_as_pdf,
                color: Colors.white),
              onPressed: () => setState(() => _showPdf = !_showPdf),
              tooltip: _showPdf ? 'Show Video' : 'View PDF',
            ),
          // Mark complete manually
          IconButton(
            icon: Icon(
              _marked ? Icons.check_circle : Icons.check_circle_outline,
              color: _marked ? AppTheme.success : Colors.white),
            onPressed: _marked ? null : _markComplete,
            tooltip: 'Mark as Complete',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(children: [

              // ── Video / PDF Area ──
              if (!_showPdf && _chewieCtrl != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Chewie(controller: _chewieCtrl!))
              else if (_showPdf && _pdfPath != null)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.42,
                  child: PDFView(
                    filePath: _pdfPath!,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: true,
                    pageFling: false,
                    onError: (e) => debugPrint('PDF error: $e'),
                  ))
              else if (_lesson?.videoUrl == null && _lesson?.pdfUrl == null)
                Container(
                  height: 200, color: Colors.black,
                  child: const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library_outlined, color: Colors.white54, size: 60),
                      SizedBox(height: 12),
                      Text('No video content', style: TextStyle(color: Colors.white54)),
                    ])))
              else
                Container(
                  height: 200, color: Colors.black,
                  child: Center(child: CircularProgressIndicator(
                    color: AppTheme.primary.withOpacity(0.6)))),

              // ── Lesson Info + Controls ──
              Expanded(
                child: Container(
                  color: AppTheme.bg,
                  child: Column(children: [

                    // Current lesson details
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_lesson?.title ?? '',
                          style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                        if (_lesson?.description != null) ...[
                          const SizedBox(height: 6),
                          Text(_lesson!.description!,
                            style: const TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.5)),
                        ],
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textGrey),
                          const SizedBox(width: 4),
                          Text(_lesson?.durationFormatted ?? '',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                          const Spacer(),
                          if (_marked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12)),
                              child: const Row(children: [
                                Icon(Icons.check_circle, color: AppTheme.success, size: 14),
                                SizedBox(width: 4),
                                Text('Completed',
                                  style: TextStyle(
                                    color: AppTheme.success, fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                              ])),
                        ]),
                      ]),
                    ),

                    const Divider(height: 1),

                    // Prev / Next navigation
                    if (_allLessons.length > 1) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        color: Colors.white,
                        child: Row(children: [
                          // Previous lesson
                          Builder(builder: (_) {
                            final idx = _allLessons.indexWhere(
                              (l) => l.lessonId == widget.lessonId);
                            final hasPrev = idx > 0;
                            return Expanded(child: OutlinedButton.icon(
                              icon: const Icon(Icons.skip_previous, size: 18),
                              label: const Text('Previous', style: TextStyle(fontSize: 13)),
                              onPressed: hasPrev ? () => _goToLesson(_allLessons[idx - 1]) : null,
                            ));
                          }),
                          const SizedBox(width: 12),
                          // Next lesson
                          Builder(builder: (_) {
                            final idx = _allLessons.indexWhere(
                              (l) => l.lessonId == widget.lessonId);
                            final hasNext = idx < _allLessons.length - 1;
                            return Expanded(child: ElevatedButton.icon(
                              icon: const Icon(Icons.skip_next, size: 18),
                              label: const Text('Next', style: TextStyle(fontSize: 13)),
                              onPressed: hasNext ? () => _goToLesson(_allLessons[idx + 1]) : null,
                            ));
                          }),
                        ]),
                      ),
                      const Divider(height: 1),
                    ],

                    // All lessons list
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Row(children: [
                        const Text('Course Content',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const Spacer(),
                        Text('${_allLessons.length} lessons',
                          style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                      ]),
                    ),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _allLessons.length,
                        itemBuilder: (_, i) {
                          final l = _allLessons[i];
                          final isCurrent = l.lessonId == widget.lessonId;
                          return GestureDetector(
                            onTap: () => _goToLesson(l),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppTheme.primary.withOpacity(0.08) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent ? AppTheme.primary : Colors.transparent,
                                  width: isCurrent ? 2 : 0)),
                              child: Row(children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? AppTheme.primary : AppTheme.bg,
                                    borderRadius: BorderRadius.circular(8)),
                                  child: Icon(
                                    l.videoUrl != null
                                        ? Icons.play_arrow : Icons.picture_as_pdf,
                                    color: isCurrent ? Colors.white : AppTheme.textGrey,
                                    size: 18)),
                                const SizedBox(width: 10),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${i + 1}. ${l.title}',
                                      style: TextStyle(
                                        fontWeight: isCurrent
                                            ? FontWeight.w700 : FontWeight.w500,
                                        fontSize: 13,
                                        color: isCurrent
                                            ? AppTheme.primary : AppTheme.textDark),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(l.durationFormatted,
                                      style: const TextStyle(
                                        fontSize: 11, color: AppTheme.textGrey)),
                                  ])),
                                if (isCurrent)
                                  const Icon(Icons.play_circle_filled,
                                    color: AppTheme.primary, size: 20),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
    );
  }
}
