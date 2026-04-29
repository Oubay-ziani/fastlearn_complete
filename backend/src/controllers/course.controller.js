// ═══════════════════════════════════════════════════════════
// COURSE CONTROLLER — MVC Pattern
// Implements: Course.addLesson, setPrice, publish
// Instructor: createCourse, addLesson, setCoursePrice
// Student: watchCourses, viewEnrolledCourses, buyCourse (free)
// ═══════════════════════════════════════════════════════════
const { v4: uuid } = require('uuid');
const { db }       = require('../config/firebase');
const { COLLECTIONS, COURSE_STATUS, PAYMENT_STATUS } = require('../config/constants');

class CourseController {

  // ── GET all published courses ──
  // GET /api/courses
  static async getAllCourses(req, res, next) {
    try {
      const { category, search, limit = 20, offset = 0 } = req.query;

      let query = db.collection(COLLECTIONS.COURSES)
        .where('status', '==', COURSE_STATUS.PUBLISHED)
        .orderBy('createdAt', 'desc')
        .limit(Number(limit));

      if (category && category !== 'All') {
        query = query.where('category', '==', category);
      }

      const snap    = await query.get();
      let courses   = snap.docs.map(d => ({ id: d.id, ...d.data() }));

      // Client-side search filter
      if (search) {
        const q = search.toLowerCase();
        courses = courses.filter(c =>
          c.title?.toLowerCase().includes(q) ||
          c.description?.toLowerCase().includes(q) ||
          c.teacherName?.toLowerCase().includes(q) ||
          c.category?.toLowerCase().includes(q)
        );
      }

      res.json({ courses, count: courses.length });
    } catch (err) { next(err); }
  }

  // ── GET single course ──
  // GET /api/courses/:id
  static async getCourseById(req, res, next) {
    try {
      const doc = await db.collection(COLLECTIONS.COURSES).doc(req.params.id).get();
      if (!doc.exists) return res.status(404).json({ error: 'Course not found' });
      res.json({ course: { id: doc.id, ...doc.data() } });
    } catch (err) { next(err); }
  }

  // ── CREATE COURSE (Instructor.createCourse) ──
  // POST /api/courses
  static async createCourse(req, res, next) {
    try {
      const { title, description, category, price, thumbnailUrl } = req.body;
      const teacherId   = req.user.uid;
      const teacherName = req.user.name;

      if (!title || !description || !category) {
        return res.status(400).json({ error: 'title, description, and category are required' });
      }

      const id  = uuid();
      const now = new Date();

      const courseData = {
        courseId:       id,
        title:          title.trim(),
        description:    description.trim(),
        category,
        price:          Number(price) || 0,
        status:         COURSE_STATUS.DRAFT,
        teacherId,
        teacherName,
        teacherAvatar:  req.user.profilePicture || null,
        thumbnailUrl:   thumbnailUrl || null,
        lessonCount:    0,
        enrollmentCount:0,
        rating:         0,
        ratingCount:    0,
        createdAt:      now,
        updatedAt:      now,
      };

      await db.collection(COLLECTIONS.COURSES).doc(id).set(courseData);
      res.status(201).json({ success: true, courseId: id, course: courseData });
    } catch (err) { next(err); }
  }

  // ── UPDATE COURSE ──
  // PUT /api/courses/:id
  static async updateCourse(req, res, next) {
    try {
      const { id } = req.params;
      const doc    = await db.collection(COLLECTIONS.COURSES).doc(id).get();
      if (!doc.exists) return res.status(404).json({ error: 'Course not found' });

      // Only teacher or admin can update
      if (doc.data().teacherId !== req.user.uid && req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Not authorized to update this course' });
      }

      const allowedFields = ['title', 'description', 'category', 'price', 'thumbnailUrl'];
      const updates = {};
      for (const field of allowedFields) {
        if (req.body[field] !== undefined) updates[field] = req.body[field];
      }
      updates.updatedAt = new Date();

      await db.collection(COLLECTIONS.COURSES).doc(id).update(updates);
      res.json({ success: true, message: 'Course updated' });
    } catch (err) { next(err); }
  }

  // ── DELETE COURSE ──
  // DELETE /api/courses/:id
  static async deleteCourse(req, res, next) {
    try {
      const { id }  = req.params;
      const doc     = await db.collection(COLLECTIONS.COURSES).doc(id).get();
      if (!doc.exists) return res.status(404).json({ error: 'Course not found' });
      if (doc.data().teacherId !== req.user.uid && req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Not authorized' });
      }

      // Delete all lessons sub-collection
      const lessons = await db.collection(COLLECTIONS.COURSES).doc(id)
        .collection(COLLECTIONS.LESSONS).get();
      const batch = db.batch();
      lessons.docs.forEach(l => batch.delete(l.ref));
      batch.delete(db.collection(COLLECTIONS.COURSES).doc(id));
      await batch.commit();

      res.json({ success: true, message: 'Course and all lessons deleted' });
    } catch (err) { next(err); }
  }

