// ═══════════════════════════════════════════════════════════
// DOMAIN ENTITIES — Exact implementation of the CLASS DIAGRAM
// All classes, all attributes, all methods preserved
// ═══════════════════════════════════════════════════════════

// ──────────────── USER (Base class) ────────────────
class UserEntity {
  final String userId;
  final String name;
  final String email;
  final String role;
  final String? profilePicture;
  final bool isActive;
  final DateTime createdAt;

  const UserEntity({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.profilePicture,
    this.isActive = true,
    required this.createdAt,
  });

  // Methods from class diagram
  bool register() => true;           // handled via AuthRepository
  bool login() => true;              // handled via AuthRepository
  void logout() {}                   // handled via AuthRepository
  void manageProfile() {}            // handled via ProfileViewModel
}

// ──────────────── STUDENT ────────────────
class StudentEntity extends UserEntity {
  final List<String> enrolledCourseIds;
  final List<String> completedCourseIds;

  const StudentEntity({
    required super.userId,
    required super.name,
    required super.email,
    required super.createdAt,
    super.profilePicture,
    super.isActive,
    this.enrolledCourseIds = const [],
    this.completedCourseIds = const [],
  }) : super(role: 'student');

  // Methods from class diagram
  void buyCourse(CourseEntity course) {}      // → PaymentViewModel
  void watchCourses() {}                      // → VideoPlayerScreen
  void downloadCertificate() {}              // → CertificateRepository
  void viewEnrolledCourses() {}              // → StudentDashboard
  void takeExam() {}                          // → QuizScreen
  void submitAnswers() {}                     // → QuizViewModel
  void reserveSession() {}                   // → SessionViewModel
  void viewExamResults() {}                  // → ExamResultScreen
}

// ──────────────── INSTRUCTOR ────────────────
class InstructorEntity extends UserEntity {
  final String bio;
  final double totalEarnings;
  final List<String> courseIds;

  const InstructorEntity({
    required super.userId,
    required super.name,
    required super.email,
    required super.createdAt,
    super.profilePicture,
    super.isActive,
    required this.bio,
    this.totalEarnings = 0.0,
    this.courseIds = const [],
  }) : super(role: 'instructor');

  // Methods from class diagram
  void createCourse() {}                     // → CourseViewModel
  void addLesson() {}                         // → CourseViewModel
  void setCoursePrice() {}                   // → CourseViewModel
  void setLessonQuestions() {}               // → QuizViewModel
  void createExam() {}                        // → QuizViewModel
  void manageSessionAvailability() {}        // → SessionViewModel
  void viewEarnings() {}                     // → InstructorDashboard
}

// ──────────────── ADMIN ────────────────
class AdminEntity extends UserEntity {
  const AdminEntity({
    required super.userId,
    required super.name,
    required super.email,
    required super.createdAt,
    super.profilePicture,
    super.isActive,
  }) : super(role: 'admin');

  // Methods from class diagram
  void manageUsers() {}                      // → AdminViewModel
  void approveOrRejectCourse() {}            // → AdminViewModel
  void managePlatformPayments() {}           // → AdminViewModel
  void viewPlatformAnalytics() {}            // → AnalyticsViewModel
  void suspendAccount(UserEntity user) {}    // → AdminViewModel
  void deleteAccount(UserEntity user) {}     // → AdminViewModel
}

// ──────────────── COURSE ────────────────
class CourseEntity {
  final String courseId;
  final String title;
  final String description;
  final double price;
  final String status;
  final String teacherId;
  final String teacherName;
  final String? teacherAvatar;
  final String category;
  final String? thumbnailUrl;
  final int lessonCount;
  final int enrollmentCount;
  final double rating;
  final int ratingCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CourseEntity({
    required this.courseId,
    required this.title,
    required this.description,
    required this.price,
    required this.status,
    required this.teacherId,
    required this.teacherName,
    this.teacherAvatar,
    required this.category,
    this.thumbnailUrl,
    this.lessonCount = 0,
    this.enrollmentCount = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isFree => price == 0;

  // Methods from class diagram
  void addLesson(LessonEntity lesson) {}     // → CourseViewModel
  void setPrice(double price) {}             // → CourseViewModel
  void publish() {}                          // → CourseViewModel
}

// ──────────────── LESSON ────────────────
class LessonEntity {
  final String lessonId;
  final String courseId;
  final String title;
  final String? description;
  final String? videoUrl;
  final String? pdfUrl;
  final int durationSeconds;
  final int orderIndex;
  final bool isFree;
  final DateTime? createdAt;

  const LessonEntity({
    required this.lessonId,
    required this.courseId,
    required this.title,
    this.description,
    this.videoUrl,
    this.pdfUrl,
    this.durationSeconds = 0,
    this.orderIndex = 0,
    this.isFree = false,
    this.createdAt,
  });

  String get durationFormatted {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final rm = m % 60;
      return '${h}h ${rm}m';
    }
    return '${m}m ${s}s';
  }

  // Methods from class diagram
  void addQuestion() {}                      // → QuizViewModel
}

// ──────────────── EXAM ────────────────
class ExamEntity {
  final String examId;
  final String courseId;
  final String? lessonId;
  final String title;
  final int passingScore;
  final List<QuestionEntity> questions;
  final DateTime createdAt;

