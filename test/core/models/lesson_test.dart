import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/lesson.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';

void main() {
  test('Lesson round-trips the Q1W1 shape from PROJECT_FLOW.md Part 5', () {
    final json = {
      'id': 'q1w1',
      'title': 'Scientific Models and the Particle Model of Matter',
      'subject': 'chemistry',
      'summary': 'summary text',
      'steps': <String>[],
      'hasAR': true,
      'isUnlockedByDefault': true,
      'week': 1,
      'quarter': 1,
    };

    final lesson = Lesson.fromJson(json);

    expect(lesson.id, 'q1w1');
    expect(lesson.subject, SubjectKey.chemistry);
    expect(lesson.hasAR, true);
    expect(lesson.isUnlockedByDefault, true);
    expect(lesson.arPayload, isNull);
    expect(lesson.toJson()['subject'], 'chemistry');
  });

  test('Lesson defaults hasAR/isUnlockedByDefault to false when absent', () {
    final lesson = Lesson.fromJson(const {
      'id': 'q1w5',
      'title': 'Planning and Recording Scientific Investigations',
      'subject': 'chemistry',
      'summary': 'summary text',
      'steps': <String>[],
    });

    expect(lesson.hasAR, false);
    expect(lesson.isUnlockedByDefault, false);
  });
}
