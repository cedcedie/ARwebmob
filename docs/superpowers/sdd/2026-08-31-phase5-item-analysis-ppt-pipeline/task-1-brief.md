### Task 1: `ItemAnalysisCalculator` — difficulty, discrimination, distractor math

**Files:**
- Create: `lib/core/services/item_analysis_calculator.dart`
- Test: `test/core/services/item_analysis_calculator_test.dart`

**Interfaces:**
- Consumes: `QuizAttempt` (Phase 2 model — `answers: List<int>`, `score`,
  `studentId`), `BuiltInQuestion` (Phase 1 model — `correctIndex`,
  `options`, `type`). Callers resolve the question bank for a given
  `quizId` themselves (built-in banks via `kPreTestQuestionsByLesson`/
  `kPostTestQuestionsByLesson`, or a teacher-linked quiz via
  `QuizRepository.questionsFromTeacherQuiz` — both already produce
  `List<BuiltInQuestion>`, so this calculator only ever needs that one
  type, never `TeacherQuizQuestion` directly).
- Produces: `class QuestionItemAnalysis` (`questionIndex`, `difficultyIndex`,
  `discriminationIndex`, `distractorRates: Map<int, double>` — option index
  → fraction of students who picked it) and
  `List<QuestionItemAnalysis> computeItemAnalysis({required List<BuiltInQuestion> questions, required List<QuizAttempt> attempts})`.
  Consumed by Task 2's provider.

**Exact formulas (PROJECT_FLOW.md Part 7.5, replicate exactly):**
- Difficulty index: `(students who answered this question correctly) / (total students who attempted this quiz)`.
- Discrimination index: sort students by their total quiz `score`
  descending, top ~27% and bottom ~27% (use `(attempts.length * 0.27).ceil()`,
  minimum 1 student per group if `attempts.length >= 2`), then
  `(top group's correct rate on this question) - (bottom group's correct rate on this question)`.
