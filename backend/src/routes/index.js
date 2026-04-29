// ═══════════════════════════════════════════════════════════
// ALL BACKEND ROUTES — Express Router
// MVC: Routes → Controllers → Services → Firebase
// ═══════════════════════════════════════════════════════════
const express = require('express');

// ─── Auth Routes ───────────────────────────────────────────
const authRouter = express.Router();
const { db, auth } = require('../config/firebase');
const { COLLECTIONS } = require('../config/constants');
const { verifyToken } = require('../middleware/auth');

// GET /api/auth/me — get current user profile
authRouter.get('/me', verifyToken, async (req, res, next) => {
  try {
    const doc = await db.collection(COLLECTIONS.USERS).doc(req.user.uid).get();
    if (!doc.exists) return res.status(404).json({ error: 'User not found' });
    res.json({ user: { id: doc.id, ...doc.data() } });
  } catch (err) { next(err); }
});

// PUT /api/auth/profile — update profile (manageProfile)
authRouter.put('/profile', verifyToken, async (req, res, next) => {
  try {
    const { name, bio, profilePicture } = req.body;
    const updates = {};
    if (name) updates.name = name.trim();
    if (bio !== undefined) updates.bio = bio.trim();
    if (profilePicture) updates.profilePicture = profilePicture;
    updates.updatedAt = new Date();

    await db.collection(COLLECTIONS.USERS).doc(req.user.uid).update(updates);
    if (name) await auth.updateUser(req.user.uid, { displayName: name });
    res.json({ success: true, message: 'Profile updated' });
  } catch (err) { next(err); }
});

// POST /api/auth/register — create user doc after Firebase Auth signup
authRouter.post('/register', async (req, res, next) => {
  try {
    const { uid, name, email, role = 'student', bio } = req.body;
    if (!uid || !name || !email) {
      return res.status(400).json({ error: 'uid, name, email required' });
    }

    const userData = {
      name: name.trim(),
      email: email.trim(),
      role,
      profilePicture: null,
      isActive: true,
      createdAt: new Date(),
      ...(role === 'instructor' && { bio: bio?.trim() || '', totalEarnings: 0 }),
    };

    await db.collection(COLLECTIONS.USERS).doc(uid).set(userData);
    res.status(201).json({ success: true, message: 'User registered' });
  } catch (err) { next(err); }
});

module.exports.authRoutes = authRouter;

// ─── Course Routes ─────────────────────────────────────────
const courseRouter = express.Router();
const CourseController = require('../controllers/course.controller');
const { requireInstructor, requireInstructorOrAdmin } = require('../middleware/auth');

courseRouter.get('/', CourseController.getAllCourses);
courseRouter.get('/teacher/my', verifyToken, requireInstructor, CourseController.getTeacherCourses);
courseRouter.get('/enrolled/my', verifyToken, CourseController.getEnrolledCourses);
courseRouter.get('/:id', CourseController.getCourseById);
courseRouter.post('/', verifyToken, requireInstructor, CourseController.createCourse);
courseRouter.put('/:id', verifyToken, requireInstructorOrAdmin, CourseController.updateCourse);
courseRouter.delete('/:id', verifyToken, requireInstructorOrAdmin, CourseController.deleteCourse);
courseRouter.put('/:id/price', verifyToken, requireInstructorOrAdmin, CourseController.setCoursePrice);
courseRouter.put('/:id/submit', verifyToken, requireInstructor, CourseController.submitForReview);
courseRouter.post('/:id/enroll', verifyToken, CourseController.enrollFreeCourse);
courseRouter.get('/:id/lessons', verifyToken, CourseController.getCourseLessons);
courseRouter.post('/:id/lessons', verifyToken, requireInstructorOrAdmin, CourseController.addLesson);
courseRouter.delete('/:id/lessons/:lessonId', verifyToken, requireInstructorOrAdmin, CourseController.deleteLesson);
courseRouter.post('/:id/lessons/:lessonId/complete', verifyToken, CourseController.markLessonComplete);
courseRouter.get('/:id/results', verifyToken, CourseController.getEnrolledCourses);

module.exports.courseRoutes = courseRouter;

// ─── Quiz Routes ───────────────────────────────────────────
const quizRouter  = express.Router();
const QuizController = require('../controllers/quiz.controller');

