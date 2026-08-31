// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TeacherLessonImpl _$$TeacherLessonImplFromJson(
  Map<String, dynamic> json,
) => _$TeacherLessonImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  subject: _subjectFromJson(json['subject'] as String),
  content: json['content'] as String?,
  createdAt: json['createdAt'] as String?,
  linkedQuizId: json['linkedQuizId'] as String?,
  summary: json['summary'] as String?,
  steps: (json['steps'] as List<dynamic>?)?.map((e) => e as String).toList(),
  labExperimentId: json['labExperimentId'] as String?,
  arPayload: json['arPayload'] == null
      ? null
      : ARPayload.fromJson(json['arPayload'] as Map<String, dynamic>),
  isPredefined: json['isPredefined'] as bool?,
  quarter: (json['quarter'] as num?)?.toInt(),
  week: (json['week'] as num?)?.toInt(),
  pdfUrl: json['pdfUrl'] as String?,
  contentImageUrls: (json['contentImageUrls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  contentStatus: json['contentStatus'] as String?,
  learningObjectives: (json['learningObjectives'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  keyLearningSteps: (json['keyLearningSteps'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  keyVocabulary: (json['keyVocabulary'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  arModelIndex: (json['arModelIndex'] as num?)?.toInt(),
  arContext: json['arContext'] as String?,
  hasAR: json['hasAR'] as bool?,
  curriculum: json['curriculum'] == null
      ? null
      : CurriculumContent.fromJson(json['curriculum'] as Map<String, dynamic>),
  isArchived: json['isArchived'] as bool? ?? false,
);

Map<String, dynamic> _$$TeacherLessonImplToJson(_$TeacherLessonImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'subject': _subjectToJson(instance.subject),
      'content': instance.content,
      'createdAt': instance.createdAt,
      'linkedQuizId': instance.linkedQuizId,
      'summary': instance.summary,
      'steps': instance.steps,
      'labExperimentId': instance.labExperimentId,
      'arPayload': instance.arPayload?.toJson(),
      'isPredefined': instance.isPredefined,
      'quarter': instance.quarter,
      'week': instance.week,
      'pdfUrl': instance.pdfUrl,
      'contentImageUrls': instance.contentImageUrls,
      'contentStatus': instance.contentStatus,
      'learningObjectives': instance.learningObjectives,
      'keyLearningSteps': instance.keyLearningSteps,
      'keyVocabulary': instance.keyVocabulary,
      'arModelIndex': instance.arModelIndex,
      'arContext': instance.arContext,
      'hasAR': instance.hasAR,
      'curriculum': instance.curriculum?.toJson(),
      'isArchived': instance.isArchived,
    };
