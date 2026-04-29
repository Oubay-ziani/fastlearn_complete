import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/domain/entities.dart';

// ═══════════════════════════════════════════════════════════
// DATA MODELS — Firestore ↔ Domain Entity serialization
// All models implement fromFirestore + toFirestore
// ═══════════════════════════════════════════════════════════

// ──────────────── USER MODEL ────────────────
class UserModel {
  static UserEntity fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final role = d['role'] as String? ?? 'student';
    final base = {
      'uid': doc.id,
      'name': d['name'] ?? '',
      'email': d['email'] ?? '',
      'profilePicture': d['profilePicture'],
      'isActive': d['isActive'] ?? true,
      'createdAt': (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    };
    switch (role) {
      case 'instructor':
        return InstructorEntity(
          userId: doc.id,
          name: base['name'] as String,
          email: base['email'] as String,
          createdAt: base['createdAt'] as DateTime,
          profilePicture: base['profilePicture'] as String?,
          isActive: base['isActive'] as bool,
          bio: d['bio'] ?? '',
          totalEarnings: (d['totalEarnings'] ?? 0).toDouble(),
        );
      case 'admin':
        return AdminEntity(
          userId: doc.id,
          name: base['name'] as String,
          email: base['email'] as String,
          createdAt: base['createdAt'] as DateTime,
          profilePicture: base['profilePicture'] as String?,
          isActive: base['isActive'] as bool,
        );
      default:
        return StudentEntity(
          userId: doc.id,
          name: base['name'] as String,
          email: base['email'] as String,
          createdAt: base['createdAt'] as DateTime,
          profilePicture: base['profilePicture'] as String?,
          isActive: base['isActive'] as bool,
        );
    }
  }
}

