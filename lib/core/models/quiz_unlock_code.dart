import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_unlock_code.freezed.dart';
part 'quiz_unlock_code.g.dart';

@freezed
class QuizUnlockCode with _$QuizUnlockCode {
  const factory QuizUnlockCode({
    required String id,
    required String quizId,
    required String studentId,
    required String code,
    required String generatedAt,
    String? usedAt,
    String? expiresAt,
    required bool isUsed,
    @Default(false) bool isArchived,
  }) = _QuizUnlockCode;

  factory QuizUnlockCode.fromJson(Map<String, dynamic> json) =>
      _$QuizUnlockCodeFromJson(json);
}
