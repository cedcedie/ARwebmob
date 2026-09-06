import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/data/curriculum_data.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/question_type.dart';

void main() {
  test(
    'kBuiltInLessons has exactly 24 lessons, 8 per subject, in curriculum order',
    () {
      expect(kBuiltInLessons, hasLength(24));

      final bySubject = <SubjectKey, int>{};
      for (final lesson in kBuiltInLessons) {
        bySubject[lesson.subject] = (bySubject[lesson.subject] ?? 0) + 1;
      }
      expect(bySubject[SubjectKey.chemistry], 8);
      expect(bySubject[SubjectKey.biology], 8);
      expect(bySubject[SubjectKey.physics], 8);

      // Curriculum order: q1w1..q1w8, q2w1..q2w8, q3w1..q3w8.
      final expectedIds = [
        for (final q in [1, 2, 3])
          for (final w in [1, 2, 3, 4, 5, 6, 7, 8]) 'q${q}w$w',
      ];
      expect(kBuiltInLessons.map((l) => l.id).toList(), expectedIds);
    },
  );

  test('every lesson id is unique', () {
    final ids = kBuiltInLessons.map((l) => l.id).toSet();
    expect(ids, hasLength(24));
  });

  test('hasAR is true for all 23 AR-enabled lessons and false only for Q1W5 '
      '(PROJECT_FLOW.md Part 6.1\'s marker table)', () {
    for (final lesson in kBuiltInLessons) {
      expect(
        lesson.hasAR,
        lesson.arPayload != null,
        reason: '${lesson.id}.hasAR must match whether it has an arPayload',
      );
    }

    final noArLessons = kBuiltInLessons
        .where((l) => !l.hasAR)
        .map((l) => l.id)
        .toList();
    expect(noArLessons, ['q1w5']);

    final arLessons = kBuiltInLessons.where((l) => l.hasAR).toList();
    expect(arLessons, hasLength(23));
  });

  test('Q1W1 matches the worked example in PROJECT_FLOW.md Part 6.0.1', () {
    final q1w1 = kBuiltInLessons.firstWhere((l) => l.id == 'q1w1');
    expect(q1w1.title, 'Scientific Models and the Particle Model of Matter');
    expect(q1w1.subject, SubjectKey.chemistry);
    expect(q1w1.isUnlockedByDefault, true);
    expect(q1w1.quarter, 1);
    expect(q1w1.week, 1);
    expect(q1w1.arPayload, isNotNull);
    expect(q1w1.arPayload!.title, 'Democritus Atom');
    expect(q1w1.arPayload!.modelIndex, 0);
    expect(q1w1.arPayload!.detectionMode, 'marker');
    expect(q1w1.arPayload!.keyIdeas, hasLength(4));
  });

  test('every lesson has a post-test question bank', () {
    for (final lesson in kBuiltInLessons) {
      expect(
        kPostTestQuestionsByLesson[lesson.id],
        isNotNull,
        reason:
            '${lesson.id} must have a post-test (falls back to legacy questions[])',
      );
      expect(kPostTestQuestionsByLesson[lesson.id], isNotEmpty);
    }
  });

  test(
    'Q1W1 pre-test is 8 true/false questions, stamped with lesson metadata',
    () {
      final preTest = kPreTestQuestionsByLesson['q1w1'];
      expect(preTest, isNotNull);
      expect(preTest, hasLength(8));
      for (final q in preTest!) {
        expect(q.subject, SubjectKey.chemistry);
        expect(q.lessonId, 'q1w1');
        expect(q.type, QuestionType.tf);
        expect(q.options, hasLength(4));
        expect(q.options[2], '-');
        expect(q.options[3], '-');
      }
      expect(
        preTest.first.question,
        'Scientists use models to explain things that cannot be easily seen.',
      );
      expect(preTest.first.correctIndex, 0);
    },
  );

  test('every question in every bank has exactly 4 option slots', () {
    for (final bank in [
      ...kPreTestQuestionsByLesson.values,
      ...kPostTestQuestionsByLesson.values,
    ]) {
      for (final q in bank) {
        expect(
          q.options,
          hasLength(4),
          reason: '${q.id} must have 4 option slots',
        );
      }
    }
  });
}
