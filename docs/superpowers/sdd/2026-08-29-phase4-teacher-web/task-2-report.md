# Task 2 report — `QuizRepository` (Firestore CRUD for teacher-authored quizzes)

## Status: DONE

## Files
- Created: `lib/core/services/quiz_repository.dart`
- Created: `test/core/services/quiz_repository_test.dart`

## TDD evidence

### RED — `flutter test test/core/services/quiz_repository_test.dart` before implementation

Compilation failed as expected, class didn't exist yet:

```
test/core/services/quiz_repository_test.dart:11:8: Error: Error when reading 'lib/core/services/quiz_repository.dart': The system cannot find the file specified
  import 'package:ar_science_explorer/core/services/quiz_repository.dart';
         ^
test/core/services/quiz_repository_test.dart:34:18: Error: Method not found: 'QuizRepository'.
    final repo = QuizRepository(firestore: firestore);
...
00:00 +0 -1: Some tests failed.
```

(This run also caught a test-file bug of mine — a missing required `steps` param on
a `Lesson(...)` literal used in the `mergedQuizzes` test — fixed before moving on to
GREEN, unrelated to the RED-for-missing-class check itself.)

### GREEN — `flutter test test/core/services/quiz_repository_test.dart` after implementation

```
00:00 +0: createQuiz writes a doc under /quizzes/{quiz.id}
00:00 +1: updateQuiz overwrites an existing doc
00:00 +2: deleteQuiz removes a doc
00:00 +3: watchTeacherQuizzes streams /quizzes documents as TeacherQuiz
00:00 +4: fetchTeacherQuizzes returns a one-shot list of TeacherQuiz
00:00 +5: mergedQuizzes synthesizes a built-in display quiz per lesson+phase bank
00:00 +6: mergedQuizzes appends teacher-authored quizzes after built-ins
00:00 +7: All tests passed!
```

All 7 tests pass.

## Design decision: the built-in-merge method

The brief left the return shape of the `mergedLessons`-analog method open. I added:

```dart
class DisplayQuiz {
  const DisplayQuiz({required this.quiz, required this.isBuiltIn});
  final TeacherQuiz quiz;
  final bool isBuiltIn;
}

List<DisplayQuiz> mergedQuizzes({
  required List<TeacherQuiz> teacherQuizzes,
  required List<Lesson> lessons,
  required Map<String, List<BuiltInQuestion>> preTestQuestionsByLesson,
  required Map<String, List<BuiltInQuestion>> postTestQuestionsByLesson,
});
```

Rationale:
- Unlike lessons (one built-in list, one shape), the built-in question banks are
  keyed by lesson id and split pre/post, with a structurally different model
  (`BuiltInQuestion`, not `TeacherQuiz`). Forcing a synthesized bank into a "real"
  `TeacherQuiz` and pretending it round-trips to Firestore felt wrong — a teacher
  screen needs to know which rows are actually editable/deletable and which are
  read-only curriculum content. `DisplayQuiz.isBuiltIn` makes that explicit for the
  consuming UI (Task 10) without adding an "isBuiltIn" field to the real
  `TeacherQuiz` freezed model (which would leak a UI-only concern into the
  Firestore-persisted shape).
- I still reuse the real `TeacherQuiz`/`TeacherQuizQuestion` types *inside*
  `DisplayQuiz.quiz` (rather than inventing a third parallel model) so a display
  list is just `List<DisplayQuiz>` and the UI can render both kinds uniformly
  (title, subject, question count, phase) via the same `.quiz` accessor.
- One synthesized `DisplayQuiz` per lesson **+ phase** that has a non-empty bank
  (so a lesson with both a pre- and post-test bank produces two rows, e.g.
  `builtin-q1w1-pre` / `builtin-q1w1-post`), titled `"<lesson title> Pre-Test"` /
  `"<lesson title> Post-Test"` — this mirrors how the built-in banks are actually
  structured (separate pre/post maps) rather than trying to merge pre+post into one
  quiz per lesson, which the data doesn't support cleanly (they're different
  question sets).
- Built-ins are ordered before Firestore-authored quizzes (pre-test banks, then
  post-test banks, then authored quizzes) — same "built-in first" convention as
  `LessonRepository.mergedLessons`.
- This class still takes the built-in maps as parameters rather than importing
  `curriculum_data.dart` directly, per the brief's explicit instruction, mirroring
  `LessonRepository.mergedLessons`'s existing pattern.
- Synthesized ids use a `builtin-<lessonId>-<phase>` prefix so callers (and future
  code, e.g. Task 5's eligibility checks) can recognize/filter built-in rows by id
  shape alone if needed, without relying on `isBuiltIn` always being threaded
  through.

This is not consumed by any other task yet (Task 10 will use it), so per the brief
this is a documented, reasonable choice that can be revisited then if the actual UI
needs something different.

## `flutter analyze`

18 issues found, all pre-existing (verified against files untouched by this task) —
`invalid_annotation_target` warnings on other freezed models, `deprecated_member_use`
on `quiz_player_screen.dart`, `unnecessary_import` on an existing test file, and
`prefer_initializing_formals` info-level notices on constructor bodies across
multiple existing services. My new `quiz_repository.dart` triggers exactly one
`prefer_initializing_formals` info notice, for the same
`FirebaseFirestore firestore) : _firestore = firestore` constructor pattern already
used verbatim in `lesson_repository.dart` (and 4 other existing services) — i.e. it
matches the established, currently-accepted codebase style rather than introducing a
new problem. No new warning/error *categories* were introduced.

## Full suite

- Before this task (per brief): 115/115 passing.
- After this task: **122/122 passing** (115 pre-existing + 7 new
  `quiz_repository_test.dart` tests). Zero regressions.

## Commit

```
7a1962a feat(teacher): add QuizRepository CRUD for /quizzes
 2 files changed, 270 insertions(+)
 create mode 100644 lib/core/services/quiz_repository.dart
 create mode 100644 test/core/services/quiz_repository_test.dart
```

## Concerns

None blocking. One note for whoever implements Task 10 (quizzes screen): the
`DisplayQuiz.isBuiltIn` flag is the intended signal for whether to show edit/delete
UI on a row — please don't try to route built-in rows through `updateQuiz`/
`deleteQuiz` (their synthesized ids like `builtin-q1w1-pre` don't correspond to any
real Firestore doc).