  // ── SET PRICE (Instructor.setCoursePrice, Course.setPrice) ──
  // PUT /api/courses/:id/price
  static async setCoursePrice(req, res, next) {
    try {
      const { price } = req.body;
      if (price === undefined || isNaN(Number(price)) || Number(price) < 0) {
        return res.status(400).json({ error: 'Valid price required (>= 0)' });
      }

      const doc = await db.collection(COLLECTIONS.COURSES).doc(req.params.id).get();
      if (!doc.exists) return res.status(404).json({ error: 'Course not found' });
      if (doc.data().teacherId !== req.user.uid && req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Not authorized' });
      }

      await db.collection(COLLECTIONS.COURSES).doc(req.params.id).update({
        price: Number(price), updatedAt: new Date(),
      });

      res.json({ success: true, message: `Price updated to $${price}` });
    } catch (err) { next(err); }
  }

  // ── PUBLISH COURSE (Course.publish — submit for review) ──
  // PUT /api/courses/:id/submit
  static async submitForReview(req, res, next) {
    try {
      const { id } = req.params;
      const doc    = await db.collection(COLLECTIONS.COURSES).doc(id).get();
      if (!doc.exists) return res.status(404).json({ error: 'Course not found' });
      if (doc.data().teacherId !== req.user.uid) {
        return res.status(403).json({ error: 'Not authorized' });
      }

      const lessonSnap = await db.collection(COLLECTIONS.COURSES).doc(id)
        .collection(COLLECTIONS.LESSONS).limit(1).get();
      if (lessonSnap.empty) {
        return res.status(400).json({ error: 'Add at least one lesson before submitting' });
      }

      await db.collection(COLLECTIONS.COURSES).doc(id).update({
        status: COURSE_STATUS.PENDING,
        submittedAt: new Date(),
        updatedAt: new Date(),
      });

      res.json({ success: true, message: 'Course submitted for admin review' });
    } catch (err) { next(err); }
  }

  // ── GET LESSONS (Course.addLesson relationship) ──
  // GET /api/courses/:id/lessons
  static async getCourseLessons(req, res, next) {
    try {
      const { id } = req.params;

      // Check access
      const courseDoc = await db.collection(COLLECTIONS.COURSES).doc(id).get();
      if (!courseDoc.exists) return res.status(404).json({ error: 'Course not found' });

      const snap    = await db.collection(COLLECTIONS.COURSES).doc(id)
        .collection(COLLECTIONS.LESSONS)
        .orderBy('orderIndex')
        .get();

      let lessons = snap.docs.map(d => ({ id: d.id, ...d.data() }));

      // If not enrolled or teacher, only return free lessons
      const userId = req.user?.uid;
      if (userId) {
        const enrollDoc = await db.collection(COLLECTIONS.ENROLLMENTS)
          .doc(`${userId}_${id}`).get();
        const isTeacher = courseDoc.data().teacherId === userId;
        const isAdmin   = req.user?.role === 'admin';
        const enrolled  = enrollDoc.exists;

        if (!enrolled && !isTeacher && !isAdmin) {
          lessons = lessons.map(l => ({
            ...l,
            videoUrl: l.isFree ? l.videoUrl : null,
            pdfUrl: l.isFree ? l.pdfUrl : null,
            locked: !l.isFree,
          }));
        }
      }

      res.json({ lessons, count: lessons.length });
    } catch (err) { next(err); }
  }

  // ── ADD LESSON (Instructor.addLesson, Course.addLesson, Lesson.addQuestion) ──
  // POST /api/courses/:id/lessons
  static async addLesson(req, res, next) {
    try {
      const { id }                                    = req.params;
      const { title, description, videoUrl, pdfUrl,
              orderIndex, durationSeconds, isFree }   = req.body;

      const courseDoc = await db.collection(COLLECTIONS.COURSES).doc(id).get();
      if (!courseDoc.exists) return res.status(404).json({ error: 'Course not found' });
      if (courseDoc.data().teacherId !== req.user.uid && req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Not authorized' });
      }

      if (!title) return res.status(400).json({ error: 'Lesson title required' });

      const lessonId = uuid();
      const lesson   = {
        lessonId,
        courseId: id,
        title: title.trim(),
        description: description?.trim() || null,
        videoUrl:   videoUrl   || null,
        pdfUrl:     pdfUrl     || null,
        orderIndex: Number(orderIndex)   || 0,
        durationSeconds: Number(durationSeconds) || 0,
        isFree:     Boolean(isFree),
        createdAt:  new Date(),
      };

      const batch = db.batch();
      batch.set(
        db.collection(COLLECTIONS.COURSES).doc(id)
          .collection(COLLECTIONS.LESSONS).doc(lessonId),
        lesson
      );
      batch.update(
        db.collection(COLLECTIONS.COURSES).doc(id),
        { lessonCount: db.FieldValue.increment(1), updatedAt: new Date() }
      );
      await batch.commit();

      res.status(201).json({ success: true, lessonId, lesson });
    } catch (err) { next(err); }
  }

