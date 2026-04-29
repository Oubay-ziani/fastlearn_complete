import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

// ═══════════════════════════════════════════════════════════
// PROFILE SCREEN — UserEntity.manageProfile()
// ═══════════════════════════════════════════════════════════
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl  = TextEditingController();
  File?  _avatar;
  final  _picker  = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).user;
    _nameCtrl.text = user?.name ?? '';
    if (user?.role == AppConstants.roleInstructor) {
      // cast to InstructorEntity to get bio
      _bioCtrl.text = (user as dynamic).bio ?? '';
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _bioCtrl.dispose(); super.dispose(); }

  Future<void> _pickAvatar() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _avatar = File(img.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final vm  = ref.read(authViewModelProvider);
    final err = await vm.updateProfile(
      name: _nameCtrl.text.trim(),
      bio: vm.isInstructor ? _bioCtrl.text.trim() : null,
      avatarFile: _avatar,
    );
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.error));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: AppTheme.success));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm   = ref.watch(authViewModelProvider);
    final user = vm.user;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [

            // ── Avatar ──
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: _avatar != null
                      ? FileImage(_avatar!)
                      : (user?.profilePicture != null
                          ? NetworkImage(user!.profilePicture!) as ImageProvider
                          : null),
                  child: (_avatar == null && user?.profilePicture == null)
                      ? Text(
                          user?.name.isNotEmpty == true
                              ? user!.name.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(color: Colors.white, fontSize: 36,
                              fontWeight: FontWeight.bold))
                      : null,
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16)),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            const Text('Tap to change photo',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            const SizedBox(height: 28),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
              child: Text((user?.role ?? '').toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 12))),
            const SizedBox(height: 28),

            // Name
            _buildLabel('Full Name'),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary),
                hintText: 'Your full name'),
              validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 16),

            // Email (read-only)
            _buildLabel('Email Address'),
            TextFormField(
              initialValue: user?.email,
              readOnly: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textGrey),
                filled: true,
                fillColor: Color(0xFFF3F4F6)),
              style: const TextStyle(color: AppTheme.textGrey),
            ),
            const SizedBox(height: 4),
            const Text('Email cannot be changed',
              style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
            const SizedBox(height: 16),

            // Bio (instructor only)
            if (vm.isInstructor) ...[
              _buildLabel('Bio / About You'),
              TextFormField(
                controller: _bioCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Tell students about yourself, your experience and expertise...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.info_outline, color: AppTheme.primary))),
                validator: (v) {
                  if (vm.isInstructor && (v == null || v.isEmpty)) {
                    return 'Bio is required for instructors';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 8),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: vm.isLoading ? null : _save,
                child: vm.isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 16),

            // Danger zone
            const Divider(),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.logout, color: AppTheme.error),
              label: const Text('Sign Out', style: TextStyle(color: AppTheme.error)),
              onPressed: () async {
                await vm.logout();
                if (context.mounted) context.go('/auth/login');
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))));
}
