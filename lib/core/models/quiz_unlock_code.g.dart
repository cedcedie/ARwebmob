// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_unlock_code.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuizUnlockCodeImpl _$$QuizUnlockCodeImplFromJson(Map<String, dynamic> json) =>
    _$QuizUnlockCodeImpl(
      id: json['id'] as String,
      quizId: json['quizId'] as String,
      studentId: json['studentId'] as String,
      code: json['code'] as String,
      generatedAt: json['generatedAt'] as String,
      usedAt: json['usedAt'] as String?,
      expiresAt: json['expiresAt'] as String?,
      isUsed: json['isUsed'] as bool,
      isArchived: json['isArchived'] as bool? ?? false,
    );

Map<String, dynamic> _$$QuizUnlockCodeImplToJson(
  _$QuizUnlockCodeImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'quizId': instance.quizId,
  'studentId': instance.studentId,
  'code': instance.code,
  'generatedAt': instance.generatedAt,
  'usedAt': instance.usedAt,
  'expiresAt': instance.expiresAt,
  'isUsed': instance.isUsed,
  'isArchived': instance.isArchived,
};
