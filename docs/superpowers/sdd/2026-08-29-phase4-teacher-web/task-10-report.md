# Task 10 report — Quizzes screen (list, dynamic question-list form)

## Decision: reuse `DisplayQuiz` from `QuizRepository`

Task 2 already defined `DisplayQuiz` in `lib/core/services/quiz_repository.dart`.
`QuizzesViewModel` reuses it directly rather than introducing a duplicate type.
`buildQuizzesViewModel` pairs `watchTeacherQuizzes` with
`fetchTeacherLessons` + `mergedQuizzes(...)` using `kPreTestQuestionsByLesson` /
`kPostTestQuestionsByLesson`.

## TDD evidence

**RED** — added 7 widget tests in
`test/features/teacher/quizzes/quizzes_screen_test.dart` covering:
- synthesized built-in pre-test rows are read-only (`Built-in` badge)
- teacher quizzes show Edit/Delete
- Add/remove question rows in dynamic form
- incomplete option set blocked with validation message (no Firestore write)
- complete submit writes exact `TeacherQuiz`/`TeacherQuizQuestion` shape
- edit calls `updateQuiz`

Ran `flutter test test/features/teacher/quizzes/quizzes_screen_test.dart`
before implementation — compile failures on stubs. Confirmed RED.

**GREEN** — implemented:
- `quizzes_providers.dart` — `buildQuizzesViewModel` + `quizzesViewModelProvider`
- `quiz_form.dart` — dynamic `QuizQuestionDraft` editors (4 options, radio
  correct index, hint, mc/tf type); controllers on text fields so widget tests
  sync state reliably
- `quizzes_screen.dart` — `DataTable2` list + dialog CRUD
- wired `quizzesViewModelProvider` in `teacherProviderOverridesFor`

Notable test fix: replaced `ChoiceChip` with `Radio<int>` for correct-option
selection — chips did not reliably update `correctIndex` under widget tests.

Final run: **7/7 quizzes screen tests pass** (`--concurrency=1`).

## Full suite

```
flutter test --concurrency=1
03:14 +168: All tests passed!
```

## Files changed (Task 10 scope)

- `lib/features/teacher/quizzes/quizzes_providers.dart`
- `lib/features/teacher/quizzes/quiz_form.dart`
- `lib/features/teacher/quizzes/quizzes_screen.dart`
- `lib/features/teacher/widgets/dynamic_string_list_field.dart` (shared)
- `lib/features/teacher/app/teacher_providers.dart` (quizzes override)
- `test/features/teacher/quizzes/quizzes_screen_test.dart`

## Commit

`3b7e79a` — `feat(teacher): add lessons and quizzes screens`
(branch `worktree-phase1-scaffold-core-auth`).
