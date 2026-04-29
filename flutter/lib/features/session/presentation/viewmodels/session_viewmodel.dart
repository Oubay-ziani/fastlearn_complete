import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '/core/constants/app_constants.dart';
import '/core/domain/entities.dart';
import '/core/data/models.dart';

// ═══════════════════════════════════════════════════════════
// SESSION VIEWMODEL — MVVM + Observer
// Implements ALL Session methods from class diagram:
// Session.reserve(), Session.cancel()
// Instructor: manageSessionAvailability()
// Student: reserveSession()
// ═══════════════════════════════════════════════════════════
class SessionViewModel extends ChangeNotifier {
  final _db   = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  List<SessionEntity> _sessions  = [];
  bool                _isLoading = false;
  String?             _error;

  List<SessionEntity> get sessions  => _sessions;
  bool                get isLoading => _isLoading;
  String?             get error     => _error;

  // ── MANAGE SESSION AVAILABILITY (Instructor: manageSessionAvailability) ──
  void watchInstructorSessions(String instructorId) {
    _db.collection(AppConstants.sessionsCol)
        .where('instructorId', isEqualTo: instructorId)
        .orderBy('scheduledAt')
        .snapshots()
        .listen((s) {
      _sessions = s.docs.map((d) => SessionModel.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  // ── Watch student sessions ──
  void watchStudentSessions(String studentId) {
    _db.collection(AppConstants.sessionsCol)
        .where('studentId', isEqualTo: studentId)
        .orderBy('scheduledAt')
        .snapshots()
        .listen((s) {
      _sessions = s.docs.map((d) => SessionModel.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  // ── Watch available sessions ──
  void watchAvailableSessions() {
    _db.collection(AppConstants.sessionsCol)
        .where('status', isEqualTo: AppConstants.sessionScheduled)
        .where('studentId', isNull: true)
        .orderBy('scheduledAt')
        .snapshots()
        .listen((s) {
      _sessions = s.docs.map((d) => SessionModel.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  // ── CREATE SESSION SLOT ──
  Future<String?> createSession({
    required String instructorId,
    required DateTime scheduledAt,
    required int durationMinutes,
    required double price,
  }) async {
    _setLoading(true);
    try {
      final id = _uuid.v4();
      final model = SessionModel(
        sessionId: id,
        instructorId: instructorId,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        status: AppConstants.sessionScheduled,
        price: price,
      );
      await _db.collection(AppConstants.sessionsCol).doc(id)
          .set(model.toFirestore());
      _setLoading(false);
      return id;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  // ── RESERVE SESSION (Student: reserveSession, Session.reserve) ──
  Future<bool> reserveSession({
    required String sessionId,
    required String studentId,
  }) async {
    _setLoading(true);
    try {
      // Check session is still available
      final doc = await _db.collection(AppConstants.sessionsCol).doc(sessionId).get();
      final d = doc.data() as Map<String, dynamic>;
      if (d['studentId'] != null) {
        _error = 'Session already booked';
        _setLoading(false);
        return false;
      }
      await _db.collection(AppConstants.sessionsCol).doc(sessionId)
          .update({'studentId': studentId});
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── CANCEL SESSION (Session.cancel) ──
  Future<bool> cancelSession(String sessionId, String userId) async {
    _setLoading(true);
    try {
      final doc = await _db.collection(AppConstants.sessionsCol).doc(sessionId).get();
      final d = doc.data() as Map<String, dynamic>;
      // Only instructor or booked student can cancel
      if (d['instructorId'] != userId && d['studentId'] != userId) {
        _error = 'Unauthorized';
        _setLoading(false);
        return false;
      }
      await _db.collection(AppConstants.sessionsCol).doc(sessionId)
          .update({'status': AppConstants.sessionCancelled});
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── DELETE SESSION SLOT ──
  Future<void> deleteSession(String sessionId) async {
    await _db.collection(AppConstants.sessionsCol).doc(sessionId).delete();
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void clearError() { _error = null; notifyListeners(); }
}
