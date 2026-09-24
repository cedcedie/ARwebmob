import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/ar/existing_models.dart';

void main() {
  test('every bundled model is offered, with its own marker and model index', () {
    final q4w1 = existingModelForMarker('/markers/Q4W1.jpg');
    expect(q4w1, isNotNull);
    expect(q4w1!.modelIndex, 9);
    expect(q4w1.glbAsset, 'assets/models/FaultBlockDiagram_Q4W1.glb');
    expect(q4w1.label, startsWith('Q4W1 ·'));

    final markers = kExistingModels.map((m) => m.markerImage).toSet();
    expect(markers.length, kExistingModels.length);
    expect(kExistingModels.length, greaterThanOrEqualTo(29));
  });

  test('an unknown or missing marker resolves to no model', () {
    expect(existingModelForMarker(null), isNull);
    expect(existingModelForMarker('/markers/nope.jpg'), isNull);
  });
}