  // ── DELETE LESSON ──
  // DELETE /api/courses/:courseId/lessons/:lessonId
  static async deleteLesson(req, res, next) {
    try {
      const { id, lessonId } = req.params;

      const courseDoc = await db.collection(COLLECTIONS.COURSES).doc(id).get();
      if (!courseDoc.exists) return res.status(404).json({ error: 'Course not found' });
      if (courseDoc.data().teacherId !== req.user.uid && req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Not authorized' });
      }

      const batch = db.batch();
      batch.delete(
        db.collection(COLLECTIONS.COURSES).doc(id)
          .collection(COLLECTIONS.LESSONS).doc(lessonId)
      );
      batch.update(
        db.collection(COLLECTIONS.COURSES).doc(id),
        { lessonCount: db.FieldValue.increment(-1), updatedAt: new Date() }
      );
      await batch.commit();

      res.json({ success: true, message: 'Lesson deleted' });
    } catch (err) { next(err); }
  }

  // ── ENROLL FREE COURSE (Student.buyCourse for free courses) ──
  // POST /api/courses/:id/enroll
  static async enrollFreeCourse(req, res, next) {
    try {
      const { id }  = req.params;
      const userId  = req.user.uid;

      const courseDoc = await db.collection(COLLECTIONS.COURSES).doc(id).get();
      if (!courseDoc.exists) return res.status(404).json({ error: 'Course not found' });

      const course = courseDoc.data();
      if (course.price > 0) {
        return res.status(400).json({
          error: 'This is a paid course. Use /api/payments/create-intent to purchase.'
        });
      }

      const enrollId  = `${userId}_${id}`;
      const enrollDoc = await db.collection(COLLECTIONS.ENROLLMENTS).doc(enrollId).get();
      if (enrollDoc.exists) {
        return res.json({ success: true, message: 'Already enrolled', alreadyEnrolled: true });
      }

      const batch = db.batch();
      batch.set(db.collection(COLLECTIONS.ENROLLMENTS).doc(enrollId), {
        enrollmentId: enrollId,
        userId,
        courseId: id,
        enrolledAt: new Date(),
        completed: false,
        progress: 0,
        completedLessons: [],
      });
      batch.update(db.collection(COLLECTIONS.COURSES).doc(id), {
        enrollmentCount: db.FieldValue.increment(1),
      });
      await batch.commit();

      res.status(201).json({ success: true, message: 'Enrolled successfully!' });
    } catch (err) { next(err); }
  }

  // ── MARK LESSON COMPLETE (Student.watchCourses progress) ──
  // POST /api/courses/:id/lessons/:lessonId/complete
  static async markLessonComplete(req, res, next) {
    try {
      const { id, lessonId } = req.params;
      const userId           = req.user.uid;
      const enrollId         = `${userId}_${id}`;

      const enrollDoc = await db.collection(COLLECTIONS.ENROLLMENTS).doc(enrollId).get();
      if (!enrollDoc.exists) return res.status(403).json({ error: 'Not enrolled in this course' });

      const enrollment = enrollDoc.data();
      const completed  = enrollment.completedLessons || [];
      if (completed.includes(lessonId)) {
        return res.json({ success: true, message: 'Already marked complete', progress: enrollment.progress });
      }

      const courseDoc   = await db.collection(COLLECTIONS.COURSES).doc(id).get();
      const totalLessons = courseDoc.data().lessonCount || 1;
      const newCompleted = [...completed, lessonId];
      const progress     = Math.round((newCompleted.length / totalLessons) * 100);
      const isCompleted  = progress >= 100;

      await db.collection(COLLECTIONS.ENROLLMENTS).doc(enrollId).update({
        completedLessons: newCompleted,
        progress,
        completed: isCompleted,
        ...(isCompleted && { completedAt: new Date() }),
      });

      res.json({ success: true, progress, completed: isCompleted });
    } catch (err) { next(err); }
  }

  // ── GET TEACHER COURSES ──
  // GET /api/courses/teacher/my
  static async getTeacherCourses(req, res, next) {
    try {
      const snap = await db.collection(COLLECTIONS.COURSES)
        .where('teacherId', '==', req.user.uid)
        .orderBy('createdAt', 'desc')
        .get();
      const courses = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      res.json({ courses, count: courses.length });
    } catch (err) { next(err); }
  }

  // ── GET ENROLLED COURSES (Student.viewEnrolledCourses) ──
  // GET /api/courses/enrolled/my
  static async getEnrolledCourses(req, res, next) {
    try {
      const snap = await db.collection(COLLECTIONS.ENROLLMENTS)
        .where('userId', '==', req.user.uid)
        .orderBy('enrolledAt', 'desc')
        .get();

      const enrollments = snap.docs.map(d => ({ id: d.id, ...d.data() }));

      // Fetch course details for each enrollment
      const courses = await Promise.all(
        enrollments.map(async e => {
          const cDoc = await db.collection(COLLECTIONS.COURSES).doc(e.courseId).get();
          return {
            enrollment: e,
            course: cDoc.exists ? { id: cDoc.id, ...cDoc.data() } : null,
          };
        })
      );

      res.json({ courses: courses.filter(c => c.course !== null) });
    } catch (err) { next(err); }
  }
}

module.exports = CourseController;
