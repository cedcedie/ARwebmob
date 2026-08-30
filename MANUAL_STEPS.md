# Manual Steps — Things Only You Can Do

This tracks everything the implementation needs from you directly — installs,
credentials, Unity Editor actions, Firebase console work, and on-device
verification. Treat it as a living checklist, not a one-time list.

**Worktree note:** Active app code lives on branch `worktree-phase1-scaffold-core-auth`
in `.claude/worktrees/phase1-scaffold-core-auth`. Run `flutter` commands from
that directory unless you've merged to `main`.

---

## 0. One-time environment setup

- [ ] **Flutter SDK** on PATH — run `flutter doctor` and fix anything red
      (Android toolchain especially).
- [ ] **Android SDK / Android Studio** — at least one SDK platform + build-tools
      matching the Unity export (see Unity section below).
- [ ] **Chrome** (or another browser) for Teacher Web smoke tests
      (`flutter run -d chrome` from the worktree).
- [ ] **Physical Android phone** (recommended over emulator for AR/Unity embed).
- [ ] **Unity Hub + Unity 6000.4.0f1** with **Android Build Support**, **Android
      SDK & NDK Tools**, **OpenJDK** modules installed.
- [ ] Confirm Unity Hub's **NDK is ≥ 27.2.12479018** (Unity 6000.x Android
      embedding requirement).

---

## 1. Open product decisions (confirm before Phase 5)

- [ ] **Q1** (PROJECT_FLOW.md Part 13): Item analysis is **Teacher Web only**,
      not shown to students. Default: yes — confirm with client/stakeholder.
- [ ] **Q2** (PROJECT_FLOW.md Part 13): PPTX support = convert to slide
      images/PDF at teacher upload time, **not** a native on-device PPTX renderer.
      Default: yes — confirm with client/stakeholder.

---

## 2. Firebase — account & config (you must do this)

This repo expects **one shared Firebase project** for both Android (student)
and Web (teacher). There is **no** `firestore.rules` file in git — rules are
managed in the Firebase console.

### 2.1 Project wiring

- [ ] Confirm which Firebase project backs this app (same as the retired
      `ar-science-explorer` web app — **no migration**, same collections).
- [ ] Install tooling (one-time on this machine):
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
- [ ] Run **`flutterfire configure`** from the worktree (recommended) and pick
      your existing project — writes `firebase_options.dart`,
      `google-services.json`, etc. **Use this command** (works even when
      `flutterfire` is not on PATH):
      ```powershell
      cd C:\Users\cedri\OneDrive\Documents\GitHub\ARwebmob\.claude\worktrees\phase1-scaffold-core-auth
      dart pub global run flutterfire_cli:flutterfire configure
      ```
      Select platforms **Web** and **Android** when prompted.
      **Or** hand-copy `google-services.json` (Android) + web config from
      Firebase Console → Project Settings.
- [ ] Confirm you can **edit Firestore security rules** in the console (or via
      Firebase CLI tied to your account).

### 2.2 Auth accounts to create (Firebase Console → Authentication)

- [ ] **At least one teacher account** — any email that is **not** the student
      pattern `/^\d+@arscience\.school$/` (e.g. `teacher@yourschool.edu` + password).
      Used for `flutter run -d chrome` Teacher Web sign-in.
- [ ] **Student test accounts** — create users with emails like
      `123456@arscience.school` (6 digits + `@arscience.school`) for Android testing.
      The app derives `studentId` from the part before `@`.

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

- [ ] **Verify or update Firestore rules** so teacher-authenticated users (non-student
      email) can write the collections above. If Teacher Web shows
      `permission-denied` in the browser console after sign-in, fix rules first.

### 2.4 Optional: initial student roster

- [ ] Create `/students/{studentId}` docs via Teacher Web **Students** screen,
      or seed manually in the console if you prefer pre-populated rosters before
      first login.

---

## 3. Unity — Editor actions only you can perform

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

