// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_attempt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuizAttemptImpl _$$QuizAttemptImplFromJson(Map<String, dynamic> json) =>
    _$QuizAttemptImpl(
      id: json['id'] as String,
      quizId: json['quizId'] as String,
      studentId: json['studentId'] as String,
      attemptNumber: (json['attemptNumber'] as num).toInt(),
      score: json['score'] as num,
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      correctAnswers: (json['correctAnswers'] as num).toInt(),
      answers: (json['answers'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      timestamp: json['timestamp'] as String,
      timeSpentSeconds: (json['timeSpentSeconds'] as num?)?.toInt(),
      locked: json['locked'] as bool,
    );

Map<String, dynamic> _$$QuizAttemptImplToJson(_$QuizAttemptImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quizId': instance.quizId,
      'studentId': instance.studentId,
      'attemptNumber': instance.attemptNumber,
      'score': instance.score,
      'totalQuestions': instance.totalQuestions,
      'correctAnswers': instance.correctAnswers,
      'answers': instance.answers,
      'timestamp': instance.timestamp,
      'timeSpentSeconds': instance.timeSpentSeconds,
      'locked': instance.locked,
    };
