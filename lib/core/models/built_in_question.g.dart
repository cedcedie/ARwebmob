// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'built_in_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BuiltInQuestionImpl _$$BuiltInQuestionImplFromJson(
  Map<String, dynamic> json,
) => _$BuiltInQuestionImpl(
  id: json['id'] as String,
  subject: _subjectFromJson(json['subject'] as String),
  topicId: json['topicId'] as String?,
  lessonId: json['lessonId'] as String?,
  question: json['question'] as String,
  options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
  correctIndex: (json['correctIndex'] as num).toInt(),
  hint: json['hint'] as String,
  type: json['type'] == null
      ? QuestionType.mc
      : _typeFromJson(json['type'] as String?),
);

Map<String, dynamic> _$$BuiltInQuestionImplToJson(
  _$BuiltInQuestionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'subject': _subjectToJson(instance.subject),
  'topicId': instance.topicId,
  'lessonId': instance.lessonId,
  'question': instance.question,
  'options': instance.options,
  'correctIndex': instance.correctIndex,
  'hint': instance.hint,
  'type': _typeToJson(instance.type),
};
