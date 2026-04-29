import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/constants/app_constants.dart';
import '/core/domain/entities.dart';
import '/core/data/models.dart';

// ═══════════════════════════════════════════════════════════
// ADMIN VIEWMODEL — MVVM + Observer
// Implements ALL Admin methods from class diagram:
// manageUsers, approveOrRejectCourse, managePlatformPayments,
// viewPlatformAnalytics, suspendAccount, deleteAccount
// ═══════════════════════════════════════════════════════════
class AdminViewModel extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  List<UserEntity>     _users     = [];
  List<CourseEntity>   _courses   = [];
  List<PaymentEntity>  _payments  = [];
  AnalyticsEntity?     _analytics;
  bool                 _isLoading = false;
  String?              _error;

  List<UserEntity>    get users     => _users;
  List<CourseEntity>  get courses   => _courses;
  List<PaymentEntity> get payments  => _payments;
  AnalyticsEntity?    get analytics => _analytics;
  bool                get isLoading => _isLoading;
  String?             get error     => _error;

  // ── MANAGE USERS (Admin: manageUsers) ──
  void watchAllUsers() {
    _db.collection(AppConstants.usersCol)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((s) {
      _users = s.docs.map((d) => UserModel.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  // ── SUSPEND ACCOUNT (Admin: suspendAccount) ──
  Future<void> suspendAccount(String userId) async {
    await _db.collection(AppConstants.usersCol).doc(userId)
        .update({'isActive': false, 'suspendedAt': FieldValue.serverTimestamp()});
  }

  // ── RESTORE ACCOUNT ──
  Future<void> restoreAccount(String userId) async {
    await _db.collection(AppConstants.usersCol).doc(userId)
        .update({'isActive': true});
  }

  // ── DELETE ACCOUNT (Admin: deleteAccount) ──
  Future<void> deleteAccount(String userId) async {
    // Delete user data
    await _db.collection(AppConstants.usersCol).doc(userId).delete();
    // Note: Also delete from FirebaseAuth via backend (requires Admin SDK)
  }

  // ── ASSIGN ROLE ──
  Future<void> assignRole(String userId, String role) async {
    await _db.collection(AppConstants.usersCol).doc(userId).update({'role': role});
  }

  // ── WATCH PENDING COURSES (Admin: approveOrRejectCourse) ──
  void watchPendingCourses() {
    _db.collection(AppConstants.coursesCol)
        .where('status', isEqualTo: AppConstants.statusPending)
        .snapshots()
        .listen((s) {
      _courses = s.docs.map((d) => CourseModel.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  // ── APPROVE COURSE ──
  Future<void> approveCourse(String courseId) async {
    await _db.collection(AppConstants.coursesCol).doc(courseId)
        .update({'status': AppConstants.statusPublished, 'approvedAt': FieldValue.serverTimestamp()});
  }

  // ── REJECT COURSE ──
  Future<void> rejectCourse(String courseId) async {
    await _db.collection(AppConstants.coursesCol).doc(courseId)
        .update({'status': AppConstants.statusRejected});
  }

  // ── MANAGE PAYMENTS (Admin: managePlatformPayments) ──
  void watchAllPayments() {
    _db.collection(AppConstants.paymentsCol)
        .orderBy('paidAt', descending: true)
        .limit(100)
        .snapshots()
        .listen((s) {
      _payments = s.docs.map((d) => PaymentModel.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  // ── VIEW ANALYTICS (Admin: viewPlatformAnalytics, Analytics: generateReport) ──
  Future<void> loadAnalytics() async {
    _setLoading(true);
    try {
      final [usersSnap, coursesSnap, enrollSnap, paymentsSnap] = await Future.wait([
        _db.collection(AppConstants.usersCol).count().get(),
        _db.collection(AppConstants.coursesCol).count().get(),
        _db.collection(AppConstants.enrollmentsCol).count().get(),
        _db.collection(AppConstants.paymentsCol)
            .where('status', isEqualTo: AppConstants.paymentSuccess).get(),
      ]);

      double totalRevenue = 0;
      final revenueByMonth = <String, double>{};
      final enrollmentsByMonth = <String, int>{};

      for (final doc in (paymentsSnap as QuerySnapshot).docs) {
        final d = doc.data() as Map<String, dynamic>;
        totalRevenue += (d['amount'] ?? 0).toDouble();
        final ts = d['paidAt'] as Timestamp?;
        if (ts != null) {
          final key = '${ts.toDate().year}-${ts.toDate().month.toString().padLeft(2,'0')}';
          revenueByMonth[key] = (revenueByMonth[key] ?? 0) + (d['amount'] ?? 0).toDouble();
        }
      }

      final enrollSnap2 = await _db.collection(AppConstants.enrollmentsCol).get();
      for (final doc in enrollSnap2.docs) {
        final d = doc.data();
        final ts = d['enrolledAt'] as Timestamp?;
        if (ts != null) {
          final key = '${ts.toDate().year}-${ts.toDate().month.toString().padLeft(2,'0')}';
          enrollmentsByMonth[key] = (enrollmentsByMonth[key] ?? 0) + 1;
        }
      }

      _analytics = AnalyticsModel(
        totalUsers: (usersSnap as AggregateQuerySnapshot).count ?? 0,
        totalCourses: (coursesSnap as AggregateQuerySnapshot).count ?? 0,
        totalRevenue: totalRevenue,
        totalEnrollments: (enrollSnap as AggregateQuerySnapshot).count ?? 0,
        revenueByMonth: revenueByMonth,
        enrollmentsByMonth: enrollmentsByMonth,
      );
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // ── DELETE COURSE (moderation) ──
  Future<void> deleteCourse(String courseId) async {
    await _db.collection(AppConstants.coursesCol).doc(courseId).delete();
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void clearError() { _error = null; notifyListeners(); }
}
