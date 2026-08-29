# Phase 4: Teacher Web — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Teacher (Flutter Web) target: lesson CRUD, quiz CRUD,
student roster, and access-code **issuance** (the redemption side already
exists from Phase 2 — `AccessCodeService.redeem`). Desktop-appropriate
layouts (real tables, keyboard-friendly forms), not a stretched phone
screen. Item analysis (PROJECT_FLOW.md Part 7.5) and the PPT/PDF content
pipeline (Part 8) are explicitly **out of scope** — design spec Section 6
assigns both to Phase 5, pending Q1/Q2 client confirmation.

**Architecture:** Same shared-`core/` pattern as Phases 1–3: no new business
rules, only new Firestore-writing capability layered onto Phase 1/2's
read-mostly services, plus new screens. `LessonRepository` and
`StudentRepository` (currently read/merge-only) gain create/update/archive
methods; a new `QuizRepository` and `AccessCodeIssuanceService` are added
from scratch. `main.dart`'s `kIsWeb` placeholder (`Text('Teacher shell
(placeholder)')`) is replaced with a real teacher-only `GoRouter` shell,
mirroring `buildStudentRouter`/`StudentShell`'s existing pattern
(`lib/features/student/app/router.dart`) but with a side-nav desktop layout
instead of bottom tabs. Every new Firestore-touching class keeps Phase
1–3's constructor-injection pattern so tests use `fake_cloud_firestore`,
never a live project.

**Tech Stack:** `shadcn_ui` (component base), `data_table_2` (dense
sortable tables), `lucide_icons_flutter`, `flutter_form_builder` +
`form_builder_validators` (CRUD forms), `model_viewer_plus` (`.glb` preview
in the lesson editor). Everything from Phases 1–3 (Riverpod, go_router,
freezed models, `fake_cloud_firestore`, Firebase Auth) continues unchanged.
`cached_network_image` is deferred — nothing in this phase serves images
over a network yet (that's Part 8/Phase 5's Firebase Storage move); adding
it now with no caller would be dead weight, so it's dropped from this
phase's dependency list despite being in the design spec's Phase 4 package
table.

**Spec:** `PROJECT_FLOW.md` Part 2.1/2.2 (target split, desktop layout
requirement), Part 3.1–3.3 (teacher auth — no explicit role field, any
non-student-pattern email is a teacher), Part 4.1/4.2 (data models —
`TeacherLesson`, `TeacherQuiz`, `TeacherQuizQuestion`, `QuizUnlockCode`,
`StudentRecord`; built-in-vs-Firestore merge rule), Part 5 (curriculum is
fixed/built-in, teachers only add *additional* lessons), Part 9 (all of
it — the 3 code types, the 6-step validation order already implemented in
`AccessCodeService.redeem`, and the still-unbuilt issuance side). Design
spec `docs/superpowers/specs/2026-08-28-flutter-ar-science-explorer-design.md`
Section 6 (Phase 4 scope + package list) and Section 5.1 (Teacher Web UI
stack). This plan does not restate their content, only implements it.

## Global Constraints

