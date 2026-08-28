import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';

void main() {
  test('StudentRecord round-trips the example document from PROJECT_FLOW.md 4.3', () {
    final json = {
      'id': '123456',
      'studentId': '123456',
      'name': 'Juan Dela Cruz',
      'grade': '7',
      'section': 'Rizal',
      'scores': {'chemistry': 85, 'biology': null, 'physics': null},
      'completedLessonIds': ['q1w1', 'q1w2'],
      'completedLabExperimentIds': <String>[],
      'completedQuizIds': ['builtin-q1w1-pre', 'builtin-q1w1-post'],
      'unlockedLessonIds': ['q1w1', 'q1w2', 'q1w3'],
      'unlockedQuizIds': ['builtin-q1w1-post'],
      'quizAttempts': [
        {
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
        },
      ],
      'isArchived': false,
    };

    final student = StudentRecord.fromJson(json);

    expect(student.studentId, '123456');
    expect(student.scores['chemistry'], 85);
    expect(student.scores['biology'], isNull);
    expect(student.completedLessonIds, ['q1w1', 'q1w2']);
    expect(student.quizAttempts, hasLength(1));
    expect(student.quizAttempts.first.score, 80);
    expect(student.isArchived, false);
  });

  test('StudentRecord defaults isArchived to false and uid to null when absent', () {
    final student = StudentRecord.fromJson(const {
      'id': '654321',
      'studentId': '654321',
      'name': 'Maria Santos',
      'grade': '7',
      'section': 'Bonifacio',
      'scores': {'chemistry': null, 'biology': null, 'physics': null},
      'completedLessonIds': <String>[],
      'completedLabExperimentIds': <String>[],
      'completedQuizIds': <String>[],
      'unlockedLessonIds': <String>[],
      'unlockedQuizIds': <String>[],
      'quizAttempts': <Map<String, dynamic>>[],
    });

    expect(student.uid, isNull);
    expect(student.isArchived, false);
  });
}
