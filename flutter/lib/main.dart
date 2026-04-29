import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

// ═══════════════════════════════════════════════════════════
// MAIN — App Entry Point
// SINGLETON: Firebase initialized once
// OBSERVER: ProviderScope wraps entire widget tree
// ═══════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // SINGLETON pattern: Firebase initialized once at app start
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(
    // OBSERVER pattern: ProviderScope enables Riverpod state management
    const ProviderScope(child: FastLearnApp()),
  );
}

class FastLearnApp extends ConsumerWidget {
  const FastLearnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Fast Learn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
