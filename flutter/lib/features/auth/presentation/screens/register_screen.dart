import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _bioCtrl    = TextEditingController();
  bool  _obscure    = true;
  String _role = AppConstants.roleStudent;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = ref.read(authViewModelProvider);
    final err = await vm.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role: _role,
      bio: _role == AppConstants.roleInstructor ? _bioCtrl.text.trim() : null,
    );
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Role selector ──
              const Text('I am a...', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              Row(children: [
                _RoleChip(
                  label: 'Student',
                  icon: Icons.school,
                  selected: _role == AppConstants.roleStudent,
                  onTap: () => setState(() => _role = AppConstants.roleStudent),
                ),
                const SizedBox(width: 12),
                _RoleChip(
                  label: 'Instructor',
                  icon: Icons.cast_for_education,
                  selected: _role == AppConstants.roleInstructor,
                  onTap: () => setState(() => _role = AppConstants.roleInstructor),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Name ──
              _buildLabel('Full Name'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Your full name',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary)),
                validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 16),

              // ── Email ──
              _buildLabel('Email'),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'you@email.com',
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primary)),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Password ──
              _buildLabel('Password'),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Minimum 6 characters',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Bio (instructor only) ──
              if (_role == AppConstants.roleInstructor) ...[
                _buildLabel('Bio / Expertise'),
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Tell students about yourself and your expertise',
                    prefixIcon: Icon(Icons.info_outline, color: AppTheme.primary)),
                  validator: (v) =>
                    _role == AppConstants.roleInstructor && (v == null || v.isEmpty)
                    ? 'Bio required for instructors' : null,
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 8),

              // ── Register Button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: vm.isLoading ? null : _register,
                  child: vm.isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 20),

              Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Already have an account? ', style: TextStyle(color: AppTheme.textGrey)),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Text('Sign In',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                ),
              ])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)));
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip({required this.label, required this.icon,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? AppTheme.primary : AppTheme.divider, width: 2),
        boxShadow: selected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 12, offset: const Offset(0, 4))] : [],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: selected ? Colors.white : AppTheme.textGrey, size: 20),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(
          fontWeight: FontWeight.w600, fontSize: 14,
          color: selected ? Colors.white : AppTheme.textDark)),
      ]),
    ),
  );
}
