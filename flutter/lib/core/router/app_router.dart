import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di/providers.dart';
import '../constants/app_constants.dart';

// Screens
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';

import '../../features/courses/presentation/screens/home_screen.dart';
import '../../features/courses/presentation/screens/course_detail_screen.dart';
import '../../features/courses/presentation/screens/create_course_screen.dart';
import '../../features/courses/presentation/screens/edit_course_screen.dart';
import '../../features/courses/presentation/screens/add_lesson_screen.dart';
import '../../features/courses/presentation/screens/browse_screen.dart';

import '../../features/video/presentation/screens/video_player_screen.dart';

import '../../features/quiz/presentation/screens/quiz_screen.dart';
import '../../features/quiz/presentation/screens/quiz_results_screen.dart';
import '../../features/quiz/presentation/screens/create_exam_screen.dart';

import '../../features/payment/presentation/screens/payment_screen.dart';
import '../../features/payment/presentation/screens/payment_history_screen.dart';

import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_courses_screen.dart';
import '../../features/admin/presentation/screens/admin_payments_screen.dart';
import '../../features/admin/presentation/screens/admin_analytics_screen.dart';

import '../../features/teacher/presentation/screens/teacher_dashboard_screen.dart';
import '../../features/teacher/presentation/screens/teacher_earnings_screen.dart';

import '../../features/student/presentation/screens/student_dashboard_screen.dart';
import '../../features/student/presentation/screens/enrolled_courses_screen.dart';

import '../../features/certificate/presentation/screens/certificates_screen.dart';
import '../../features/session/presentation/screens/sessions_screen.dart';
final routerProvider = Provider<GoRouter>((ref) {
  final authVM = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authVM.isLoggedIn;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) {
        switch (authVM.role) {
          case AppConstants.roleAdmin: return '/admin';
          case AppConstants.roleInstructor: return '/teacher';
          default: return '/home';
        }
      }
      return null;
    },
    routes: [
      // ── Auth ──
      GoRoute(path: '/auth/login',          builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register',        builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/auth/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

      // ── Student / Main ──
      GoRoute(path: '/home',    builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/browse',  builder: (_, __) => const BrowseScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(
        path: '/course/:id',
        builder: (_, state) => CourseDetailScreen(courseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/course/:id/lesson/:lid',
        builder: (_, state) => VideoPlayerScreen(
          courseId: state.pathParameters['id']!,
          lessonId: state.pathParameters['lid']!,
        ),
      ),
      GoRoute(
        path: '/course/:id/quiz/:eid',
        builder: (_, state) => QuizScreen(
          courseId: state.pathParameters['id']!,
          examId: state.pathParameters['eid']!,
        ),
      ),
      GoRoute(
        path: '/course/:id/quiz/:eid/results',
        builder: (_, state) => QuizResultsScreen(
          courseId: state.pathParameters['id']!,
          examId: state.pathParameters['eid']!,
        ),
      ),
      GoRoute(
        path: '/course/:id/pay',
        builder: (_, state) => PaymentScreen(courseId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/payments/history', builder: (_, __) => const PaymentHistoryScreen()),
      GoRoute(path: '/student/dashboard', builder: (_, __) => const StudentDashboardScreen()),
      GoRoute(path: '/student/courses',   builder: (_, __) => const EnrolledCoursesScreen()),
      GoRoute(path: '/certificates',      builder: (_, __) => const CertificatesScreen()),
      GoRoute(path: '/sessions',          builder: (_, __) => const SessionsScreen()),
      GoRoute(path: '/sessions/book',     builder: (_, __) => const BookSessionScreen()),

      // ── Teacher ──
      GoRoute(path: '/teacher',              builder: (_, __) => const TeacherDashboardScreen()),
      GoRoute(path: '/teacher/earnings',     builder: (_, __) => const TeacherEarningsScreen()),
      GoRoute(path: '/teacher/create-course',builder: (_, __) => const CreateCourseScreen()),
      GoRoute(
        path: '/teacher/course/:id/edit',
        builder: (_, state) => EditCourseScreen(courseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/teacher/course/:id/add-lesson',
        builder: (_, state) => AddLessonScreen(courseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/teacher/course/:id/create-exam',
        builder: (_, state) => CreateExamScreen(courseId: state.pathParameters['id']!),
      ),

      // ── Admin ──
      GoRoute(path: '/admin',           builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/users',     builder: (_, __) => const AdminUsersScreen()),
      GoRoute(path: '/admin/courses',   builder: (_, __) => const AdminCoursesScreen()),
      GoRoute(path: '/admin/payments',  builder: (_, __) => const AdminPaymentsScreen()),
      GoRoute(path: '/admin/analytics', builder: (_, __) => const AdminAnalyticsScreen()),
    ],
  );
});
