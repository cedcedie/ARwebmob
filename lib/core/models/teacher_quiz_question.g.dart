// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_quiz_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TeacherQuizQuestionImpl _$$TeacherQuizQuestionImplFromJson(
  Map<String, dynamic> json,
) => _$TeacherQuizQuestionImpl(
  question: json['question'] as String,
  options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
  correctIndex: (json['correctIndex'] as num).toInt(),
  hint: json['hint'] as String,
  type: json['type'] == null
      ? QuestionType.mc
      : _typeFromJson(json['type'] as String?),
);

Map<String, dynamic> _$$TeacherQuizQuestionImplToJson(
  _$TeacherQuizQuestionImpl instance,
) => <String, dynamic>{
  'question': instance.question,
  'options': instance.options,
  'correctIndex': instance.correctIndex,
  'hint': instance.hint,
  'type': _typeToJson(instance.type),
};
