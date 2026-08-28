// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_quiz.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TeacherQuizImpl _$$TeacherQuizImplFromJson(Map<String, dynamic> json) =>
    _$TeacherQuizImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: _subjectFromJson(json['subject'] as String),
      topicId: json['topicId'] as String?,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => TeacherQuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as String,
      phase: json['phase'] == null
          ? QuizPhase.post
          : _phaseFromJson(json['phase'] as String?),
    );

Map<String, dynamic> _$$TeacherQuizImplToJson(_$TeacherQuizImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'subject': _subjectToJson(instance.subject),
      'topicId': instance.topicId,
      'questions': instance.questions.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt,
      'phase': _phaseToJson(instance.phase),
    };
