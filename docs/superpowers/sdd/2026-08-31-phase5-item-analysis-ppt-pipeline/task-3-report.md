# Task 3 Report: Item analysis screen (fl_chart) + teacher-quiz question resolution

## Summary

Implemented per the brief with one necessary correction (fl_chart API name)
and one addition beyond the brief's explicit steps (actually wiring the
`.family` provider override + a route, since a "navigate to it" link is
useless if the destination throws `UnimplementedError`).

## What was implemented

1. **`pubspec.yaml`**: added `fl_chart: ^0.69.0`; ran `flutter pub get`
   (resolved to 0.69.2, recorded in `pubspec.lock`).

2. **`lib/features/teacher/quizzes/item_analysis_providers.dart`**: replaced
   `buildItemAnalysisViewModel` with the brief's `async*` version — adds a
   required `QuizRepository quizRepository` parameter, resolves non-built-in
   quiz ids via `quizRepository.fetchQuizById` +
   `quizRepository.questionsFromTeacherQuiz(teacherQuiz, lessonId: quizId)`,
   and falls back to an empty question list when `fetchQuizById` returns
   `null`. `itemAnalysisViewModelProvider` (the `.family` StreamProvider)
   unchanged.

3. **`lib/features/teacher/quizzes/item_analysis_screen.dart`** (new):
   `ItemAnalysisScreen` (ConsumerWidget) + `_QuestionAnalysisCard`, exactly
   per the brief, with one fix (see Concerns/Deviations below).

4. **Test file updates**
   (`test/features/teacher/quizzes/item_analysis_providers_test.dart`):
   - Updated the two existing Task 2 call sites to pass
     `quizRepository: QuizRepository(firestore: firestore)`.
   - Added a new test, `'resolves a teacher-authored quiz's real questions
     via QuizRepository'`: seeds a `TeacherQuiz` doc via
     `QuizRepository.createQuiz` and a matching `QuizAttempt`, asserts the
     resolved `vm.questions` come from the real teacher quiz, not an empty
     list.
   - Added a second new test beyond the brief's minimum,
     `'degrades to an empty question list for a dangling teacher quiz id'`:
     no quiz doc exists for the id passed in; asserts `vm.questions` is
     empty and nothing crashes. This directly covers the parent's
     self-review question about a dangling/missing teacher quiz.

5. **`test/features/teacher/quizzes/item_analysis_screen_test.dart`** (new):
   the brief's exact widget test — asserts attempt count, question text,
   and the difficulty percentage render.

