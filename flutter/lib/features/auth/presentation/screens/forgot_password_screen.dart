// ═══════════════════════════════════════════════════════════
// REMAINING SCREENS — All screens referenced by the router
// Full implementations of every screen
// ═══════════════════════════════════════════════════════════

// ──────────────── forgot_password_screen.dart ────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_emailCtrl.text.isEmpty || !_emailCtrl.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email'), backgroundColor: AppTheme.error));
      return;
    }
    final vm = ref.read(authViewModelProvider);
    final err = await vm.sendPasswordReset(_emailCtrl.text.trim());
    if (!mounted) return;
    if (err == null) {
      setState(() => _sent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(authViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 80, height: 80,
                  decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                  child: const Icon(Icons.mark_email_read, color: Colors.white, size: 40)),
                const SizedBox(height: 24),
                const Text('Email Sent!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('We sent a reset link to ${_emailCtrl.text}',
                  textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textGrey)),
                const SizedBox(height: 32),
                ElevatedButton(onPressed: () => context.go('/auth/login'), child: const Text('Back to Login')),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock_reset, size: 70, color: AppTheme.primary),
                const SizedBox(height: 20),
                const Text('Forgot Password?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Enter your email and we\'ll send you a reset link',
                  textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textGrey)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'you@email.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primary))),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: vm.isLoading ? null : _send,
                  child: vm.isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Send Reset Link'))),
              ]),
      ),
    );
  }
}