- Distractor rates: for each wrong option index, `(students who chose it) / (total students who attempted)`. Multiple-choice only — for a `QuestionType.tf` question, still compute it (the formula doesn't care about question type), but Task 3's UI only surfaces it for MC questions per Part 7.5's "optional, multiple-choice only" framing (a UI-layer choice, not a calculator-layer one — the calculator stays generic).

- [ ] **Step 1: Write the failing test**

```dart
// test/core/services/item_analysis_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/built_in_question.dart';
import 'package:ar_science_explorer/core/models/question_type.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/services/item_analysis_calculator.dart';

List<BuiltInQuestion> _twoQuestions() => [
      BuiltInQuestion(
        id: 'q0', subject: SubjectKey.chemistry, lessonId: 'q1w1',
        question: 'Q0', options: const ['A', 'B', 'C', 'D'],
        correctIndex: 0, hint: 'hint', type: QuestionType.mc,
      ),
      BuiltInQuestion(
        id: 'q1', subject: SubjectKey.chemistry, lessonId: 'q1w1',
        question: 'Q1', options: const ['A', 'B', 'C', 'D'],
        correctIndex: 1, hint: 'hint', type: QuestionType.mc,
      ),
    ];

QuizAttempt _attempt(String studentId, int score, List<int> answers) => QuizAttempt(
      id: 'attempt-$studentId', quizId: 'builtin-q1w1-post', studentId: studentId,
      attemptNumber: 1, score: score, totalQuestions: 2, correctAnswers: 0,
      answers: answers, timestamp: DateTime(2026, 8, 20).toIso8601String(), locked: true,
    );

void main() {
  test('difficulty index is the fraction of students correct on each question', () {
    final attempts = [
      _attempt('1', 100, [0, 1]), // both correct
      _attempt('2', 50, [0, 2]),  // q0 correct, q1 wrong
      _attempt('3', 50, [3, 1]),  // q0 wrong, q1 correct
      _attempt('4', 0, [3, 2]),   // both wrong
    ];

    final result = computeItemAnalysis(questions: _twoQuestions(), attempts: attempts);

    expect(result[0].difficultyIndex, closeTo(2 / 4, 0.0001)); // q0: students 1,2 correct
    expect(result[1].difficultyIndex, closeTo(2 / 4, 0.0001)); // q1: students 1,3 correct
  });

  test('discrimination index compares top-scoring vs bottom-scoring groups', () {
    // 10 students, scores 100 down to 10 in steps of 10 — top ~27% = 3, bottom ~27% = 3.
    final attempts = List.generate(10, (i) {
      final score = 100 - i * 10;
      // Question 0: only the top 3 scorers (i = 0,1,2) answer it correctly.
      final q0Correct = i < 3;
      return _attempt('$i', score, [q0Correct ? 0 : 1, 0]);
    });

    final result = computeItemAnalysis(questions: _twoQuestions(), attempts: attempts);

    // Top group (highest 3 scores) got q0 100% correct; bottom group (lowest 3) got it 0%.
    expect(result[0].discriminationIndex, closeTo(1.0, 0.0001));
  });

  test('distractor rates report the fraction choosing each wrong option', () {
    final attempts = [
      _attempt('1', 0, [1, 0]), // chose option 1 for q0
      _attempt('2', 0, [1, 0]), // chose option 1 for q0
      _attempt('3', 0, [2, 0]), // chose option 2 for q0
      _attempt('4', 100, [0, 0]), // correct on q0
    ];

    final result = computeItemAnalysis(questions: _twoQuestions(), attempts: attempts);

    expect(result[0].distractorRates[1], closeTo(2 / 4, 0.0001));
    expect(result[0].distractorRates[2], closeTo(1 / 4, 0.0001));
    expect(result[0].distractorRates.containsKey(0), false); // correct option isn't a distractor
  });

  test('returns an empty list for zero attempts, not a crash', () {
    final result = computeItemAnalysis(questions: _twoQuestions(), attempts: const []);
    expect(result, hasLength(2));
    expect(result[0].difficultyIndex, 0.0);
    expect(result[0].discriminationIndex, 0.0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/item_analysis_calculator_test.dart`
Expected: FAIL — file doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/core/services/item_analysis_calculator.dart
import '../models/built_in_question.dart';
import '../models/quiz_attempt.dart';

/// Per-question item analysis result — PROJECT_FLOW.md Part 7.5.
class QuestionItemAnalysis {
  const QuestionItemAnalysis({
    required this.questionIndex,
    required this.difficultyIndex,
    required this.discriminationIndex,
    required this.distractorRates,
  });

  final int questionIndex;
  final double difficultyIndex;
  final double discriminationIndex;

  /// Wrong-option index -> fraction of all students who chose it. The
  /// correct option is never a key here.
  final Map<int, double> distractorRates;
}

/// Computes per-question item analysis across every attempt on one quiz.
/// [questions] and each attempt's `answers[i]` must be index-aligned —
/// callers are responsible for resolving the right question bank for the
/// quiz (built-in or teacher-authored) before calling this.
List<QuestionItemAnalysis> computeItemAnalysis({
  required List<BuiltInQuestion> questions,
  required List<QuizAttempt> attempts,
}) {
  final total = attempts.length;
  if (total == 0) {
    return [
      for (var i = 0; i < questions.length; i++)
        QuestionItemAnalysis(
          questionIndex: i,
          difficultyIndex: 0.0,
          discriminationIndex: 0.0,
          distractorRates: const {},
        ),
    ];
  }

  final sortedByScore = [...attempts]..sort((a, b) => b.score.compareTo(a.score));
  final groupSize = (total * 0.27).ceil().clamp(1, total);
  final topGroup = sortedByScore.take(groupSize).toList();
  final bottomGroup = sortedByScore.reversed.take(groupSize).toList();

  return [
    for (var i = 0; i < questions.length; i++)
      _analyzeQuestion(i, questions[i], attempts, topGroup, bottomGroup, total),
  ];
}

QuestionItemAnalysis _analyzeQuestion(
  int questionIndex,
  BuiltInQuestion question,
  List<QuizAttempt> attempts,
  List<QuizAttempt> topGroup,
  List<QuizAttempt> bottomGroup,
  int total,
) {
  bool answeredCorrectly(QuizAttempt a) =>
      questionIndex < a.answers.length && a.answers[questionIndex] == question.correctIndex;

  final correctCount = attempts.where(answeredCorrectly).length;
  final difficultyIndex = correctCount / total;

  final topCorrectRate = topGroup.isEmpty
      ? 0.0
      : topGroup.where(answeredCorrectly).length / topGroup.length;
  final bottomCorrectRate = bottomGroup.isEmpty
      ? 0.0
      : bottomGroup.where(answeredCorrectly).length / bottomGroup.length;
  final discriminationIndex = topCorrectRate - bottomCorrectRate;

  final distractorCounts = <int, int>{};
  for (final attempt in attempts) {
    if (questionIndex >= attempt.answers.length) continue;
    final chosen = attempt.answers[questionIndex];
    if (chosen == question.correctIndex) continue;
    if (chosen < 0 || chosen >= question.options.length) continue; // unanswered (-1) or invalid
    distractorCounts[chosen] = (distractorCounts[chosen] ?? 0) + 1;
  }
  final distractorRates = {
    for (final entry in distractorCounts.entries) entry.key: entry.value / total,
  };

  return QuestionItemAnalysis(
    questionIndex: questionIndex,
    difficultyIndex: difficultyIndex,
    discriminationIndex: discriminationIndex,
    distractorRates: distractorRates,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/item_analysis_calculator_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/item_analysis_calculator.dart test/core/services/item_analysis_calculator_test.dart
git commit -m "feat: ItemAnalysisCalculator — difficulty/discrimination/distractor math (Part 7.5)"
```

---

