# Task 4 report — Extend `StudentRepository` with roster listing

## Summary

Added `watchAllStudents({bool includeArchived = false})`, `createStudent(StudentRecord student)`,
and `archiveStudent(String studentId)` to `lib/core/services/student_repository.dart`, following
the exact pattern already established by `LessonRepository` (Task 3).

- `StudentRecord.isArchived` already existed (confirmed by reading
  `lib/core/models/student_record.dart` first, per the brief's instruction) — no model change
  was needed, unlike Task 3's `TeacherLesson`.
- `createStudent` delegates to the existing `saveStudent` (both write the full doc via
  `.set(student.toJson())`), avoiding duplicate logic.
- `archiveStudent` uses a partial `.update({'isArchived': true})`, not `.set()`, so no other
  field can be touched.

## TDD evidence

### RED

Added 4 new tests to `test/core/services/student_repository_test.dart` before touching the
implementation. Running just that file failed to even compile, as expected:

```
test/core/services/student_repository_test.dart:89:31: Error: The method 'watchAllStudents' isn't defined for the type 'StudentRepository'.
test/core/services/student_repository_test.dart:102:31: Error: The method 'watchAllStudents' isn't defined for the type 'StudentRepository'.
test/core/services/student_repository_test.dart:112:16: Error: The method 'createStudent' isn't defined for the type 'StudentRepository'.
test/core/services/student_repository_test.dart:127:16: Error: The method 'archiveStudent' isn't defined for the type 'StudentRepository'.
00:00 +0 -1: Some tests failed.
```

### GREEN

After implementing the three methods, `flutter test test/core/services/student_repository_test.dart`:

```
00:00 +0: getStudent returns null when the document does not exist
00:00 +1: saveStudent writes to /students/{studentId}, then getStudent reads it back
00:00 +2: watchStudent streams updates as the document changes
00:00 +3: watchAllStudents returns only non-archived students by default
00:00 +4: watchAllStudents(includeArchived: true) returns archived students too
00:00 +5: createStudent writes a new doc keyed by studentId
00:00 +6: archiveStudent sets isArchived without touching any other field
00:00 +7: All tests passed!
```

## Full suite

- Before this task's changes: 127 passing (baseline established by prior tasks in this phase;
  not re-verified independently since Task 3 already reported it).
- After this task's changes: **131/131 passing** (127 baseline + 4 new tests added here), zero
  regressions. Full `flutter test` output ended with `+130 ... All tests passed!` (131 total
  tests counted from `+0` through `+130`).

## `flutter analyze`

18 pre-existing issues (7 `invalid_annotation_target` warnings on `@JsonKey` in freezed models,
9 `prefer_initializing_formals` infos on constructors across services — including one
pre-existing info on `student_repository.dart`'s constructor, unrelated to this change — 2
`deprecated_member_use` infos on `RadioListTile`, 1 `unnecessary_import` info in an unrelated
test file). **No new warnings or infos were introduced by this task's changes.**

## `archiveStudent` partial-update proof

The test `archiveStudent sets isArchived without touching any other field` explicitly asserts,
after calling `archiveStudent('123456')`:

- `result.isArchived == true`
- `result.scores == student.scores` (unchanged)
- `result.completedLessonIds == student.completedLessonIds` (unchanged)
- `result.unlockedLessonIds == student.unlockedLessonIds` (unchanged)
- `result.quizAttempts == student.quizAttempts` (unchanged)

This is backed by the implementation using `_students.doc(studentId).update({'isArchived': true})`
(a partial Firestore update) rather than `.set()`, so no other field can be silently reset —
satisfying the hard requirement that Part 9/7's logic elsewhere depends on those lists never
being silently reset.

## Commit

```
dffed66 feat(teacher): add roster listing to StudentRepository
 2 files changed, 84 insertions(+)
```

## Files changed

- `lib/core/services/student_repository.dart` — added `watchAllStudents`, `createStudent`,
  `archiveStudent`.
- `test/core/services/student_repository_test.dart` — added 4 tests covering all three new
  methods, including the explicit "other fields survive archiving" assertion.

## Status: DONE

No concerns. No new model fields needed, no duplicate logic, implementation matches the
established `LessonRepository` pattern from Task 3.
