import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/ar/marker_mapping.dart';
import 'package:ar_science_explorer/core/data/curriculum_data.dart';
import 'package:ar_science_explorer/core/models/ar_payload.dart';
import 'package:ar_science_explorer/core/models/lesson.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';

Lesson _lesson({
  required String id,
  required int quarter,
  required int week,
  ARPayload? arPayload,
}) {
  return Lesson(
    id: id,
    title: 'title',
    subject: SubjectKey.chemistry,
    summary: 'summary',
    steps: const [],
    quarter: quarter,
    week: week,
    arPayload: arPayload,
  );
}

void main() {
  group('markerAssetForLesson', () {
    test('derives /markers/Q1W1.jpg when there is no override', () {
      final lesson = _lesson(id: 'q1w1', quarter: 1, week: 1);
      expect(markerAssetForLesson(lesson), '/markers/Q1W1.jpg');
    });

    test('derives /markers/Q3W8.jpg (double-digit-safe)', () {
      final lesson = _lesson(id: 'q3w8', quarter: 3, week: 8);
      expect(markerAssetForLesson(lesson), '/markers/Q3W8.jpg');
    });

    test('fallback scheme matches the explicit-override scheme (root-relative, no '
        'assets/ prefix) so both agree', () {
      final lesson = _lesson(id: 'q2w5', quarter: 2, week: 5);
      expect(markerAssetForLesson(lesson), startsWith('/markers/'));
      expect(markerAssetForLesson(lesson), isNot(startsWith('assets/')));
    });

    test('returns the explicit markerImage override as-is when present', () {
      final lesson = _lesson(
        id: 'q1w1',
        quarter: 1,
        week: 1,
        arPayload: const ARPayload(
          modelIndex: 0,
          detectionMode: 'marker',
          anchorHint: 'hint',
          lessonSteps: [],
          markerImage: '/custom/override.jpg',
        ),
      );
      expect(markerAssetForLesson(lesson), '/custom/override.jpg');
    });
  });

  group('lessonForTrackableName', () {
    test('finds q1w1 from a mixed-case trackable name', () {
      final found = lessonForTrackableName(kBuiltInLessons, 'DemocritusAtomQ1W1');
      expect(found?.id, 'q1w1');
    });

    test('finds q3w2 from a lowercase trackable name, disambiguating from q3w1 '
        '(both share arPayload.modelIndex 8)', () {
      final found = lessonForTrackableName(
        kBuiltInLessons,
        'q3w2inclined_plane_slide_playground',
      );
      expect(found?.id, 'q3w2');
    });

    test('returns null when the trackable name has no Q<n>W<n> pattern', () {
      expect(lessonForTrackableName(kBuiltInLessons, 'SomeNameWithNoPattern'), isNull);
    });
  });

  test('q1w5 has no arPayload and hasAR is false', () {
    final q1w5 = kBuiltInLessons.firstWhere((l) => l.id == 'q1w5');
    expect(q1w5.arPayload, isNull);
    expect(q1w5.hasAR, false);
  });
}
