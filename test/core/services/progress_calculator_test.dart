// test/core/services/progress_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/data/curriculum_data.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/services/progress_calculator.dart';

StudentRecord _studentWith({
  List<String> completedLessonIds = const [],
  List<QuizAttempt> quizAttempts = const [],
}) => StudentRecord(
  id: '111111',
  name: 'Test Student',
  studentId: '111111',
  grade: '7',
  section: 'Rizal',
  scores: const {'chemistry': null, 'biology': null, 'physics': null},
  completedLessonIds: completedLessonIds,
  completedLabExperimentIds: const [],
  completedQuizIds: const [],
  unlockedLessonIds: const [],
  unlockedQuizIds: const [],
  quizAttempts: quizAttempts,
);

void main() {
  group('scoreBandFor', () {
    test('applies the exact Part 10.1 thresholds', () {
      expect(scoreBandFor(100), ScoreBand.good);
      expect(scoreBandFor(80), ScoreBand.good);
      expect(scoreBandFor(79), ScoreBand.caution);
      expect(scoreBandFor(50), ScoreBand.caution);
      expect(scoreBandFor(49), ScoreBand.needsWork);
      expect(scoreBandFor(0), ScoreBand.needsWork);
    });
  });

  group('nextIncompleteLesson', () {
    test('returns the first lesson in curriculum order not yet completed', () {
      final student = _studentWith(completedLessonIds: ['q1w1', 'q1w2']);
      final next = nextIncompleteLesson(kBuiltInLessons, student);
      expect(next?.id, 'q1w3');
    });

    test('returns null once every lesson is complete', () {
      final allIds = kBuiltInLessons.map((l) => l.id).toList();
      final student = _studentWith(completedLessonIds: allIds);
      expect(nextIncompleteLesson(kBuiltInLessons, student), isNull);
    });
  });

  group('percentComplete', () {
    test('divides completed count by 24', () {
      final student = _studentWith(
        completedLessonIds: ['q1w1', 'q1w2', 'q1w3'],
      );
      expect(percentComplete(student), closeTo(3 / 24, 0.0001));
    });
  });

  group('currentQuarterWeek', () {
    test('derives quarter/week from the next incomplete lesson', () {
      final student = _studentWith(
        completedLessonIds: ['q1w1', 'q1w2', 'q1w3', 'q1w4'],
      );
      final result = currentQuarterWeek(kBuiltInLessons, student);
      expect(result?.quarter, 1);
      expect(result?.week, 5);
    });
  });

  group('lastNAttempts', () {
    test('returns the 3 most recent attempts, newest first', () {
      final attempts = [
        QuizAttempt(
          id: 'a1',
          quizId: 'builtin-q1w1-post',
          studentId: '111111',
          attemptNumber: 1,
          score: 60,
          totalQuestions: 5,
          correctAnswers: 3,
          answers: const [0, 0, 0, 0, 0],
          timestamp: DateTime(2026, 8, 1).toIso8601String(),
          locked: true,
        ),
        QuizAttempt(
          id: 'a2',
          quizId: 'builtin-q1w2-post',
          studentId: '111111',
          attemptNumber: 1,
          score: 80,
          totalQuestions: 5,
          correctAnswers: 4,
          answers: const [0, 0, 0, 0, 0],
          timestamp: DateTime(2026, 8, 5).toIso8601String(),
          locked: true,
        ),
        QuizAttempt(
          id: 'a3',
          quizId: 'builtin-q1w3-post',
          studentId: '111111',
          attemptNumber: 1,
          score: 40,
          totalQuestions: 5,
          correctAnswers: 2,
          answers: const [0, 0, 0, 0, 0],
          timestamp: DateTime(2026, 8, 10).toIso8601String(),
          locked: true,
        ),
        QuizAttempt(
          id: 'a4',
          quizId: 'builtin-q1w4-post',
          studentId: '111111',
          attemptNumber: 1,
          score: 90,
          totalQuestions: 5,
          correctAnswers: 5,
          answers: const [0, 0, 0, 0, 0],
          timestamp: DateTime(2026, 8, 15).toIso8601String(),
          locked: true,
        ),
      ];
      final student = _studentWith(quizAttempts: attempts);

      final last3 = lastNAttempts(student);

      expect(last3, hasLength(3));
      expect(last3.map((a) => a.id).toList(), ['a4', 'a3', 'a2']);
    });
  });
}
