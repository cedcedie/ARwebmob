// test/core/models/quiz_attempt_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/models/quiz_unlock_code.dart';

void main() {
  test('QuizAttempt round-trips the example attempt from PROJECT_FLOW.md 4.3', () {
    final json = {
      'id': 'attempt-abc123',
      'quizId': 'builtin-q1w1-post',
      'studentId': '123456',
      'attemptNumber': 1,
      'score': 80,
      'totalQuestions': 5,
      'correctAnswers': 4,
      'answers': [2, 0, 1, 3, 0],
      'timestamp': '2026-08-20T09:15:00.000Z',
      'timeSpentSeconds': 340,
      'locked': true,
    };

    final attempt = QuizAttempt.fromJson(json);

    expect(attempt.id, 'attempt-abc123');
    expect(attempt.score, 80);
    expect(attempt.answers, [2, 0, 1, 3, 0]);
    expect(attempt.locked, true);
    expect(attempt.toJson()['quizId'], 'builtin-q1w1-post');
  });

  test('QuizUnlockCode round-trips with optional fields present', () {
    final json = {
      'id': 'code-1',
      'quizId': 'builtin-q1w1-post',
      'studentId': '123456',
      'code': 'XYZ123',
      'generatedAt': '2026-08-20T09:00:00.000Z',
      'usedAt': '2026-08-20T09:15:00.000Z',
      'expiresAt': '2026-08-27T09:00:00.000Z',
      'isUsed': true,
      'isArchived': false,
    };

    final unlockCode = QuizUnlockCode.fromJson(json);

    expect(unlockCode.code, 'XYZ123');
    expect(unlockCode.isUsed, true);
    expect(unlockCode.isArchived, false);
  });
}
