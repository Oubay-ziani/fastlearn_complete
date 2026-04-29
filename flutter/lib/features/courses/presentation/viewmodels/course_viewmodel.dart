import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '/core/constants/app_constants.dart';
import '/core/domain/entities.dart';
import '/core/data/models.dart';

// ═══════════════════════════════════════════════════════════
// COURSE VIEWMODEL — MVVM + Observer Pattern
// Implements ALL methods from class diagram:
// Course: addLesson, setPrice, publish
// Instructor: createCourse, addLesson, setCoursePrice, setLessonQuestions
// Student: watchCourses, viewEnrolledCourses
// ═══════════════════════════════════════════════════════════
class CourseViewModel extends ChangeNotifier {
  final _db      = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _uuid    = const Uuid();

  List<CourseEntity>    _courses        = [];
  List<CourseEntity>    _filteredCourses= [];
  List<LessonEntity>    _lessons        = [];
  List<String>          _enrolledIds    = [];
  List<EnrollmentEntity>_enrollments    = [];
  CourseEntity?         _selectedCourse;
  String                _searchQuery    = '';
  String                _selectedCategory = 'All';
  bool                  _isLoading      = false;
  String?               _error;
  double                _uploadProgress = 0;

  List<CourseEntity>    get courses         => _filteredCourses;
  List<LessonEntity>    get lessons         => _lessons;
  List<String>          get enrolledIds     => _enrolledIds;
  List<EnrollmentEntity>get enrollments     => _enrollments;
  CourseEntity?         get selectedCourse  => _selectedCourse;
  bool                  get isLoading       => _isLoading;
  String?               get error           => _error;
  double                get uploadProgress  => _uploadProgress;
  String                get searchQuery     => _searchQuery;
  String                get selectedCategory=> _selectedCategory;

  bool isEnrolled(String courseId) => _enrolledIds.contains(courseId);

  // ── Watch published courses (Student: watchCourses) ──
  void watchPublishedCourses() {
    _db.collection(AppConstants.coursesCol)
        .where('status', isEqualTo: AppConstants.statusPublished)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((s) {
      _courses = s.docs.map((d) => CourseModel.fromFirestore(d)).toList();
      _applyFilter();
    });
  }

  // ── Watch teacher's own courses ──
  void watchTeacherCourses(String teacherId) {
    _db.collection(AppConstants.coursesCol)
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((s) {
      _courses = s.docs.map((d) => CourseModel.fromFirestore(d)).toList();
      _applyFilter();
    });
  }

