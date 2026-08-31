# Manual Steps — Things Only You (or the Client) Can Do

This tracks everything the implementation needs done outside the codebase —
installs, credentials, Unity Editor actions, Firebase console work, and
on-device verification. Treat it as a living checklist, not a one-time list.

Every item below is labeled with who does it:

- **[DEV]** — you, as the person currently holding this codebase (`cedcedie`).
- **[CLIENT]** — the person/school this project is being handed over to.
- **[EITHER]** — genuinely doesn't matter who runs it, whoever has the access at the time.

For the full narrative version of the DEV→CLIENT handover sequence (with
copy-pasteable terminal commands end to end), see **`PROJECT_HANDOVER.md`**
at the repo root — this file stays the flat, checkbox-style reference; that
one is the step-by-step walkthrough.

**Repo note:** As of this update, all phases are merged onto `main` — there
is no active development worktree/branch anymore. Run every command below
from the repo root: `C:\Users\cedri\OneDrive\Documents\GitHub\ARwebmob`.

---

## 0. [DEV] One-time environment setup

- [ ] **Flutter SDK** on PATH — run `flutter doctor` and fix anything red
      (Android toolchain especially).
- [ ] **Android SDK / Android Studio** — at least one SDK platform + build-tools
      matching the Unity export (see Unity section below).
- [ ] **Chrome** (or another browser) for Teacher Web smoke tests
      (`flutter run -d chrome` from the repo root).
- [ ] **Physical Android phone** (recommended over emulator for AR/Unity embed).
- [ ] **Unity Hub + Unity 6000.4.0f1** with **Android Build Support**, **Android
      SDK & NDK Tools**, **OpenJDK** modules installed.
- [ ] Confirm Unity Hub's **NDK is ≥ 27.2.12479018** (Unity 6000.x Android
      embedding requirement).

---

## 1. Product decisions — status

- [x] **Q1** (PROJECT_FLOW.md Part 13): Item analysis is **Teacher Web only**,
      not shown to students. **Confirmed 2026-08-31**, before Phase 5 was built
      (see `docs/superpowers/sdd/2026-08-31-phase5-item-analysis-ppt-pipeline/progress.md`).
      No action needed.
- [x] **Q2** (PROJECT_FLOW.md Part 13): PPTX support = convert to slide
      images/PDF at teacher upload time, **not** a native on-device PPTX
      renderer. **Confirmed 2026-08-31**, same source as Q1. No action needed.
- [ ] **[CLIENT] New decision — PPTX upload availability.** The teacher
      lesson-content picker currently offers **both** PDF and PPTX as file
      choices, but PPTX conversion depends on an **undeployed** Cloud Function
      (see §6). PDF works fully today; PPTX silently gets stuck at
      `contentStatus: 'processing'` forever if picked while the function is
      undeployed — no error shown to the teacher. This is a known, disclosed
      gap, not a bug that was missed. **The client needs to decide**: accept
      PDF-only for now (recommended — free, works today), or fund/approve
      deploying the Cloud Function (§6, requires the Blaze plan) so PPTX
      works too. Revisit item 3 of §7 once decided.

---

## 2. Firebase — accounts & config

This app expects **one Firebase project** shared by both the Android (student)
and Web (teacher) targets. There is **no** `firestore.rules` file in git —
rules are managed in the Firebase console, per-project.

**Two-project model for this handover** (see `PROJECT_HANDOVER.md` for the
full walkthrough):

- **[DEV] Your own project, for testing now**: `ar-science-explorer`
  (already exists under your Firebase account — confirmed via
  `firebase projects:list`). Use this for all local dev/testing between now
  and handover.
- **[CLIENT] Their own new project, for the real handover**: created fresh
  by the client under their own Google account — **not** a transfer of the
  project above. At handover, re-run `flutterfire configure` against the
  client's new project (§2.1 below), which re-registers the apps; Firestore
  starts empty and needs reseeding (auth accounts, any test data).

### 2.1 Project wiring

- [ ] **[EITHER, whoever owns the target project]** Install tooling
      (one-time on this machine):
      ```powershell
      dart pub global activate flutterfire_cli
      npm install -g firebase-tools
      ```
      If `flutterfire` is "not recognized", either add
      `%LOCALAPPDATA%\Pub\Cache\bin` to your PATH **or** use the form below
      (no PATH change needed).
- [ ] Sign in to Firebase CLI (opens browser):
      ```powershell
      firebase login
      ```
