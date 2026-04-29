// ═══════════════════════════════════════════════════════════
// PAYMENT CONTROLLER — MVC Pattern
// Implements: Payment.process(), Payment.refund()
// Admin: managePlatformPayments
// Student: buyCourse
// ═══════════════════════════════════════════════════════════
const stripe       = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { v4: uuid } = require('uuid');
const { db }       = require('../config/firebase');
const { COLLECTIONS, PAYMENT_STATUS, COURSE_STATUS, INSTRUCTOR_SHARE } = require('../config/constants');

class PaymentController {

  /**
   * Create Stripe Payment Intent (Payment.process — step 1)
   * POST /api/payments/create-intent
   */
  static async createPaymentIntent(req, res, next) {
    try {
      const { courseId, sessionId } = req.body;
      const userId = req.user.uid;

      let amount = 0;
      let description = '';

      if (courseId) {
        // Course purchase
        const courseDoc = await db.collection(COLLECTIONS.COURSES).doc(courseId).get();
        if (!courseDoc.exists) return res.status(404).json({ error: 'Course not found' });

        const course = courseDoc.data();
        if (course.status !== COURSE_STATUS.PUBLISHED) {
          return res.status(400).json({ error: 'Course is not available for purchase' });
        }
        if (course.price <= 0) {
          return res.status(400).json({ error: 'This course is free. No payment needed.' });
        }

        // Check already enrolled
        const enrollDoc = await db.collection(COLLECTIONS.ENROLLMENTS)
          .doc(`${userId}_${courseId}`).get();
        if (enrollDoc.exists) {
          return res.status(400).json({ error: 'Already enrolled in this course' });
        }

        amount      = Math.round(course.price * 100); // Stripe uses cents
        description = `Course: ${course.title}`;

      } else if (sessionId) {
        // Session booking
        const sessionDoc = await db.collection(COLLECTIONS.SESSIONS).doc(sessionId).get();
        if (!sessionDoc.exists) return res.status(404).json({ error: 'Session not found' });

        const session = sessionDoc.data();
        if (session.studentId) return res.status(400).json({ error: 'Session already booked' });

        amount      = Math.round(session.price * 100);
        description = `1-on-1 Session`;
      } else {
        return res.status(400).json({ error: 'courseId or sessionId required' });
      }

      // Create Stripe Payment Intent
      const intent = await stripe.paymentIntents.create({
        amount,
        currency: 'usd',
        description,
        metadata: { userId, courseId: courseId || '', sessionId: sessionId || '' },
        automatic_payment_methods: { enabled: true },
      });

      res.json({
        clientSecret: intent.client_secret,
        paymentIntentId: intent.id,
        amount: amount / 100,
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * Confirm payment and complete enrollment (Payment.process — step 2)
   * POST /api/payments/confirm
   */
  static async confirmPayment(req, res, next) {
    try {
      const { paymentIntentId, courseId, sessionId } = req.body;
      const userId = req.user.uid;

      // Verify with Stripe
      const intent = await stripe.paymentIntents.retrieve(paymentIntentId);
      if (intent.status !== 'succeeded') {
        return res.status(400).json({ error: `Payment not completed: ${intent.status}` });
      }

      const batch   = db.batch();
      const payId   = uuid();
      const amount  = intent.amount / 100;
      const payRef  = db.collection(COLLECTIONS.PAYMENTS).doc(payId);

      // Save payment record
      batch.set(payRef, {
        paymentId: payId,
        userId,
        courseId: courseId || null,
        sessionId: sessionId || null,
        amount,
        status: PAYMENT_STATUS.SUCCESS,
        stripePaymentIntentId: paymentIntentId,
        paidAt: new Date(),
        createdAt: new Date(),
      });

      if (courseId) {
        // Enroll user
        const enrollRef = db.collection(COLLECTIONS.ENROLLMENTS).doc(`${userId}_${courseId}`);
        batch.set(enrollRef, {
          enrollmentId: `${userId}_${courseId}`,
          userId,
          courseId,
          enrolledAt: new Date(),
          completed: false,
          progress: 0,
          completedLessons: [],
        });

        // Increment enrollment count
        const courseRef = db.collection(COLLECTIONS.COURSES).doc(courseId);
        batch.update(courseRef, { enrollmentCount: db.FieldValue.increment(1) });

        // Update instructor earnings (70% split)
        const courseDoc = await db.collection(COLLECTIONS.COURSES).doc(courseId).get();
        const teacherId = courseDoc.data().teacherId;
        if (teacherId) {
          const teacherRef = db.collection(COLLECTIONS.USERS).doc(teacherId);
          batch.update(teacherRef, {
            totalEarnings: db.FieldValue.increment(amount * INSTRUCTOR_SHARE),
          });
        }
      } else if (sessionId) {
        // Book session
        const sessionRef = db.collection(COLLECTIONS.SESSIONS).doc(sessionId);
        batch.update(sessionRef, {
          studentId: userId,
          paidAt: new Date(),
        });
      }

      await batch.commit();

      res.json({
        success: true,
        paymentId: payId,
        message: courseId ? 'Enrolled successfully!' : 'Session booked!',
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * Refund a payment (Payment.refund, Admin.managePlatformPayments)
   * POST /api/payments/refund
   */
  static async refundPayment(req, res, next) {
    try {
      const { paymentId } = req.body;

      const payDoc = await db.collection(COLLECTIONS.PAYMENTS).doc(paymentId).get();
      if (!payDoc.exists) return res.status(404).json({ error: 'Payment not found' });

      const payment = payDoc.data();
      if (payment.status === PAYMENT_STATUS.REFUNDED) {
        return res.status(400).json({ error: 'Payment already refunded' });
      }

      // Process Stripe refund
      await stripe.refunds.create({
        payment_intent: payment.stripePaymentIntentId,
      });

      // Update payment status
      await db.collection(COLLECTIONS.PAYMENTS).doc(paymentId).update({
        status: PAYMENT_STATUS.REFUNDED,
        refundedAt: new Date(),
      });

      res.json({ success: true, message: 'Refund processed successfully' });
    } catch (err) {
      next(err);
    }
  }

  /**
   * Get user payment history
   * GET /api/payments/my
   */
  static async getMyPayments(req, res, next) {
    try {
      const snap = await db.collection(COLLECTIONS.PAYMENTS)
        .where('userId', '==', req.user.uid)
        .orderBy('paidAt', 'desc')
        .limit(50)
        .get();

      const payments = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      res.json({ payments });
    } catch (err) {
      next(err);
    }
  }

  /**
   * Admin: Get all payments (Admin.managePlatformPayments)
   * GET /api/payments/all
   */
  static async getAllPayments(req, res, next) {
    try {
      const { limit = 100, status } = req.query;
      let query = db.collection(COLLECTIONS.PAYMENTS)
        .orderBy('paidAt', 'desc')
        .limit(Number(limit));

      if (status) query = query.where('status', '==', status);

      const snap = await query.get();
      const payments = snap.docs.map(d => ({ id: d.id, ...d.data() }));

      const totalRevenue = payments
        .filter(p => p.status === PAYMENT_STATUS.SUCCESS)
        .reduce((sum, p) => sum + p.amount, 0);

      res.json({ payments, totalRevenue, count: payments.length });
    } catch (err) {
      next(err);
    }
  }

  /**
   * Stripe webhook handler
   * POST /api/payments/webhook
   */
  static async handleWebhook(req, res, next) {
    const sig = req.headers['stripe-signature'];
    try {
      const event = stripe.webhooks.constructEvent(
        req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);

      switch (event.type) {
        case 'payment_intent.succeeded':
          console.log('💰 Payment succeeded:', event.data.object.id);
          break;
        case 'payment_intent.payment_failed':
          console.log('❌ Payment failed:', event.data.object.id);
          const intent = event.data.object;
          // Save failed payment record
          await db.collection(COLLECTIONS.PAYMENTS).add({
            userId: intent.metadata.userId,
            courseId: intent.metadata.courseId || null,
            amount: intent.amount / 100,
            status: PAYMENT_STATUS.FAILED,
            stripePaymentIntentId: intent.id,
            paidAt: new Date(),
          });
          break;
        default:
          console.log(`Unhandled webhook event: ${event.type}`);
      }

      res.json({ received: true });
    } catch (err) {
      console.error('[Webhook]', err.message);
      res.status(400).json({ error: `Webhook error: ${err.message}` });
    }
  }
}

module.exports = PaymentController;
