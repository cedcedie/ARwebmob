import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/ar_payload.dart';
import 'package:ar_science_explorer/core/models/curriculum_content.dart';

void main() {
  test('ARPayload round-trips the Q1W1 Democritus Atom payload verbatim', () {
    // Real data from PROJECT_FLOW.md Part 6.0.1.
    final json = {
      'modelIndex': 0,
      'detectionMode': 'marker',
      'anchorHint': 'q1w1',
      'lessonSteps': <String>[],
      'title': 'Democritus Atom',
      'subtitle': 'Ancient Greek Atomic Theory (c. 400 BCE)',
      'description':
          'Democritus proposed that all matter consists of tiny, indivisible '
              'particles called "atomos".',
      'keyIdeas': [
        'Smallest, indestructible building blocks of matter',
        'Particles in constant, random motion',
        'Differ in shape and size',
        'Form all materials in the universe',
      ],
    };

    final payload = ARPayload.fromJson(json);

    expect(payload.modelIndex, 0);
    expect(payload.detectionMode, 'marker');
    expect(payload.title, 'Democritus Atom');
    expect(payload.keyIdeas, hasLength(4));
    expect(payload.historicalImpact, isNull);
    expect(payload.toJson()['title'], 'Democritus Atom');
  });

  test('CurriculumContent round-trips with all-optional fields absent', () {
    final content = CurriculumContent.fromJson(const {});
    expect(content.standards, isNull);
    expect(content.learningCompetencies, isNull);
    expect(content.integration, isNull);
  });
}
