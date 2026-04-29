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

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool  _obscure   = true;
  late  AnimationController _animCtrl;
  late  Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final vm  = ref.read(authViewModelProvider);
    final err = await vm.login(
        email: _emailCtrl.text.trim(), password: _passCtrl.text);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppTheme.error));
    }
  }

  Future<void> _googleSignIn() async {
    final vm  = ref.read(authViewModelProvider);
    final err = await vm.signInWithGoogle();
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // ── Logo ──────────────────────────────────────
                  Center(
                    child: Column(children: [
                      // الصورة الحقيقية للوغو
                      Image.asset(
                        'assets/images/logo.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppTheme.primary, AppTheme.secondary]),
                            borderRadius: BorderRadius.circular(22)),
                          child: const Icon(Icons.school,
                              color: Colors.white, size: 52),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Fast Learn',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark)),
                      const SizedBox(height: 6),
                      const Text('Sign in to continue learning',
                          style: TextStyle(
                              color: AppTheme.textGrey, fontSize: 14)),
                    ]),
                  ),

                  const SizedBox(height: 40),

                  // ── Email ──────────────────────────────────────
                  const Text('Email',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'you@email.com',
                      prefixIcon:
                          Icon(Icons.email_outlined, color: AppTheme.primary)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // ── Password ───────────────────────────────────
                  const Text('Password',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppTheme.primary),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password required';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // ── Forgot password ────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          context.push('/auth/forgot-password'),
                      child: const Text('Forgot Password?',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Login Button ───────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: vm.isLoading ? null : _login,
                      child: vm.isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Divider ────────────────────────────────────
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or',
                          style:
                              TextStyle(color: AppTheme.textGrey))),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 20),

                  // ── Google Sign-In ─────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.g_mobiledata,
                          size: 26, color: Colors.red),
                      label: const Text('Continue with Google'),
                      onPressed:
                          vm.isLoading ? null : _googleSignIn,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Register link ──────────────────────────────
                  Center(
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Don't have an account? ",
                              style:
                                  TextStyle(color: AppTheme.textGrey)),
                          GestureDetector(
                            onTap: () =>
                                context.push('/auth/register'),
                            child: const Text('Sign Up',
                                style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
