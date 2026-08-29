# Task 3 report — Extend `LessonRepository` with teacher-authored CRUD

## Decision: soft-delete via `isArchived`

Followed the brief's recommendation and added `@Default(false) bool isArchived`
to the `TeacherLesson` freezed model (`lib/core/models/teacher_lesson.dart`),
rather than hard-deleting Firestore docs. Rationale (matches the brief):
lessons may already be referenced elsewhere by id (`linkedQuizId`, students'
`unlockedLessonIds`), so hard-deleting the doc would leave dangling
references. This also mirrors the existing pattern already used by
`StudentRecord.isArchived` and `QuizUnlockCode.isArchived` — same
`@Default(false) bool isArchived` field style.

Regenerated freezed/json_serializable output with
`dart run build_runner build --delete-conflicting-outputs` — succeeded with
no errors (30 outputs written, only `teacher_lesson.freezed.dart` /
`teacher_lesson.g.dart` among them relevant to this change).

## TDD evidence

**RED** — wrote 5 new tests in
`test/core/services/lesson_repository_test.dart`:
- `createLesson writes a doc at /lessons/{lesson.id}`
- `updateLesson overwrites the existing doc`
- `archiveLesson sets isArchived: true without altering other fields`
  (asserts `title`/`subject`/`summary` are unchanged while `isArchived`
  flips to `true`)
- `mergedLessons excludes archived teacher lessons by default`
- `mergedLessons includes archived teacher lessons when includeArchived: true`

Ran `flutter test test/core/services/lesson_repository_test.dart` before
implementing — failed to compile with 4 errors: `createLesson`, `updateLesson`,
`archiveLesson` undefined on `LessonRepository`, and `includeArchived` not a
recognized named parameter on `mergedLessons`. Confirmed RED.

**GREEN** — implemented on `LessonRepository`
(`lib/core/services/lesson_repository.dart`):
- `Future<void> createLesson(TeacherLesson lesson)` — `set()`s
  `lesson.toJson()` at `/lessons/{lesson.id}`.
- `Future<void> updateLesson(TeacherLesson lesson)` — same `set()` call
  (overwrite semantics), i.e. same implementation as `createLesson` since
  Firestore's `set()` naturally covers both create and full-overwrite.
- `Future<void> archiveLesson(String lessonId)` — `update({'isArchived': true})`,
  a partial update that leaves all other fields untouched (verified by the
  RED/GREEN test explicitly).
- `mergedLessons(List<TeacherLesson> teacherLessons, {bool includeArchived = false})` —
  added the `includeArchived` parameter; filters out `tl.isArchived` entries
  unless `includeArchived` is `true`.

Ran `flutter test test/core/services/lesson_repository_test.dart` again — all
8 tests (3 pre-existing + 5 new) passed. Confirmed GREEN.

## Full suite results

Ran `flutter test` (whole suite) after implementation:

```
00:32 +127: All tests passed!
```

127/127 tests passed, **zero regressions**. Searched the entire repo
(`lib/` and `test/`) for other `TeacherLesson(` construction call sites
before making the change — found only the one file already covered by
`lesson_repository_test.dart`, so no other call sites needed touching. The
`@Default(false)` on the new `isArchived` field meant no existing
construction call broke.

(Did not have a "before" count from a separate pre-change full-suite run
since the model change and test additions were done together per the brief's
step ordering — the relevant regression check is the full 127-test green run
above, which includes every pre-existing Phase 1–3 test.)

## `flutter analyze`

Ran `flutter analyze` — reports 18 pre-existing issues (7 `invalid_annotation_target`
warnings on unrelated `@JsonKey` usages, 6 `prefer_initializing_formals` info
notices including one on `lesson_repository.dart`'s pre-existing constructor,
2 `deprecated_member_use` info notices in `quiz_player_screen.dart`, 1
`unnecessary_import` info notice in `scan_tab_test.dart`). None of these
relate to the new `isArchived` field or the three new `LessonRepository`
methods added in this task — all pre-exist this change. No new
warnings/errors introduced.

## Files changed

- `lib/core/models/teacher_lesson.dart` — added `@Default(false) bool isArchived`.
- `lib/core/models/teacher_lesson.freezed.dart`, `teacher_lesson.g.dart` — regenerated.
- `lib/core/services/lesson_repository.dart` — added `createLesson`,
  `updateLesson`, `archiveLesson`, and `includeArchived` param on
  `mergedLessons`.
- `test/core/services/lesson_repository_test.dart` — added 5 new tests.

No other call sites required changes.

## Commit

`deb4f51` — "feat(teacher): add create/update/archive to LessonRepository"
(branch `worktree-phase1-scaffold-core-auth`).
