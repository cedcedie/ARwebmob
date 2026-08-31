# Project Handover — Your Execution Plan

This is **your** plan, not the client's — you're the one running every
command and clicking through every Firebase screen (on your own machine
solo, and later on the client's machine via AnyDesk). The client only ever
receives two things at the end: the APK, and access to the GitHub repo.
Nothing here assumes the client installs or runs anything themselves.

Testing isn't covered here — the client tests the app themselves once
they have it. The AR/mobile side is already verified working from your
last Unity export, so that's not re-explained either; this is just: get a
correctly-configured build into their hands.

Organized as a timeline in four phases, so you know exactly what to do
before the meeting, during the meeting, after the meeting, and at final
handoff — with rough time budgets and copy-pasteable commands for
everything.

---

## Where things stand right now

- All code is merged on `main`, 264/264 tests passing, `flutter analyze`
  clean (25 cosmetic issues only). Nothing left to build in the codebase
  itself.
- Your own Firebase project (`ar-science-explorer`) is separate from the
  client's — it stays yours, only used for your own testing.
- No debug APK currently exists — it needs building fresh, **after**
  Firebase is pointed at the client's project (order matters, explained in
  Phase 3).
- `android/unityLibrary` (the Unity export) also doesn't currently exist on
  `main` — same reason, needs a fresh export before an APK can be built.

---

## Prerequisites — what needs to be installed, and where

**On your own machine** — all of this is already installed and verified
working as of this session (confirmed via `flutter doctor`), listed here
only so it's reproducible if you're ever setting up a new/different
machine:

| Tool | Get it from | Why |
|---|---|---|
| **Git** | <https://git-scm.com/downloads> | clone/push the repo |
| **Flutter SDK** | <https://docs.flutter.dev/get-started/install/windows> | builds/runs the app (Dart comes bundled, no separate install) |
| **Android SDK + `cmdline-tools`** | via `flutter doctor --android-licenses`, or Android Studio's SDK Manager if you install that too | needed for `flutter build apk`; run `flutter doctor` and fix anything it flags red |
| **Unity Hub + Unity 6000.4.0f1** | <https://unity.com/download> (add version 6000.4.0f1 via Hub), with the **Android Build Support** module ticked during install | Unity ships its own bundled Android SDK/NDK/OpenJDK inside that module — nothing extra to install for it |
| **Node.js (LTS)** | <https://nodejs.org> | brings `npm`, which installs `firebase-tools` (Node.js isn't otherwise used by this project) |
| **Firebase CLI + FlutterFire CLI** | after Node.js/Flutter above: | drives `flutterfire configure` / `firebase deploy` |

```powershell
dart pub global activate flutterfire_cli
npm install -g firebase-tools
firebase login
```

Verify everything at once:
```powershell
git --version
flutter --version
node --version
npm --version
flutter doctor
```
`flutter doctor` should show no red `[!]`/`[X]` lines under Android
toolchain, Chrome, or Windows.

**On the client's machine** — **nothing needs installing.** They only ever
need: a way to open a `.apk` file on their Android phone (built-in), and
whatever browser is already there for you to drive during the AnyDesk
session (Phase 1). No Flutter, no Git, no Node — none of it touches their
machine.

---

## PHASE 0 — Solo, on your own machine, anytime before the meeting

Nothing here needs the client. Budget: ~30 min, mostly the Unity export.

### 0.1 Push the repo to GitHub (if not already there)

```powershell
cd C:\Users\cedri\OneDrive\Documents\GitHub\ARwebmob
git remote add origin <your-private-repo-url>
git push -u origin main
```

Create it as **private** on GitHub first if you haven't — Settings when
creating the repo, or `gh repo create <name> --private --source=. --push`
if you have the `gh` CLI.

### 0.2 Re-export Unity

You know this flow already — quick recap since the export folder doesn't
currently exist on `main`:

1. Open the Unity project (`C:\Users\cedri\VuforiaAR`) in Unity Editor.
2. `Flutter Embed → Export project to Flutter app` → target
   `C:\Users\cedri\OneDrive\Documents\GitHub\ARwebmob\android\unityLibrary`.
3. If Gradle complains about `mergeDebugConsumerProguardFiles` afterward,
   remove the `-ignorewarnings` line from
   `android/unityLibrary/proguard-unity.txt` (known, one-line fix, same as
   every previous export).

**Do not run `flutter build apk` yet** — wait until Phase 3, after Firebase
is pointed at the client's project. Building now would bake in *your own*
Firebase config, and the client would end up on the wrong project with no
error to tell you.

