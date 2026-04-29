// ═══════════════════════════════════════════════════════════
// FAST LEARN BACKEND — Node.js / Express
// Architecture: MVC (Controller → Service → Firebase)
// SINGLETON: Firebase Admin initialized once
// ═══════════════════════════════════════════════════════════
require('dotenv').config();

const express    = require('express');
const cors       = require('cors');
const helmet     = require('helmet');
const morgan     = require('morgan');
const rateLimit  = require('express-rate-limit');

// Routes
const authRoutes      = require('./routes/auth.routes');
const courseRoutes    = require('./routes/course.routes');
const paymentRoutes   = require('./routes/payment.routes');
const adminRoutes     = require('./routes/admin.routes');
const analyticsRoutes = require('./routes/analytics.routes');
const sessionRoutes   = require('./routes/session.routes');

// Firebase SINGLETON init
require('./config/firebase');

const app  = express();
const PORT = process.env.PORT || 5000;

// ── Security middleware ──
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true,
}));
app.use(morgan('dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ── Rate limiting ──
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: { error: 'Too many requests. Please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

// ── Health check ──
app.get('/health', (_, res) =>
  res.json({ status: 'OK', timestamp: new Date().toISOString(), version: '2.0.0' }));

// ── API Routes ──
app.use('/api/auth',      authRoutes);
app.use('/api/courses',   courseRoutes);
app.use('/api/payments',  paymentRoutes);
app.use('/api/admin',     adminRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/sessions',  sessionRoutes);

// ── 404 handler ──
app.use((req, res) =>
  res.status(404).json({ error: `Route not found: ${req.method} ${req.path}` }));

// ── Global error handler ──
app.use((err, req, res, next) => {
  console.error('[ERROR]', err.message, err.stack);
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
});

// ── Start server ──
app.listen(PORT, () => {
  console.log(`\n🚀 Fast Learn Backend running on port ${PORT}`);
  console.log(`📡 Health: http://localhost:${PORT}/health`);
  console.log(`🔥 Firebase: initialized (SINGLETON)`);
  console.log(`🌍 ENV: ${process.env.NODE_ENV || 'development'}\n`);
});

module.exports = app;
