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
