# Task 11 report — Students screen (roster list, create/archive)

**Commit:** `3b7e79a` — bundled in `feat(teacher): add lessons and quizzes screens` (includes Tasks 9–12 teacher UI)

**Files:**
- `lib/features/teacher/students/students_providers.dart`
- `lib/features/teacher/students/student_form.dart`
- `lib/features/teacher/students/student_id_format.dart`
- `lib/features/teacher/students/students_screen.dart`
- `test/features/teacher/students/students_screen_test.dart`

## Deliverables

- **Roster table** (`DataTable2`): Name, Student ID (`00-0000` display via `formatStudentIdForDisplay`), Grade, Section, per-subject score chips (Chem/Bio/Phys), Archive action.
- **Archived filter** via `studentsIncludeArchivedProvider` + `FilterChip`; wired through `teacherProviderOverridesFor`.
- **Create form** (`StudentFormSheet`): name, studentId (6-digit validation + `StudentIdInputFormatter` mask), grade, section only. Submits `blankStudentRecord()` with empty scores/activity lists.
- **Archive** calls `StudentRepository.archiveStudent` per row.

## TDD evidence

**Widget tests** (`students_screen_test.dart`, 6 tests):
1. Table shows non-archived students by default.
2. Archived filter toggle calls include-archived handler.
3. Table includes archived students when `includeArchived: true`.
4. Create form rejects student IDs that are not exactly 6 digits.
5. Submit calls `createStudent` with empty/default activity fields (verified via `FakeFirebaseFirestore`).
6. Archive button invokes `onArchiveStudent` with the row's student id.

All 6 pass (`flutter test test/features/teacher/students/students_screen_test.dart`).

## Provider wiring

`studentsViewModelProvider` and `studentsIncludeArchivedProvider` registered in `teacherProviderOverridesFor` (`lib/features/teacher/app/teacher_providers.dart`).

## Full suite

168/168 tests passing after Task 11+12 (`flutter test --reporter compact`).

## Status

**DONE**