6. **Wiring the navigation link** (Step 7, `quizzes_screen.dart` +
   supporting files): read the real current `quizzes_screen.dart` first, per
   instructions. Its existing row actions (Edit/Delete) both use
   `showDialog`, but `ItemAnalysisScreen` is a full `Scaffold`+`AppBar`
   designed to be pushed as a route (per the brief's own code), so a dialog
   would be the wrong fit. The codebase's established pattern for
   "navigate to a full screen backed by a `.family` provider that needs
   injected services" is the student side's `arLabOverrideFor` +
   go_router-push pattern (`student_providers.dart` /
   `student/app/router.dart`) — followed that precedent rather than
   inventing a new one:
   - `lib/features/teacher/app/teacher_providers.dart`: added
     `itemAnalysisOverrideFor(quizId, {required quizTitle, required
     services})`, mirroring `arLabOverrideFor`.
   - `lib/features/teacher/app/router.dart`: added
     `GoRoute(path: '/teacher/quizzes/:quizId/item-analysis', ...)` whose
     builder wraps `ItemAnalysisScreen` in a `ProviderScope` overridden with
     `itemAnalysisOverrideFor`; quiz title travels via `state.extra`.
   - `lib/features/teacher/quizzes/quizzes_screen.dart`: added a
     `LucideIcons.barChart` "Item analysis" `IconButton` to every quiz row
     (built-in and teacher-authored alike, since both accumulate attempts)
     that does `context.push('/teacher/quizzes/${quiz.id}/item-analysis',
     extra: quiz.title)`. Widened the Actions column
     (`ColumnSize.S` → `ColumnSize.M`, table `minWidth` 900 → 960) to fit
     the third icon button without a `RenderFlex` overflow (this broke
     existing `quizzes_screen_test.dart` tests until fixed — see TDD
     evidence).

## Deviations from the brief (and why)

- **fl_chart API name fix**: the brief's screen code uses `BarRodData(...)`.
  fl_chart 0.69.2 (resolved from the brief's own `^0.69.0` constraint) has
  no such class — the rod-data class is `BarChartRodData`. Verified by
  grepping the installed package source
  (`fl_chart-0.69.2/lib/src/chart/bar_chart/bar_chart_data.dart`).
  Corrected both call sites in `item_analysis_screen.dart` to
  `BarChartRodData`; everything else in the brief's screen code is used
  verbatim.
- **Provider override + route wiring beyond Step 7's literal text**: Step 7
  only says "add a way to navigate ... to `ItemAnalysisScreen`". Taken
  literally that could mean just a button that pushes the widget with no
  working data source, which would throw `UnimplementedError` immediately
  (the family provider's default throws until overridden — same pattern as
  every other view-model provider in this codebase). Added the override +
  route so the link actually works, since that's clearly the point of "wire
  a link into the existing screen" and the plan's task list didn't have a
  separate task for it.
- **Item analysis button shown for built-in quiz rows too**, not just
  teacher-authored ones: built-in quizzes also produce `QuizAttempt`
  records and item analysis is equally meaningful for them (this mirrors
  how `buildItemAnalysisViewModel` handles both `isBuiltin` and
  teacher-linked ids symmetrically). Edit/Delete stayed gated to
  non-built-in rows, unchanged.
- Did **not** touch `TeacherShell`'s disabled "Item Analysis — Coming in
  Phase 5" nav-rail placeholder; that's a separate future top-level list
  view, out of this task's scope (a per-quiz row link, not a global list).

## TDD evidence

RED (before the fl_chart fix):
```
lib/features/teacher/quizzes/item_analysis_screen.dart:75:23: Error: The
method 'BarRodData' isn't defined for the type '_QuestionAnalysisCard'.
```
GREEN after renaming to `BarChartRodData`:
```
00:02 +5: All tests passed!
```
(item_analysis_screen_test.dart: 1 test, item_analysis_providers_test.dart:
4 tests — 2 original + 2 new)

RED (after adding the third IconButton to quizzes_screen.dart, before
widening the Actions column):
```
01:28 +203 -2: .../quizzes_screen_test.dart: complete submit calls
createQuiz with entered shape [E]
...RenderFlex overflowed...
01:29 +203 -3: ...editing a teacher quiz calls updateQuiz [E]
```
GREEN after `ColumnSize.S` → `ColumnSize.M` / `minWidth` 900 → 960:
```
00:09 +7: All tests passed!
```
(quizzes_screen_test.dart: all 7 tests)

## Full suite

`flutter test`: **206/206 passed**.
`flutter analyze`: 32 pre-existing info/warnings (JsonKey annotation
placement, `prefer_initializing_formals`, deprecated Flutter form-field
APIs, one unrelated `unnecessary_import` in `lessons_screen.dart`) — same
categories/count as before this task's changes, no new issues. The one new
warning this task introduced (`unused_import` for `teacher_quiz.dart` in
`item_analysis_providers.dart`, left over from drafting the import list)
was caught and removed before the final analyze run.

## Self-review (parent's explicit checklist)

1. **Non-built-in quizId resolves via `quizRepository.fetchQuizById` +
   `questionsFromTeacherQuiz`?** Yes — covered by the new
   `'resolves a teacher-authored quiz's real questions via QuizRepository'`
   test: seeds a real `TeacherQuiz` doc, asserts `vm.questions.first.question
   == 'What is H2O?'` (not empty).
2. **Dangling/missing teacher quiz degrades to empty list, not a crash?**
   Yes — covered by the new
   `'degrades to an empty question list for a dangling teacher quiz id'`
   test: no doc seeded for `'missing-quiz'`, `fetchQuizById` returns `null`,
   `vm.questions` asserted `isEmpty`, stream completes normally.
3. **Distractor-rate section only for `QuestionType.mc`, not T/F?** Yes —
   `_QuestionAnalysisCard.build` guards the block with
   `if (question.type == QuestionType.mc && result.distractorRates.isNotEmpty)`,
   unchanged from the brief.

## Files changed

- `pubspec.yaml`, `pubspec.lock`
- `lib/features/teacher/quizzes/item_analysis_providers.dart`
- `lib/features/teacher/quizzes/item_analysis_screen.dart` (new)
- `lib/features/teacher/quizzes/quizzes_screen.dart`
- `lib/features/teacher/app/router.dart`
- `lib/features/teacher/app/teacher_providers.dart`
- `test/features/teacher/quizzes/item_analysis_providers_test.dart`
- `test/features/teacher/quizzes/item_analysis_screen_test.dart` (new)

## Concerns

- None blocking. The two deviations above (fl_chart API name, and going
  slightly past Step 7's literal wording to actually wire the provider
  override + route) were both necessary for the feature to compile and
  function; flagged clearly above for review.
