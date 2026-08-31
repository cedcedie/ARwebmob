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