  const ExamEntity({
    required this.examId,
    required this.courseId,
    this.lessonId,
    required this.title,
    required this.passingScore,
    this.questions = const [],
    required this.createdAt,
  });

  // Methods from class diagram
  void createQuestion() {}                   // → QuizViewModel
  int autoGrade(Map<String, String> answers) {
    int score = 0;
    for (final q in questions) {
      if (answers[q.questionId] == q.correctAnswer) {
        score += q.marks;
      }
    }
    return score;
  }
}

// ──────────────── QUESTION ────────────────
class QuestionEntity {
  final String questionId;
  final String examId;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final int marks;

  const QuestionEntity({
    required this.questionId,
    required this.examId,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.marks,
  });
}

// ──────────────── EXAM RESULT ────────────────
class ExamResultEntity {
  final String resultId;
  final String examId;
  final String userId;
  final String courseId;
  final int score;
  final int totalMarks;
  final bool passed;
  final DateTime takenAt;

  const ExamResultEntity({
    required this.resultId,
    required this.examId,
    required this.userId,
    required this.courseId,
    required this.score,
    required this.totalMarks,
    required this.passed,
    required this.takenAt,
  });

  double get percentage => totalMarks > 0 ? (score / totalMarks) * 100 : 0;

  // Methods from class diagram
  void viewResult() {}                       // → ExamResultScreen
}

// ──────────────── ENROLLMENT ────────────────
class EnrollmentEntity {
  final String enrollmentId;
  final String userId;
  final String courseId;
  final DateTime enrolledAt;
  final bool completed;
  final int progress;
  final List<String> completedLessons;

  const EnrollmentEntity({
    required this.enrollmentId,
    required this.userId,
    required this.courseId,
    required this.enrolledAt,
    this.completed = false,
    this.progress = 0,
    this.completedLessons = const [],
  });

  // Methods from class diagram
  void generateCertificate() {}              // → CertificateRepository
}

// ──────────────── CERTIFICATE ────────────────
class CertificateEntity {
  final String certificateId;
  final String userId;
  final String studentName;
  final String courseName;
  final DateTime issuedDate;
  final String? downloadUrl;

  const CertificateEntity({
    required this.certificateId,
    required this.userId,
    required this.studentName,
    required this.courseName,
    required this.issuedDate,
    this.downloadUrl,
  });

  // Methods from class diagram
  Future<void> download() async {}           // → CertificateRepository
}

// ──────────────── SESSION ────────────────
class SessionEntity {
  final String sessionId;
  final String instructorId;
  final String? studentId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status;
  final double price;
  final DateTime? paidAt;

  const SessionEntity({
    required this.sessionId,
    required this.instructorId,
    this.studentId,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    required this.price,
    this.paidAt,
  });

  // Methods from class diagram
  void reserve() {}                          // → SessionViewModel
  void cancel() {}                           // → SessionViewModel
}

// ──────────────── PAYMENT ────────────────
class PaymentEntity {
  final String paymentId;
  final String userId;
  final String? courseId;
  final String? sessionId;
  final double amount;
  final String status;
  final DateTime paidAt;
  final String? stripePaymentIntentId;

  const PaymentEntity({
    required this.paymentId,
    required this.userId,
    this.courseId,
    this.sessionId,
    required this.amount,
    required this.status,
    required this.paidAt,
    this.stripePaymentIntentId,
  });

  // Methods from class diagram
  Future<bool> process() async => status == 'success';   // → PaymentViewModel
  Future<bool> refund() async => false;                  // → AdminViewModel
}

// ──────────────── ANALYTICS ────────────────
class AnalyticsEntity {
  final int totalUsers;
  final int totalCourses;
  final double totalRevenue;
  final int totalEnrollments;
  final Map<String, int> enrollmentsByMonth;
  final Map<String, double> revenueByMonth;

  const AnalyticsEntity({
    required this.totalUsers,
    required this.totalCourses,
    required this.totalRevenue,
    required this.totalEnrollments,
    this.enrollmentsByMonth = const {},
    this.revenueByMonth = const {},
  });

  // Methods from class diagram
  Map<String, dynamic> generateReport() => {
    'totalUsers': totalUsers,
    'totalCourses': totalCourses,
    'totalRevenue': totalRevenue,
    'totalEnrollments': totalEnrollments,
    'enrollmentsByMonth': enrollmentsByMonth,
    'revenueByMonth': revenueByMonth,
  };
}