### 0.3 Have ready for the meeting

- The client's Gmail/Google account they'll use for Firebase (ask them to
  have it ready and logged in, or be ready to log in during the call).
- Know your own Google account email (the one you'll ask them to grant
  access to — see Phase 1.4).

---

## PHASE 1 — Live session via AnyDesk, on the client's computer

This is the only part that needs the client present. Budget: ~20-25 min.
Everything here is clicking in a browser (Firebase Console) — no terminal,
no installs on their machine.

### 1.1 Client logs into Firebase Console

In their browser (already logged into their own Google account, or have
them log in): go to <https://console.firebase.google.com>.

### 1.2 Create the project

1. Click **Add project**.
2. Name it (e.g. `ar-science-explorer-<schoolname>`) → Continue.
3. Google Analytics prompt → toggle off (not used by this app) → Create
   project. Takes ~30 seconds to provision.
4. Stay on the free **Spark** plan for now — nothing needed yet requires
   billing (that only matters if PPTX support gets chosen in 1.3 below).

### 1.3 Decide: PDF-only, or PPTX support too?

The teacher lesson-upload screen offers both PDF and PPTX as file choices.
PDF works today, for free, no extra setup. PPTX needs a Cloud Function
that requires the paid Blaze plan to deploy — realistically **$0 real
cost** at this scale (free tier comfortably covers a handful of students),
but a billing card has to be attached regardless of usage.

- **Recommended: PDF-only for now.** Tell the client to have teachers
  upload lesson content as PDF, not PPTX, until this is revisited. Nothing
  further to do here.
- **If they want PPTX now**: confirms they're okay attaching a card, then
  do Phase 2.5 (below, optional) at some point after this meeting — no
  need to hold up the rest of the meeting for it.

### 1.4 Grant yourself access — the step that lets you finish everything else solo

