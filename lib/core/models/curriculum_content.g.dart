// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'curriculum_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CurriculumIntegrationImpl _$$CurriculumIntegrationImplFromJson(
  Map<String, dynamic> json,
) => _$CurriculumIntegrationImpl(
  qualities: (json['qualities'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  description: json['description'] as String?,
);

Map<String, dynamic> _$$CurriculumIntegrationImplToJson(
  _$CurriculumIntegrationImpl instance,
) => <String, dynamic>{
  'qualities': instance.qualities,
  'description': instance.description,
};

_$CurriculumContentImpl _$$CurriculumContentImplFromJson(
  Map<String, dynamic> json,
) => _$CurriculumContentImpl(
  standards: json['standards'] as String?,
  performanceStandards: json['performanceStandards'] as String?,
  learningCompetencies: (json['learningCompetencies'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  objectives: (json['objectives'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  contentDetails: json['contentDetails'] as String?,
  integration: json['integration'] == null
      ? null
      : CurriculumIntegration.fromJson(
          json['integration'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$$CurriculumContentImplToJson(
  _$CurriculumContentImpl instance,
) => <String, dynamic>{
  'standards': instance.standards,
  'performanceStandards': instance.performanceStandards,
  'learningCompetencies': instance.learningCompetencies,
  'objectives': instance.objectives,
  'contentDetails': instance.contentDetails,
  'integration': instance.integration?.toJson(),
};
