# Task 3 brief — Extend `LessonRepository` with teacher-authored CRUD

(Copied verbatim from `docs/superpowers/plans/2026-08-29-phase4-teacher-web.md`, Task 3.)

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
