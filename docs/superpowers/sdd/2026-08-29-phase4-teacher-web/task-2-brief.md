# Task 2 brief — `QuizRepository` (Firestore CRUD for teacher-authored quizzes)

(Copied verbatim from `docs/superpowers/plans/2026-08-29-phase4-teacher-web.md`, Task 2.)

**Files:**
- Create: `lib/core/services/quiz_repository.dart`
- Test: `test/core/services/quiz_repository_test.dart`

**Interfaces:**
- Produces: `QuizRepository` class, consumed by Task 10 (quizzes screen)
  and Task 5 (issuance eligibility checks may need to resolve a quiz by
  lesson id).
- Consumes: `TeacherQuiz`/`TeacherQuizQuestion` (existing, `lib/core/models/`),
  `FirebaseFirestore`.

```dart
class QuizRepository {
  QuizRepository({required FirebaseFirestore firestore});

  Stream<List<TeacherQuiz>> watchTeacherQuizzes();
  Future<List<TeacherQuiz>> fetchTeacherQuizzes();
  Future<void> createQuiz(TeacherQuiz quiz);
  Future<void> updateQuiz(TeacherQuiz quiz);
  Future<void> deleteQuiz(String quizId);

  /// Merges built-in question banks (kPreTestQuestionsByLesson/
  /// kPostTestQuestionsByLesson, passed in — this class doesn't import
  /// curriculum_data.dart directly, mirroring LessonRepository.mergedLessons'
  /// existing pattern of taking built-ins as a parameter, not a global) with
  /// Firestore-authored TeacherQuiz docs into one display list. Built-in
  /// entries are synthesized as read-only TeacherQuiz-shaped view records —
  /// exact return type decided during implementation (a small
  /// `DisplayQuiz`/`(TeacherQuiz, {required bool isBuiltIn})` pair is
  /// probably simplest; don't force built-ins into the real TeacherQuiz
  /// freezed type just to satisfy this one screen).
}
```

- [ ] **Step 1: Write failing tests** for `createQuiz`/`updateQuiz`/
  `deleteQuiz`/`watchTeacherQuizzes`/`fetchTeacherQuizzes` against
  `fake_cloud_firestore`, following `lesson_repository_test.dart`'s
  existing style for the read/watch cases.
- [ ] **Step 2:** Run `flutter test test/core/services/quiz_repository_test.dart`
  — expect FAIL (class doesn't exist).
- [ ] **Step 3:** Implement `quiz_repository.dart` writing to `/quizzes`
  (Part 4.2's collection map), doc id = `TeacherQuiz.id`.
- [ ] **Step 4:** Run the test file again — expect PASS.
- [ ] **Step 5:** Run `flutter analyze` — no new lints.
- [ ] **Step 6:** Commit: `feat(teacher): add QuizRepository CRUD for /quizzes`.
