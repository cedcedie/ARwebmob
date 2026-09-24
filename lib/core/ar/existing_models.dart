import '../data/curriculum_data.dart';
import 'model_assets.dart';

/// A 3D model that already ships with the app, so a teacher can attach it to a
/// lesson without uploading anything. The marker image is its stable identity:
/// `modelIndex` alone is shared by several lessons (e.g. every Q3 lesson is 8).
class ExistingModel {
  const ExistingModel({
    required this.lessonId,
    required this.label,
    required this.modelIndex,
    required this.markerImage,
    required this.glbAsset,
  });

  final String lessonId;
  final String label;
  final int modelIndex;
  final String markerImage;
  final String glbAsset;
}

final List<ExistingModel> kExistingModels = [
  for (final lesson in kBuiltInLessons)
    if (lesson.arPayload?.markerImage != null &&
        glbAssetForQuarterWeek(lesson.quarter, lesson.week) != null)
      ExistingModel(
        lessonId: lesson.id,
        label:
            '${lesson.id.toUpperCase()} · '
            '${lesson.arPayload!.title ?? lesson.title}',
        modelIndex: lesson.arPayload!.modelIndex,
        markerImage: lesson.arPayload!.markerImage!,
        glbAsset: glbAssetForQuarterWeek(lesson.quarter, lesson.week)!,
      ),
];

ExistingModel? existingModelForMarker(String? markerImage) {
  if (markerImage == null) return null;
  for (final model in kExistingModels) {
    if (model.markerImage == markerImage) return model;
  }
  return null;
}