// ──────────────── COURSE MODEL ────────────────
class CourseModel extends CourseEntity {
  const CourseModel({
    required super.courseId,
    required super.title,
    required super.description,
    required super.price,
    required super.status,
    required super.teacherId,
    required super.teacherName,
    super.teacherAvatar,
    required super.category,
    super.thumbnailUrl,
    super.lessonCount,
    super.enrollmentCount,
    super.rating,
    super.ratingCount,
    required super.createdAt,
    super.updatedAt,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CourseModel(
      courseId: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      status: d['status'] ?? 'draft',
      teacherId: d['teacherId'] ?? '',
      teacherName: d['teacherName'] ?? '',
      teacherAvatar: d['teacherAvatar'],
      category: d['category'] ?? 'Other',
      thumbnailUrl: d['thumbnailUrl'],
      lessonCount: d['lessonCount'] ?? 0,
      enrollmentCount: d['enrollmentCount'] ?? 0,
      rating: (d['rating'] ?? 0).toDouble(),
      ratingCount: d['ratingCount'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'description': description,
    'price': price,
    'status': status,
    'teacherId': teacherId,
    'teacherName': teacherName,
    'teacherAvatar': teacherAvatar,
    'category': category,
    'thumbnailUrl': thumbnailUrl,
    'lessonCount': lessonCount,
    'enrollmentCount': enrollmentCount,
    'rating': rating,
    'ratingCount': ratingCount,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

// ──────────────── LESSON MODEL ────────────────
class LessonModel extends LessonEntity {
  const LessonModel({
    required super.lessonId,
    required super.courseId,
    required super.title,
    super.description,
    super.videoUrl,
    super.pdfUrl,
    super.durationSeconds,
    super.orderIndex,
    super.isFree,
    super.createdAt,
  });

  factory LessonModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LessonModel(
      lessonId: doc.id,
      courseId: d['courseId'] ?? '',
      title: d['title'] ?? '',
      description: d['description'],
      videoUrl: d['videoUrl'],
      pdfUrl: d['pdfUrl'],
      durationSeconds: d['durationSeconds'] ?? 0,
      orderIndex: d['orderIndex'] ?? 0,
      isFree: d['isFree'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'courseId': courseId,
    'title': title,
    'description': description,
    'videoUrl': videoUrl,
    'pdfUrl': pdfUrl,
    'durationSeconds': durationSeconds,
    'orderIndex': orderIndex,
    'isFree': isFree,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

// ──────────────── EXAM MODEL ────────────────
class ExamModel extends ExamEntity {
  const ExamModel({
    required super.examId,
    required super.courseId,
    super.lessonId,
    required super.title,
    required super.passingScore,
    super.questions,
    required super.createdAt,
  });

  factory ExamModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ExamModel(
      examId: doc.id,
      courseId: d['courseId'] ?? '',
      lessonId: d['lessonId'],
      title: d['title'] ?? '',
      passingScore: d['passingScore'] ?? 60,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'courseId': courseId,
    'lessonId': lessonId,
    'title': title,
    'passingScore': passingScore,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

// ──────────────── QUESTION MODEL ────────────────
class QuestionModel extends QuestionEntity {
  const QuestionModel({
    required super.questionId,
    required super.examId,
    required super.questionText,
    required super.options,
    required super.correctAnswer,
    required super.marks,
  });

  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return QuestionModel(
      questionId: doc.id,
      examId: d['examId'] ?? '',
      questionText: d['questionText'] ?? '',
      options: List<String>.from(d['options'] ?? []),
      correctAnswer: d['correctAnswer'] ?? '',
      marks: d['marks'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'examId': examId,
    'questionText': questionText,
    'options': options,
    'correctAnswer': correctAnswer,
    'marks': marks,
  };
}

// ──────────────── EXAM RESULT MODEL ────────────────
class ExamResultModel extends ExamResultEntity {
  const ExamResultModel({
    required super.resultId,
    required super.examId,
    required super.userId,
    required super.courseId,
    required super.score,
    required super.totalMarks,
    required super.passed,
    required super.takenAt,
  });

  factory ExamResultModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ExamResultModel(
      resultId: doc.id,
      examId: d['examId'] ?? '',
      userId: d['userId'] ?? '',
      courseId: d['courseId'] ?? '',
      score: d['score'] ?? 0,
      totalMarks: d['totalMarks'] ?? 0,
      passed: d['passed'] ?? false,
      takenAt: (d['takenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'examId': examId,
    'userId': userId,
    'courseId': courseId,
    'score': score,
    'totalMarks': totalMarks,
    'passed': passed,
    'takenAt': FieldValue.serverTimestamp(),
  };
}

// ──────────────── ENROLLMENT MODEL ────────────────
class EnrollmentModel extends EnrollmentEntity {
  const EnrollmentModel({
    required super.enrollmentId,
    required super.userId,
    required super.courseId,
    required super.enrolledAt,
    super.completed,
    super.progress,
    super.completedLessons,
  });

  factory EnrollmentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EnrollmentModel(
      enrollmentId: doc.id,
      userId: d['userId'] ?? '',
      courseId: d['courseId'] ?? '',
      enrolledAt: (d['enrolledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completed: d['completed'] ?? false,
      progress: d['progress'] ?? 0,
      completedLessons: List<String>.from(d['completedLessons'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'courseId': courseId,
    'enrolledAt': FieldValue.serverTimestamp(),
    'completed': completed,
    'progress': progress,
    'completedLessons': completedLessons,
  };
}

// ──────────────── CERTIFICATE MODEL ────────────────
class CertificateModel extends CertificateEntity {
  const CertificateModel({
    required super.certificateId,
    required super.userId,
    required super.studentName,
    required super.courseName,
    required super.issuedDate,
    super.downloadUrl,
  });

  factory CertificateModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CertificateModel(
      certificateId: doc.id,
      userId: d['userId'] ?? '',
      studentName: d['studentName'] ?? '',
      courseName: d['courseName'] ?? '',
      issuedDate: (d['issuedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      downloadUrl: d['downloadUrl'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'studentName': studentName,
    'courseName': courseName,
    'issuedDate': FieldValue.serverTimestamp(),
    'downloadUrl': downloadUrl,
  };
}

// ──────────────── SESSION MODEL ────────────────
class SessionModel extends SessionEntity {
  const SessionModel({
    required super.sessionId,
    required super.instructorId,
    super.studentId,
    required super.scheduledAt,
    required super.durationMinutes,
    required super.status,
    required super.price,
    super.paidAt,
  });

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SessionModel(
      sessionId: doc.id,
      instructorId: d['instructorId'] ?? '',
      studentId: d['studentId'],
      scheduledAt: (d['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: d['durationMinutes'] ?? 60,
      status: d['status'] ?? 'scheduled',
      price: (d['price'] ?? 0).toDouble(),
      paidAt: (d['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'instructorId': instructorId,
    'studentId': studentId,
    'scheduledAt': Timestamp.fromDate(scheduledAt),
    'durationMinutes': durationMinutes,
    'status': status,
    'price': price,
    'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
  };
}

// ──────────────── PAYMENT MODEL ────────────────
class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.paymentId,
    required super.userId,
    super.courseId,
    super.sessionId,
    required super.amount,
    required super.status,
    required super.paidAt,
    super.stripePaymentIntentId,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      paymentId: doc.id,
      userId: d['userId'] ?? '',
      courseId: d['courseId'],
      sessionId: d['sessionId'],
      amount: (d['amount'] ?? 0).toDouble(),
      status: d['status'] ?? 'pending',
      paidAt: (d['paidAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stripePaymentIntentId: d['stripePaymentIntentId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'courseId': courseId,
    'sessionId': sessionId,
    'amount': amount,
    'status': status,
    'paidAt': FieldValue.serverTimestamp(),
    'stripePaymentIntentId': stripePaymentIntentId,
  };
}

// ──────────────── ANALYTICS MODEL ────────────────
class AnalyticsModel extends AnalyticsEntity {
  const AnalyticsModel({
    required super.totalUsers,
    required super.totalCourses,
    required super.totalRevenue,
    required super.totalEnrollments,
    super.enrollmentsByMonth,
    super.revenueByMonth,
  });

  factory AnalyticsModel.fromMap(Map<String, dynamic> d) => AnalyticsModel(
    totalUsers: d['totalUsers'] ?? 0,
    totalCourses: d['totalCourses'] ?? 0,
    totalRevenue: (d['totalRevenue'] ?? 0).toDouble(),
    totalEnrollments: d['totalEnrollments'] ?? 0,
    enrollmentsByMonth: Map<String, int>.from(d['enrollmentsByMonth'] ?? {}),
    revenueByMonth: (d['revenueByMonth'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toDouble())),
  );
}
