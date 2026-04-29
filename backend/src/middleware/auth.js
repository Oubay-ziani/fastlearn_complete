// ═══════════════════════════════════════════════════════════
// AUTH MIDDLEWARE — Verifies Firebase ID tokens
// Used to protect all private routes
// ═══════════════════════════════════════════════════════════
const { auth, db } = require('../config/firebase');
const { COLLECTIONS } = require('../config/constants');

/**
 * Verifies Firebase ID token and attaches user to req.user
 */
const verifyToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const token     = authHeader.split(' ')[1];
    const decoded   = await auth.verifyIdToken(token);
    const userDoc   = await db.collection(COLLECTIONS.USERS).doc(decoded.uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found in database' });
    }

    const userData = userDoc.data();

    if (userData.isActive === false) {
      return res.status(403).json({ error: 'Account suspended. Contact support.' });
    }

    req.user = {
      uid:    decoded.uid,
      email:  decoded.email,
      role:   userData.role || 'student',
      name:   userData.name || '',
      ...userData,
    };

    next();
  } catch (err) {
    if (err.code === 'auth/id-token-expired') {
      return res.status(401).json({ error: 'Token expired. Please sign in again.' });
    }
    if (err.code === 'auth/argument-error') {
      return res.status(401).json({ error: 'Invalid token format.' });
    }
    console.error('[verifyToken]', err.message);
    return res.status(401).json({ error: 'Authentication failed' });
  }
};

/**
 * Restrict access to instructor role
 */
const requireInstructor = (req, res, next) => {
  if (req.user?.role !== 'instructor' && req.user?.role !== 'admin') {
    return res.status(403).json({ error: 'Instructor access required' });
  }
  next();
};

/**
 * Restrict access to admin role
 */
const requireAdmin = (req, res, next) => {
  if (req.user?.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

/**
 * Instructor OR Admin
 */
const requireInstructorOrAdmin = (req, res, next) => {
  if (!['instructor', 'admin'].includes(req.user?.role)) {
    return res.status(403).json({ error: 'Instructor or Admin access required' });
  }
  next();
};

module.exports = { verifyToken, requireInstructor, requireAdmin, requireInstructorOrAdmin };
