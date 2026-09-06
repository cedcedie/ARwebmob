// functions/src/index.js
const { onObjectFinalized } = require('firebase-functions/v2/storage');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { execFile } = require('node:child_process');
const { promisify } = require('node:util');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');

initializeApp();
const execFileAsync = promisify(execFile);

// Matches uploads under lessons/{lessonId}/{fileName}.pptx — Task 5/6's
// LessonContentUploadService writes exactly this path shape. Generated slide
// PNGs land under lessons/{lessonId}/slides/{n}.png, which has an extra path
// segment and a different extension, so this pattern deliberately does not
// match them — otherwise this function would re-trigger itself on its own
// output.
const PPTX_PATH_PATTERN = /^lessons\/([^/]+)\/([^/]+\.pptx)$/i;

exports.convertLessonPptx = onObjectFinalized(
  { region: 'us-central1', memory: '2GiB', timeoutSeconds: 300, cpu: 2 },
  async (event) => {
    const filePath = event.data.name;
    const match = filePath.match(PPTX_PATH_PATTERN);
    if (!match) return; // not a lesson PPTX upload — ignore (slide PNGs, PDF uploads, other files)

    const [, lessonId] = match;
    const bucket = getStorage().bucket(event.data.bucket);
    const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'pptx-'));
    const localPptxPath = path.join(tmpDir, 'input.pptx');

    try {
      await bucket.file(filePath).download({ destination: localPptxPath });

      // Headless LibreOffice: convert PPTX -> PDF -> per-page PNGs. Going
      // through an intermediate PDF is LibreOffice's most reliable path for
      // slide-accurate image export (a direct pptx->png batch conversion is
      // less consistent across LibreOffice versions).
      await execFileAsync('soffice', [
        '--headless', '--convert-to', 'pdf', '--outdir', tmpDir, localPptxPath,
      ]);
      const localPdfPath = path.join(tmpDir, 'input.pdf');

      // pdftoppm ships in poppler-utils (see functions/Dockerfile), not in
      // libreoffice-impress. It zero-pads the page number in the output
      // filename to the width needed for the total page count (e.g.
      // slide-01.png .. slide-12.png), so the lexical .sort() below always
      // matches slide order regardless of how many slides the deck has.
      await execFileAsync('pdftoppm', ['-png', '-r', '150', localPdfPath, path.join(tmpDir, 'slide')]);

      const files = (await fs.readdir(tmpDir))
        .filter((f) => f.startsWith('slide') && f.endsWith('.png'))
        .sort();

      const uploadedUrls = [];
      for (let i = 0; i < files.length; i++) {
        const destPath = `lessons/${lessonId}/slides/${i}.png`;
        await bucket.upload(path.join(tmpDir, files[i]), {
          destination: destPath,
          metadata: { contentType: 'image/png' },
        });
        const [url] = await bucket.file(destPath).getSignedUrl({
          action: 'read',
          expires: '01-01-2100', // effectively permanent for this app's purposes
        });
        uploadedUrls.push(url);
      }

      await getFirestore().collection('lessons').doc(lessonId).update({
        contentImageUrls: uploadedUrls,
        contentStatus: 'ready',
      });
    } catch (error) {
      console.error(`[convertLessonPptx] Failed for ${filePath}:`, error);
      await getFirestore().collection('lessons').doc(lessonId).update({
        contentStatus: 'ready', // fail open — don't leave the lesson stuck "processing" forever.
                                 // TeacherLesson.contentStatus only models 'processing' | 'ready' | null
                                 // (Task 4), so there is no distinct "error" value to set here;
                                 // contentImageUrls stays as whatever it was before (the original
                                 // single pptx URL), which isn't viewable as an image, but the
                                 // lesson isn't silently stuck in "processing" forever.
      }).catch(() => {}); // best-effort — don't let a Firestore write failure mask the original error
      throw error; // still surfaces in Cloud Functions logs/monitoring
    } finally {
      await fs.rm(tmpDir, { recursive: true, force: true });
    }
  },
);

