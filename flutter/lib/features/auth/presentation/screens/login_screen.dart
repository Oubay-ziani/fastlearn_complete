import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool  _obscure   = true;
  String? _emailError;
  String? _passError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Validate locally before calling Firebase ──
  bool _validate() {
    setState(() { _emailError = null; _passError = null; });
    bool ok = true;
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email address');
      ok = false;
    } else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      ok = false;
    }
    if (pass.isEmpty) {
      setState(() => _passError = 'Please enter your password');
      ok = false;
    } else if (pass.length < 6) {
      setState(() => _passError = 'Password must be at least 6 characters');
      ok = false;
    }
    return ok;
  }

  Future<void> _login() async {
    if (!_validate()) return;
    final vm  = ref.read(authViewModelProvider);
    final err = await vm.login(
        email: _emailCtrl.text.trim(), password: _passCtrl.text);
    if (!mounted) return;
    if (err != null) {
      // Map Firebase errors to field-specific messages
      if (err.toLowerCase().contains('password') ||
          err.toLowerCase().contains('incorrect') ||
          err.toLowerCase().contains('wrong')) {
        setState(() => _passError = '❌ Incorrect password. Please try again.');
      } else if (err.toLowerCase().contains('email') ||
          err.toLowerCase().contains('user') ||
          err.toLowerCase().contains('found')) {
        setState(() => _emailError = '❌ No account found with this email.');
      } else if (err.toLowerCase().contains('network') ||
          err.toLowerCase().contains('connection')) {
        _showSnack('⚠️ Network error. Please check your connection.', AppTheme.warning);
      } else {
        _showSnack(err, AppTheme.error);
      }
    }
  }

  Future<void> _googleSignIn() async {
    final vm  = ref.read(authViewModelProvider);
    final err = await vm.signInWithGoogle();
    if (!mounted) return;
    if (err != null && err != 'Google sign-in cancelled') {
      _showSnack(err, AppTheme.error);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [

        // ── Header with logo ─────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 30, 0, 36),
              child: Column(children: [
                // Logo image
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.school, color: Color(0xFF1A73E8), size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('FastLearn',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                const Text('E-Learning Made Easy',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ]),
            ),
          ),
        ),

        // ── Form ─────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('Welcome Back!',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 4),
              const Text('Sign in to continue learning',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              const SizedBox(height: 28),

              // Email field
              _buildField(
                controller: _emailCtrl,
                hint: 'Email Address',
                icon: Icons.email_outlined,
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() => _emailError = null),
              ),
              const SizedBox(height: 14),

              // Password field
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

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/auth/forgot-password'),
                  child: const Text('Forgot Password?',
                      style: TextStyle(
                          color: Color(0xFF1A73E8),
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),

              // Sign In button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: vm.isLoading ? null : _login,
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
                      : const Text('Sign In',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 20),

              // Divider
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('or',
                      style: TextStyle(color: Colors.grey.shade400,
                          fontSize: 13)),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 20),

              // Google button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: vm.isLoading ? null : _googleSignIn,
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
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.g_mobiledata,
                              color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 10),
                    const Text('Continue with Google',
                        style: TextStyle(
                            color: Color(0xFF1A1A2E),
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ]),
                ),
              ),
              const SizedBox(height: 28),

              // Register link
              Center(child: Row(
                  mainAxisSize: MainAxisSize.min, children: [
                const Text("Don't have an account? ",
                    style: TextStyle(color: Color(0xFF6B7280))),
                GestureDetector(
                  onTap: () => context.push('/auth/register'),
                  child: const Text('Sign Up',
                      style: TextStyle(
                          color: Color(0xFF1A73E8),
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
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: errorText != null
                ? AppTheme.error
                : const Color(0xFFE5E7EB)),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
            suffixIcon: suffix,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 16),
          ),
        ),
      ),
      if (errorText != null) ...[
        const SizedBox(height: 6),
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
}
