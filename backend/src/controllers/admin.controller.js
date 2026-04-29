// ═══════════════════════════════════════════════════════════
// ADMIN CONTROLLER — MVC Pattern
// Implements ALL Admin methods from class diagram:
// manageUsers, approveOrRejectCourse, managePlatformPayments,
// viewPlatformAnalytics, suspendAccount, deleteAccount
// Analytics.generateReport()
// ═══════════════════════════════════════════════════════════
const { db, auth } = require('../config/firebase');
const { COLLECTIONS, ROLES, COURSE_STATUS, PAYMENT_STATUS } = require('../config/constants');

class AdminController {

  // ── MANAGE USERS (Admin.manageUsers) ──
  // GET /api/admin/users
  static async getAllUsers(req, res, next) {
    try {
      const { role, limit = 100 } = req.query;
      let query = db.collection(COLLECTIONS.USERS).limit(Number(limit));
      if (role) query = query.where('role', '==', role);

      const snap  = await query.get();
      const users = snap.docs.map(d => ({ id: d.id, ...d.data(), password: undefined }));
      res.json({ users, count: users.length });
    } catch (err) { next(err); }
  }

  // GET /api/admin/users/:id
  static async getUserById(req, res, next) {
    try {
      const doc = await db.collection(COLLECTIONS.USERS).doc(req.params.id).get();
      if (!doc.exists) return res.status(404).json({ error: 'User not found' });
      res.json({ user: { id: doc.id, ...doc.data() } });
    } catch (err) { next(err); }
  }

  // ── ASSIGN ROLE ──
  // PUT /api/admin/users/:id/role
  static async assignRole(req, res, next) {
    try {
      const { role } = req.body;
      if (!Object.values(ROLES).includes(role)) {
        return res.status(400).json({ error: `Invalid role. Must be: ${Object.values(ROLES).join(', ')}` });
      }
      await db.collection(COLLECTIONS.USERS).doc(req.params.id).update({ role });
      // Also set custom claim in Firebase Auth
      await auth.setCustomUserClaims(req.params.id, { role });
      res.json({ success: true, message: `Role updated to ${role}` });
    } catch (err) { next(err); }
  }

  // ── SUSPEND ACCOUNT (Admin.suspendAccount) ──
  // PUT /api/admin/users/:id/suspend
  static async suspendAccount(req, res, next) {
    try {
      const { id } = req.params;
      if (id === req.user.uid) return res.status(400).json({ error: 'Cannot suspend yourself' });

      await db.collection(COLLECTIONS.USERS).doc(id).update({
        isActive: false,
        suspendedAt: new Date(),
        suspendedBy: req.user.uid,
      });
      // Disable in Firebase Auth
      await auth.updateUser(id, { disabled: true });
      res.json({ success: true, message: 'Account suspended' });
    } catch (err) { next(err); }
  }

  // ── RESTORE ACCOUNT ──
  // PUT /api/admin/users/:id/restore
  static async restoreAccount(req, res, next) {
    try {
      const { id } = req.params;
      await db.collection(COLLECTIONS.USERS).doc(id).update({ isActive: true, suspendedAt: null });
      await auth.updateUser(id, { disabled: false });
      res.json({ success: true, message: 'Account restored' });
    } catch (err) { next(err); }
  }

  // ── DELETE ACCOUNT (Admin.deleteAccount) ──
  // DELETE /api/admin/users/:id
  static async deleteAccount(req, res, next) {
    try {
      const { id } = req.params;
      if (id === req.user.uid) return res.status(400).json({ error: 'Cannot delete yourself' });

      // Delete from Firestore
      await db.collection(COLLECTIONS.USERS).doc(id).delete();
      // Delete from Firebase Auth
      try { await auth.deleteUser(id); } catch (_) { /* user may not exist in auth */ }

      res.json({ success: true, message: 'Account deleted' });
    } catch (err) { next(err); }
  }

  // ── APPROVE / REJECT COURSE (Admin.approveOrRejectCourse) ──
  // PUT /api/admin/courses/:id/approve
  static async approveCourse(req, res, next) {
    try {
      const { id } = req.params;
      const doc = await db.collection(COLLECTIONS.COURSES).doc(id).get();
      if (!doc.exists) return res.status(404).json({ error: 'Course not found' });
      if (doc.data().status !== COURSE_STATUS.PENDING) {
        return res.status(400).json({ error: 'Course is not pending review' });
      }

      await db.collection(COLLECTIONS.COURSES).doc(id).update({
        status: COURSE_STATUS.PUBLISHED,
        approvedAt: new Date(),
        approvedBy: req.user.uid,
      });

      res.json({ success: true, message: 'Course approved and published' });
    } catch (err) { next(err); }
  }

