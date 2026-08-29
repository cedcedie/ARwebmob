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
    test('derives assets/markers/Q1W1.jpg when there is no override', () {
      final lesson = _lesson(id: 'q1w1', quarter: 1, week: 1);
      expect(markerAssetForLesson(lesson), 'assets/markers/Q1W1.jpg');
    });

    test('derives assets/markers/Q3W8.jpg (double-digit-safe)', () {
      final lesson = _lesson(id: 'q3w8', quarter: 3, week: 8);
      expect(markerAssetForLesson(lesson), 'assets/markers/Q3W8.jpg');
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

  group('lessonForMarkerIndex', () {
    test('finds q1w1 by its own arPayload.modelIndex', () {
      final q1w1 = kBuiltInLessons.firstWhere((l) => l.id == 'q1w1');
      final found = lessonForMarkerIndex(
        kBuiltInLessons,
        q1w1.arPayload!.modelIndex,
      );
      expect(found?.id, 'q1w1');
    });

    test('returns null for an index no lesson uses', () {
      expect(lessonForMarkerIndex(kBuiltInLessons, 9999), isNull);
    });
  });

  test('q1w5 has no arPayload and hasAR is false', () {
    final q1w5 = kBuiltInLessons.firstWhere((l) => l.id == 'q1w5');
    expect(q1w5.arPayload, isNull);
    expect(q1w5.hasAR, false);
  });
}
