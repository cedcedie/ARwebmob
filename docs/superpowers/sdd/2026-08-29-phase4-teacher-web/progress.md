# SDD ledger — plan: docs/superpowers/plans/2026-08-29-phase4-teacher-web.md

## Setup

- Working directory: `.claude\worktrees\phase1-scaffold-core-auth` (branch
  `worktree-phase1-scaffold-core-auth`) — same worktree Phases 1–3 were
  built in, continuing that convention rather than creating a new worktree.
- Started while Phase 3 Task 11's `flutter build apk --debug` device-test
  build runs in the background (unrelated — Unity/Gradle native build, no
  file overlap with anything Phase 4 touches). Phase 3 stays open (`t11`)
  until that build and the on-device test are both confirmed; Phase 4
  proceeds in parallel per user instruction.
- Pre-flight conflict scan: the plan was written by this same session
  directly from the design spec + a full codebase context-gathering pass
  (models, services, router pattern, existing teacher placeholder) — see
  the plan's own citations. Scanned once more before Task 1 dispatch for
  contradictions between tasks/Global Constraints: none found. One open
  decision the plan explicitly defers to each task's implementer (not a
  conflict, a flagged choice): whether `TeacherLesson`/quiz "built-in vs
  Firestore" merge helpers return a new small display type or reuse
  existing models with a side flag (Tasks 2 and 9). Left for those tasks'
  implementers per the plan's own wording.
- Scripts referenced by the skill (`scripts/task-brief`, `scripts/review-package`)
  are bash — not directly runnable in this Windows/PowerShell environment
  without WSL/git-bash. Following the same manual substitution already
  established in Phase 3's session: task briefs are hand-copied from the
  plan file into `task-N-brief.md`, and reviewers are handed `git diff`
  output directly (via a file written with the Write tool) instead of a
  `review-package` script run.

## Task log

