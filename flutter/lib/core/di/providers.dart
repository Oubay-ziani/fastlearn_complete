import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '/features/courses/presentation/viewmodels/course_viewmodel.dart';
import '/features/quiz/presentation/viewmodels/quiz_viewmodel.dart';
import '/features/payment/presentation/viewmodels/payment_viewmodel.dart';
import '/features/admin/presentation/viewmodels/admin_viewmodel.dart';
import '/features/session/presentation/viewmodels/session_viewmodel.dart';
import '/features/certificate/presentation/viewmodels/certificate_viewmodel.dart';

// ═══════════════════════════════════════════════════════════
// DEPENDENCY INJECTION — Riverpod Providers
// SINGLETON pattern: each provider is created once
// OBSERVER pattern: ChangeNotifierProvider watches ViewModel
// ═══════════════════════════════════════════════════════════

/// Auth ViewModel — global singleton
final authViewModelProvider = ChangeNotifierProvider<AuthViewModel>((ref) {
  final vm = AuthViewModel();
  vm.initialize();
  return vm;
});

/// Course ViewModel — global singleton
final courseViewModelProvider = ChangeNotifierProvider<CourseViewModel>((ref) {
  return CourseViewModel();
});

/// Quiz ViewModel — global singleton
final quizViewModelProvider = ChangeNotifierProvider<QuizViewModel>((ref) {
  return QuizViewModel();
});

/// Payment ViewModel — global singleton
final paymentViewModelProvider = ChangeNotifierProvider<PaymentViewModel>((ref) {
  return PaymentViewModel();
});

/// Admin ViewModel — global singleton
final adminViewModelProvider = ChangeNotifierProvider<AdminViewModel>((ref) {
  return AdminViewModel();
});

/// Session ViewModel — global singleton
final sessionViewModelProvider = ChangeNotifierProvider<SessionViewModel>((ref) {
  return SessionViewModel();
});

/// Certificate ViewModel — global singleton
final certificateViewModelProvider = ChangeNotifierProvider<CertificateViewModel>((ref) {
  return CertificateViewModel();
});
