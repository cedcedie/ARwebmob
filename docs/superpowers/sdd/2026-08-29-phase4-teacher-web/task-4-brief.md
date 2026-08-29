# Task 4 brief — Extend `StudentRepository` with roster listing

(Copied verbatim from `docs/superpowers/plans/2026-08-29-phase4-teacher-web.md`, Task 4.)

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
