import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_attempt.freezed.dart';
part 'quiz_attempt.g.dart';

@freezed
class QuizAttempt with _$QuizAttempt {
  const factory QuizAttempt({
    required String id,
    required String quizId,
    required String studentId,
    required int attemptNumber,
    required num score,
    required int totalQuestions,
    required int correctAnswers,
    required List<int> answers, // selected option index per question, in order
    required String timestamp, // ISO string, kept as string to match Firestore exactly
    int? timeSpentSeconds,
    required bool locked,
  }) = _QuizAttempt;

  factory QuizAttempt.fromJson(Map<String, dynamic> json) =>
      _$QuizAttemptFromJson(json);
}
