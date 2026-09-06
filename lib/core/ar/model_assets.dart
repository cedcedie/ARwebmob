// lib/core/ar/model_assets.dart
//
// Quarter/week → `.glb` mapping from PROJECT_FLOW.md Part 6.1. Used by the
// teacher lesson editor to preview bundled models without opening Unity.

const Map<String, String> kGlbAssetByQuarterWeek = {
  'Q1W1': 'assets/models/democritus_atom.glb',
  'Q1W2': 'assets/models/waterpolarity.glb',
  'Q1W3': 'assets/models/solid_liquid_gas.glb',
  'Q1W4': 'assets/models/particle_motion_temperature.glb',
  'Q1W6': 'assets/models/beakers.glb',
  'Q1W7': 'assets/models/saturated_unsaturated.glb',
  'Q1W8': 'assets/models/salt_dissolving_in_water.glb',
  'Q2W1': 'assets/models/Microscope.glb',
  'Q2W2': 'assets/models/plant_cell.glb',
  'Q2W3': 'assets/models/prokaryoticCell.glb',
  'Q2W4': 'assets/models/mitosis_phases.glb',
  'Q2W5': 'assets/models/Fertilization_Model_Light.glb',
  'Q2W6': 'assets/models/amoeba_binary_fission.glb',
  'Q2W7': 'assets/models/biological_organization.glb',
  'Q2W8': 'assets/models/food_web.glb',
  'Q3W1': 'assets/models/spring.glb',
  'Q3W2': 'assets/models/inclined_plane_slide_playground.glb',
  'Q3W3': 'assets/models/seesaw.glb',
  'Q3W4': 'assets/models/compass.glb',
  'Q3W5': 'assets/models/car.glb',
  'Q3W6': 'assets/models/jeepney.glb',
  'Q3W7': 'assets/models/thermometer.glb',
  'Q3W8': 'assets/models/spoon.glb',
};

/// Fallback when only [modelIndex] is known — not unique per lesson (Phase 3
/// Task 2 finding), but sufficient for a read-only teacher preview.
const List<String> kGlbAssetsByModelIndex = [
  'assets/models/democritus_atom.glb',
  'assets/models/waterpolarity.glb',
  'assets/models/solid_liquid_gas.glb',
  'assets/models/particle_motion_temperature.glb',
  'assets/models/Fertilization_Model_Light.glb',
  'assets/models/beakers.glb',
  'assets/models/saturated_unsaturated.glb',
  'assets/models/salt_dissolving_in_water.glb',
  'assets/models/spring.glb',
];

String? glbAssetForQuarterWeek(int? quarter, int? week) {
  if (quarter == null || week == null) return null;
  return kGlbAssetByQuarterWeek['Q${quarter}W$week'];
}

String? glbAssetForModelIndex(int? modelIndex) {
  if (modelIndex == null ||
      modelIndex < 0 ||
      modelIndex >= kGlbAssetsByModelIndex.length) {
    return null;
  }
  return kGlbAssetsByModelIndex[modelIndex];
}

String? resolveGlbPreviewPath({int? quarter, int? week, int? modelIndex}) {
  return glbAssetForQuarterWeek(quarter, week) ??
      glbAssetForModelIndex(modelIndex);
}

bool isFlutterTestEnvironment() {
  return const bool.fromEnvironment('FLUTTER_TEST');
}