- **Item analysis and the PPT pipeline are not this phase.** Do not add
  `fl_chart`, `firebase_storage`, or any PPTX-conversion code — those are
  Phase 5, gated on Q1/Q2 client confirmation (design spec Section 7). If a
  screen in this phase needs a placeholder for either (e.g. an "Item
  Analysis" nav entry), it's fine to stub it as a disabled/"coming soon"
  entry, not build the feature.
- **Built-in content is read-only from the Teacher Web UI.** The 24
  built-in lessons (`kBuiltInLessons`) and their pre/post question banks
  (`kPreTestQuestionsByLesson`/`kPostTestQuestionsByLesson`) are compiled
  Dart data, not Firestore documents (PROJECT_FLOW.md Part 4.2) — nothing
  in this phase writes to them. The Lessons/Quizzes screens show built-ins
  merged alongside teacher-authored Firestore docs (reusing
  `LessonRepository.mergedLessons`) but render them with an
  edit-disabled/"built-in" badge, not editable rows.
- **No new access-code *types* or validation rules.** `AccessCodeService.redeem`
  (Phase 2, Part 9.2's 6-step order) is the fixed contract this phase's
  issuance code must write *into*, not modify. Task 5 below documents the
  exact `/unlockCodes` and `/quizUnlockCodes` field shapes `redeem()`
  already reads — issuance must produce documents matching those shapes
  exactly, verified by round-trip tests that call `redeem()` against a
  freshly-issued code.
- **Quiz-retake issuance is guarded.** Part 9.1's type 3: a retake code may
  only be issued for a student who has *already completed* the relevant
  post-test at least once. `AccessCodeIssuanceService` must check this
  (via `QuizAttemptService`/`StudentRecord.quizAttempts`) and refuse
  otherwise — this is a real business rule, not a UI nicety, so it's
  TDD'd, not just a disabled button.
- **Teacher role inference reuses Phase 1's `isStudentEmail`/`AuthService`
  unchanged.** There is still no explicit role field (Part 3.1) — "teacher"
  is simply "signed in, and the email doesn't match the student pattern."
  No new Firestore field, no new Auth custom claim.
- **Desktop layout, not a stretched phone screen** (Part 2.2, restated
  because it's the whole reason `shadcn_ui`/`data_table_2` were chosen
  over reusing the student side's Material 3 + `skeletonizer` stack). Side
  navigation, not bottom tabs; real tables, not stacked cards; forms sized
  for a keyboard and mouse, not touch targets.
- All new Firestore-touching classes take `FirebaseFirestore` (and any
  other dependency) as a constructor parameter (Phase 1–3's established
  pattern) so tests inject `fake_cloud_firestore`.
- Visual design is free within Part 2.2/5.1's constraints (`/impeccable`
  skill for the polish pass, per the design spec's closing note) as long as
  every documented requirement (dense tables, dynamic option-list quiz
  forms, `.glb` preview, positive code-issuance feedback echoing the code)
  is met.

---

## Implementation Status

**Status:** Complete (2026-08-29). All 13 tasks implemented on branch
`worktree-phase1-scaffold-core-auth` in worktree
`.claude/worktrees/phase1-scaffold-core-auth`.

| Task | Commit | Deliverable |
|------|--------|-------------|
| 1 | `ce01728` | Phase 4 UI dependencies (`shadcn_ui`, `data_table_2`, etc.) |
| 2 | `7a1962a` | `QuizRepository` + `DisplayQuiz` merge helper |
| 3 | `deb4f51` | `LessonRepository` create/update/archive + `isArchived` |
| 4 | `dffed66` | `StudentRepository` roster listing |
| 5 | `055fce2` | `AccessCodeIssuanceService` (3 code types, round-trip tested) |
| 6–12 | `3b7e79a` | Teacher auth, `TeacherServices`, shell/router/`main.dart`, Lessons/Quizzes/Students/Access Codes screens + widget tests |
| 6–8 report | `e0edd16` | SDD task-6-report (covers auth/shell/router) |
| 9–10 reports | (in `3b7e79a` tree) | task-9-report, task-10-report |
| 11–12 reports | `3e52410` | SDD task-11/12 reports |
| 13 | — | **`flutter test` 168/168 passing.** Manual Chrome smoke + on-device redeem round-trip still yours — see `MANUAL_STEPS.md` (Firestore teacher write rules added). |

**SDD ledger & artifacts:**
`docs/superpowers/sdd/2026-08-29-phase4-teacher-web/` — `progress.md`,
`task-N-brief.md`, `task-N-report.md`, review diffs per task.

**Spec:** `docs/superpowers/specs/2026-08-28-flutter-ar-science-explorer-design.md`
(Section 6, Phase 4).

---

## File Structure

```
lib/
  core/
    services/
      lesson_repository.dart        # MODIFY: + createLesson/updateLesson/archiveLesson
      student_repository.dart       # MODIFY: + watchAllStudents/createStudent/archiveStudent
      quiz_repository.dart          # NEW: /quizzes CRUD (TeacherQuiz)
      access_code_issuance_service.dart  # NEW: issue the 3 code types
  features/
    teacher/
      app/
        teacher_providers.dart      # NEW: TeacherServices bundle, currentTeacherEmailProvider
        router.dart                 # NEW: buildTeacherRouter
        teacher_shell.dart          # NEW: side-nav desktop shell
      auth/
        teacher_login_screen.dart   # NEW
        teacher_auth_providers.dart # NEW: TeacherAuthViewModel
      lessons/
        lessons_screen.dart         # NEW: data table + create/edit
        lesson_form.dart            # NEW: flutter_form_builder form
        lessons_providers.dart      # NEW
      quizzes/
        quizzes_screen.dart         # NEW
        quiz_form.dart              # NEW: dynamic question list
        quizzes_providers.dart      # NEW
      students/
        students_screen.dart        # NEW
        student_form.dart            # NEW
        students_providers.dart      # NEW
      access_codes/
        access_codes_screen.dart     # NEW: 3 issuance forms + issued-codes table
        access_codes_providers.dart  # NEW
  main.dart                          # MODIFY: replace kIsWeb placeholder with teacher shell
pubspec.yaml                         # MODIFY: + shadcn_ui, data_table_2, lucide_icons_flutter,
                                      #   flutter_form_builder, form_builder_validators,
                                      #   model_viewer_plus
test/
  core/services/
    quiz_repository_test.dart                  # NEW
    lesson_repository_test.dart                 # MODIFY: + CRUD cases
    student_repository_test.dart                # MODIFY: + roster cases
    access_code_issuance_service_test.dart       # NEW
  features/teacher/
    auth/teacher_auth_providers_test.dart        # NEW
    lessons/lessons_screen_test.dart              # NEW
    quizzes/quizzes_screen_test.dart               # NEW
    students/students_screen_test.dart             # NEW
    access_codes/access_codes_screen_test.dart      # NEW
```

---

### Task 1: Add Phase 4 dependencies

**Files:** Modify `pubspec.yaml`.

**Interfaces:** None — this task adds no code, only makes packages
resolvable for later tasks. Not independently testable (same rationale as
Phase 3 Task 1: a dependency with no code using it yet has nothing to
assert against).

- [ ] **Step 1:** Add to `pubspec.yaml` dependencies: `shadcn_ui: ^0.x.x`,
  `data_table_2: ^2.x.x`, `lucide_icons_flutter: ^3.x.x`,
  `flutter_form_builder: ^9.x.x`, `form_builder_validators: ^11.x.x`,
  `model_viewer_plus: ^1.x.x` — check pub.dev for each package's actual
  latest version before writing it in (Phase 3 hit a real version mismatch
  doing this from memory; don't repeat that).
- [ ] **Step 2:** Run `flutter pub get`, confirm it resolves with no
  conflicts against the existing Riverpod/Firebase/go_router versions.
- [ ] **Step 3:** Run `flutter test` (full suite) — expect all existing
  tests still pass unchanged; this step only proves the dependency add
  didn't break anything already built.
- [ ] **Step 4:** Commit: `deps: add Teacher Web UI packages (Phase 4)`.

---

### Task 2: `QuizRepository` — Firestore CRUD for teacher-authored quizzes

**Files:**
- Create: `lib/core/services/quiz_repository.dart`
- Test: `test/core/services/quiz_repository_test.dart`

**Interfaces:**
- Produces: `QuizRepository` class, consumed by Task 10 (quizzes screen)
  and Task 5 (issuance eligibility checks may need to resolve a quiz by
  lesson id).
- Consumes: `TeacherQuiz`/`TeacherQuizQuestion` (existing, `lib/core/models/`),
  `FirebaseFirestore`.

```dart
class QuizRepository {
  QuizRepository({required FirebaseFirestore firestore});

  Stream<List<TeacherQuiz>> watchTeacherQuizzes();
  Future<List<TeacherQuiz>> fetchTeacherQuizzes();
  Future<void> createQuiz(TeacherQuiz quiz);
  Future<void> updateQuiz(TeacherQuiz quiz);
  Future<void> deleteQuiz(String quizId);

  /// Merges built-in question banks (kPreTestQuestionsByLesson/
  /// kPostTestQuestionsByLesson, passed in — this class doesn't import
  /// curriculum_data.dart directly, mirroring LessonRepository.mergedLessons'
  /// existing pattern of taking built-ins as a parameter, not a global) with
  /// Firestore-authored TeacherQuiz docs into one display list. Built-in
  /// entries are synthesized as read-only TeacherQuiz-shaped view records —
  /// exact return type decided during implementation (a small
  /// `DisplayQuiz`/`(TeacherQuiz, {required bool isBuiltIn})` pair is
  /// probably simplest; don't force built-ins into the real TeacherQuiz
  /// freezed type just to satisfy this one screen).
}
```

- [ ] **Step 1: Write failing tests** for `createQuiz`/`updateQuiz`/
  `deleteQuiz`/`watchTeacherQuizzes`/`fetchTeacherQuizzes` against
  `fake_cloud_firestore`, following `lesson_repository_test.dart`'s
  existing style for the read/watch cases.
- [ ] **Step 2:** Run `flutter test test/core/services/quiz_repository_test.dart`
  — expect FAIL (class doesn't exist).
- [ ] **Step 3:** Implement `quiz_repository.dart` writing to `/quizzes`
  (Part 4.2's collection map), doc id = `TeacherQuiz.id`.
- [ ] **Step 4:** Run the test file again — expect PASS.
- [ ] **Step 5:** Run `flutter analyze` — no new lints.
- [ ] **Step 6:** Commit: `feat(teacher): add QuizRepository CRUD for /quizzes`.

---

### Task 3: Extend `LessonRepository` with teacher-authored CRUD

**Files:**
- Modify: `lib/core/services/lesson_repository.dart`
- Modify: `test/core/services/lesson_repository_test.dart`

**Interfaces:**
- Produces: three new methods on the existing `LessonRepository` class
  (Task 9 consumes them).
- Consumes: `TeacherLesson` (existing model).

```dart
Future<void> createLesson(TeacherLesson lesson);
Future<void> updateLesson(TeacherLesson lesson);
Future<void> archiveLesson(String lessonId); // soft delete — see note below
```

Note on delete semantics: `TeacherLesson` has no `isArchived` field today
(unlike `StudentRecord`/`QuizUnlockCode`, which do). Decide during
implementation whether to (a) add `isArchived` to `TeacherLesson` — a small,
backward-compatible freezed model change with a default of `false` — or
(b) hard-delete the Firestore doc. Given lessons may already be linked from
`linkedQuizId`/students' `unlockedLessonIds` by the time a teacher wants to
remove one, prefer (a): archive, don't hard-delete, and filter archived
lessons out of `mergedLessons()`'s default output (add an
`includeArchived` parameter defaulting to `false`, mirroring how
`StudentRepository`/roster listing will need the same distinction in Task 4).

- [ ] **Step 1: Write failing tests** for create/update/archive, plus a
  case proving `mergedLessons()` excludes archived teacher lessons by
  default but includes them when `includeArchived: true`.
- [ ] **Step 2:** Run `flutter test test/core/services/lesson_repository_test.dart`
  — expect FAIL.
- [ ] **Step 3:** Implement. If adding `isArchived` to `TeacherLesson`,
  regenerate freezed/json_serializable output
  (`dart run build_runner build --delete-conflicting-outputs`).
- [ ] **Step 4:** Run the test file again — expect PASS.
- [ ] **Step 5:** Run full `flutter test` — confirm no regression in
  Phase 2/3 tests that construct `TeacherLesson` (the new field must have
  a safe default so existing call sites/fixtures don't break).
- [ ] **Step 6:** Commit: `feat(teacher): add create/update/archive to LessonRepository`.

---

### Task 4: Extend `StudentRepository` with roster listing

**Files:**
- Modify: `lib/core/services/student_repository.dart`
- Modify: `test/core/services/student_repository_test.dart`

**Interfaces:**

```dart
Stream<List<StudentRecord>> watchAllStudents({bool includeArchived = false});
Future<void> createStudent(StudentRecord student);
Future<void> archiveStudent(String studentId); // sets isUsed=true... no —
  // sets StudentRecord.isArchived = true (field already exists, unlike
  // TeacherLesson — see Task 3's note). Pure update, no new field needed.
```

- [ ] **Step 1: Write failing tests**: `watchAllStudents` returns all
  non-archived students by default, all when `includeArchived: true`;
  `createStudent` writes a new doc keyed by `StudentRecord.studentId`;
  `archiveStudent` flips `isArchived` without touching any other field
  (scores, `quizAttempts`, unlock lists must survive untouched — assert
  this explicitly, since Part 9/7's logic elsewhere depends on those lists
  never being silently reset).
- [ ] **Step 2:** Run `flutter test test/core/services/student_repository_test.dart`
  — expect FAIL.
- [ ] **Step 3:** Implement against `/students` (Part 4.2).
- [ ] **Step 4:** Run again — expect PASS.
- [ ] **Step 5:** Commit: `feat(teacher): add roster listing to StudentRepository`.

---

### Task 5: `AccessCodeIssuanceService` — the three code types

This is the highest-risk task in the phase: it must produce documents
matching exactly what `AccessCodeService.redeem` (Phase 2,
`lib/core/services/access_code_service.dart`) already reads, or issued
codes will silently fail to redeem. Every test in this task should
round-trip through the real `redeem()` method, not just assert on the
written Firestore doc shape in isolation.

**Files:**
- Create: `lib/core/services/access_code_issuance_service.dart`
- Test: `test/core/services/access_code_issuance_service_test.dart`

**Interfaces:**
- Produces: `AccessCodeIssuanceService`, consumed by Task 11 (access codes
  screen).
- Consumes: `AccessCodeService` (Phase 2, for round-trip tests only — the
  issuance service itself writes directly to Firestore, it does not call
  `redeem`), `QuizAttemptService`/`StudentRepository` (for the retake
  eligibility guard), `quiz_id.dart`'s `builtinQuizId`.

**Exact schemas to write** (reverse-engineered from `redeem()`'s reads —
restated here so this task's implementer doesn't have to re-read that file
line by line):

`/unlockCodes/{code}` (doc id **is** the code string, uppercase):
```
{
  "type": "subject" | "lesson",       // "quiz" type also read by redeem()
                                        // step 5, but this service issues
                                        // retake codes via /quizUnlockCodes
                                        // instead (cleaner typed model,
                                        // see Global Constraints) — do not
                                        // also implement the "quiz" /unlockCodes
                                        // path unless a later task finds a
                                        // concrete reason redeem() step 5 vs
                                        // step 1 matters for this app.
  "subjects": ["chemistry"],           // full-subject code (type: subject, no lessonIds)
  "lessonIds": ["q1w1", "q1w2"],       // subject code w/ explicit lesson list (type: subject)
  "targetId": "q1w3",                  // single-lesson code (type: lesson)
  "targetStudentId": "123456",         // present only for a student-targeted code
  "usedByStudentIds": [],              // always start empty
  "isUsed": false                      // unused by redeem() for type != "quiz", but
                                        // write it anyway for schema consistency
}
```

`/quizUnlockCodes/{autoId}` (auto-generated doc id — matches existing
`QuizUnlockCode` model exactly, use its own `toJson()`):
```dart
QuizUnlockCode(
  id: ..., // Firestore auto-id
  quizId: builtinQuizId(lessonId, QuizPhase.post), // retakes are always post-test (Part 7.1)
  studentId: studentId,
  code: generatedCode,
  generatedAt: DateTime.now().toIso8601String(),
  isUsed: false,
)
```

**Proposed public API:**

```dart
class AccessCodeIssuanceService {
  AccessCodeIssuanceService({
    required FirebaseFirestore firestore,
    required QuizAttemptService quizAttemptService,
  });

  /// Type 1 — subject/lesson-wide, untargeted. lessonIds null/empty = whole subject.
  Future<String> issueSubjectCode({
    required List<String> subjects,
    List<String>? lessonIds,
    String? customCode, // teacher may want a memorable code; else auto-generate
  });

  /// Type 2 — single lesson, targeted to one student.
  Future<String> issueLessonCode({
    required String lessonId,
    required String studentId,
    String? customCode,
  });

  /// Type 3 — quiz retake, targeted, one-time-use. Throws
  /// StateError/returns a typed failure if the student has no recorded
  /// attempt yet on this lesson's post-test (Part 9.1's hard requirement).
  Future<String> issueQuizRetakeCode({
    required String lessonId,
    required String studentId,
  });

  Stream<List<Map<String, dynamic>>> watchIssuedUnlockCodes(); // for the codes table
  Stream<List<QuizUnlockCode>> watchIssuedRetakeCodes();
}
```

- [ ] **Step 1: Write failing tests**, each as a full round-trip:
  1. `issueSubjectCode` (whole-subject variant) → call the real
     `AccessCodeService.redeem` with a student not in any target list →
     succeeds, matches redeem() step 3's success message.
  2. `issueSubjectCode` with `lessonIds` → `redeem()` targeting a lesson
     in the list succeeds (step 2); targeting a lesson NOT in the list
     fails with the "isn't valid for this lesson" message.
  3. `issueLessonCode` → `redeem()` from the targeted student succeeds
     (step 6); from a different student fails with the
     "assigned to a different student" message (this is the
     `targetStudentId` mismatch path already in `redeem()`).
  4. `issueQuizRetakeCode` when the student has **zero** attempts on that
     lesson's post-test → throws/returns failure, **no document written**.
  5. `issueQuizRetakeCode` when the student has ≥1 recorded post-test
     attempt → succeeds, and the resulting code round-trips through
     `redeem()`'s step 1 (`AccessCodeTarget.quiz`, `targetId: lessonId`)
     successfully, and a second `redeem()` call with the same code fails
     (already used).
  6. A duplicate custom code (teacher types a code that already exists in
     `/unlockCodes`) is rejected or auto-suffixed — decide one behavior and
     test it; don't leave this undefined.
- [ ] **Step 2:** Run `flutter test test/core/services/access_code_issuance_service_test.dart`
  — expect FAIL (class doesn't exist).
- [ ] **Step 3:** Implement, including the random-code generator (e.g. 6
  uppercase alphanumeric characters, collision-checked against
  `/unlockCodes` before writing — reuse the same generator for the
  `/quizUnlockCodes` `code` field for a consistent look).
- [ ] **Step 4:** Run again — expect PASS, all 6+ cases green.
- [ ] **Step 5:** Run the *existing* `access_code_service_test.dart` too —
  confirm zero changes needed there; this task must not modify `redeem()`
  (Global Constraints).
- [ ] **Step 6:** Run `flutter analyze`.
- [ ] **Step 7:** Commit: `feat(teacher): add AccessCodeIssuanceService for the 3 code types`.

---

### Task 6: Teacher auth — sign-in screen + view model

**Files:**
- Create: `lib/features/teacher/auth/teacher_auth_providers.dart`
- Create: `lib/features/teacher/auth/teacher_login_screen.dart`
- Test: `test/features/teacher/auth/teacher_auth_providers_test.dart`

**Interfaces:**
- Produces: `currentTeacherEmailProvider` (`StreamProvider<String?>`,
  mirrors `student_providers.dart`'s `currentStudentIdProvider` exactly but
  inverted — null while signed out *or* while the signed-in email matches
  the student pattern), `TeacherAuthViewModel` (email/password fields,
  submit, error message state).
- Consumes: `AuthService.signInTeacher` (Phase 1, already exists, unused
  until now), `isStudentEmail` (Phase 1).

```dart
final currentTeacherEmailProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) {
    final email = user?.email;
    if (email == null || isStudentEmail(email)) return null;
    return email;
  });
});
```

- [ ] **Step 1: Write failing tests** for `TeacherAuthViewModel`: submit
  with valid credentials calls `AuthService.signInTeacher` and clears any
  prior error; submit with a student-pattern email is rejected client-side
  before even calling `AuthService` (fast, clear feedback — "use the
  student app to sign in" style message, not a generic auth error);
  `AuthService` throwing surfaces as a displayable error message, not an
  unhandled exception.
- [ ] **Step 2:** Run the test — expect FAIL.
- [ ] **Step 3:** Implement `TeacherAuthViewModel` + `teacher_login_screen.dart`
  (email/password `TextField`s + submit button, `shadcn_ui` components,
  centered card layout appropriate for a desktop browser tab, not a mobile
  full-bleed form).
- [ ] **Step 4:** Run again — expect PASS.
- [ ] **Step 5:** Commit: `feat(teacher): add teacher sign-in screen and view model`.

---

### Task 7: `TeacherServices` bundle + provider overrides

**Files:** Create `lib/features/teacher/app/teacher_providers.dart`.

**Interfaces:** Mirrors `student_providers.dart`'s `StudentServices`/
`studentProviderOverridesFor` pattern exactly.

```dart
class TeacherServices {
  const TeacherServices({
    required this.lessonRepository,
    required this.quizRepository,
    required this.studentRepository,
    required this.accessCodeIssuanceService,
  });

  final LessonRepository lessonRepository;
  final QuizRepository quizRepository;
  final StudentRepository studentRepository;
  final AccessCodeIssuanceService accessCodeIssuanceService;
}

List<Override> teacherProviderOverridesFor({required TeacherServices services});
```

- [ ] **Step 1:** Implement `TeacherServices` and the override list,
  wiring each screen's view-model provider (defined in Tasks 9–12) to the
  bundled repositories — same shape as `studentProviderOverridesFor`.
- [ ] **Step 2:** No standalone test file — this is pure DI wiring, verified
  by the screen tests in Tasks 9–12 exercising it end-to-end (same
  rationale as Phase 3 Task 1: wiring-only code isn't independently
  testable in isolation).
- [ ] **Step 3:** Commit: `feat(teacher): add TeacherServices provider bundle`.

---

### Task 8: Teacher shell + router, wired into `main.dart`

**Files:**
- Create: `lib/features/teacher/app/teacher_shell.dart`
- Create: `lib/features/teacher/app/router.dart`
- Modify: `lib/main.dart`

**Interfaces:**

```dart
GoRouter buildTeacherRouter({required TeacherServices services});
```

Route table (side-nav entries, all under one `ShellRoute`):
`/teacher/lessons`, `/teacher/quizzes`, `/teacher/students`,
`/teacher/access-codes` — plus a disabled/greyed "Item Analysis" nav entry
per Global Constraints (no route, just a visible placeholder so the nav
doesn't look incomplete, tooltip explaining it's coming in a later phase).

`main.dart`'s `kIsWeb` branch changes from:
```dart
if (kIsWeb) {
  return const MaterialApp(
    title: 'AR Science Explorer',
    home: Scaffold(body: Center(child: Text('Teacher shell (placeholder)'))),
  );
}
```
to a `Consumer` watching `currentTeacherEmailProvider` — null shows
`TeacherLoginScreen` (Task 6), non-null shows `MaterialApp.router` with
`buildTeacherRouter`, mirroring the Android branch's existing
`currentStudentIdProvider` pattern immediately below it in the same file.

- [ ] **Step 1:** Implement `TeacherShell` — a permanent side navigation
  rail/drawer (desktop-width assumption, Part 2.2) with the 4 real entries
  + 1 disabled entry, `child` as the main content area.
- [ ] **Step 2:** Implement `buildTeacherRouter`.
- [ ] **Step 3:** Modify `main.dart`'s web branch.
- [ ] **Step 4:** Manual smoke check: `flutter run -d chrome`, confirm
  the login screen renders, and (once Tasks 9–12 exist) the 4 nav entries
  route correctly. This step has no automated assertion of its own — it's
  a checkpoint before building screen content in Tasks 9–12, same as how
  Phase 3 treated its Unity export step.
- [ ] **Step 5:** Commit: `feat(teacher): add teacher shell, router, wire into main.dart`.

---

### Task 9: Lessons screen — list + create/edit + `.glb` preview

**Files:**
- Create: `lib/features/teacher/lessons/lessons_screen.dart`
- Create: `lib/features/teacher/lessons/lesson_form.dart`
- Create: `lib/features/teacher/lessons/lessons_providers.dart`
- Test: `test/features/teacher/lessons/lessons_screen_test.dart`

**Interfaces:**
- Produces: `lessonsViewModelProvider` (`StreamProvider` wrapping
  `LessonRepository.watchTeacherLessons()` + `mergedLessons()`,
  exposing `List<(Lesson, {required bool isBuiltIn})>`-shaped display
  rows, or an equivalent small record/class — decided during
  implementation, matching Task 2's same open decision for quizzes).
- Consumes: `LessonRepository` (Task 3), `kBuiltInLessons`.

Screen: `data_table_2` `DataTable2` with columns (Title, Subject,
Quarter/Week, AR?, Built-in?, Actions). Built-in rows show a badge and no
edit/archive action (Global Constraints). Teacher-authored rows get
Edit/Archive icon buttons (`lucide_icons_flutter`).

Form (`flutter_form_builder`): title, subject (dropdown), summary,
content, steps (dynamic string list — reuse the same
add/remove-row pattern the quiz form (Task 10) needs for options/questions,
consider extracting a shared `DynamicStringListField` widget used by both),
quarter/week (numeric), linkedQuizId (dropdown populated from
`QuizRepository`'s teacher-authored quizzes). AR payload section: if the
lesson has (or the teacher sets) a `arPayload.modelIndex`, show a
`model_viewer_plus` `ModelViewer` preview of the corresponding `.glb` asset
from `assets/models/` (Section 4's project structure) so the teacher can
confirm the right model before saving — read-only preview, this phase does
not add UI to *change* which `.glb` file a model index points to, only to
preview the existing mapping.

- [ ] **Step 1: Write failing widget tests**: table renders built-in
  lessons as non-editable, teacher lessons as editable; tapping "Add
  Lesson" opens the form; submitting a valid form calls
  `LessonRepository.createLesson`; editing a row pre-fills the form and
  calls `updateLesson`; archiving a row calls `archiveLesson` and the row
  disappears from the default (non-archived) view.
- [ ] **Step 2:** Run — expect FAIL.
- [ ] **Step 3:** Implement `lessons_providers.dart`, `lesson_form.dart`,
  `lessons_screen.dart`.
- [ ] **Step 4:** Run — expect PASS.
- [ ] **Step 5:** Commit: `feat(teacher): add lessons screen (list, CRUD form, glb preview)`.

---

### Task 10: Quizzes screen — list + create/edit with dynamic questions

**Files:**
- Create: `lib/features/teacher/quizzes/quizzes_screen.dart`
- Create: `lib/features/teacher/quizzes/quiz_form.dart`
- Create: `lib/features/teacher/quizzes/quizzes_providers.dart`
- Test: `test/features/teacher/quizzes/quizzes_screen_test.dart`

**Interfaces:** Same shape as Task 9, backed by `QuizRepository` (Task 2)
instead of `LessonRepository`.

Form: title, subject, phase (pre/post dropdown), topicId, and a **dynamic
list of `TeacherQuizQuestion` editors** — each row: question text, exactly
4 option text fields (`TeacherQuizQuestion.options` is fixed-length-4),
correct-option selector (radio bound to `correctIndex`), hint text, type
(mc/tf dropdown). Add/remove question rows; validate at least 1 question
and every question has all 4 options filled + a selected correct index
before allowing submit (`form_builder_validators`).

- [ ] **Step 1: Write failing widget tests**: table lists built-in banks
  (read-only, synthesized display rows per Task 2's merge helper) and
  teacher quizzes (editable); adding a question row appends one editor
  block; removing one removes it; submit with an incomplete question (a
  blank option) is blocked with a validation message, not silently
  accepted; a complete submit calls `QuizRepository.createQuiz`/`updateQuiz`
  with the exact `TeacherQuiz`/`TeacherQuizQuestion` shape entered.
- [ ] **Step 2:** Run — expect FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run — expect PASS.
- [ ] **Step 5:** Commit: `feat(teacher): add quizzes screen (list, dynamic question-list form)`.

---

### Task 11: Students screen — roster list + create/edit/archive

**Files:**
- Create: `lib/features/teacher/students/students_screen.dart`
- Create: `lib/features/teacher/students/student_form.dart`
- Create: `lib/features/teacher/students/students_providers.dart`
- Test: `test/features/teacher/students/students_screen_test.dart`

**Interfaces:** Backed by `StudentRepository.watchAllStudents`/
`createStudent`/`archiveStudent` (Task 4).

Table columns: Name, Student ID, Grade, Section, Scores (chemistry/
biology/physics, e.g. as three small chips), Archived toggle filter.
Create form: name, studentId (6-digit, reuse
`normalizeStudentIdInput`/the same `00-0000` display mask Part 3.2
specifies for the Android login field, for input consistency), grade,
section. Scores/completion/unlock lists are **not** editable from this
form — those are derived from real quiz/lesson activity and access-code
redemption, not something a teacher hand-edits; the form only covers the
roster-identity fields a teacher actually enters when adding a new
student.

- [ ] **Step 1: Write failing widget tests**: table shows non-archived
  students by default, includes archived when the filter toggle is on;
  create form validates the student ID is exactly 6 digits before
  allowing submit; submit calls `createStudent` with a `StudentRecord`
  that has empty/default `scores`/`completedLessonIds`/etc. (a brand-new
  student has no activity yet); archiving a row calls `archiveStudent`
  and it drops out of the default view.
- [ ] **Step 2:** Run — expect FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run — expect PASS.
- [ ] **Step 5:** Commit: `feat(teacher): add students screen (roster list, create/archive)`.

---

### Task 12: Access Codes screen — issue codes + issued-codes table

**Files:**
- Create: `lib/features/teacher/access_codes/access_codes_screen.dart`
- Create: `lib/features/teacher/access_codes/access_codes_providers.dart`
- Test: `test/features/teacher/access_codes/access_codes_screen_test.dart`

**Interfaces:** Backed by `AccessCodeIssuanceService` (Task 5).

Three issuance forms (tabs or a segmented control to switch between them,
per Part 9.1's 3 types):
1. **Subject/lesson-wide**: subject dropdown, optional lesson multi-select
   (empty = whole subject), optional custom code.
2. **Lesson-specific (targeted)**: student picker (searchable, backed by
   `StudentRepository`), lesson dropdown, optional custom code.
3. **Quiz retake (targeted)**: student picker, lesson dropdown — this form
   must show an inline warning/disable-submit state if the selected
   student has no recorded post-test attempt for the selected lesson yet
   (surfacing Task 5's eligibility guard *before* submit, not just as a
   thrown-error toast after).

On successful issuance: a genuine acknowledgment beat per Part 9.4 —
display the generated code prominently (large, copyable text, not just a
toast that vanishes) so the teacher can immediately relay it to the
student.

Below the forms: a table of previously-issued codes (`watchIssuedUnlockCodes`
+ `watchIssuedRetakeCodes` merged into one list), columns: Code, Type,
Target (student id or "any"), Status (unused/used/archived), Issued At.

- [ ] **Step 1: Write failing widget tests**: each of the 3 forms calls
  the matching `AccessCodeIssuanceService` method with the values entered;
  a successful issuance displays the returned code prominently; the retake
  form's submit is disabled (or errors clearly) when the eligibility guard
  fails, with a message distinct from a generic Firestore error; the
  issued-codes table renders rows from both `/unlockCodes` and
  `/quizUnlockCodes` sources merged.
- [ ] **Step 2:** Run — expect FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run — expect PASS.
- [ ] **Step 5:** Commit: `feat(teacher): add access codes screen (issue 3 types, issued-codes table)`.

---

### Task 13: Run the full test suite and confirm the phase is complete

**Files:** None created — verification only.

- [ ] **Step 1:** Run `flutter test` (full suite) — expect all Phase 1–4
  tests passing, zero regressions in Phase 1–3 tests.
- [ ] **Step 2:** Run `flutter analyze` — zero new warnings/errors.
- [ ] **Step 3:** Manual smoke pass on `flutter run -d chrome`: sign in as
  a teacher (a non-student-pattern email/password in the shared Firebase
  project), walk all 4 screens, create one lesson, one quiz, one student,
  issue one of each code type, then switch to the Android build and
  confirm a redeemed code (issued from Task 12's screen) actually unlocks
  content for a real student login — this is the one end-to-end check
  proving Task 5's schemas truly interop with Phase 2's `redeem()`, not
  just against each other's own tests.
- [ ] **Step 4:** Check `MANUAL_STEPS.md` — add a note (if not already
  covered) that Firestore security rules must permit a **teacher-role**
  (non-student-pattern email) authenticated write to `/lessons`,
  `/quizzes`, `/students`, `/unlockCodes`, `/quizUnlockCodes` — this repo
  has no `firestore.rules` file today (confirmed absent), so rules are
  presumably managed directly in the Firebase console; flag this as a
  manual verification step here rather than assuming it's already correct.
- [ ] **Step 5:** Checkpoint commit if Step 4 added anything: `docs: note Phase 4 Firestore rules manual step`.

---

## Summary

| Task | Deliverable | TDD? |
|---|---|---|
| 1 | Phase 4 dependencies | No (dependency-only) |
| 2 | `QuizRepository` | Yes |
| 3 | `LessonRepository` CRUD | Yes |
| 4 | `StudentRepository` roster | Yes |
| 5 | `AccessCodeIssuanceService` | Yes (heaviest — round-trips through `redeem()`) |
| 6 | Teacher auth screen + view model | Yes |
| 7 | `TeacherServices` DI bundle | No (wiring-only) |
| 8 | Teacher shell + router + `main.dart` wire-up | No (manual smoke checkpoint) |
| 9 | Lessons screen | Yes |
| 10 | Quizzes screen | Yes |
| 11 | Students screen | Yes |
| 12 | Access codes screen | Yes |
| 13 | Full verification pass | — |
