import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/entities.dart';

// ═══════════════════════════════════════════════════════════
// EDIT COURSE SCREEN — Instructor manage course + Course.setPrice
// ═══════════════════════════════════════════════════════════
class EditCourseScreen extends ConsumerStatefulWidget {
  final String courseId;
  const EditCourseScreen({super.key, required this.courseId});
  @override
  ConsumerState<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends ConsumerState<EditCourseScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  String   _category = AppConstants.categories.first;
  File?    _thumbnail;
  CourseEntity? _course;
  bool     _isLoaded = false;
  final    _picker   = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(courseViewModelProvider).selectCourse(widget.courseId);
      final c = ref.read(courseViewModelProvider).selectedCourse;
      if (c != null && mounted) {
        setState(() {
          _course    = c;
          _titleCtrl.text = c.title;
          _descCtrl.text  = c.description;
          _priceCtrl.text = c.price.toString();
          _category  = c.category;
          _isLoaded  = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _thumbnail = File(img.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = ref.read(courseViewModelProvider);
    await vm.updateCourse(widget.courseId, {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text) ?? 0,
      'category': _category,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Course updated!'), backgroundColor: AppTheme.success));
    context.pop();
  }

  Future<void> _submitForReview() async {
    await ref.read(courseViewModelProvider).submitForReview(widget.courseId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Course submitted for review!'), backgroundColor: AppTheme.success));
    context.pop();
  }

  Future<void> _deleteCourse() async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Course'),
      content: const Text('This will permanently delete the course and all its lessons. Continue?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete')),
      ]));
    if (confirm == true) {
      await ref.read(courseViewModelProvider).deleteCourse(widget.courseId);
      if (mounted) context.go('/teacher');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(courseViewModelProvider);

    if (!_isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Edit Course'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
            onPressed: _deleteCourse,
            tooltip: 'Delete course'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Status badge
            if (_course != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(_course!.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Text('Status: ${_course!.status.toUpperCase()}',
                  style: TextStyle(
                    color: _statusColor(_course!.status),
                    fontWeight: FontWeight.w700, fontSize: 12))),
              const SizedBox(height: 20),
            ],

            // Thumbnail
            GestureDetector(
              onTap: _pickThumbnail,
              child: Container(
                height: 160, width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  image: _thumbnail != null
                      ? DecorationImage(image: FileImage(_thumbnail!), fit: BoxFit.cover)
                      : (_course?.thumbnailUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_course!.thumbnailUrl!),
                              fit: BoxFit.cover)
                          : null),
                  color: AppTheme.bg,
                  border: Border.all(color: AppTheme.divider)),
                child: _thumbnail == null && _course?.thumbnailUrl == null
                    ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate, color: AppTheme.textGrey, size: 36),
                        SizedBox(height: 8),
                        Text('Upload Thumbnail', style: TextStyle(color: AppTheme.textGrey)),
                      ])
                    : Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8)),
                            child: const Text('Change Photo',
                              style: TextStyle(color: Colors.white, fontSize: 11)))))),
            ),
            const SizedBox(height: 20),

            _buildLabel('Title'),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.title, color: AppTheme.primary)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            _buildLabel('Description'),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(alignLabelWithHint: true),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            _buildLabel('Category'),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category, color: AppTheme.primary)),
              items: AppConstants.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),

            _buildLabel('Price (USD)'),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.attach_money, color: AppTheme.primary)),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid price';
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Action buttons
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: vm.isLoading ? null : _save,
              child: vm.isLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            )),
            const SizedBox(height: 12),

            if (_course?.status == AppConstants.statusDraft ||
                _course?.status == AppConstants.statusRejected)
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Submit for Review'),
                onPressed: _submitForReview,
              )),
            const SizedBox(height: 12),

            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add New Lesson'),
              onPressed: () => context.push('/teacher/course/${widget.courseId}/add-lesson'),
            )),
            const SizedBox(height: 12),

            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              icon: const Icon(Icons.quiz_outlined),
              label: const Text('Create Exam'),
              onPressed: () => context.push('/teacher/course/${widget.courseId}/create-exam'),
            )),
          ]),
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
    AppConstants.statusPublished => AppTheme.success,
    AppConstants.statusPending   => AppTheme.warning,
    AppConstants.statusRejected  => AppTheme.error,
    _ => AppTheme.textGrey,
  };

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)));
}