- [ ] Run **`flutterfire configure`** from the repo root and pick the target
      project (your `ar-science-explorer` now; the client's new project at
      handover) — writes `firebase_options.dart`, `google-services.json`,
      etc.:
      ```powershell
      cd C:\Users\cedri\OneDrive\Documents\GitHub\ARwebmob
      dart pub global run flutterfire_cli:flutterfire configure
      ```
      Select platforms **Web** and **Android** when prompted.
      **Or** hand-copy `google-services.json` (Android) + web config from
      Firebase Console → Project Settings.
- [ ] Confirm you can **edit Firestore security rules** in the console (or via
      Firebase CLI tied to your account).

### 2.2 Auth accounts to create (Firebase Console → Authentication)

- [ ] **[EITHER]** **At least one teacher account** — any email that is
      **not** the student pattern `/^\d+@arscience\.school$/`
      (e.g. `teacher@yourschool.edu` + password). Used for
      `flutter run -d chrome` Teacher Web sign-in.
- [ ] **[EITHER]** **Student test accounts** — create users with emails like
      `123456@arscience.school` (6 digits + `@arscience.school`) for Android
      testing. The app derives `studentId` from the part before `@`.

### 2.3 Firestore security rules — student reads + teacher writes

Students need read/write on their own `/students/{studentId}` doc and read on
lessons/quizzes/codes as the app expects. Teachers need **write** access when
signed in with a non-student email:

| Collection | Teacher needs |
|---|---|
| `/lessons/{lessonId}` | create, update |
| `/quizzes/{quizId}` | create, update, delete |
| `/students/{studentId}` | create, update (archive) |
| `/unlockCodes/{code}` | create (doc id = code string) |
| `/quizUnlockCodes/{docId}` | create |

- [ ] **[EITHER, whoever owns the target project]** **Verify or update
      Firestore rules** so teacher-authenticated users (non-student email)
      can write the collections above. If Teacher Web shows
      `permission-denied` in the browser console after sign-in, fix rules
      first.

### 2.4 Optional: initial student roster

- [ ] **[EITHER]** Create `/students/{studentId}` docs via Teacher Web
      **Students** screen, or seed manually in the console if you prefer
      pre-populated rosters before first login.

### 2.5 [DEV → CLIENT] Ownership transfer, at handover

Once the client's own project (§2.1) is live and verified working:

- [ ] Firebase Console → Project Settings → **Users and permissions** → add
      the client's Google account as **Owner**.
- [ ] Confirm the client can sign in and see the project themselves.
- [ ] Step yourself down to a lesser role (or remove yourself entirely) once
      the client confirms they're set — only relevant if you were ever Owner
      on *their* project (you won't be, under the two-project model above,
      unless they explicitly add you for support).

---

## 3. Unity — [DEV] Editor actions only you can perform

Unity project location: **`C:\Users\cedri\VuforiaAR`** (external to this repo).

### 3.1 One-time setup (mostly done)

- [x] Unity version confirmed: **6000.4.0f1 (Unity 6.4)**.
- [x] Embed package: **`flutter_embed_unity`** + `flutter_embed_unity_6000_0_android`
      (not `flutter_unity_widget`).
- [x] Scene confirmed: **23 markers/models** already set up in `SampleScene.unity`.
- [ ] Confirm **Android Build Support + NDK ≥ 27.2.12479018** in Unity Hub modules
      (if not already verified).

### 3.2 Import FlutterEmbed Unity package (one-time)

- [ ] Unity Package Manager → Add package from git URL:
      `https://github.com/learntoflutter/flutter_embed_unity.git?path=example_unity_6000_0_project/Assets/FlutterEmbed`
      (6000.x path — matches 6000.4.0f1).

### 3.3 Export to Flutter (repeat after every Unity change)

Export target (repo root):
```
C:\Users\cedri\OneDrive\Documents\GitHub\ARwebmob\android\unityLibrary
```

**Player Settings checklist** (required before export succeeds):

- [ ] **Application Entry Point** → `Activity` only (not GameActivity).
      `File → Build Profiles → Player Settings → Android → Other Settings`.
- [ ] **Export Project** ticked under Android platform settings in Build Profiles.
- [ ] **Target architectures** → **ARM64 only** (Vuforia requirement). If
      `flutter_embed_unity`'s export checker demands ARMv7+ARM64, apply the local
      patch documented in `docs/superpowers/NICE_TO_HAVES.md` (`ProjectExportChecker.cs`
      in `Library/PackageCache` — **reapply after package reinstall**).

**Export:**

- [ ] Unity menu: **`Flutter Embed → Export project to Flutter app`** → Android
      → select the `android/unityLibrary` path above.