  // PUT /api/admin/courses/:id/reject
  static async rejectCourse(req, res, next) {
    try {
      const { id } = req.params;
      const { reason } = req.body;

      await db.collection(COLLECTIONS.COURSES).doc(id).update({
        status: COURSE_STATUS.REJECTED,
        rejectedAt: new Date(),
        rejectedBy: req.user.uid,
        rejectionReason: reason || 'Does not meet platform standards',
      });

      res.json({ success: true, message: 'Course rejected' });
    } catch (err) { next(err); }
  }

  // GET /api/admin/courses/pending
  static async getPendingCourses(req, res, next) {
    try {
      const snap = await db.collection(COLLECTIONS.COURSES)
        .where('status', '==', COURSE_STATUS.PENDING)
        .orderBy('createdAt', 'desc')
        .get();
      const courses = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      res.json({ courses, count: courses.length });
    } catch (err) { next(err); }
  }

  // ── DELETE COURSE (moderation) ──
  // DELETE /api/admin/courses/:id
  static async deleteCourse(req, res, next) {
    try {
      await db.collection(COLLECTIONS.COURSES).doc(req.params.id).delete();
      res.json({ success: true, message: 'Course deleted' });
    } catch (err) { next(err); }
  }

  // ── VIEW ANALYTICS (Admin.viewPlatformAnalytics + Analytics.generateReport) ──
  // GET /api/admin/analytics
  static async getPlatformAnalytics(req, res, next) {
    try {
      const [usersSnap, coursesSnap, enrollSnap, paymentsSnap] = await Promise.all([
        db.collection(COLLECTIONS.USERS).count().get(),
        db.collection(COLLECTIONS.COURSES).count().get(),
        db.collection(COLLECTIONS.ENROLLMENTS).count().get(),
        db.collection(COLLECTIONS.PAYMENTS)
          .where('status', '==', PAYMENT_STATUS.SUCCESS).get(),
      ]);

      let totalRevenue   = 0;
      const revenueByMonth    = {};
      const enrollmentsByMonth = {};

      for (const doc of paymentsSnap.docs) {
        const d   = doc.data();
        totalRevenue += d.amount || 0;
        const ts  = d.paidAt?.toDate?.() || new Date(d.paidAt);
        const key = `${ts.getFullYear()}-${String(ts.getMonth() + 1).padStart(2, '0')}`;
        revenueByMonth[key] = (revenueByMonth[key] || 0) + (d.amount || 0);
      }

      const allEnrollSnap = await db.collection(COLLECTIONS.ENROLLMENTS).get();
      for (const doc of allEnrollSnap.docs) {
        const d  = doc.data();
        const ts = d.enrolledAt?.toDate?.() || new Date(d.enrolledAt);
        const key = `${ts.getFullYear()}-${String(ts.getMonth() + 1).padStart(2, '0')}`;
        enrollmentsByMonth[key] = (enrollmentsByMonth[key] || 0) + 1;
      }

      // Analytics.generateReport() implementation
      const report = {
        totalUsers:       usersSnap.data().count,
        totalCourses:     coursesSnap.data().count,
        totalRevenue,
        totalEnrollments: enrollSnap.data().count,
        revenueByMonth,
        enrollmentsByMonth,
        generatedAt: new Date().toISOString(),
      };

      res.json({ analytics: report });
    } catch (err) { next(err); }
  }

  // ── MANAGE PLATFORM PAYMENTS (Admin.managePlatformPayments) ──
  // GET /api/admin/payments
  static async getPlatformPayments(req, res, next) {
    try {
      const { status, limit = 100 } = req.query;
      let query = db.collection(COLLECTIONS.PAYMENTS)
        .orderBy('paidAt', 'desc').limit(Number(limit));
      if (status) query = query.where('status', '==', status);

      const snap     = await query.get();
      const payments = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      const totalRevenue = payments
        .filter(p => p.status === PAYMENT_STATUS.SUCCESS)
        .reduce((s, p) => s + p.amount, 0);

      res.json({ payments, totalRevenue, count: payments.length });
    } catch (err) { next(err); }
  }
}

module.exports = AdminController;
