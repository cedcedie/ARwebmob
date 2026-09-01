// scripts/create-test-accounts.js
//
// One-time setup script: creates the teacher + student test accounts in
// Firebase Authentication for whichever project the service account key
// points at. Safe to re-run -- skips any account that already exists
// instead of erroring.
//
// Setup (once):
//   1. Firebase Console (target project) -> Project Settings -> Service
//      accounts tab -> "Generate new private key" -> saves a .json file.
//   2. Put that file somewhere OUTSIDE this repo (it's a real credential,
//      never commit it) -- e.g. C:\Users\cedri\service-account-key.json.
//   3. cd scripts && npm install
//
// Run:
//   node create-test-accounts.js "C:\path\to\service-account-key.json"
//
// Edit the ACCOUNTS list below before running if you want different
// emails/passwords than the defaults.

const admin = require('firebase-admin');

const keyPath = process.argv[2];
if (!keyPath) {
  console.error('Usage: node create-test-accounts.js <path-to-service-account-key.json>');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(require('path').resolve(keyPath))),
});

// Edit this list as needed. Student emails MUST match the app's pattern:
// exactly 6 digits + @arscience.school -- the app derives the studentId
// from the digits before @. Teacher emails just need to NOT match that
// pattern.
const ACCOUNTS = [
  { email: 'teacher@example-school.edu', password: 'password', role: 'teacher' },
  { email: '100001@arscience.school', password: 'password', role: 'student' },
  { email: '100002@arscience.school', password: 'password', role: 'student' },
  { email: '100003@arscience.school', password: 'password', role: 'student' },
];

async function main() {
  for (const { email, password, role } of ACCOUNTS) {
    try {
      const existing = await admin.auth().getUserByEmail(email).catch(() => null);
      if (existing) {
        console.log(`SKIP  ${role.padEnd(8)} ${email} (already exists)`);
        continue;
      }
      await admin.auth().createUser({ email, password });
      console.log(`OK    ${role.padEnd(8)} ${email}`);
    } catch (error) {
      console.error(`FAIL  ${role.padEnd(8)} ${email} -- ${error.message}`);
    }
  }
  console.log('\nDone. Passwords are whatever is set in ACCOUNTS above -- share them with whoever needs to sign in.');
}

main().then(() => process.exit(0));
