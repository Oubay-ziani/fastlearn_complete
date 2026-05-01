import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/auth/login');
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.school, color: Color(0xFF1565C0), size: 64),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('FastLearn',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: 1)),
            const SizedBox(height: 8),
            const Text('E-Learning Made Easy',
                style: TextStyle(fontSize: 15, color: Colors.white70)),
          ]),
        ),
      )),
    ),
  );
}