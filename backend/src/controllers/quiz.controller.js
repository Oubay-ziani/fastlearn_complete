// ═══════════════════════════════════════════════════════════
// QUIZ CONTROLLER — MVC Pattern
// Implements ALL quiz methods from class diagram:
// Instructor: createExam, setLessonQuestions
// Exam: createQuestion, autoGrade
// Student: takeExam, submitAnswers
// ExamResult: viewResult
// ═══════════════════════════════════════════════════════════
const { v4: uuid } = require('uuid');
const { db }       = require('../config/firebase');
const { COLLECTIONS } = require('../config/constants');

class QuizController {

  // ── CREATE EXAM (Instructor.createExam) ──
  // POST /api/courses/:courseId/exams
  static async createExam(req, res, next) {
    try {
      const { courseId }                    = req.params;
      const { title, passingScore, lessonId } = req.body;

      if (!title) return res.status(400).json({ error: 'Exam title required' });

      const courseDoc = await db.collection(COLLECTIONS.COURSES).doc(courseId).get();
      if (!courseDoc.exists) return res.status(404).json({ error: 'Course not found' });
      if (courseDoc.data().teacherId !== req.user.uid && req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Not authorized' });
      }

      const examId = uuid();
      const exam   = {
        examId,
        courseId,
        lessonId: lessonId || null,
        title: title.trim(),
        passingScore: Number(passingScore) || 60,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      await db.collection(COLLECTIONS.COURSES).doc(courseId)
        .collection(COLLECTIONS.EXAMS).doc(examId).set(exam);

      res.status(201).json({ success: true, examId, exam });
    } catch (err) { next(err); }
  }

  // ── GET EXAMS FOR COURSE ──
  // GET /api/courses/:courseId/exams
  static async getCourseExams(req, res, next) {
    try {
      const snap = await db.collection(COLLECTIONS.COURSES).doc(req.params.courseId)
        .collection(COLLECTIONS.EXAMS).get();
      const exams = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      res.json({ exams });
    } catch (err) { next(err); }
  }

  // ── ADD QUESTION (Instructor.setLessonQuestions, Exam.createQuestion, Lesson.addQuestion) ──
  // POST /api/courses/:courseId/exams/:examId/questions
  static async addQuestion(req, res, next) {
    try {
      const { courseId, examId }                       = req.params;
      const { questionText, options, correctAnswer, marks } = req.body;

      if (!questionText || !options || !correctAnswer) {
        return res.status(400).json({ error: 'questionText, options, and correctAnswer required' });
      }
      if (!Array.isArray(options) || options.length < 2) {
        return res.status(400).json({ error: 'At least 2 options required' });
      }
      if (!options.includes(correctAnswer)) {
        return res.status(400).json({ error: 'correctAnswer must be one of the options' });
      }

      const courseDoc = await db.collection(COLLECTIONS.COURSES).doc(courseId).get();
      if (!courseDoc.exists) return res.status(404).json({ error: 'Course not found' });
      if (courseDoc.data().teacherId !== req.user.uid && req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Not authorized' });
      }

      const questionId = uuid();
      const question   = {
        questionId,
        examId,
        questionText: questionText.trim(),
        options,
        correctAnswer,
        marks: Number(marks) || 1,
        createdAt: new Date(),
      };

      await db.collection(COLLECTIONS.COURSES).doc(courseId)
        .collection(COLLECTIONS.EXAMS).doc(examId)
        .collection(COLLECTIONS.QUESTIONS).doc(questionId).set(question);

      res.status(201).json({ success: true, questionId, question });
    } catch (err) { next(err); }
  }

  // ── GET QUESTIONS ──
  // GET /api/courses/:courseId/exams/:examId/questions
  static async getExamQuestions(req, res, next) {
    try {
      const { courseId, examId } = req.params;

      // Check enrollment or instructor
      const userId    = req.user.uid;
      const courseDoc = await db.collection(COLLECTIONS.COURSES).doc(courseId).get();
      const isTeacher = courseDoc.data()?.teacherId === userId;
      const isAdmin   = req.user.role === 'admin';

      if (!isTeacher && !isAdmin) {
        const enrollDoc = await db.collection(COLLECTIONS.ENROLLMENTS)
          .doc(`${userId}_${courseId}`).get();
        if (!enrollDoc.exists) {
          return res.status(403).json({ error: 'Enroll in course to access exam' });
        }
      }

      const snap      = await db.collection(COLLECTIONS.COURSES).doc(courseId)
        .collection(COLLECTIONS.EXAMS).doc(examId)
        .collection(COLLECTIONS.QUESTIONS).get();

      // Students don't see correct answer during exam
      const questions = snap.docs.map(d => {
        const q = { id: d.id, ...d.data() };
        if (!isTeacher && !isAdmin) delete q.correctAnswer;
        return q;
      });

      res.json({ questions, count: questions.length });
    } catch (err) { next(err); }
  }

  // ── DELETE QUESTION ──
  // DELETE /api/courses/:courseId/exams/:examId/questions/:questionId
  static async deleteQuestion(req, res, next) {
    try {
      const { courseId, examId, questionId } = req.params;
      await db.collection(COLLECTIONS.COURSES).doc(courseId)
        .collection(COLLECTIONS.EXAMS).doc(examId)
        .collection(COLLECTIONS.QUESTIONS).doc(questionId).delete();
      res.json({ success: true, message: 'Question deleted' });
    } catch (err) { next(err); }
  }

  // ── SUBMIT ANSWERS (Student.submitAnswers + Exam.autoGrade) ──
  // POST /api/courses/:courseId/exams/:examId/submit
  static async submitExam(req, res, next) {
    try {
      const { courseId, examId } = req.params;
      const { answers }          = req.body; // { questionId: selectedAnswer }
      const userId               = req.user.uid;

      if (!answers || typeof answers !== 'object') {
        return res.status(400).json({ error: 'answers object required' });
      }

      // Verify enrollment
      const enrollDoc = await db.collection(COLLECTIONS.ENROLLMENTS)
        .doc(`${userId}_${courseId}`).get();
      if (!enrollDoc.exists) {
        return res.status(403).json({ error: 'Not enrolled in this course' });
      }

      // Get exam and questions
      const examDoc = await db.collection(COLLECTIONS.COURSES).doc(courseId)
        .collection(COLLECTIONS.EXAMS).doc(examId).get();
      if (!examDoc.exists) return res.status(404).json({ error: 'Exam not found' });
      const exam = examDoc.data();

      const questionsSnap = await db.collection(COLLECTIONS.COURSES).doc(courseId)
        .collection(COLLECTIONS.EXAMS).doc(examId)
        .collection(COLLECTIONS.QUESTIONS).get();
      const questions = questionsSnap.docs.map(d => ({ id: d.id, ...d.data() }));

      // ── EXAM.autoGrade() implementation ──
      let score      = 0;
      let totalMarks = 0;
      const breakdown = [];

      for (const q of questions) {
        totalMarks += q.marks;
        const userAnswer = answers[q.questionId];
        const correct    = userAnswer === q.correctAnswer;
        if (correct) score += q.marks;
        breakdown.push({
          questionId:    q.questionId,
          questionText:  q.questionText,
          userAnswer,
          correctAnswer: q.correctAnswer,
          correct,
          marks:         correct ? q.marks : 0,
        });
      }

      const percentage = totalMarks > 0 ? (score / totalMarks) * 100 : 0;
      const passed     = percentage >= exam.passingScore;

      // Save result
      const resultId = uuid();
      const result   = {
        resultId,
        examId,
        courseId,
        userId,
        score,
        totalMarks,
        percentage: Math.round(percentage),
        passed,
        answers,
        breakdown,
        takenAt: new Date(),
      };

      await db.collection(COLLECTIONS.EXAM_RESULTS).doc(resultId).set(result);

      // If passed, check if course complete for certificate
      if (passed) {
        const enrollment = enrollDoc.data();
        if (enrollment.completed) {
          // Trigger certificate generation signal
          result.certEligible = true;
        }
      }

      res.json({ success: true, result });
    } catch (err) { next(err); }
  }

  // ── VIEW RESULTS (Student.viewExamResults, ExamResult.viewResult) ──
  // GET /api/courses/:courseId/results
  static async getUserResults(req, res, next) {
    try {
      const { courseId } = req.params;
      const userId       = req.user.uid;

      const snap    = await db.collection(COLLECTIONS.EXAM_RESULTS)
        .where('userId', '==', userId)
        .where('courseId', '==', courseId)
        .orderBy('takenAt', 'desc')
        .get();

      const results = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      res.json({ results });
    } catch (err) { next(err); }
  }

  // ── GET RESULT BY ID ──
  // GET /api/results/:resultId
  static async getResultById(req, res, next) {
    try {
      const doc = await db.collection(COLLECTIONS.EXAM_RESULTS).doc(req.params.resultId).get();
      if (!doc.exists) return res.status(404).json({ error: 'Result not found' });
      if (doc.data().userId !== req.user.uid && req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Not authorized' });
      }
      res.json({ result: { id: doc.id, ...doc.data() } });
    } catch (err) { next(err); }
  }
}

module.exports = QuizController;
