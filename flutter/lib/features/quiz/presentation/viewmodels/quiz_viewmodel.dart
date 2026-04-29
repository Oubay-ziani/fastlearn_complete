import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '/core/constants/app_constants.dart';
import '/core/domain/entities.dart';
import '/core/data/models.dart';

// ═══════════════════════════════════════════════════════════
// QUIZ VIEWMODEL — MVVM + Observer
// Implements ALL methods from class diagram:
// Instructor: setLessonQuestions, createExam
// Student: takeExam, submitAnswers, viewExamResults
// Exam: createQuestion, autoGrade
// ExamResult: viewResult
// ═══════════════════════════════════════════════════════════
class QuizViewModel extends ChangeNotifier {
  final _db   = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  List<ExamEntity>       _exams       = [];
  List<QuestionEntity>   _questions   = [];
  List<ExamResultEntity> _results     = [];
  ExamEntity?            _currentExam;
  final Map<String, String>    _answers     = {};
  ExamResultEntity?      _lastResult;
  bool                   _isLoading   = false;
  bool                   _submitted   = false;
  String?                _error;

  List<ExamEntity>       get exams       => _exams;
  List<QuestionEntity>   get questions   => _questions;
  List<ExamResultEntity> get results     => _results;
  ExamEntity?            get currentExam => _currentExam;
  Map<String, String>    get answers     => _answers;
  ExamResultEntity?      get lastResult  => _lastResult;
  bool                   get isLoading   => _isLoading;
  bool                   get submitted   => _submitted;
  String?                get error       => _error;

  // ── Watch exams for a course ──
  void watchCourseExams(String courseId) {
    _db.collection(AppConstants.coursesCol).doc(courseId)
        .collection(AppConstants.examsCol)
        .snapshots()
        .listen((s) {
      _exams = s.docs.map((d) => ExamModel.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  // ── Load exam with questions ──
  Future<void> loadExam(String courseId, String examId) async {
    _setLoading(true);
    _answers.clear();
    _submitted = false;
    _lastResult = null;

    final examDoc = await _db.collection(AppConstants.coursesCol).doc(courseId)
        .collection(AppConstants.examsCol).doc(examId).get();
    _currentExam = ExamModel.fromFirestore(examDoc);

    final qs = await _db.collection(AppConstants.coursesCol).doc(courseId)
        .collection(AppConstants.examsCol).doc(examId)
        .collection(AppConstants.questionsCol).get();
    _questions = qs.docs.map((d) => QuestionModel.fromFirestore(d)).toList();

    _setLoading(false);
  }

  // ── CREATE EXAM (Instructor: createExam, Exam: createQuestion) ──
  Future<String?> createExam({
    required String courseId,
    String? lessonId,
    required String title,
    required int passingScore,
  }) async {
    _setLoading(true);
    try {
      final id = _uuid.v4();
      final model = ExamModel(
        examId: id,
        courseId: courseId,
        lessonId: lessonId,
        title: title,
        passingScore: passingScore,
        createdAt: DateTime.now(),
      );
      await _db.collection(AppConstants.coursesCol).doc(courseId)
          .collection(AppConstants.examsCol).doc(id).set(model.toFirestore());
      _setLoading(false);
      return id;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  // ── ADD QUESTION (Instructor: setLessonQuestions, Lesson: addQuestion) ──
  Future<void> addQuestion({
    required String courseId,
    required String examId,
    required String questionText,
    required List<String> options,
    required String correctAnswer,
    required int marks,
  }) async {
    final id = _uuid.v4();
    final model = QuestionModel(
      questionId: id,
      examId: examId,
      questionText: questionText,
      options: options,
      correctAnswer: correctAnswer,
      marks: marks,
    );
    await _db.collection(AppConstants.coursesCol)
        .doc(courseId).collection(AppConstants.examsCol)
        .doc(examId).collection(AppConstants.questionsCol)
        .doc(id).set(model.toFirestore());
    _questions = [..._questions, model];
    notifyListeners();
  }

  // ── DELETE QUESTION ──
  Future<void> deleteQuestion(String courseId, String examId, String questionId) async {
    await _db.collection(AppConstants.coursesCol).doc(courseId)
        .collection(AppConstants.examsCol).doc(examId)
        .collection(AppConstants.questionsCol).doc(questionId).delete();
    _questions.removeWhere((q) => q.questionId == questionId);
    notifyListeners();
  }

  // ── SELECT ANSWER (Student: takeExam) ──
  void selectAnswer(String questionId, String answer) {
    _answers[questionId] = answer;
    notifyListeners();
  }

  // ── SUBMIT ANSWERS (Student: submitAnswers, Exam: autoGrade) ──
  Future<ExamResultEntity?> submitAnswers({
    required String userId,
    required String courseId,
    required String examId,
  }) async {
    if (_currentExam == null || _questions.isEmpty) return null;
    _setLoading(true);
    try {
      // Auto grade (Exam: autoGrade method)
      int score = 0;
      int totalMarks = 0;
      for (final q in _questions) {
        totalMarks += q.marks;
        if (_answers[q.questionId] == q.correctAnswer) {
          score += q.marks;
        }
      }

      final passed = _currentExam!.passingScore <= (totalMarks > 0 ? score / totalMarks * 100 : 0);
      final id = _uuid.v4();

      final result = ExamResultModel(
        resultId: id,
        examId: examId,
        userId: userId,
        courseId: courseId,
        score: score,
        totalMarks: totalMarks,
        passed: passed,
        takenAt: DateTime.now(),
      );

      await _db.collection(AppConstants.examResultsCol).doc(id)
          .set(result.toFirestore());

      _lastResult = result;
      _submitted = true;
      _setLoading(false);
      return result;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  // ── LOAD RESULTS (Student: viewExamResults, ExamResult: viewResult) ──
  Future<void> loadUserResults(String userId, String courseId) async {
    _setLoading(true);
    final snap = await _db.collection(AppConstants.examResultsCol)
        .where('userId', isEqualTo: userId)
        .where('courseId', isEqualTo: courseId)
        .orderBy('takenAt', descending: true)
        .get();
    _results = snap.docs.map((d) => ExamResultModel.fromFirestore(d)).toList();
    _setLoading(false);
  }

  void resetQuiz() {
    _answers.clear();
    _submitted = false;
    _lastResult = null;
    notifyListeners();
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void clearError() { _error = null; notifyListeners(); }
}
