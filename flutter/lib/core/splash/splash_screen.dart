import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fastlearn/core/di/providers.dart';
import 'package:fastlearn/core/theme/app_theme.dart';
import 'package:fastlearn/core/constants/app_constants.dart';

// ═══════════════════════════════════════════════════════════
// SPLASH SCREEN — shown on app launch
// Displays the real Fast Learn logo with animation
// ═══════════════════════════════════════════════════════════
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    // Navigate after 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      final auth = ref.read(authViewModelProvider);
      if (auth.isLoggedIn) {
        switch (auth.role) {
          case AppConstants.roleAdmin:
            context.go('/admin');
            break;
          case AppConstants.roleInstructor:
            context.go('/teacher');
            break;
          default:
            context.go('/home');
            break;
        }
      } else {
        context.go('/auth/login');
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── App Logo ──
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.20),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.school,
                          color: Color(0xFF1A73E8),
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── App Name ──
                  const Text(
                    'FastLearn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'E-Learning Made Easy',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 52),

                  // ── Loading indicator ──
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      color: Colors.white54,
                      strokeWidth: 2.5,
                    ),
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