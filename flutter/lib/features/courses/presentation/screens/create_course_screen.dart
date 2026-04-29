import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

// ═══════════════════════════════════════════════════════════
// CREATE COURSE SCREEN — Instructor.createCourse + Course.publish
// ═══════════════════════════════════════════════════════════
class CreateCourseScreen extends ConsumerStatefulWidget {
  const CreateCourseScreen({super.key});
  @override
  ConsumerState<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends ConsumerState<CreateCourseScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _priceCtrl   = TextEditingController(text: '0');
  String _category   = AppConstants.categories.first;
  File?  _thumbnail;
  final _picker      = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _thumbnail = File(img.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authViewModelProvider);
    if (auth.uid == null) return;

    final vm = ref.read(courseViewModelProvider);
    final id = await vm.createCourse(
      teacherId: auth.uid!,
      teacherName: auth.user?.name ?? '',
      teacherAvatar: auth.user?.profilePicture,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      thumbnailFile: _thumbnail,
    );

    if (!mounted) return;
    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Course created! Add lessons to get started.'),
        backgroundColor: AppTheme.success));
      context.pushReplacement('/teacher/course/$id/add-lesson');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(vm.error ?? 'Failed to create course'),
        backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(courseViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Create New Course'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Thumbnail picker
          GestureDetector(
            onTap: _pickThumbnail,
            child: Container(
              height: 180, width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
                image: _thumbnail != null ? DecorationImage(
                  image: FileImage(_thumbnail!), fit: BoxFit.cover) : null),
              child: _thumbnail == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 54, height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.add_photo_alternate, color: AppTheme.primary, size: 28)),
                const SizedBox(height: 10),
                const Text('Upload Course Thumbnail',
                  style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.w500)),
                const Text('Recommended: 1280×720px',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
              ]) : null,
            ),
          ),
          const SizedBox(height: 24),

          const _Label('Course Title'),
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. Complete Flutter Development Course',
              prefixIcon: Icon(Icons.title, color: AppTheme.primary)),
            validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: 16),

          const _Label('Description'),
          TextFormField(
            controller: _descCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Describe what students will learn...',
              alignLabelWithHint: true,
              prefixIcon: Padding(padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.description, color: AppTheme.primary))),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Description is required';
              if (v.length < 50) return 'Description must be at least 50 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),

          const _Label('Category'),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.category, color: AppTheme.primary)),
            items: AppConstants.categories.map((c) =>
              DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 16),

          const _Label('Price (USD)'),
          TextFormField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: '0 for free',
              prefixIcon: Icon(Icons.attach_money, color: AppTheme.primary)),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Price required';
              final p = double.tryParse(v);
              if (p == null || p < 0) return 'Enter a valid price';
              return null;
            },
          ),
          const SizedBox(height: 12),
          const Text('Set 0 for a free course. You can change this later.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),

          if (vm.uploadProgress > 0 && vm.uploadProgress < 1) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: vm.uploadProgress,
              backgroundColor: AppTheme.divider,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary)),
            const SizedBox(height: 4),
            Text('Uploading thumbnail: ${(vm.uploadProgress * 100).toInt()}%',
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          ],
          const SizedBox(height: 32),

          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: vm.isLoading ? null : _submit,
            child: vm.isLoading
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 12),
                    Text('Creating Course...'),
                  ])
                : const Text('Create Course & Add Lessons'),
          )),
        ])),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ADD LESSON SCREEN — Instructor.addLesson + Course.addLesson
// Supports: Video upload + PDF upload + Lesson.addQuestion
// ═══════════════════════════════════════════════════════════
class AddLessonScreen extends ConsumerStatefulWidget {
  final String courseId;
  const AddLessonScreen({super.key, required this.courseId});
  @override
  ConsumerState<AddLessonScreen> createState() => _AddLessonScreenState();
}

