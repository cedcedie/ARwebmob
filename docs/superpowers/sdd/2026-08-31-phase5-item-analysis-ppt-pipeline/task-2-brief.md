### Task 2: Item analysis provider — resolve attempts + question bank, run the calculator

**Files:**
- Create: `lib/features/teacher/quizzes/item_analysis_providers.dart`
- Test: `test/features/teacher/quizzes/item_analysis_providers_test.dart`

**Interfaces:**
- Consumes: `computeItemAnalysis` (Task 1); `StudentRepository.watchAllStudents`
  (Phase 4 — already exists, used by the roster); `kPreTestQuestionsByLesson`/
  `kPostTestQuestionsByLesson` (Phase 2 Task 1); `QuizRepository.questionsFromTeacherQuiz`
  (the teacher-quiz-reachability fix from this session — read
  `lib/core/services/quiz_repository.dart` to confirm its exact current
  signature before wiring against it, it was added after this plan's initial
  drafting).
- Produces: `class ItemAnalysisViewModel` (`quizTitle`, `questions: List<BuiltInQuestion>`,
  `results: List<QuestionItemAnalysis>`, `attemptCount: int`) and
  `itemAnalysisViewModelProvider` (`.family<ItemAnalysisViewModel, String>`,
  keyed on `quizId`), following the same override-at-app-startup pattern
  every other screen provider in this codebase uses.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/teacher/quizzes/item_analysis_providers_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/quiz_id.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/features/teacher/quizzes/item_analysis_providers.dart';

StudentRecord _studentWith(String id, QuizAttempt attempt) => StudentRecord(
      id: id, name: 'Student $id', studentId: id, grade: '7', section: 'A',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [], completedLabExperimentIds: const [],
      completedQuizIds: const [], unlockedLessonIds: const [], unlockedQuizIds: const [],
      quizAttempts: [attempt],
    );

void main() {
  test('resolves the built-in question bank and every attempt on this quiz', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    final quizId = builtinQuizId('q1w1', QuizPhase.post);

    await studentRepo.saveStudent(_studentWith('111111', QuizAttempt(
      id: 'a1', quizId: quizId, studentId: '111111', attemptNumber: 1,
      score: 100, totalQuestions: 8, correctAnswers: 8,
      answers: const [0, 0, 0, 0, 0, 0, 0, 0],
      timestamp: DateTime(2026, 8, 20).toIso8601String(), locked: true,
    )));
    await studentRepo.saveStudent(_studentWith('222222', QuizAttempt(
      id: 'a2', quizId: quizId, studentId: '222222', attemptNumber: 1,
      score: 0, totalQuestions: 8, correctAnswers: 0,
      answers: const [1, 1, 1, 1, 1, 1, 1, 1],
      timestamp: DateTime(2026, 8, 20).toIso8601String(), locked: true,
    )));

    final stream = buildItemAnalysisViewModel(
      quizId: quizId,
      quizTitle: 'Q1W1 Post-Test',
      studentRepository: studentRepo,
    );
    final vm = await stream.first;

    expect(vm.attemptCount, 2);
    expect(vm.questions, hasLength(8));
    expect(vm.results, hasLength(8));
    expect(vm.results[0].difficultyIndex, closeTo(0.5, 0.0001));
  });

  test('ignores attempts on other quizzes', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    final postId = builtinQuizId('q1w1', QuizPhase.post);
    final preId = builtinQuizId('q1w1', QuizPhase.pre);

    await studentRepo.saveStudent(_studentWith('111111', QuizAttempt(
      id: 'a1', quizId: preId, studentId: '111111', attemptNumber: 1,
      score: 100, totalQuestions: 8, correctAnswers: 8,
      answers: const [0, 0, 0, 0, 0, 0, 0, 0],
      timestamp: DateTime(2026, 8, 20).toIso8601String(), locked: false,
    )));

    final stream = buildItemAnalysisViewModel(
      quizId: postId,
      quizTitle: 'Q1W1 Post-Test',
      studentRepository: studentRepo,
    );
    final vm = await stream.first;

    expect(vm.attemptCount, 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/teacher/quizzes/item_analysis_providers_test.dart`
Expected: FAIL — file doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/features/teacher/quizzes/item_analysis_providers.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/data/curriculum_data.dart';
import '../../../core/models/built_in_question.dart';
import '../../../core/quiz_id.dart';
import '../../../core/services/item_analysis_calculator.dart';
import '../../../core/services/student_repository.dart';

class ItemAnalysisViewModel {
  const ItemAnalysisViewModel({
    required this.quizTitle,
    required this.questions,
    required this.results,
    required this.attemptCount,
  });

  final String quizTitle;
  final List<BuiltInQuestion> questions;
  final List<QuestionItemAnalysis> results;
  final int attemptCount;
}

final itemAnalysisViewModelProvider =
    StreamProvider.autoDispose.family<ItemAnalysisViewModel, String>((ref, quizId) {
  throw UnimplementedError(
    'itemAnalysisViewModelProvider must be overridden at app startup with a '
    'real stream for the given quizId.',
  );
});

Stream<ItemAnalysisViewModel> buildItemAnalysisViewModel({
  required String quizId,
  required String quizTitle,
  required StudentRepository studentRepository,
}) {
  final parsed = parseBuiltinId(quizId);
  final questions = parsed.isBuiltin && parsed.lessonId != null
      ? (parsed.phase.name == 'pre'
          ? kPreTestQuestionsByLesson[parsed.lessonId!] ?? const <BuiltInQuestion>[]
          : kPostTestQuestionsByLesson[parsed.lessonId!] ?? const <BuiltInQuestion>[])
      : const <BuiltInQuestion>[]; // teacher-linked quiz question resolution — see Task 2 note below

  return studentRepository.watchAllStudents(includeArchived: true).map((students) {
    final attempts = [
      for (final student in students)
        for (final attempt in student.quizAttempts)
          if (attempt.quizId == quizId) attempt,
    ];

    return ItemAnalysisViewModel(
      quizTitle: quizTitle,
      questions: questions,
      results: computeItemAnalysis(questions: questions, attempts: attempts),
      attemptCount: attempts.length,
    );
  });
}
```

**Note on teacher-linked quizzes:** this task's test only exercises the
built-in-lesson path (matching what a first implementation needs to prove
the core wiring). If `parsed.isBuiltin` is false (a teacher-authored,
non-`builtin-`-prefixed quiz id), `questions` currently resolves to an
empty list — this is a known, deliberate scope trim for this task, not a
silent gap: item analysis on a teacher-created quiz needs `QuizRepository`
injected and a lookup by raw quiz id, which the next task (screen wiring)
should add once you've re-confirmed `QuizRepository`'s exact current
`getQuiz`/similar method against the real file (it may have changed since
this plan was drafted, per the Global Constraints note above). Do not
implement this speculatively in Task 2 — do it for real in Task 3 once
you're looking at the real, current `QuizRepository` API.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/teacher/quizzes/item_analysis_providers_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/teacher/quizzes/item_analysis_providers.dart \
        test/features/teacher/quizzes/item_analysis_providers_test.dart
git commit -m "feat: item analysis provider — resolve attempts + built-in question bank"
```

---