### 3.4 Post-export fixes (may be needed every re-export)

These live in **gitignored / Unity-regenerated** paths — reapply if the build
fails after a fresh export (full details in `docs/superpowers/NICE_TO_HAVES.md`):

- [ ] Remove `-ignorewarnings` line from
      `android/unityLibrary/proguard-unity.txt` if Gradle fails with
      `mergeDebugConsumerProguardFiles` / consumer proguard error (AGP 9.x).
- [ ] Gradle wiring is already committed (`310fdf3`) — normally no re-edit
      needed unless you reset `settings.gradle.kts` / `app/build.gradle.kts`.

### 3.5 Unity C# bridge (already edited — re-verify after scene changes)

Scripts touched in Phase 3 (in the Unity project, not this Flutter repo):

- `Assets/Scripts/ARTargetVisibilityAndInteraction.cs` — sends
  `markerFound` / `markerLost` + Vuforia `trackableName` to Flutter.
- `Assets/Scripts/ModelHotspotLegend.cs` — scaffold only, not wired.

- [ ] Optional: Unity **Play mode** smoke — Console should show
      `SendToFlutter` log lines with correct trackable names (Editor stub logs
      instead of sending to Flutter — expected).

---

## 4. [DEV or CLIENT, whoever has the device] Android build & on-device test

- [x] **`flutter build apk --debug`** succeeded once (IL2CPP ~24 min first time;
      ~2 min on cache hit). APK:
      `build/app/outputs/flutter-apk/app-debug.apk` (~806 MB debug/unstripped).
- [ ] **Install on a physical device** — `flutter install` or adb:
      `adb install build/app/outputs/flutter-apk/app-debug.apk`
- [ ] **Sign in as a student** — real login screen exists
      (`lib/features/student/auth/student_login_screen.dart`); use a student
      test account created in §2.2.
- [ ] **AR end-to-end on device** — this is the one step in this whole
      document that genuinely **cannot be automated**, no device/emulator
      available in the dev environment this was built in:
      1. Navigate to a lesson with AR (e.g. q1w1).
      2. Open **Scan** tab — Unity camera view should appear.
      3. Point at a printed marker — Flutter overlay (title/description) should
         update; voice narration should play for q1w1–q1w5 lessons.
      4. Complete **Read** → **Review** flow; run pre/post quiz if applicable.
- [ ] If NDK build fails with corrupted NDK 28: delete
      `%LOCALAPPDATA%\Android\Sdk\ndk\28.2.13676358` and rebuild (see
      `NICE_TO_HAVES.md`).

---

## 5. Teacher Web — [DEV or CLIENT] manual verification

Automated gate passed: **`flutter test` 264/264** on `main` (includes a
dedicated `test/integration/` suite exercising real teacher→student flows
against a shared fake Firestore — access-code round trip, pre/post-test
retake rule, item analysis, and lesson-content delivery — so most of what
used to require manual cross-target clicking is now covered by an automated
test that runs on every `flutter test`).

### 5.1 Run locally

From the repo root:
```powershell
cd C:\Users\cedri\OneDrive\Documents\GitHub\ARwebmob
flutter run -d chrome
```

- [ ] **Sign in** with a teacher Firebase account (non-student email).
- [ ] Walk all four nav sections:
      - **Lessons** — list shows built-ins (read-only badge) + teacher lessons;
        create/edit/archive a teacher lesson; optional `.glb` preview if model index set;
        empty roster shows a tailored empty state.
      - **Quizzes** — built-in banks read-only; create/edit/delete teacher quiz.
      - **Students** — roster list, archived filter, create student, archive
        (single-row archive now asks for confirmation, matching bulk archive).
      - **Access Codes** — issue all **3 code types**; confirm generated code
        displays prominently (copyable); a thrown error during issuance now
        shows a real error toast instead of a stuck spinner.
- [ ] **Item Analysis** — open a quiz's detail view; Item Analysis is reached
      from there (intentionally not a top-level nav-rail entry — nested under
      the quiz it belongs to, not a disabled placeholder).

### 5.2 Optional manual spot-check of the automated cross-target flow

The real coverage now lives in `test/integration/` and runs automatically —
this is only worth doing by hand if you want to see it happen live in two
browser windows (or a browser + a device) rather than trust the test suite:

- [ ] From **Access Codes** on Web, issue a subject-wide code, a
      lesson-targeted code, and a quiz-retake code (student needs ≥1 post-test
      attempt first).
- [ ] On the **Android student app**, redeem each and confirm content
      unlocks per `PROJECT_FLOW.md` Part 9.

---