Project Settings (gear icon, top left) → **Users and permissions** → **Add
member** → enter **your own** Google account email → role **Editor** (or
Owner if they're comfortable) → **Add member**.

This is the important one — once you have this, you can do every remaining
technical step from your own machine later, without needing AnyDesk again.

### 1.5 Create accounts (Authentication tab)

Authentication (left sidebar) → **Get started** (first time) → Sign-in
method tab → enable **Email/Password** if not already on → Users tab →
**Add user** for each:

- **One teacher account** — any real email that does **not** match the
  student pattern below, e.g. `teacher@theirschool.edu` + a password you
  both note down.
- **A few student test accounts** — emails matching exactly
  `123456@arscience.school` (6 digits + `@arscience.school`) — the app
  reads the digits before `@` as the student's ID. Create 2-3 for testing.

### 1.6 Set Firestore rules

Firestore Database (left sidebar) → if not created yet, **Create
database** → production mode → pick a region close to them → Enable. Then
**Rules** tab → replace the default contents with this (copy-paste the
whole block):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null;
    }
    function isStudent() {
      return isSignedIn() &&
        request.auth.token.email.matches('^[0-9]+@arscience[.]school$');
    }
    function isTeacher() {
      return isSignedIn() && !isStudent();
    }

    match /students/{studentId} {
      allow read, write: if isTeacher() ||
        (isStudent() &&
         request.auth.token.email == studentId + '@arscience.school');
    }
    match /lessons/{lessonId} {
      allow read: if isSignedIn();
      allow create, update: if isTeacher();
    }
    match /quizzes/{quizId} {
      allow read: if isSignedIn();
      allow create, update, delete: if isTeacher();
    }
    match /unlockCodes/{code} {
      allow read: if isSignedIn();
      allow create: if isTeacher();
    }
    match /quizUnlockCodes/{docId} {
      allow read: if isSignedIn();
      allow create: if isTeacher();
    }
    match /quizAttempts/{attemptId} {
      allow read: if isSignedIn();
      allow create: if isStudent();
    }
  }
}
```

Click **Publish**. This is a fresh ruleset, not battle-tested against every
edge case the way the app's own Dart code is — after Phase 3's APK is
installed, if anything shows `permission-denied` in a browser console or
fails silently, this is the first place to check, and it's safe to loosen
a specific `match` block if something legitimate is being blocked.

**That's the whole meeting — nothing else needs the client present.**

---

## PHASE 2.5 — Optional, only if PPTX support was chosen in 1.3

Skip this whole section if you're going PDF-only. Do this solo, from your
own machine, once you have Editor access (Phase 1.4) — no AnyDesk needed.

1. **Attach billing.** Firebase Console (client's project) → Project
   Settings → Usage and billing → upgrade to **Blaze**.
2. **Grant the Cloud Run service account signing permission.** IAM & Admin
   → find `PROJECT_NUMBER-compute@developer.gserviceaccount.com` (project
   number is on the project's Settings page) → Edit → add role
   **Service Account Token Creator**. Without this, deploys succeed but
   every PPTX conversion fails at the signing step.
3. **Wire `functions/` into `firebase.json`** — add this to your local
   `firebase.json` (regenerated in Phase 3.1 by then):
   ```json
   "functions": [{ "source": "functions", "codebase": "default" }]
   ```
4. **Deploy:**
   ```powershell
   firebase deploy --only functions
   ```
5. **⚠️ Real test upload before trusting it.** `functions/Dockerfile`
   installs LibreOffice + poppler-utils, but a plain Firebase Functions
   deploy builds via Google Cloud Buildpacks, which — unverified without
   an actual deploy — may ignore that Dockerfile entirely. Upload a real
   `.pptx` through the teacher lesson form, wait ~30-60s, check that
   lesson's Firestore doc for `contentStatus: 'ready'` and real
   `contentImageUrls`. If it's stuck at `'processing'` or Cloud Functions
   logs show `ENOENT` on `soffice`/`pdftoppm`, the fix is redeploying
   `functions/` as a plain Cloud Run service instead (`gcloud run deploy
   --source functions/`, which does respect a Dockerfile) — a real
   restructure, treat it as a separate task if it comes to that.

---

## PHASE 3 — Solo, back on your own machine, after the meeting

No client needed. Budget: ~30-40 min, mostly the APK's IL2CPP compile time
running in the background.

### 3.1 Point the app at the client's project

```powershell
cd C:\Users\cedri\OneDrive\Documents\GitHub\ARwebmob
dart pub global run flutterfire_cli:flutterfire configure
```
Pick the client's project (you have access from Phase 1.4) → select
platforms **Web** and **Android**. This regenerates
`lib/firebase_options.dart` and `android/app/google-services.json`.

### 3.2 Commit and push that change

```powershell
git add lib/firebase_options.dart android/app/google-services.json
git commit -m "chore: point Firebase config at client project"
git push
```

### 3.3 Build the APK

```powershell
flutter build apk --debug
```
Expect the full ~24-minute IL2CPP compile (fresh build environment, no
cache). Output: `build/app/outputs/flutter-apk/app-debug.apk` (~806 MB).

### 3.4 (Optional) Deploy Teacher Web — full step-by-step

This makes Teacher Web a real, permanent, internet-reachable website (see
the explanation above this Phase for why that's different from
`flutter run -d chrome`). Do this after 3.1/3.2, from the repo root.

1. **Find (or create) `firebase.json`.** It should already exist at the
   repo root (`C:\Users\cedri\OneDrive\Documents\GitHub\ARwebmob\firebase.json`)
   — `flutterfire configure` (3.1) creates or updates it automatically. If
   it's missing entirely, running the deploy command in step 3 below will
   fail with a clear "no Firebase project" error — if that happens, run
   `firebase init hosting` first and let it detect the existing project.
2. **Open it in a text editor** — right-click the file in File Explorer →
   Open with → Notepad (or VS Code if you have it) — and add a
   `"hosting"` entry. It'll already have other content
   (`flutterfire configure` writes things there too) — add this as a new
   key alongside whatever's already there, not replacing the whole file:
   ```json
   "hosting": {
     "public": "build/web",
     "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
     "rewrites": [{ "source": "**", "destination": "/index.html" }]
   }
   ```
   Save and close. This only needs doing once — future deploys reuse it.
3. **Build the web app** (produces `build/web`, the static files that
   actually get uploaded):
   ```powershell
   flutter build web --release
   ```
   Takes roughly 1-3 minutes. You'll see a line ending in
   `√ Built build\web` when it's done.
4. **Deploy it:**
   ```powershell
   firebase deploy --only hosting
   ```
   Takes about 30-60 seconds. Watch the terminal output — near the end
   you'll see a line that looks like:
   ```
   ✔  Deploy complete!

   Project Console: https://console.firebase.google.com/project/<project-id>/overview
   Hosting URL: https://<project-id>.web.app
   ```
   **That `Hosting URL` line is the real, live link** — copy it exactly.
5. **Verify it actually works before handing it off** — paste that URL
   into a browser yourself right now. You should see the Teacher Web
   login screen. Sign in with the teacher account you created in 1.5 to
   confirm it fully loads and connects to the client's Firestore, not
   just that the page renders.
6. **Re-run steps 3-4** any time you want a future code change to go
   live — nothing auto-deploys on a git push, this is always a manual
   two-command step.

### 3.5 Checkpoint — upload the APK to Drive

Once 3.3 finishes, upload `app-debug.apk` to Google Drive and grab a
shareable link — that's what goes to the client in Phase 4. (If you're
picking this back up in a later session with me, this is the natural point
to report back: "APK built, here's the Drive link" — I can't build or
touch the APK file myself, so this handoff has to happen outside our
session either way.)

---

## PHASE 4 — Final handoff to the client

Async, no meeting needed.

1. **Add the client as a GitHub collaborator** (optional, but matches
   "they receive the repo too" — they don't need to do anything with it):
   GitHub repo → Settings → Collaborators → add their GitHub username/email
   with **Write** access. Or transfer the repo to their GitHub account
   entirely if that's the arrangement.
2. **Send the client:**
   - The Drive link to `app-debug.apk`, with a one-line install note:
     "download, open the file on your Android phone, allow install from
     this source when prompted."
   - **The Teacher Web URL from 3.4** — this is how they actually use
     Teacher Web day to day: **just a link, opened in any browser, nothing
     to install.** Once it's deployed it's a real website like any other;
     Flutter/Git/terminal never enter the picture for normal use. Send
     this plus the teacher login you created in 1.5.
   - Confirmation their GitHub access is set up, if you did step 1.
3. **Optional, separate thing — running the raw source code themselves,
   not required for the handoff, and not how they'd normally use the app.**
   The deployed Hosting URL (3.4) is the actual deliverable and needs
   nothing installed to use — it's just a website. This step is only for
   if they (or their own dev, later) want to run the code directly instead.

   **Should you install this for them?** No, not proactively — it's not
   part of getting the handoff done. If you're already in the AnyDesk
   session (Phase 1) and want to save them a step later, you *could* do
   this install then, since you're already remoted in; otherwise, just
   leave these instructions for them (or their own dev) to follow
   whenever/if they ever want it. Either way, this is separate from
   everything the handoff actually depends on.

   If/when someone does want it, here's the real step-by-step, assuming
   nothing is installed on that machine yet:

   1. **Git** — <https://git-scm.com/downloads> → download the Windows
      installer → run it → click through with the defaults (nothing to
      configure). Lets them download and update the project's code.
   2. **Flutter SDK** — <https://docs.flutter.dev/get-started/install/windows>
      → follow that page's Windows steps exactly (download a zip, extract
      it somewhere permanent like `C:\src\flutter`, add it to PATH — the
      page explains PATH, don't skip it). **Dart** installs automatically
      with Flutter, nothing separate needed for it.
   3. **Node.js** — <https://nodejs.org> → download the **LTS** version →
      run the installer → defaults are fine. This is only needed if they
      later want to also run `firebase` commands themselves (e.g.
      redeploy Hosting on their own) — `npm` comes bundled with Node.js
      automatically, no separate npm install:
      ```powershell
      npm install -g firebase-tools
      ```
      Skip this step entirely if they only ever want to view the app
      locally via `flutter run -d chrome`, nothing more.
   4. **Verify it all worked** — open a **new** terminal (Windows key →
      type `PowerShell` → Enter; close and reopen if one was already open
      so it picks up the changes) and run:
      ```powershell
      git --version
      flutter --version
      ```
      Each should print a version number, not "not recognized." If
      `flutter --version` fails, run `flutter doctor` — it explains
      exactly what's still wrong.
   5. **Then run the app:**
      ```powershell
      git clone <repo-url>
      cd <folder you cloned into>
      flutter pub get
      flutter run -d chrome
      ```
      This opens Teacher Web in Chrome, live-reloading, already pointed
      at *their* Firebase project (since `firebase_options.dart` was
      reconfigured and pushed in Phase 3.1/3.2) — nothing else to set up.
4. Done — they test it themselves from here.

---

## Known, disclosed limitations — worth mentioning to the client

1. **No responsive/adaptive layout on Teacher Web** — deliberate
   desktop/laptop-only design, not built for tablets or narrow viewports.
2. **PPTX upload is off by default** (Phase 1.3) — PDF works fully; PPTX
   needs the optional Phase 2.5 if they want it later.
3. **No CI/CD** — Hosting/Functions deploys are manual commands you run
   yourself; nothing auto-updates on a git push.
