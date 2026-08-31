# Project Handover — AR Science Explorer

This is the **complete, standalone handover document** — written assuming
the client (or their own technical person) is on a brand-new machine with
nothing installed, and shouldn't need anything else to get this project
running end to end. Everything they need — installs, commands, rules
tables, decisions — is inlined directly in this file. Follow it in order;
each step says who does it.

`MANUAL_STEPS.md` at the repo root also exists, but it's the developer's
own internal working notes/status checklist — not something the client
needs to read. Some content is intentionally duplicated between the two
for that reason (this doc stays usable on its own even if `MANUAL_STEPS.md`
is out of date or ignored).

---

## 0. Where things stand right now

- **Code**: all 5 phases (foundation, student core, AR Lab, Teacher Web,
  analytics/PPT pipeline) are merged onto `main` — this is the only branch,
  no worktrees remain.
- **Tests**: 264/264 passing (`flutter test` from the repo root), including
  a dedicated `test/integration/` suite that exercises real teacher→student
  flows (access codes, quiz retake rules, item analysis, lesson content
  delivery) against a shared fake Firestore backend.
- **Static analysis**: `flutter analyze` holds at 25 issues, all
  warnings/info-level (no errors) — style lints and one pre-existing
  deprecated-API warning outside this project's touched scope. Not a
  correctness concern.
- **Teacher Web UI/UX**: went through 7 rounds of adversarial critique
  (design + correctness reviewed independently each round), final combined
  score 33/40 — solidly in the "Good" band. Every P0/P1 finding across all
  7 rounds was closed; remaining open items are disclosed, minor polish.
- **Known, disclosed limitations** (not oversights — see §10 below):
  physical AR marker-scanning can't be automated in this dev environment
  (no device available), and the PPTX-upload Cloud Function is written but
  intentionally undeployed pending a client decision.

---

## 0.5 [CLIENT — only if they have their own technical person] Setting up their own machine, from zero

Everything in this document that has terminal commands can be run by the
client's own developer, on their own machine, without you — that's the
whole point of the role labels in this doc. This section assumes **nothing
is installed yet**, including not knowing what a "terminal" is.

**What's a terminal, and how do I open one (Windows)?** A terminal is a
text window where you type commands instead of clicking things — every
gray code block below (like the ones with `flutter` or `npm` in them) gets
typed into one, one line at a time, then Enter. To open one: press the
Windows key, type `PowerShell`, press Enter. A blue-ish window opens with a
blinking cursor — that's it, that's the terminal used for every command in
this document.

**What to install, in this order, with direct links:**

1. **Git** — <https://git-scm.com/downloads> — download the Windows
   installer, run it, click through with the defaults (no settings need
   changing). This is what lets you download (`clone`) and update the
   project's code.
2. **Flutter SDK** — <https://docs.flutter.dev/get-started/install/windows>
   — follow that page's Windows instructions exactly (it walks through
   downloading a zip, extracting it somewhere permanent like `C:\src\flutter`,
   and adding it to your PATH — the page explains what PATH means and how,
   don't skip that part). This is the toolkit that builds and runs the
   actual app. **Dart** (a second, related tool this project also uses)
   installs automatically as part of Flutter — nothing extra to do for it.
3. **Node.js** — <https://nodejs.org> — download the **LTS** version,
   run the installer, defaults are fine. This is what **`npm`** comes
   bundled with — you don't install npm separately; installing Node.js
   gives you npm automatically. Node.js/npm here is only used to install
   one tool (`firebase-tools`, step 5 below) — nothing about this project
   itself runs on Node.js day-to-day.
4. **Verify the first three installed correctly** — open a **new**
   PowerShell window (close and reopen if one was already open, so it
   picks up the changes) and type each of these one at a time, pressing
   Enter after each:
   ```powershell
   git --version
   flutter --version
   node --version
   npm --version
   ```
   Each should print a version number, not an error like "not recognized."
   If `flutter --version` fails, run `flutter doctor` — it explains exactly
   what's still missing and how to fix it.
5. **Install two more command-line tools this project needs** (both via
   `npm`/`dart`, which you now have from steps 2-3):
   ```powershell
   dart pub global activate flutterfire_cli
   npm install -g firebase-tools
   ```
6. **Get the project's code** — see §1 below for the exact `git clone`
   command once repo access has been granted.
7. **From inside the cloned project folder**, install the project's own
   dependencies and confirm it's healthy before touching Firebase at all:
   ```powershell
   cd <folder you cloned into>
   flutter pub get
   flutter test
   ```
   This should end with `264/264` (or higher) tests passing — if it
   doesn't, stop and investigate before proceeding; something's wrong with
   the checkout itself, not anything Firebase-related yet.
