import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '/core/constants/app_constants.dart';
import '/core/domain/entities.dart';
import '/core/data/models.dart';

// ═══════════════════════════════════════════════════════════
// PAYMENT VIEWMODEL — MVVM + Observer
// Implements: Payment.process(), Payment.refund()
// Admin: managePlatformPayments
// Student: buyCourse
// ═══════════════════════════════════════════════════════════
class PaymentViewModel extends ChangeNotifier {
  final _db   = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  List<PaymentEntity> _payments    = [];
  PaymentEntity?      _lastPayment;
  bool                _isLoading   = false;
  bool                _paymentSuccess = false;
  String?             _error;

  List<PaymentEntity> get payments       => _payments;
  PaymentEntity?      get lastPayment    => _lastPayment;
  bool                get isLoading      => _isLoading;
  bool                get paymentSuccess => _paymentSuccess;
  String?             get error          => _error;

  // ── PROCESS PAYMENT (Payment.process) ──
  // In production: integrate with Stripe backend
  Future<bool> processCoursePayment({
    required String userId,
    required String courseId,
    required double amount,
    String? stripePaymentIntentId,
  }) async {
    _setLoading(true);
    _paymentSuccess = false;
    try {
      // Simulate Stripe payment processing
      // In production: call your backend /api/payment/create-intent
      // then confirm with FlutterStripe.instance.confirmPayment
      await Future.delayed(const Duration(seconds: 2)); // Simulate network call

      final id = _uuid.v4();
      final payment = PaymentModel(
        paymentId: id,
        userId: userId,
        courseId: courseId,
        amount: amount,
        status: AppConstants.paymentSuccess,
        paidAt: DateTime.now(),
        stripePaymentIntentId: stripePaymentIntentId ?? 'pi_mock_${_uuid.v4()}',
      );

      // Save payment record
      await _db.collection(AppConstants.paymentsCol).doc(id)
          .set(payment.toFirestore());

      // Update instructor earnings
      final courseDoc = await _db.collection(AppConstants.coursesCol)
          .doc(courseId).get();
      final teacherId = (courseDoc.data() as Map)['teacherId'] as String?;
      if (teacherId != null) {
        await _db.collection(AppConstants.usersCol).doc(teacherId).update({
          'totalEarnings': FieldValue.increment(amount * 0.7), // 70% to instructor
        });
      }

      _lastPayment = payment;
      _paymentSuccess = true;
      _setLoading(false);
      return true;
    } catch (e) {
      // Save failed payment record
      final id = _uuid.v4();
      await _db.collection(AppConstants.paymentsCol).doc(id).set({
        'userId': userId, 'courseId': courseId, 'amount': amount,
        'status': AppConstants.paymentFailed,
        'paidAt': FieldValue.serverTimestamp(),
      });
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── PROCESS SESSION PAYMENT ──
  Future<bool> processSessionPayment({
    required String userId,
    required String sessionId,
    required double amount,
  }) async {
    _setLoading(true);
    try {
      await Future.delayed(const Duration(seconds: 2));
      final id = _uuid.v4();
      final payment = PaymentModel(
        paymentId: id,
        userId: userId,
        sessionId: sessionId,
        amount: amount,
        status: AppConstants.paymentSuccess,
        paidAt: DateTime.now(),
      );
      await _db.collection(AppConstants.paymentsCol).doc(id).set(payment.toFirestore());
      await _db.collection(AppConstants.sessionsCol).doc(sessionId).update({
        'studentId': userId,
        'status': AppConstants.sessionScheduled,
        'paidAt': FieldValue.serverTimestamp(),
      });
      _lastPayment = payment;
      _paymentSuccess = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── REFUND (Payment.refund, Admin: managePlatformPayments) ──
  Future<bool> refundPayment(String paymentId) async {
    _setLoading(true);
    try {
      // In production: call Stripe refund API via backend
      await Future.delayed(const Duration(seconds: 1));
      await _db.collection(AppConstants.paymentsCol).doc(paymentId)
          .update({'status': AppConstants.paymentRefunded});
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── Load user payments ──
  Future<void> loadUserPayments(String userId) async {
    _setLoading(true);
    final snap = await _db.collection(AppConstants.paymentsCol)
        .where('userId', isEqualTo: userId)
        .orderBy('paidAt', descending: true)
        .get();
    _payments = snap.docs.map((d) => PaymentModel.fromFirestore(d)).toList();
    _setLoading(false);
  }

  // ── Load all payments (Admin) ──
  void watchAllPayments() {
    _db.collection(AppConstants.paymentsCol)
        .orderBy('paidAt', descending: true)
        .snapshots()
        .listen((s) {
      _payments = s.docs.map((d) => PaymentModel.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  // ── Check if user paid for course ──
  Future<bool> hasPaidForCourse(String userId, String courseId) async {
    final snap = await _db.collection(AppConstants.paymentsCol)
        .where('userId', isEqualTo: userId)
        .where('courseId', isEqualTo: courseId)
        .where('status', isEqualTo: AppConstants.paymentSuccess)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void clearError() { _error = null; notifyListeners(); }
  void resetPaymentState() { _paymentSuccess = false; _lastPayment = null; notifyListeners(); }
}
