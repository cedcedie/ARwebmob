import 'package:freezed_annotation/freezed_annotation.dart';

part 'curriculum_content.freezed.dart';
part 'curriculum_content.g.dart';

@freezed
class CurriculumIntegration with _$CurriculumIntegration {
  const factory CurriculumIntegration({
    List<String>? qualities,
    String? description,
  }) = _CurriculumIntegration;

  factory CurriculumIntegration.fromJson(Map<String, dynamic> json) =>
      _$CurriculumIntegrationFromJson(json);
}

@freezed
class CurriculumContent with _$CurriculumContent {
  const factory CurriculumContent({
    String? standards,
    String? performanceStandards,
    List<String>? learningCompetencies,
    List<String>? objectives,
    String? contentDetails,
    CurriculumIntegration? integration,
  }) = _CurriculumContent;

  factory CurriculumContent.fromJson(Map<String, dynamic> json) =>
      _$CurriculumContentFromJson(json);
}
