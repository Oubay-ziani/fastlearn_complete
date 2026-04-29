// ═══════════════════════════════════════════════════════════
// BACKEND CONSTANTS — single source of truth
// ═══════════════════════════════════════════════════════════
const COLLECTIONS = {
  USERS:        'users',
  COURSES:      'courses',
  LESSONS:      'lessons',
  ENROLLMENTS:  'enrollments',
  PAYMENTS:     'payments',
  EXAMS:        'exams',
  QUESTIONS:    'questions',
  EXAM_RESULTS: 'examResults',
  CERTIFICATES: 'certificates',
  SESSIONS:     'sessions',
  ANALYTICS:    'analytics',
};

const ROLES = {
  STUDENT:    'student',
  INSTRUCTOR: 'instructor',
  ADMIN:      'admin',
};

const COURSE_STATUS = {
  DRAFT:     'draft',
  PENDING:   'pending',
  PUBLISHED: 'published',
  REJECTED:  'rejected',
};

const PAYMENT_STATUS = {
  PENDING:  'pending',
  SUCCESS:  'success',
  FAILED:   'failed',
  REFUNDED: 'refunded',
};

const SESSION_STATUS = {
  SCHEDULED: 'scheduled',
  CANCELLED: 'cancelled',
  COMPLETED: 'completed',
};

// Platform revenue split
const PLATFORM_COMMISSION = 0.30; // 30%
const INSTRUCTOR_SHARE    = 0.70; // 70%

module.exports = {
  COLLECTIONS,
  ROLES,
  COURSE_STATUS,
  PAYMENT_STATUS,
  SESSION_STATUS,
  PLATFORM_COMMISSION,
  INSTRUCTOR_SHARE,
};