// ---------------------------------------------------------------------------
// Teacher-initiated student password reset.
//
// This has to be a server function. Firebase Auth's client SDK can only
// change the password of the *currently signed-in* user, and student logins
// use a synthetic `<id>@arscience.school` address with no real mailbox, so
// the usual "send a reset email" path can never reach the student. Without
// this, a student who forgets their password is simply locked out forever,
// with no recovery route anywhere in the product.
//
// Only the Admin SDK can set another account's password, so authorization is
// enforced here rather than trusted from the caller: the caller must be a
// signed-in, allowlisted teacher (the same rule firestore.rules applies), and
// the target must be a student account. A teacher can never use this to take
// over another teacher's account.
// ---------------------------------------------------------------------------
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getAuth } = require('firebase-admin/auth');

const BOOTSTRAP_TEACHER_EMAIL = 'nadinevictoria17@gmail.com';
const STUDENT_EMAIL_PATTERN = /^[0-9]+@arscience\.school$/;
const MIN_PASSWORD_LENGTH = 6;

async function assertCallerIsTeacher(auth) {
  const email = auth && auth.token && auth.token.email;
  if (!email) {
    throw new HttpsError('unauthenticated', 'Sign in first.');
  }
  if (STUDENT_EMAIL_PATTERN.test(email)) {
    throw new HttpsError('permission-denied', 'Student accounts cannot do this.');
  }
  if (email.toLowerCase() === BOOTSTRAP_TEACHER_EMAIL) return email;

  const doc = await getFirestore()
    .collection('teachers')
    .doc(email.toLowerCase())
    .get();
  if (!doc.exists) {
    throw new HttpsError(
      'permission-denied',
      'This account does not have teacher access.',
    );
  }
  return email;
}

exports.setStudentPassword = onCall({ region: 'us-central1' }, async (request) => {
  const callerEmail = await assertCallerIsTeacher(request.auth);

  const studentId = String((request.data && request.data.studentId) || '').replace(/\D/g, '');
  const newPassword = String((request.data && request.data.newPassword) || '');

  if (!studentId) {
    throw new HttpsError('invalid-argument', 'A student ID is required.');
  }
  if (newPassword.length < MIN_PASSWORD_LENGTH) {
    throw new HttpsError(
      'invalid-argument',
      `Password must be at least ${MIN_PASSWORD_LENGTH} characters.`,
    );
  }

  const email = `${studentId}@arscience.school`;
  // Guard against the id somehow resolving to a non-student address.
  if (!STUDENT_EMAIL_PATTERN.test(email)) {
    throw new HttpsError('invalid-argument', 'That is not a student account.');
  }

  let user;
  try {
    user = await getAuth().getUserByEmail(email);
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      // The roster row can exist without a login — every student added
      // before Add Student began provisioning accounts is in exactly this
      // state, so say so plainly instead of failing with a raw code.
      throw new HttpsError(
        'not-found',
        'This student has no login yet. Create one with "Create login" instead.',
      );
    }
    throw error;
  }

  await getAuth().updateUser(user.uid, { password: newPassword });
  console.log(`[setStudentPassword] ${callerEmail} reset the password for ${email}`);
  return { ok: true };
});

// Creates a login for a student who has a roster row but no Auth account —
// the state every student added before password provisioning existed is in.
exports.createStudentLogin = onCall({ region: 'us-central1' }, async (request) => {
  const callerEmail = await assertCallerIsTeacher(request.auth);

  const studentId = String((request.data && request.data.studentId) || '').replace(/\D/g, '');
  const password = String((request.data && request.data.password) || '');

  if (!studentId) {
    throw new HttpsError('invalid-argument', 'A student ID is required.');
  }
  if (password.length < MIN_PASSWORD_LENGTH) {
    throw new HttpsError(
      'invalid-argument',
      `Password must be at least ${MIN_PASSWORD_LENGTH} characters.`,
    );
  }

  const email = `${studentId}@arscience.school`;
  const roster = await getFirestore().collection('students').doc(studentId).get();
  if (!roster.exists) {
    throw new HttpsError(
      'not-found',
      'There is no student with that ID on the roster.',
    );
  }

  try {
    await getAuth().createUser({ email, password });
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      throw new HttpsError(
        'already-exists',
        'This student already has a login. Use "Reset password" instead.',
      );
    }
    throw error;
  }
  console.log(`[createStudentLogin] ${callerEmail} created a login for ${email}`);
  return { ok: true };
});
