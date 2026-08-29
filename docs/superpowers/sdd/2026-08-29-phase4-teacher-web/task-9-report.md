# Task 9 report — Lessons screen (list, CRUD form, `.glb` preview)

## Decision: `DisplayLesson` record

Followed Task 2's `DisplayQuiz` precedent and introduced `DisplayLesson`
(`lib/features/teacher/lessons/lessons_providers.dart`) with `lesson`,
`isBuiltIn`, and optional `teacherLesson` (for edit pre-fill). Built-in
detection uses `kBuiltInLessons` id set — same dedupe rule as
`LessonRepository.mergedLessons`.

## TDD evidence

**RED** — added 7 widget tests in
`test/features/teacher/lessons/lessons_screen_test.dart` covering:
- built-in rows show `Built-in` badge, no Edit/Archive tooltips
- teacher-authored rows show Edit/Archive after scroll
- Add Lesson opens dialog with form
- valid submit writes `/lessons/{id}` via `createLesson`
- Q1W1 quarter/week shows test-safe model preview placeholder
- edit pre-fills and calls `updateLesson`
- archive sets `isArchived: true` and removes row from default view

Ran `flutter test test/features/teacher/lessons/lessons_screen_test.dart`
before implementation — compile failures on stub screens/providers. Confirmed RED.

**GREEN** — implemented:
- `lessons_providers.dart` — `buildLessonsViewModel` streams
  `watchTeacherLessons` + `mergedLessons`, exposes CRUD callbacks
- `lesson_form.dart` — `flutter_form_builder` fields + shared
  `DynamicStringListField` for steps; optional AR preview via
  `model_viewer_plus` (test placeholder when `FLUTTER_TEST` set)
- `lessons_screen.dart` — `DataTable2` + `ShadButton`/`ShadBadge`, dialog CRUD
- `lib/core/ar/model_assets.dart` — Q{n}W{n} → `.glb` map (PROJECT_FLOW 6.1)
- wired `lessonsViewModelProvider` in `teacherProviderOverridesFor`

Final run: **7/7 lessons screen tests pass** (`--concurrency=1`).

## Full suite

```
flutter test --concurrency=1
03:14 +168: All tests passed!
```

168/168 (was 139 after Task 5 — +29 from previously uncommitted teacher
screens/tests bundled in the same commit).

## Files changed (Task 9 scope)

- `lib/features/teacher/lessons/lessons_providers.dart`
- `lib/features/teacher/lessons/lesson_form.dart`
- `lib/features/teacher/lessons/lessons_screen.dart`
- `lib/features/teacher/widgets/dynamic_string_list_field.dart` (shared)
- `lib/core/ar/model_assets.dart`
- `lib/features/teacher/app/teacher_providers.dart` (lessons override)
- `test/features/teacher/lessons/lessons_screen_test.dart`

## Commit

`3b7e79a` — `feat(teacher): add lessons and quizzes screens`
(branch `worktree-phase1-scaffold-core-auth`).