  // ── Watch enrolled courses (Student: viewEnrolledCourses) ──
  void watchEnrolledIds(String userId) {
    _db.collection(AppConstants.enrollmentsCol)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((s) {
      _enrolledIds = s.docs.map((d) => d['courseId'] as String).toList();
      _enrollments = s.docs.map((d) => EnrollmentModel.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  // ── Watch lessons for a course ──
  void watchLessons(String courseId) {
    _db.collection(AppConstants.coursesCol).doc(courseId)
        .collection(AppConstants.lessonsCol)
        .orderBy('orderIndex')
        .snapshots()
        .listen((s) {
      _lessons = s.docs.map((d) => LessonModel.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  // ── Select a course ──
  Future<void> selectCourse(String courseId) async {
    _setLoading(true);
    final doc = await _db.collection(AppConstants.coursesCol).doc(courseId).get();
    _selectedCourse = CourseModel.fromFirestore(doc);
    _setLoading(false);
  }

  // ── Search and filter ──
  void search(String query) {
    _searchQuery = query;
    _applyFilter();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilter();
  }

  void _applyFilter() {
    var result = List<CourseEntity>.from(_courses);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((c) =>
        c.title.toLowerCase().contains(q) ||
        c.description.toLowerCase().contains(q) ||
        c.teacherName.toLowerCase().contains(q) ||
        c.category.toLowerCase().contains(q)).toList();
    }
    if (_selectedCategory != 'All') {
      result = result.where((c) => c.category == _selectedCategory).toList();
    }
    _filteredCourses = result;
    notifyListeners();
  }

  // ── CREATE COURSE (Instructor: createCourse) ──
  Future<String?> createCourse({
    required String teacherId,
    required String teacherName,
    String? teacherAvatar,
    required String title,
    required String description,
    required String category,
    required double price,
    File? thumbnailFile,
  }) async {
    _setLoading(true);
    try {
      final id = _uuid.v4();
      String? thumbnailUrl;
      if (thumbnailFile != null) {
        thumbnailUrl = await _uploadThumbnail(thumbnailFile, id);
      }
      final model = CourseModel(
        courseId: id,
        title: title,
        description: description,
        price: price,
        status: AppConstants.statusDraft,
        teacherId: teacherId,
        teacherName: teacherName,
        teacherAvatar: teacherAvatar,
        category: category,
        thumbnailUrl: thumbnailUrl,
        createdAt: DateTime.now(),
      );
      await _db.collection(AppConstants.coursesCol).doc(id).set(model.toFirestore());
      _setLoading(false);
      return id;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  // ── ADD LESSON (Instructor: addLesson, Class: addLesson) ──
  Future<String?> addLesson({
    required String courseId,
    required String title,
    String? description,
    File? videoFile,
    File? pdfFile,
    int orderIndex = 0,
    int durationSeconds = 0,
    bool isFree = false,
  }) async {
    _setLoading(true);
    try {
      final id = _uuid.v4();
      String? videoUrl, pdfUrl;

      if (videoFile != null) {
        videoUrl = await _uploadVideo(videoFile, courseId, id);
      }
      if (pdfFile != null) {
        pdfUrl = await _uploadPdf(pdfFile, courseId, id);
      }

      final model = LessonModel(
        lessonId: id,
        courseId: courseId,
        title: title,
        description: description,
        videoUrl: videoUrl,
        pdfUrl: pdfUrl,
        orderIndex: orderIndex,
        durationSeconds: durationSeconds,
        isFree: isFree,
        createdAt: DateTime.now(),
      );
      await _db.collection(AppConstants.coursesCol).doc(courseId)
          .collection(AppConstants.lessonsCol).doc(id).set(model.toFirestore());
      await _db.collection(AppConstants.coursesCol).doc(courseId)
          .update({'lessonCount': FieldValue.increment(1)});
      _setLoading(false);
      return id;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  // ── DELETE LESSON ──
  Future<void> deleteLesson(String courseId, String lessonId) async {
    await _db.collection(AppConstants.coursesCol).doc(courseId)
        .collection(AppConstants.lessonsCol).doc(lessonId).delete();
    await _db.collection(AppConstants.coursesCol).doc(courseId)
        .update({'lessonCount': FieldValue.increment(-1)});
  }

  // ── SET PRICE (Instructor: setCoursePrice, Class: setPrice) ──
  Future<void> setCoursePrice(String courseId, double price) async {
    await _db.collection(AppConstants.coursesCol).doc(courseId)
        .update({'price': price, 'updatedAt': FieldValue.serverTimestamp()});
  }

  // ── PUBLISH COURSE (submit for review) (Class: publish) ──
  Future<void> submitForReview(String courseId) async {
    await _db.collection(AppConstants.coursesCol).doc(courseId)
        .update({'status': AppConstants.statusPending, 'updatedAt': FieldValue.serverTimestamp()});
  }

  // ── UPDATE COURSE ──
  Future<void> updateCourse(String courseId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection(AppConstants.coursesCol).doc(courseId).update(data);
  }

  // ── DELETE COURSE ──
  Future<void> deleteCourse(String courseId) async {
    await _db.collection(AppConstants.coursesCol).doc(courseId).delete();
  }

  // ── ENROLL (Student: buyCourse - free) ──
  Future<bool> enrollInCourse(String userId, String courseId) async {
    try {
      final docId = '${userId}_$courseId';
      final exists = (await _db.collection(AppConstants.enrollmentsCol).doc(docId).get()).exists;
      if (exists) return true;

      await _db.collection(AppConstants.enrollmentsCol).doc(docId).set({
        'userId': userId,
        'courseId': courseId,
        'enrolledAt': FieldValue.serverTimestamp(),
        'completed': false,
        'progress': 0,
        'completedLessons': [],
      });
      await _db.collection(AppConstants.coursesCol).doc(courseId)
          .update({'enrollmentCount': FieldValue.increment(1)});
      _enrolledIds = [..._enrolledIds, courseId];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── MARK LESSON COMPLETE (Student: watchCourses progress) ──
  Future<void> markLessonComplete(String userId, String courseId, String lessonId) async {
    final ref = _db.collection(AppConstants.enrollmentsCol).doc('${userId}_$courseId');
    await ref.update({'completedLessons': FieldValue.arrayUnion([lessonId])});
    final doc = await ref.get();
    final d = doc.data()!;
    final completed = (d['completedLessons'] as List).length;
    final courseDoc = await _db.collection(AppConstants.coursesCol).doc(courseId).get();
    final total = (courseDoc.data()!['lessonCount'] as int?) ?? 1;
    final progress = (completed / total * 100).round();
    await ref.update({'progress': progress, 'completed': progress >= 100});
    if (progress >= 100) {
      // Trigger certificate generation
      notifyListeners();
    }
  }

  // ── Get enrollment for progress check ──
  Future<EnrollmentEntity?> getEnrollment(String userId, String courseId) async {
    final doc = await _db.collection(AppConstants.enrollmentsCol)
        .doc('${userId}_$courseId').get();
    if (!doc.exists) return null;
    return EnrollmentModel.fromFirestore(doc);
  }

  // ── Upload helpers ──
  Future<String> _uploadThumbnail(File file, String courseId) async {
    final ref = _storage.ref('${AppConstants.thumbsPath}/$courseId.jpg');
    final task = ref.putFile(file);
    task.snapshotEvents.listen((s) {
      _uploadProgress = s.bytesTransferred / s.totalBytes;
      notifyListeners();
    });
    await task;
    return ref.getDownloadURL();
  }

  Future<String> _uploadVideo(File file, String courseId, String lessonId) async {
    final ref = _storage.ref('${AppConstants.videosPath}/$courseId/$lessonId.mp4');
    final task = ref.putFile(file);
    task.snapshotEvents.listen((s) {
      _uploadProgress = s.bytesTransferred / s.totalBytes;
      notifyListeners();
    });
    await task;
    return ref.getDownloadURL();
  }

  Future<String> _uploadPdf(File file, String courseId, String lessonId) async {
    final ref = _storage.ref('${AppConstants.pdfsPath}/$courseId/$lessonId.pdf');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  // ── Watch pending courses (Admin) ──
  void watchPendingCourses() {
    _db.collection(AppConstants.coursesCol)
        .where('status', isEqualTo: AppConstants.statusPending)
        .snapshots()
        .listen((s) {
      _courses = s.docs.map((d) => CourseModel.fromFirestore(d)).toList();
      _filteredCourses = _courses;
      notifyListeners();
    });
  }

  // ── Admin: approve/reject (Admin: approveOrRejectCourse) ──
  Future<void> approveCourse(String courseId) async {
    await _db.collection(AppConstants.coursesCol).doc(courseId)
        .update({'status': AppConstants.statusPublished});
  }

  Future<void> rejectCourse(String courseId) async {
    await _db.collection(AppConstants.coursesCol).doc(courseId)
        .update({'status': AppConstants.statusRejected});
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void clearError() { _error = null; notifyListeners(); }
}
