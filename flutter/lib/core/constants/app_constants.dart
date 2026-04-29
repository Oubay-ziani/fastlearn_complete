// ═══════════════════════════════════════════════════════════
// CORE: App Constants
// Centralised strings — single source of truth
// ═══════════════════════════════════════════════════════════
class AppConstants {
  AppConstants._();

  // App info
  static const appName = 'Fast Learn';
  static const appVersion = '2.0.0';

  // Firestore collections
  static const usersCol       = 'users';
  static const coursesCol     = 'courses';
  static const lessonsCol     = 'lessons';
  static const enrollmentsCol = 'enrollments';
  static const paymentsCol    = 'payments';
  static const examsCol       = 'exams';
  static const questionsCol   = 'questions';
  static const examResultsCol = 'examResults';
  static const certificatesCol= 'certificates';
  static const sessionsCol    = 'sessions';
  static const analyticsCol   = 'analytics';

  // Firebase Storage paths
  static const thumbsPath    = 'thumbnails';
  static const videosPath    = 'videos';
  static const pdfsPath      = 'pdfs';
  static const avatarsPath   = 'avatars';
  static const certsPath     = 'certificates';

  // User roles
  static const roleStudent    = 'student';
  static const roleInstructor = 'instructor';
  static const roleAdmin      = 'admin';

  // Course statuses
  static const statusDraft     = 'draft';
  static const statusPending   = 'pending';
  static const statusPublished = 'published';
  static const statusRejected  = 'rejected';

  // Payment statuses
  static const paymentPending   = 'pending';
  static const paymentSuccess   = 'success';
  static const paymentFailed    = 'failed';
  static const paymentRefunded  = 'refunded';

  // Session statuses
  static const sessionScheduled = 'scheduled';
  static const sessionCancelled = 'cancelled';
  static const sessionCompleted = 'completed';

  // Pagination
  static const pageSize = 10;

  // Backend URL (update for production)
  static const backendUrl = 'http://localhost:5000/api';

  // Stripe publishable key (replace with real key)
  static const stripePublishableKey = 'pk_test_YOUR_STRIPE_KEY';

  // Categories
  static const categories = [
    'Programming', 'Design', 'Business', 'Marketing',
    'Photography', 'Music', 'Language', 'Personal Development',
    'Health & Fitness', 'Data Science', 'AI & Machine Learning', 'Other',
  ];
  
}
