// ═══════════════════════════════════════════════════════════
// FIREBASE ADMIN — SINGLETON pattern
// Auto-detects credentials from multiple sources
// ═══════════════════════════════════════════════════════════
require('dotenv').config();
const admin = require('firebase-admin');
const path  = require('path');
const fs    = require('fs');

if (!admin.apps.length) {
  let credential;
  let source = '';

  // ── Source 1: JSON string in env var ──
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    try {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      credential = admin.credential.cert(serviceAccount);
      source = 'FIREBASE_SERVICE_ACCOUNT_JSON env var';
    } catch (e) {
      throw new Error(
        'FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON.\n' +
        'Make sure the entire JSON is on ONE line with no line breaks.\n' +
        `Parse error: ${e.message}`
      );
    }
  }

  // ── Source 2: GOOGLE_APPLICATION_CREDENTIALS env var (file path) ──
  else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    const credPath = path.resolve(process.env.GOOGLE_APPLICATION_CREDENTIALS);
    if (!fs.existsSync(credPath)) {
      throw new Error(
        `Service account file not found at: ${credPath}\n` +
        'Download from: Firebase Console → Project Settings → Service Accounts → Generate new private key'
      );
    }
    credential = admin.credential.applicationDefault();
    source = `file: ${credPath}`;
  }

  // ── Source 3: Auto-detect serviceAccountKey.json next to package.json ──
  else {
    const candidates = [
      path.join(__dirname, '../../serviceAccountKey.json'),
      path.join(__dirname, '../../../serviceAccountKey.json'),
      path.join(process.cwd(), 'serviceAccountKey.json'),
    ];

    const found = candidates.find(p => fs.existsSync(p));

    if (found) {
      const serviceAccount = JSON.parse(fs.readFileSync(found, 'utf8'));
      credential = admin.credential.cert(serviceAccount);
      source = `auto-detected: ${found}`;
    } else {
      throw new Error(
        '\n' +
        '╔══════════════════════════════════════════════════════════╗\n' +
        '║         FIREBASE CREDENTIALS NOT FOUND                  ║\n' +
        '╠══════════════════════════════════════════════════════════╣\n' +
        '║                                                          ║\n' +
        '║  QUICKEST FIX:                                           ║\n' +
        '║    1. Go to https://console.firebase.google.com          ║\n' +
        '║    2. Select your project                                ║\n' +
        '║    3. Click ⚙ (gear) → Project Settings                 ║\n' +
        '║    4. Click "Service accounts" tab                       ║\n' +
        '║    5. Click "Generate new private key" → Download JSON   ║\n' +
        '║    6. Rename it: serviceAccountKey.json                  ║\n' +
        '║    7. Place it in: backend/serviceAccountKey.json        ║\n' +
        '║    8. Run: npm run dev                                   ║\n' +
        '║                                                          ║\n' +
        '║  OR create backend/.env with:                            ║\n' +
        '║    GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json║\n' +
        '╚══════════════════════════════════════════════════════════╝\n'
      );
    }
  }

  admin.initializeApp({
    credential,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  });

  console.log(`✅ Firebase Admin initialized — ${source}`);
}

const db      = admin.firestore();
const auth    = admin.auth();
const storage = admin.storage();

db.settings({ ignoreUndefinedProperties: true });

module.exports = { admin, db, auth, storage };