class _AddLessonScreenState extends ConsumerState<AddLessonScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _titleCtrl= TextEditingController();
  final _descCtrl = TextEditingController();
  final _durCtrl  = TextEditingController(text: '0');
  File?  _videoFile;
  File?  _pdfFile;
  bool   _isFree  = false;
  int    _order   = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lessons = ref.read(courseViewModelProvider).lessons;
      setState(() => _order = lessons.length);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _durCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() => _videoFile = File(result.files.single.path!));
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() => _pdfFile = File(result.files.single.path!));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_videoFile == null && _pdfFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please upload a video or PDF for this lesson'),
        backgroundColor: AppTheme.warning));
      return;
    }

    final vm = ref.read(courseViewModelProvider);
    final id = await vm.addLesson(
      courseId: widget.courseId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      videoFile: _videoFile,
      pdfFile: _pdfFile,
      orderIndex: _order,
      durationSeconds: (int.tryParse(_durCtrl.text) ?? 0) * 60,
      isFree: _isFree,
    );

    if (!mounted) return;
    if (id != null) {
      _titleCtrl.clear(); _descCtrl.clear();
      setState(() { _videoFile = null; _pdfFile = null; _isFree = false; _order++; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lesson added! Add more or go back.'),
        backgroundColor: AppTheme.success));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(vm.error ?? 'Failed to add lesson'),
        backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(courseViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Add Lesson'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: () => context.go('/teacher'),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Lesson order indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8)),
            child: Text('Lesson #${_order + 1}',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700))),
          const SizedBox(height: 20),

          const _Label('Lesson Title'),
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. Introduction to Flutter Widgets',
              prefixIcon: Icon(Icons.play_lesson_outlined, color: AppTheme.primary)),
            validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
          ),
          const SizedBox(height: 16),

          const _Label('Description (optional)'),
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'What will students learn in this lesson?',
              alignLabelWithHint: true),
          ),
          const SizedBox(height: 16),

          const _Label('Duration (minutes)'),
          TextFormField(
            controller: _durCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.timer_outlined, color: AppTheme.primary)),
          ),
          const SizedBox(height: 20),

          // ── Video Upload ──
          const _Label('Video File'),
          GestureDetector(
            onTap: _pickVideo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _videoFile != null ? AppTheme.primary.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _videoFile != null ? AppTheme.primary : AppTheme.divider,
                  width: _videoFile != null ? 2 : 1)),
              child: Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.videocam,
                    color: _videoFile != null ? AppTheme.primary : AppTheme.textGrey, size: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_videoFile != null ? _videoFile!.path.split('/').last : 'Upload Video',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _videoFile != null ? AppTheme.textDark : AppTheme.textGrey),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(_videoFile != null ? 'Tap to change' : 'MP4, MOV, AVI supported',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                ])),
                if (_videoFile != null)
                  const Icon(Icons.check_circle, color: AppTheme.success, size: 22)
                else
                  const Icon(Icons.upload_outlined, color: AppTheme.textGrey),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // ── PDF Upload ──
          const _Label('PDF File (optional)'),
          GestureDetector(
            onTap: _pickPdf,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _pdfFile != null ? AppTheme.accent.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _pdfFile != null ? AppTheme.accent : AppTheme.divider,
                  width: _pdfFile != null ? 2 : 1)),
              child: Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.picture_as_pdf,
                    color: _pdfFile != null ? AppTheme.accent : AppTheme.textGrey, size: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_pdfFile != null ? _pdfFile!.path.split('/').last : 'Upload PDF Resource',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _pdfFile != null ? AppTheme.textDark : AppTheme.textGrey),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(_pdfFile != null ? 'Tap to change' : 'PDF files only',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                ])),
                if (_pdfFile != null)
                  const Icon(Icons.check_circle, color: AppTheme.success, size: 22)
                else
                  const Icon(Icons.upload_outlined, color: AppTheme.textGrey),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // Free lesson toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
            child: Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Free Preview', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('Allow non-enrolled students to watch this lesson',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
              ])),
              Switch(value: _isFree, onChanged: (v) => setState(() => _isFree = v),
                activeThumbColor: AppTheme.primary),
            ]),
          ),

          if (vm.uploadProgress > 0 && vm.uploadProgress < 1) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: vm.uploadProgress,
              backgroundColor: AppTheme.divider,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary)),
            const SizedBox(height: 4),
            Text('Uploading: ${(vm.uploadProgress * 100).toInt()}%',
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          ],
          const SizedBox(height: 32),

          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Lesson'),
            onPressed: vm.isLoading ? null : _submit,
          )),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            icon: const Icon(Icons.quiz_outlined),
            label: const Text('Create Exam / Quiz'),
            onPressed: () => context.push('/teacher/course/${widget.courseId}/create-exam'),
          )),
        ])),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CREATE EXAM SCREEN — Instructor.createExam + setLessonQuestions
