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
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _bioCtrl   = TextEditingController();
  bool   _obscure  = true;
  String _role     = AppConstants.roleStudent;

  // field errors
  String? _nameError;
  String? _emailError;
  String? _passError;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _bioCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError = null; _emailError = null; _passError = null;
    });
    bool ok = true;
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _nameError = 'Please enter your full name');
      ok = false;
    }
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email address');
      ok = false;
    } else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      ok = false;
    }
    if (_passCtrl.text.isEmpty) {
      setState(() => _passError = 'Please enter a password');
      ok = false;
    } else if (_passCtrl.text.length < 6) {
      setState(() => _passError = 'Password must be at least 6 characters');
      ok = false;
    }
    return ok;
  }

  Future<void> _register() async {
    if (!_validate()) return;
    final vm  = ref.read(authViewModelProvider);
    final err = await vm.register(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role:     _role,
      bio:      _role == AppConstants.roleInstructor
                    ? _bioCtrl.text.trim() : null,
    );
    if (!mounted) return;
    if (err != null) {
      if (err.toLowerCase().contains('email') ||
          err.toLowerCase().contains('already')) {
        setState(() => _emailError = '❌ This email is already registered.');
      } else if (err.toLowerCase().contains('password')) {
        setState(() => _passError = '❌ $err');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err), backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } else {
      // Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Account created! Please login.'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ));
        context.go('/auth/login');
      }
    }
  }

  Future<void> _googleRegister() async {
    final vm  = ref.read(authViewModelProvider);
    final err = await vm.signInWithGoogle(role: _role);
    if (!mounted) return;
    if (err != null && err != 'Google sign-in cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(authViewModelProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [

        // ── Header ───────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 28),
              child: Column(children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.school, color: Color(0xFF1A73E8), size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Create Account',
                    style: TextStyle(
                        color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ),

        // ── Form ─────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('Join FastLearn',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 4),
              const Text('Start your learning journey today',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              const SizedBox(height: 22),

              // Full Name
              _buildField(
                controller: _nameCtrl,
                hint: 'Full Name',
                icon: Icons.person_outline,
                errorText: _nameError,
                onChanged: (_) => setState(() => _nameError = null),
              ),
              const SizedBox(height: 12),

              // Email
              _buildField(
                controller: _emailCtrl,
                hint: 'Email Address',
                icon: Icons.email_outlined,
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() => _emailError = null),
              ),
              const SizedBox(height: 12),

              // Password
              _buildField(
                controller: _passCtrl,
                hint: 'Password',
                icon: Icons.lock_outline,
                errorText: _passError,
                obscure: _obscure,
                onChanged: (_) => setState(() => _passError = null),
                suffix: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                      color: const Color(0xFF6B7280), size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 20),

              // Role selector
              const Text('I want to join as:',
                  style: TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 14, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 12),
              Row(children: [
                _RoleCard(
                  label: 'Student',
                  icon: Icons.school,
                  selected: _role == AppConstants.roleStudent,
                  onTap: () => setState(() => _role = AppConstants.roleStudent),
                ),
                const SizedBox(width: 12),
                _RoleCard(
                  label: 'Instructor',
                  icon: Icons.cast_for_education,
                  selected: _role == AppConstants.roleInstructor,
                  onTap: () => setState(() => _role = AppConstants.roleInstructor),
                ),
              ]),

              // Bio for instructor
              if (_role == AppConstants.roleInstructor) ...[
                const SizedBox(height: 14),
                _buildField(
                  controller: _bioCtrl,
                  hint: 'Your expertise / bio',
                  icon: Icons.info_outline,
                  maxLines: 3,
                ),
              ],
              const SizedBox(height: 24),

              // Create Account button
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: vm.isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: vm.isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Create Account',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),

              // Divider
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('or', style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 13)),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 16),

              // Google button
              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton(
                  onPressed: vm.isLoading ? null : _googleRegister,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Image.network(
                      'https://www.google.com/favicon.ico',
                      width: 20, height: 20,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.g_mobiledata, color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 10),
                    const Text('Sign up with Google',
                        style: TextStyle(
                            color: Color(0xFF1A1A2E),
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ]),
                ),
              ),
              const SizedBox(height: 24),

              // Login link
              Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Already have an account? ',
                    style: TextStyle(color: Color(0xFF6B7280))),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Text('Sign In',
                      style: TextStyle(color: Color(0xFF1A73E8),
                          fontWeight: FontWeight.w700)),
                ),
              ])),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? errorText,
    bool obscure = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
    ValueChanged<String>? onChanged,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: errorText != null
                  ? AppTheme.error : const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF), fontSize: 14),
              prefixIcon: Icon(icon,
                  color: const Color(0xFF6B7280), size: 20),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 16),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(errorText,
                style: const TextStyle(
                    color: AppTheme.error, fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ]);
}

class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard({required this.label, required this.icon,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A73E8) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF1A73E8) : const Color(0xFFE5E7EB),
            width: 2),
          boxShadow: selected ? [BoxShadow(
            color: const Color(0xFF1A73E8).withOpacity(0.25),
            blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color: selected ? Colors.white : const Color(0xFF6B7280),
              size: 28),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14,
                  color: selected ? Colors.white : const Color(0xFF1A1A2E))),
        ]),
      ),
    ),
  );
}