quizRouter.get('/results/:resultId', verifyToken, QuizController.getResultById);
quizRouter.get('/:courseId/exams', verifyToken, QuizController.getCourseExams);
quizRouter.post('/:courseId/exams', verifyToken, requireInstructorOrAdmin, QuizController.createExam);
quizRouter.get('/:courseId/exams/:examId/questions', verifyToken, QuizController.getExamQuestions);
quizRouter.post('/:courseId/exams/:examId/questions', verifyToken, requireInstructorOrAdmin, QuizController.addQuestion);
quizRouter.delete('/:courseId/exams/:examId/questions/:questionId', verifyToken, requireInstructorOrAdmin, QuizController.deleteQuestion);
quizRouter.post('/:courseId/exams/:examId/submit', verifyToken, QuizController.submitExam);
quizRouter.get('/:courseId/results', verifyToken, QuizController.getUserResults);

module.exports.quizRoutes = quizRouter;

// ─── Payment Routes ────────────────────────────────────────
const paymentRouter = express.Router();
const PaymentController = require('../controllers/payment.controller');
const { requireAdmin } = require('../middleware/auth');

paymentRouter.post('/webhook', express.raw({ type: 'application/json' }), PaymentController.handleWebhook);
paymentRouter.post('/create-intent', verifyToken, PaymentController.createPaymentIntent);
paymentRouter.post('/confirm', verifyToken, PaymentController.confirmPayment);
paymentRouter.post('/refund', verifyToken, requireAdmin, PaymentController.refundPayment);
paymentRouter.get('/my', verifyToken, PaymentController.getMyPayments);
paymentRouter.get('/all', verifyToken, requireAdmin, PaymentController.getAllPayments);

module.exports.paymentRoutes = paymentRouter;

// ─── Admin Routes ──────────────────────────────────────────
const adminRouter = express.Router();
const AdminController = require('../controllers/admin.controller');

adminRouter.use(verifyToken, requireAdmin);
adminRouter.get('/users', AdminController.getAllUsers);
adminRouter.get('/users/:id', AdminController.getUserById);
adminRouter.put('/users/:id/role', AdminController.assignRole);
adminRouter.put('/users/:id/suspend', AdminController.suspendAccount);
adminRouter.put('/users/:id/restore', AdminController.restoreAccount);
adminRouter.delete('/users/:id', AdminController.deleteAccount);
adminRouter.get('/courses/pending', AdminController.getPendingCourses);
adminRouter.put('/courses/:id/approve', AdminController.approveCourse);
adminRouter.put('/courses/:id/reject', AdminController.rejectCourse);
adminRouter.delete('/courses/:id', AdminController.deleteCourse);
adminRouter.get('/analytics', AdminController.getPlatformAnalytics);
adminRouter.get('/payments', AdminController.getPlatformPayments);

module.exports.adminRoutes = adminRouter;

// ─── Analytics Routes ──────────────────────────────────────
const analyticsRouter = express.Router();

analyticsRouter.get('/platform', verifyToken, requireAdmin, AdminController.getPlatformAnalytics);

// Teacher analytics
analyticsRouter.get('/teacher', verifyToken, requireInstructor, async (req, res, next) => {
  try {
    const uid = req.user.uid;
    const [coursesSnap, paymentsSnap] = await Promise.all([
      db.collection(COLLECTIONS.COURSES).where('teacherId', '==', uid).get(),
      db.collection(COLLECTIONS.PAYMENTS).where('status', '==', 'success').get(),
    ]);

    const myCourseIds = coursesSnap.docs.map(d => d.id);
    const myPayments  = paymentsSnap.docs
      .map(d => d.data())
      .filter(p => myCourseIds.includes(p.courseId));

    const totalEnrollments = coursesSnap.docs.reduce(
      (sum, d) => sum + (d.data().enrollmentCount || 0), 0);
    const totalRevenue = myPayments.reduce((sum, p) => sum + (p.amount * 0.7), 0);

    res.json({
      totalCourses: coursesSnap.size,
      totalEnrollments,
      totalRevenue,
      transactions: myPayments.length,
    });
  } catch (err) { next(err); }
});

module.exports.analyticsRoutes = analyticsRouter;

// ─── Session Routes ────────────────────────────────────────
const sessionRouter = express.Router();
const { v4: uuidv4 } = require('uuid');
const { SESSION_STATUS } = require('../config/constants');

