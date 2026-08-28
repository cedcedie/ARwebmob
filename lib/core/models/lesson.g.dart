// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LessonImpl _$$LessonImplFromJson(Map<String, dynamic> json) => _$LessonImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  subject: _subjectFromJson(json['subject'] as String),
  topicId: json['topicId'] as String?,
  summary: json['summary'] as String,
  steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
  labExperimentId: json['labExperimentId'] as String?,
  arPayload: json['arPayload'] == null
      ? null
      : ARPayload.fromJson(json['arPayload'] as Map<String, dynamic>),
  hasAR: json['hasAR'] as bool? ?? false,
  pdfUrl: json['pdfUrl'] as String?,
  isUnlockedByDefault: json['isUnlockedByDefault'] as bool? ?? false,
  curriculum: json['curriculum'] == null
      ? null
      : CurriculumContent.fromJson(json['curriculum'] as Map<String, dynamic>),
  week: (json['week'] as num?)?.toInt(),
  quarter: (json['quarter'] as num?)?.toInt(),
);

Map<String, dynamic> _$$LessonImplToJson(_$LessonImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'subject': _subjectToJson(instance.subject),
      'topicId': instance.topicId,
      'summary': instance.summary,
      'steps': instance.steps,
      'labExperimentId': instance.labExperimentId,
      'arPayload': instance.arPayload,
      'hasAR': instance.hasAR,
      'pdfUrl': instance.pdfUrl,
      'isUnlockedByDefault': instance.isUnlockedByDefault,
      'curriculum': instance.curriculum,
      'week': instance.week,
      'quarter': instance.quarter,
    };
