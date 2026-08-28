// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StudentRecordImpl _$$StudentRecordImplFromJson(Map<String, dynamic> json) =>
    _$StudentRecordImpl(
      id: json['id'] as String,
      uid: json['uid'] as String?,
      name: json['name'] as String,
      studentId: json['studentId'] as String,
      grade: json['grade'] as String,
      section: json['section'] as String,
      scores: Map<String, num?>.from(json['scores'] as Map),
      completedLessonIds: (json['completedLessonIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      completedLabExperimentIds:
          (json['completedLabExperimentIds'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      completedQuizIds: (json['completedQuizIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      unlockedLessonIds: (json['unlockedLessonIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      unlockedQuizIds: (json['unlockedQuizIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      quizAttempts: (json['quizAttempts'] as List<dynamic>)
          .map((e) => QuizAttempt.fromJson(e as Map<String, dynamic>))
          .toList(),
      isArchived: json['isArchived'] as bool? ?? false,
    );

Map<String, dynamic> _$$StudentRecordImplToJson(_$StudentRecordImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uid': instance.uid,
      'name': instance.name,
      'studentId': instance.studentId,
      'grade': instance.grade,
      'section': instance.section,
      'scores': instance.scores,
      'completedLessonIds': instance.completedLessonIds,
      'completedLabExperimentIds': instance.completedLabExperimentIds,
      'completedQuizIds': instance.completedQuizIds,
      'unlockedLessonIds': instance.unlockedLessonIds,
      'unlockedQuizIds': instance.unlockedQuizIds,
      'quizAttempts': instance.quizAttempts,
      'isArchived': instance.isArchived,
    };