Task 1: complete (commit `ce01728`, review clean) — added `shadcn_ui
  ^0.56.2`, `data_table_2 ^2.7.2`, `lucide_icons_flutter ^3.1.17`,
  `flutter_form_builder ^10.3.0`, `form_builder_validators ^11.3.0`,
  `model_viewer_plus ^1.10.0`. Deliberately pinned `data_table_2`/
  `flutter_form_builder` below their absolute-latest majors (3.0.0/11.0.0)
  — those require Dart SDK ≥3.13 (this project is on 3.12.0) and migrate
  to Flutter's new standalone `material_ui` package, which would force an
  unrelated app-wide migration. Reviewer confirmed the reasoning is sound
  (checked against `pubspec.lock`'s actual SDK constraint) and confirmed
  `cached_network_image`/`firebase_storage`/`fl_chart` are correctly
  absent. 115/115 tests passing, no regressions.

Task 2: complete (commit `7a1962a`, review: Minor finding only, no fix
  dispatch needed) — `QuizRepository` (`lib/core/services/quiz_repository.dart`),
  `DisplayQuiz` (quiz + isBuiltIn) as the merge return shape, `mergedQuizzes()`
  synthesizing read-only rows from `kPreTestQuestionsByLesson`/
  `kPostTestQuestionsByLesson`. 7 new tests, 122/122 full suite passing.
  Minor (non-blocking) finding logged, not fixed: `_synthesize`'s inline
  `'builtin-$lessonId-${phase.name}'` duplicates `lib/core/quiz_id.dart`'s
  existing   `builtinQuizId()` helper instead of calling it — output is
  byte-for-byte identical (verified: `QuizPhase.firestoreValue` is just
  `name`), so no functional risk, just a DRY nit worth fixing opportunistically
  if `quiz_repository.dart` is touched again later.

Task 3: complete (commit `deb4f51`, review clean) — added `isArchived`
  (`@Default(false)`) to `TeacherLesson`; `createLesson`/`updateLesson`
  (`.set()`) and `archiveLesson` (partial `.update({'isArchived': true})`
  — verified by test to leave all other fields untouched) on
  `LessonRepository`; `mergedLessons(includeArchived: false)` filters
  archived teacher lessons out by default. 127/127 full suite passing.
  Reviewer noted a pre-existing (not introduced here) mangled em-dash
  encoding artifact in the file's doc comments — logged in
  `NICE_TO_HAVES.md`, cosmetic only.

Task 4: complete (commit `dffed66`, review clean) — `watchAllStudents`,
  `createStudent` (delegates to existing `saveStudent`), `archiveStudent`
  (partial `.update({'isArchived': true})`) on `StudentRepository`.
  `StudentRecord.isArchived` already existed, no model change needed.
  131/131 full suite passing.   Reviewer flagged one non-blocking test-strength
  nit (archive test's `quizAttempts` fixture is empty, so it wouldn't catch
  a hypothetical reset-to-`[]` bug) — not fixed, doesn't affect correctness
  since the implementation is a genuine partial update regardless.

Task 5: complete (commit `055fce2`, review clean — reviewer independently
  re-ran all tests + traced schema compatibility line-by-line against the
  real `redeem()` source, not just the report's claims) — `AccessCodeIssuanceService`
  (`issueSubjectCode`/`issueLessonCode`/`issueQuizRetakeCode` +
  `watchIssuedUnlockCodes`/`watchIssuedRetakeCodes`). All 3 issuance
  methods verified to write exactly the fields `redeem()` reads, with
  compatible types, for every one of the 6 required round-trip cases.
  `access_code_service.dart` confirmed untouched. 139/139 full suite
  passing. Reviewer findings, all Minor, none requiring a fix dispatch —
  logged for awareness, especially for Task 12:
  - `issueQuizRetakeCode`/internal helpers throw bare `StateError` on
    failure (duplicate custom code, ineligible retake) rather than
    returning a typed `{success, message}` result like this codebase's
    own `AccessCodeResult` convention elsewhere. **Task 12's screen must
    wrap every issuance call in try/catch** — there's no compiler
    enforcement reminding it to.
  - Code-collision check only queries `/unlockCodes`, not `/quizUnlockCodes`
    — confirmed non-exploitable (a collision would just fail to match
    `redeem()`'s per-quiz/per-student filters, not misredeem), given the
    36^6 code space and this app's real scale.
  - `issueSubjectCode` doesn't guard against `subjects: []` being passed
    (would produce a silently unredeemable code) — low real-world
    likelihood since the parameter is `required`, untested edge case.
  - Two test cases assert `result.success` without also checking the
    exact message string (weaker than ideal, not a defect).

Task 6–8: complete (commit `3b7e79a`, report `e0edd16`) — `TeacherAuthViewModel`
  + `TeacherLoginScreen` (shadcn_ui), `currentTeacherEmailProvider`,
  `TeacherServices` + `teacherProviderOverridesFor`, `TeacherShell` side
  nav (4 routes + disabled Item Analysis placeholder), `buildTeacherRouter`,
  `main.dart` web branch wired. Auth tests in
  `test/features/teacher/auth/teacher_auth_providers_test.dart`.

Task 9: complete (commit `3b7e79a`, report task-9-report.md) —
  `LessonsScreen` + `LessonForm` + `DisplayLesson` provider; built-in
  badge/read-only, teacher CRUD, `model_viewer_plus` GLB preview via
  `lib/core/ar/model_assets.dart`. Widget tests green.

Task 10: complete (commit `3b7e79a`, report task-10-report.md) —
  `QuizzesScreen` + dynamic `QuizForm`; built-in synthesized rows read-only.
  Widget tests green (some off-screen tap warnings in quiz form test, non-fatal).

Task 11: complete (commit `3b7e79a`, report `3e52410`) — `StudentsScreen`,
  6-digit student ID validation, archived filter, create/archive. Widget
  tests green.

Task 12: complete (commit `3b7e79a`, report `3e52410`) — `AccessCodesScreen`,
  3 issuance forms, prominent code display, retake eligibility guard UI,
  merged issued-codes table, `StateError` catch for duplicate custom codes.
  Widget tests green.

Task 13: automated complete (this report) — **`flutter test` 168/168
  passing**; `flutter analyze` 34 issues (info-level deprecations only after
  fixing 3 Phase-4 warnings). `MANUAL_STEPS.md` updated with Firestore
  teacher-write rules checklist. **Manual still open:** Chrome smoke walk +
  on-device redeem round-trip (user).