sessionRouter.use(verifyToken);

// GET available sessions
sessionRouter.get('/available', async (req, res, next) => {
  try {
    const snap = await db.collection(COLLECTIONS.SESSIONS)
      .where('status', '==', SESSION_STATUS.SCHEDULED)
      .where('studentId', '==', null)
      .orderBy('scheduledAt')
      .get();
    res.json({ sessions: snap.docs.map(d => ({ id: d.id, ...d.data() })) });
  } catch (err) { next(err); }
});

// GET my sessions (as student)
sessionRouter.get('/my', async (req, res, next) => {
  try {
    const snap = await db.collection(COLLECTIONS.SESSIONS)
      .where('studentId', '==', req.user.uid)
      .orderBy('scheduledAt')
      .get();
    res.json({ sessions: snap.docs.map(d => ({ id: d.id, ...d.data() })) });
  } catch (err) { next(err); }
});

// GET instructor sessions
sessionRouter.get('/instructor', requireInstructor, async (req, res, next) => {
  try {
    const snap = await db.collection(COLLECTIONS.SESSIONS)
      .where('instructorId', '==', req.user.uid)
      .orderBy('scheduledAt')
      .get();
    res.json({ sessions: snap.docs.map(d => ({ id: d.id, ...d.data() })) });
  } catch (err) { next(err); }
});

// POST create session slot (Instructor.manageSessionAvailability)
sessionRouter.post('/', requireInstructor, async (req, res, next) => {
  try {
    const { scheduledAt, durationMinutes, price } = req.body;
    if (!scheduledAt || !durationMinutes || !price) {
      return res.status(400).json({ error: 'scheduledAt, durationMinutes, price required' });
    }

    const id      = uuidv4();
    const session = {
      sessionId:       id,
      instructorId:    req.user.uid,
      instructorName:  req.user.name,
      studentId:       null,
      scheduledAt:     new Date(scheduledAt),
      durationMinutes: Number(durationMinutes),
      price:           Number(price),
      status:          SESSION_STATUS.SCHEDULED,
      paidAt:          null,
      createdAt:       new Date(),
    };

    await db.collection(COLLECTIONS.SESSIONS).doc(id).set(session);
    res.status(201).json({ success: true, sessionId: id, session });
  } catch (err) { next(err); }
});

// POST reserve session (Student.reserveSession, Session.reserve)
sessionRouter.post('/:id/reserve', async (req, res, next) => {
  try {
    const { id }  = req.params;
    const userId  = req.user.uid;
    const doc     = await db.collection(COLLECTIONS.SESSIONS).doc(id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Session not found' });

    const session = doc.data();
    if (session.studentId) return res.status(400).json({ error: 'Session already booked' });
    if (session.status !== SESSION_STATUS.SCHEDULED) {
      return res.status(400).json({ error: 'Session not available' });
    }

    await db.collection(COLLECTIONS.SESSIONS).doc(id).update({ studentId: userId });
    res.json({ success: true, message: 'Session reserved. Complete payment to confirm.' });
  } catch (err) { next(err); }
});

// PUT cancel session (Session.cancel)
sessionRouter.put('/:id/cancel', async (req, res, next) => {
  try {
    const { id }  = req.params;
    const userId  = req.user.uid;
    const doc     = await db.collection(COLLECTIONS.SESSIONS).doc(id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Session not found' });

    const session = doc.data();
    if (session.instructorId !== userId && session.studentId !== userId &&
        req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized to cancel this session' });
    }

    await db.collection(COLLECTIONS.SESSIONS).doc(id).update({
      status: SESSION_STATUS.CANCELLED,
      cancelledAt: new Date(),
      cancelledBy: userId,
    });
    res.json({ success: true, message: 'Session cancelled' });
  } catch (err) { next(err); }
});

// DELETE session slot (Instructor only)
sessionRouter.delete('/:id', requireInstructor, async (req, res, next) => {
  try {
    const doc = await db.collection(COLLECTIONS.SESSIONS).doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Session not found' });
    if (doc.data().instructorId !== req.user.uid) {
      return res.status(403).json({ error: 'Not authorized' });
    }
    await db.collection(COLLECTIONS.SESSIONS).doc(req.params.id).delete();
    res.json({ success: true, message: 'Session deleted' });
  } catch (err) { next(err); }
});

module.exports.sessionRoutes = sessionRouter;