## 6. Cloud Function — PPTX slide-image pipeline (status: written, undeployed by decision)

The code for this is written and committed (`functions/package.json`,
`functions/src/index.js`, `functions/Dockerfile`, `functions/.gcloudignore`).
**It is intentionally not deployed** — this was a deliberate decision (not
just "not gotten to yet"): deploying it requires the Firebase project to be
on the **Blaze** (pay-as-you-go) plan, and the choice made during this
session's planning was to stay on the free Spark plan for now. PDF lesson
content works fully without this function (see §1's new PPTX decision); only
`.pptx` uploads are gated behind this.

**⚠️ UNVERIFIED ARCHITECTURE CONCERN — check this before 6.4, if/when you deploy.**
`functions/Dockerfile` installs LibreOffice + poppler-utils, but
`firebase deploy --only functions` builds Gen2 functions via **Google
Cloud Buildpacks**, which — as far as could be determined without an
actual deploy — ignores any `Dockerfile` present in the function's source
directory. If that holds, the deployed function will lack `soffice`/
`pdftoppm` entirely and every conversion will fail with `ENOENT`, even
though the deploy itself reports success. Before relying on this pipeline:
run a real test deploy and a real `.pptx` upload (step 6.5) and check the
Cloud Functions logs for an `ENOENT` on `soffice`/`pdftoppm`. If that's
what happens, the fix is to stop deploying this as a Firebase Function and
instead deploy `functions/` as a **plain Cloud Run service** (`gcloud run
deploy --source functions/`, which *does* respect a `Dockerfile`) with a
Storage-Eventarc trigger wired to it, rather than `onObjectFinalized`.
That's a real restructure (different trigger wiring, different deploy
command), not a config tweak — this was scoped as a future follow-up, not
done now, since deploying anything at all was deferred by decision (§1).

- [ ] **6.1 [CLIENT — billing decision]** Confirm/upgrade the Firebase project
      to the Blaze (pay-as-you-go) plan. Cloud Run-based functions (required
      here for a custom container with LibreOffice + poppler-utils) are not
      available on the free Spark plan. Firebase Console → Project Settings
      → Usage and billing. **Realistic cost at small/local-testing scale is
      $0** — Cloud Run, Cloud Functions Gen2, and Cloud Build all have a free
      tier well above what a handful of students would use — but a billing
      card must be attached regardless of actual usage.
- [ ] **6.2 [DEV or CLIENT, whoever has console access]** Grant the Cloud Run
      service account signing permission. The function calls
      `getSignedUrl()` on each uploaded slide image. Gen2 functions run
      under the Compute Engine default service account with no local key
      file (Application Default Credentials only), so signing a URL fails
      unless that service account also holds the **Service Account Token
      Creator** role (`iam.serviceAccounts.signBlob` permission) — grant it
      to itself: IAM & Admin → find
      `PROJECT_NUMBER-compute@developer.gserviceaccount.com` → Edit → add
      role **Service Account Token Creator**. Without this, deploys succeed
      but every conversion will fail at the `getSignedUrl` call.
- [ ] **6.3 [DEV]** Wire `functions/` into the Firebase CLI config.
      `firebase.json` in this repo is gitignored and currently only holds the
      FlutterFire app-config (Android/Web app IDs) — it has no `"functions"`
      section pointing at the `functions/` directory yet. Before
      `firebase deploy --only functions` will find anything to deploy, add
      one, e.g. run `firebase init functions` from the repo root (point it at
      the existing `functions/` folder, don't let it overwrite
      `package.json`/`src/`), or manually add:
      ```json
      "functions": [{ "source": "functions", "codebase": "default" }]
      ```
      to `firebase.json`.
- [ ] **6.4 [DEV]** Deploy the function. Once 6.1–6.3 are done, from the
      **repo root** run:
      ```powershell
      firebase deploy --only functions
      ```
      Expected: the function deploys successfully and the Firebase CLI
      reports the Cloud Run service URL/trigger is live
      (`convertLessonPptx`, region `us-central1`).
- [ ] **6.5 [DEV or CLIENT]** Manual end-to-end verification. Open the
      teacher lesson form, upload a real `.pptx` for a test lesson, wait
      roughly 30-60 seconds, then check that lesson's Firestore doc
      (`/lessons/{id}`) shows `contentStatus: 'ready'` and
      `contentImageUrls` populated with real slide image URLs. Then open
      that same lesson on the student side and confirm the slide gallery
      actually renders the real slides, not a placeholder.