// Exam.createQuestion + Question management
// ═══════════════════════════════════════════════════════════
class CreateExamScreen extends ConsumerStatefulWidget {
  final String courseId;
  const CreateExamScreen({super.key, required this.courseId});
  @override
  ConsumerState<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends ConsumerState<CreateExamScreen> {
  final _titleCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController(text: '60');
  String? _examId;
  bool    _examCreated= false;

  // Question form
  final _qCtrl = TextEditingController();
  final _opt1  = TextEditingController();
  final _opt2  = TextEditingController();
  final _opt3  = TextEditingController();
  final _opt4  = TextEditingController();
  String _correct = 'A';
  int    _marks   = 1;

  @override
  void dispose() {
    _titleCtrl.dispose(); _passCtrl.dispose();
    _qCtrl.dispose(); _opt1.dispose(); _opt2.dispose();
    _opt3.dispose(); _opt4.dispose();
    super.dispose();
  }

  Future<void> _createExam() async {
    if (_titleCtrl.text.isEmpty) return;
    final vm = ref.read(quizViewModelProvider);
    final id = await vm.createExam(
      courseId: widget.courseId,
      title: _titleCtrl.text.trim(),
      passingScore: int.tryParse(_passCtrl.text) ?? 60,
    );
    if (id != null) setState(() { _examId = id; _examCreated = true; });
  }

  Future<void> _addQuestion() async {
    if (_examId == null || _qCtrl.text.isEmpty) return;
    final options = [_opt1.text, _opt2.text, _opt3.text, _opt4.text];
    if (options.any((o) => o.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fill all 4 options'), backgroundColor: AppTheme.warning));
      return;
    }

    final correctAns = switch (_correct) {
      'A' => _opt1.text, 'B' => _opt2.text,
      'C' => _opt3.text, _ => _opt4.text,
    };

    await ref.read(quizViewModelProvider).addQuestion(
      courseId: widget.courseId,
      examId: _examId!,
      questionText: _qCtrl.text.trim(),
      options: options,
      correctAnswer: correctAns,
      marks: _marks,
    );

    _qCtrl.clear(); _opt1.clear(); _opt2.clear();
    _opt3.clear(); _opt4.clear();
    setState(() { _correct = 'A'; _marks = 1; });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Question added!'), backgroundColor: AppTheme.success));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(quizViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Create Exam'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
        actions: [if (_examCreated) TextButton(
          onPressed: () => context.pop(),
          child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          if (!_examCreated) ...[
            const Text('Exam Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Exam Title',
                hintText: 'e.g. Module 1 Assessment',
                prefixIcon: Icon(Icons.quiz, color: AppTheme.primary))),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Passing Score (%)',
                prefixIcon: Icon(Icons.percent, color: AppTheme.primary))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: vm.isLoading ? null : _createExam,
              child: const Text('Create Exam & Add Questions'))),
          ] else ...[
            // Exam created banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.success.withOpacity(0.4))),
              child: Row(children: [
                const Icon(Icons.check_circle, color: AppTheme.success),
                const SizedBox(width: 10),
                Expanded(child: Text('Exam "${_titleCtrl.text}" created. Now add questions.',
                  style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600))),
              ])),
            const SizedBox(height: 20),

            // Questions list
            if (vm.questions.isNotEmpty) ...[
              Text('Questions Added (${vm.questions.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...vm.questions.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]),
                child: Row(children: [
                  Container(width: 28, height: 28,
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: Center(child: Text('${e.key + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.value.questionText,
                    style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  Text('${e.value.marks}pt', style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
                ]),
              )),
              const SizedBox(height: 16),
            ],

            const Text('Add Question', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),

            TextFormField(
              controller: _qCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Question Text',
                prefixIcon: Icon(Icons.help_outline, color: AppTheme.primary))),
            const SizedBox(height: 14),

            ...(['A', 'B', 'C', 'D'].asMap().entries.map((e) {
              final ctrl = [_opt1, _opt2, _opt3, _opt4][e.key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    labelText: 'Option ${e.value}',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(10),
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: _correct == e.value ? AppTheme.success : AppTheme.bg,
                        shape: BoxShape.circle),
                      child: Center(child: Text(e.value,
                        style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12,
                          color: _correct == e.value ? Colors.white : AppTheme.textGrey))))),
                ),
              );
            })),

            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Correct Answer:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Row(children: ['A','B','C','D'].map((opt) => GestureDetector(
                  onTap: () => setState(() => _correct = opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _correct == opt ? AppTheme.success : AppTheme.bg,
                      shape: BoxShape.circle,
                      border: Border.all(color: _correct == opt ? AppTheme.success : AppTheme.divider)),
                    child: Center(child: Text(opt, style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _correct == opt ? Colors.white : AppTheme.textGrey))),
                  ))).toList()),
              ])),
              const SizedBox(width: 20),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Marks:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _marks > 1 ? () => setState(() => _marks--) : null),
                  Text('$_marks', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                    onPressed: () => setState(() => _marks++)),
                ]),
              ]),
            ]),
            const SizedBox(height: 24),

            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
              onPressed: vm.isLoading ? null : _addQuestion,
            )),
          ],
        ]),
      ),
    );
  }
}

// ── Shared label widget ──
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)));
}