Export target (worktree path):
```
C:\Users\cedri\OneDrive\Documents\GitHub\ARwebmob\.claude\worktrees\phase1-scaffold-core-auth\android\unityLibrary
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
- [ ] Gradle wiring is already committed in the worktree (`310fdf3`) — normally
      no re-edit needed unless you reset `settings.gradle.kts` / `app/build.gradle.kts`.

### 3.5 Unity C# bridge (already edited — re-verify after scene changes)

Scripts touched in Phase 3 (in the Unity project, not this Flutter repo):

- `Assets/Scripts/ARTargetVisibilityAndInteraction.cs` — sends
  `markerFound` / `markerLost` + Vuforia `trackableName` to Flutter.
- `Assets/Scripts/ModelHotspotLegend.cs` — scaffold only, not wired.

- [ ] Optional: Unity **Play mode** smoke — Console should show
      `SendToFlutter` log lines with correct trackable names (Editor stub logs
      instead of sending to Flutter — expected).

---

## 4. Android build & on-device test (Phase 3 Task 11)

- [x] **`flutter build apk --debug`** succeeded once (IL2CPP ~24 min first time;
      ~2 min on cache hit). APK:
      `build/app/outputs/flutter-apk/app-debug.apk` (~806 MB debug/unstripped).
- [ ] **Install on a physical device** — `flutter install` or adb:
      `adb install build/app/outputs/flutter-apk/app-debug.apk`
- [ ] **Sign in as a student** — ⚠️ **Student login UI is still a placeholder**
      (`Text('Sign in')` in `main.dart`). Until a real login screen is built,
      you may need to sign in via Firebase test harness or temporary dev wiring.
      See § 6 Known gaps.
- [ ] **AR end-to-end on device:**
      1. Navigate to a lesson with AR (e.g. q1w1).
      2. Open **Scan** tab — Unity camera view should appear.
      3. Point at a printed marker — Flutter overlay (title/description) should
         update; voice narration should play for q1w1–q1w5 lessons.
      4. Complete **Read** → **Review** flow; run pre/post quiz if applicable.
- [ ] If NDK build fails with corrupted NDK 28: delete
      `%LOCALAPPDATA%\Android\Sdk\ndk\28.2.13676358` and rebuild (see
      `NICE_TO_HAVES.md`).

---

## 5. Teacher Web — manual verification (Phase 4 Task 13)

Automated gate passed: **`flutter test` 168/168** in the worktree.

### 5.1 Run locally

From the worktree:
```powershell
cd C:\Users\cedri\OneDrive\Documents\GitHub\ARwebmob\.claude\worktrees\phase1-scaffold-core-auth
flutter run -d chrome
```

- [ ] **Sign in** with a teacher Firebase account (non-student email).
- [ ] Walk all four nav sections:
      - **Lessons** — list shows built-ins (read-only badge) + teacher lessons;
        create/edit/archive a teacher lesson; optional `.glb` preview if model index set.
      - **Quizzes** — built-in banks read-only; create/edit/delete teacher quiz.
      - **Students** — roster list, archived filter, create student, archive.
      - **Access Codes** — issue all **3 code types**; confirm generated code
        displays prominently (copyable).

### 5.2 Cross-target round-trip (most important integration test)

- [ ] From **Access Codes** on Web, issue:
      1. Subject-wide code
      2. Lesson-targeted code (pick a student + lesson)
      3. Quiz retake code (student must have ≥1 post-test attempt first)
- [ ] On **Android student app**, redeem each code via the access-code entry
      (Home or wherever redeem UI lives) and confirm content unlocks per Part 9.

### 5.3 Item Analysis nav entry

- [ ] **Item Analysis** appears **disabled** in the side nav (Phase 5 placeholder) —
      tooltip should indicate coming later. No action needed until Q1 confirmed.

---

## 6. Release / production (not needed for dev yet)

- [ ] **Release signing keystore** for Play Store / production APK (debug signing
      is wired for now).
- [ ] **Firebase App Check** / production-hardening rules (if required by school IT).
- [ ] **Web hosting** for Teacher Web (Firebase Hosting, Vercel, etc.) — not
      configured in this repo yet.
- [ ] **Merge worktree branch to `main`** and delete worktree when ready.

---

## 7. Known gaps (not manual steps — awareness for testing)

These affect how "complete" the app feels; no action required unless you want
them fixed in a future phase:

| Gap | Impact |
|---|---|
| **No student login screen** on Android | `main.dart` shows placeholder `Text('Sign in')` — `AuthService.signInStudent` exists but no UI wires it. Blocks real device testing until built or dev-signed-in another way. |
| **Phase 5 not started** | Item analysis, PPT/PDF upload pipeline, `fl_chart`, Firebase Storage — out of scope until Q1/Q2 confirmed. |
| **UI polish pass** | Spec calls for `/impeccable` design pass; screens are functional, not final visual polish. |
| **BUILD.md** | Unity re-export doc referenced in spec not written yet; steps are in this file §3 instead. |
| **Unity local patches** | ARM64-only checker + proguard line — reapply after Unity package reinstall or re-export (see `NICE_TO_HAVES.md`). |

---

## 8. Not needed from you

- Dart/Flutter business logic, repositories, quiz rules, access-code validation,
  curriculum data port, Unity C# bridge edits (once pointed at the right scripts),
  Gradle wiring (already committed), and automated tests — handled in-repo.
- Subagent-driven task briefs/reports live under
  `docs/superpowers/sdd/` — no manual maintenance required.

---

## Quick reference — phase completion vs manual work

| Phase | Code status | Your manual work remaining |
|---|---|---|
| **1** Foundation | Done | Firebase configure, auth accounts |
| **2** Student core | Done | Student login UI gap blocks easy device login |
| **3** AR Lab | Build OK | Device AR scan test (§4) |
| **4** Teacher Web | Done | Chrome smoke + Firestore rules + cross-redeem (§5) |
| **5** Analytics/PPT | Not started | Confirm Q1/Q2 first |