- [ ] **6.6 [DEV]** Re-deploy after future edits. Any time
      `functions/src/index.js` (or the Dockerfile) changes, you must
      manually re-run `firebase deploy --only functions` from the repo
      root — this does **not** happen automatically as part of any other
      workflow in this repo.

---

## 7. Release / production

- [ ] **7.1 [DEV] Repo visibility** — keep this **private** on GitHub; add
      the client as a collaborator at handover rather than making it public
      (decided: this repo carries internal architecture notes and a full
      build history in `docs/superpowers/` not meant for public consumption).
- [ ] **7.2 [DEV] Release signing keystore** for Play Store / production APK
      (debug signing is wired for now) — only needed if this goes to the Play
      Store; not required for a capstone demo via sideloaded APK.
- [ ] **7.3 [CLIENT — pending §1's PPTX decision]** **Firebase App Check** /
      production-hardening rules, if required by school IT — only relevant
      once/if this moves beyond local testing.
- [ ] **7.4 [DEV, already done]** ~~Merge worktree branch to `main`~~ — done,
      `main` is now the only branch, all phases merged, worktree removed.

### 7.5 Web hosting for Teacher Web (Firebase Hosting) — [DEV or CLIENT]

Not configured yet — `firebase.json` is gitignored (machine-local, generated by
`flutterfire configure`), so this can't be committed; add it by hand once. This
is **unrelated to the Cloud Function/Blaze decision above** — Hosting is a
static-file host, free on the Spark plan, **no billing card required**.

- [ ] Add a `"hosting"` block to your local `firebase.json` (alongside whatever
      `flutterfire configure` already wrote there):
      ```json
      "hosting": {
        "public": "build/web",
        "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
        "rewrites": [{ "source": "**", "destination": "/index.html" }]
      }
      ```
      The `rewrites` entry is required for a Flutter Web app — it sends every
      route back through `index.html` so client-side routing (go_router) works
      on a hard refresh/direct link instead of 404ing.
- [ ] Build and deploy, from the repo root:
      ```powershell
      flutter build web --release
      firebase deploy --only hosting
      ```
      Firebase CLI prints a live `https://<project-id>.web.app` URL on success
      — that's the real link to hand a teacher/client instead of asking them to
      run `flutter run -d chrome` locally.
- [ ] Re-run both commands after any future Teacher Web change you want live —
      this does not auto-deploy on push; there's no CI wired up for it in this
      repo.

---

## 8. Known gaps (not manual steps — awareness for testing)

These affect how "complete" the app feels; no action required unless you want
them fixed in a future phase:

| Gap | Impact | Owner if fixed |
|---|---|---|
| **Cloud Function not deployed** | Undeployed **by decision**, not oversight (see §6/§1) — PDF works fully; PPTX gets stuck at `contentStatus: 'processing'` if picked. | [CLIENT] decision, [DEV] execution |
| **No responsive/adaptive layout on Teacher Web** | `TeacherShell`'s fixed-width `NavigationRail` and `DataTable2` tables have no breakpoints — desktop/laptop-only by deliberate design (documented in-code and in `NICE_TO_HAVES.md`), not built for tablet/narrow viewports. | Future phase, if ever needed |
| **Unity local patches** | ARM64-only export checker + proguard line — reapply after Unity package reinstall or re-export (see `NICE_TO_HAVES.md`). | [DEV], Unity-side only |
| **Mangled em-dash encoding** | Cosmetic doc-comment artifact — resolved repo-wide, noted here only for history. | Resolved |

---

## 9. Not needed from anyone

- Dart/Flutter business logic, repositories, quiz rules, access-code validation,
  curriculum data port, Unity C# bridge edits (once pointed at the right scripts),
  Gradle wiring (already committed), and automated tests (264/264, including
  cross-target integration coverage) — handled in-repo.
- Subagent-driven task briefs/reports live under
  `docs/superpowers/sdd/` — no manual maintenance required.

---

## Quick reference — phase completion vs manual work

| Phase | Code status | Manual work remaining |
|---|---|---|
| **1** Foundation | Done | Firebase configure, auth accounts (§2) |
| **2** Student core | Done | None — real login screen exists |
| **3** AR Lab | Build OK | Device AR scan test (§4) — the one un-automatable step |
| **4** Teacher Web | Done, 7 critique rounds, 33/40 | Chrome smoke + Firestore rules (§5) |
| **5** Analytics/PPT | Cloud Function code done, undeployed **by decision** | Client's PPTX decision (§1), then §6 if approved |
| **Handover** | Not started | Client's own Firebase project, repo collaborator access, ownership transfer (§2.5) — see `PROJECT_HANDOVER.md` |