8. **Android Studio/SDK** and **Unity 6000.4.0f1** are only needed if
   doing the Android/AR side (§8) — not needed for Teacher Web (§7) or
   Firebase setup (§3-§5), and are a much bigger install; skip them
   entirely if that's not the goal right now.

Once steps 1-7 are done, the client's developer can run §3 (their own
Firebase project), §4 (`flutterfire configure`), §5 (rules/accounts), and
§7 (Hosting deploy) entirely themselves, using the exact commands given in
each section below — copy each gray block into the same PowerShell window,
one at a time.

---

## 1. Repo access

The repo stays **private** on GitHub — it carries internal build history
(`docs/superpowers/`) and architecture notes not meant for public
consumption.

1. **[DEV]** If this repo isn't pushed to GitHub yet, create a private repo
   there and push `main`:
   ```powershell
   cd C:\Users\cedri\OneDrive\Documents\GitHub\ARwebmob
   git remote add origin <your-private-repo-url>
   git push -u origin main
   ```
2. **[DEV]** GitHub repo → Settings → Collaborators → add the client's
   GitHub account with at least **Write** access (or transfer the repo to
   their GitHub organization/account entirely, if that's the arrangement).
   Only the repo owner can do this step.
3. **[CLIENT]** Once added, clone it onto their own machine:
   ```powershell
   git clone <repo-url>
   ```

---

## 2. [DEV] Your own Firebase project stays yours

You already have a Firebase project (`ar-science-explorer`) under your own
account that this codebase has been developed and tested against. **That
project is not part of the handover** — it stays yours, for your own future
testing/reference if you want it. The client gets a completely separate,
brand-new project (§3). Nothing to do here except be aware of the split.

---

## 3. [CLIENT] Create their own Firebase project

1. Client goes to <https://console.firebase.google.com>, signs in with
   **their own** Google account (school/organization account recommended
   over a personal one, if they have one).
2. **Add project** → name it (e.g. `ar-science-explorer-<schoolname>`) →
   follow the prompts (Google Analytics is optional, not used by this app).
3. Stay on the free **Spark** plan for now — nothing in the core app
   (Auth, Firestore, Storage, Hosting) requires Blaze. Blaze is only needed
   if/when the PPTX Cloud Function gets deployed (§6 below).
4. Once the project exists, tell the developer its **Project ID** (shown on
   the Firebase Console's project overview) so step 4 can target it.

---

## 4. [DEV] Point the app at the client's new project

From the repo root, on a machine with the Firebase CLI installed and logged
into an account that has access to the client's new project (the client can
grant you temporary Editor access via Project Settings → Users and
permissions, or run this step themselves if they're comfortable with a
terminal):

```powershell
cd C:\Users\cedri\OneDrive\Documents\GitHub\ARwebmob
dart pub global run flutterfire_cli:flutterfire configure
```

- Select the client's project (from §3) when prompted.
- Select platforms **Web** and **Android**.
- This overwrites `firebase_options.dart` and `google-services.json` to
  point at the client's project — commit that change:
  ```powershell
  git add lib/firebase_options.dart android/app/google-services.json
  git commit -m "chore: point Firebase config at client project"
  git push
  ```

---

## 5. [DEV or CLIENT] Firestore rules and auth accounts

This has to happen on the **client's** project specifically — rules and
auth users don't carry over from the dev's own project.

### 5.1 Auth accounts (Firebase Console → Authentication → Add user)

- **At least one teacher account** — any email that is **not** the student
  pattern below (e.g. `teacher@yourschool.edu` + a password). Used to sign
  in to Teacher Web.
- **Student test accounts** — emails matching `123456@arscience.school`
  (exactly 6 digits + `@arscience.school`) — the app derives the student's
  ID from the digits before `@`.

### 5.2 Firestore security rules

There's no `firestore.rules` file in git — it's set directly in the
console (Firestore Database → Rules). Students need read/write on their
own record; teachers (any signed-in non-student email) need write on the
content collections:

| Collection | Teacher needs |
|---|---|
| `/lessons/{lessonId}` | create, update |
| `/quizzes/{quizId}` | create, update, delete |
| `/students/{studentId}` | create, update (archive) |
| `/unlockCodes/{code}` | create (doc id = code string) |
| `/quizUnlockCodes/{docId}` | create |

If Teacher Web shows `permission-denied` in the browser console after
signing in, this table is the first thing to check.

---

## 6. [CLIENT — decision required] PPTX vs PDF-only lesson content

The teacher lesson-upload form offers both PDF and PPTX as choices. PDF
works fully today, for free, no setup needed. PPTX requires deploying a
Cloud Function that needs the **Blaze** (pay-as-you-go) plan — realistically
**$0 actual cost** at small/pilot scale (Cloud Run/Functions/Build free
tiers comfortably cover a handful of students), but it does require
attaching a billing card to the Firebase project.

**Decide one:**

- **A. PDF-only for now** (recommended default) — do nothing further here.
  Teachers should be told/trained to upload lesson content as PDF, not
  PPTX, until/unless B is chosen later. No cost, no setup.
- **B. Deploy PPTX support** — client confirms they're okay attaching a
  billing card (expecting $0 real cost at this scale), then follow §6.1
  below.

Whichever is chosen, note it here for the record: ______________________

### 6.1 [DEV] If B was chosen — deploying the Cloud Function

**⚠️ Unverified architecture risk — read this first.** The function's
`Dockerfile` installs LibreOffice + poppler-utils, but a plain
`firebase deploy --only functions` builds Gen2 functions via Google Cloud
Buildpacks, which — as far as could be determined without an actual
deploy — ignores any `Dockerfile` in the function's source. If that holds,
the deployed function will lack `soffice`/`pdftoppm` and every conversion
will fail with `ENOENT`, even though the deploy itself reports success.
**Do step 4 below (a real test upload) before trusting this pipeline.** If
it fails with that error, the fix is restructuring `functions/` as a plain
Cloud Run service (`gcloud run deploy --source functions/`, which *does*
respect a Dockerfile) instead — a real architecture change, not a config
tweak; treat that as a new task if it comes up.

1. **Upgrade to Blaze.** Firebase Console (client's project) → Project
   Settings → Usage and billing → confirm/upgrade to the Blaze
   (pay-as-you-go) plan. Required because this function needs a custom
   container build — not available on the free Spark plan.
2. **Grant the Cloud Run service account signing permission.** The
   function calls `getSignedUrl()` on each uploaded slide image, which
   fails under Gen2's default credentials unless granted explicitly: IAM &
   Admin → find `PROJECT_NUMBER-compute@developer.gserviceaccount.com` →
   Edit → add role **Service Account Token Creator**.
3. **Wire `functions/` into the Firebase CLI config and deploy.**
   `firebase.json` needs a `"functions"` section — add:
   ```json
   "functions": [{ "source": "functions", "codebase": "default" }]
   ```
   then, from the repo root:
   ```powershell
   firebase deploy --only functions
   ```
   Expect success output naming the `convertLessonPptx` Cloud Run
   service/trigger, region `us-central1`.
4. **Real test upload — do not skip.** Open the teacher lesson form,
   upload a real `.pptx` for a test lesson, wait ~30-60 seconds, then
   check that lesson's Firestore doc (`/lessons/{id}`) for
   `contentStatus: 'ready'` and real `contentImageUrls`. Open the same
   lesson on the student side and confirm real slides render, not a
   placeholder. If it's stuck at `'processing'` or the Cloud Functions
   logs show an `ENOENT` on `soffice`/`pdftoppm`, that's the Buildpacks
   risk above — the pipeline needs the Cloud Run restructure before it's
   trustworthy.
5. **Re-deploy after any future edit** to `functions/src/index.js` or its
   `Dockerfile` — `firebase deploy --only functions` again; nothing
   auto-deploys.

---

## 7. [DEV or CLIENT] Deploy Teacher Web (Firebase Hosting)

Free, no billing card, independent of the PPTX decision above. From the
repo root, once `flutterfire configure` (§4) has run against the client's
project:

1. `firebase.json` is gitignored (machine-local, generated by
   `flutterfire configure`) — add a `"hosting"` block to it by hand,
   alongside whatever `flutterfire configure` already wrote there:
   ```json
   "hosting": {
     "public": "build/web",
     "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
     "rewrites": [{ "source": "**", "destination": "/index.html" }]
   }
   ```
   The `rewrites` entry matters — it sends every route back through
   `index.html` so the app's client-side routing works on a hard refresh
   or direct link instead of 404ing.
2. Build and deploy:
   ```powershell
   flutter build web --release
   firebase deploy --only hosting
   ```
3. Firebase prints a live `https://<project-id>.web.app` URL — that's the
   real link to give teachers, instead of running the app locally.
4. Re-run both commands any time you want a Teacher Web change to go live —
   there's no CI/auto-deploy wired up.

---

## 8. [DEV] Android app to the client

**⚠️ Do this after §4, not before.** The APK bakes in whatever Firebase
project `google-services.json` currently points at. Building it before §4
(`flutterfire configure` against the client's project) has run will
silently ship an app wired to the **dev's own** Firebase project instead
of the client's — no error, just wrong data. Confirm §4 is done first.

There's no Play Store release signing set up yet (not required for a
capstone demo). Two ways to get the app onto a device:

- **Sideload the debug APK** — **not currently built**: the Unity export
  (`android/unityLibrary`) and the prior APK build both only ever existed
  in the now-deleted development worktree, and neither is git-tracked
  (both gitignored), so neither survived the merge to `main`. Before an
  APK exists again, re-run the Unity export from Unity Editor
  (`MANUAL_STEPS.md` §3.3 — a GUI action, not automatable) targeting
  `android/unityLibrary` at the repo root, then
  `flutter build apk --debug` from the repo root (full ~24-minute IL2CPP
  compile, since this is a fresh build environment). Output lands at
  `build/app/outputs/flutter-apk/app-debug.apk` (~806 MB, debug/unstripped) —
  hand that file to the client to install directly (`adb install <path>`,
  or copy it to the phone and open it — Android will prompt to allow
  installs from this source).
- **Play Store internal testing track** — only worth setting up if the
  client wants a more polished install flow (auto-updates, no "unknown
  sources" prompt); requires a release signing keystore
  (dev's own reference has the detail), which isn't done yet — flag to the
  client if this is wanted.

### 8.1 [DEV or CLIENT, whoever has a physical phone] AR on-device test

This is the one step in this entire handover that genuinely **cannot be
automated** — no device/emulator was available in the environment this was
built in, so it has never been run for real. Once the APK (above) is
installed on a physical Android phone and a student test account exists
(§5.1):

1. Sign in with a student test account.
2. Navigate to a lesson with AR content (e.g. the first Chemistry lesson).
3. Open the **Scan** tab — a live Unity camera view should appear.
4. Point the camera at a printed AR marker — a Flutter overlay
   (title/description) should appear and update; voice narration should
   play for the first few lessons.
5. Complete the **Read** → **Review** flow, and run the pre/post-test quiz
   if the lesson has one.

If this doesn't work, everything *around* it (marker-to-model data,
narration lifecycle, quiz linking) is covered by automated tests and is
very unlikely to be the cause — the actual camera+Vuforia detection loop on
real hardware is the untested part.

---

## 9. [DEV → CLIENT] Ownership transfer

Once the client's project is live, verified working (§4-§7 all confirmed),
and the client is comfortable:

1. Firebase Console (client's project) → Project Settings → Users and
   permissions → confirm the client's own account is already **Owner**
   (it should be, since they created it in §3) — nothing to transfer here,
   unlike a scenario where the dev created the project first.
2. If the developer was granted temporary access in step 4/5, the client
   removes that access once everything's confirmed working, or leaves it
   in place if ongoing support is part of the arrangement — client's call.
3. GitHub repo (§1): confirm the client's collaborator access is set the
   way they want it long-term (full transfer vs. ongoing collaborator).

---

## 10. Known, disclosed limitations — not oversights

Being upfront about what this handover does **not** include, and why:

1. **Physical AR marker-scanning on a real device was never automated.**
   This dev environment has no Android device or emulator available, so
   the Scan → camera → marker-detection → Flutter overlay flow (§8.1
   above) has to be walked through by hand, once, by whoever has a
   physical phone. Everything else about the AR flow (data wiring,
   marker-to-model mapping, the Read/Review phases, voice narration
   lifecycle) is covered by automated tests; only the actual
   camera+Vuforia detection loop on real hardware isn't.
2. **PPTX upload is undeployed by decision, not oversight** — see §6 above.
3. **No responsive/adaptive layout on Teacher Web** — it's a deliberate
   desktop/laptop-only design (documented in-code on `TeacherShell`), not
   built for tablets or narrow viewports. Revisit only if the client
   specifically needs tablet support later.
4. **No CI/CD** — deploys (Hosting, Functions) are manual commands, not
   triggered automatically by a push. Worth adding later if this becomes a
   longer-running project with frequent updates.

---

## 11. Where to go for more detail

Everything essential to complete a handover is already inlined above —
these are optional, deeper references, mostly relevant to the developer
rather than the client:

- `MANUAL_STEPS.md` — the developer's own internal working checklist/status
  tracker (Unity export detail, environment verification history). Not
  required reading for the client.
- `docs/superpowers/NICE_TO_HAVES.md` — minor, deferred findings logged
  across all phases (mostly resolved; a few intentionally left for a future
  general-cleanup pass).
- `PROJECT_FLOW.md` — the original functional spec (curriculum, access-code
  rules, quiz retake rules) this app was built against.
- `docs/superpowers/sdd/` — full build-log/provenance for Phases 3-5
  (task briefs, review reports) if you want the detailed history of how
  something was built or decided.
