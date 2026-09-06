import 'package:freezed_annotation/freezed_annotation.dart';

import 'quiz_phase.dart';
import 'subject_key.dart';
import 'teacher_quiz_question.dart';

part 'teacher_quiz.freezed.dart';
part 'teacher_quiz.g.dart';

SubjectKey _subjectFromJson(String value) => SubjectKey.fromFirestore(value);
String _subjectToJson(SubjectKey value) => value.firestoreValue;
QuizPhase _phaseFromJson(String? value) => QuizPhase.fromFirestore(value);
String _phaseToJson(QuizPhase value) => value.firestoreValue;

@freezed
class TeacherQuiz with _$TeacherQuiz {
  const factory TeacherQuiz({
    required String id,
    required String title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required SubjectKey subject,
    String? topicId,
    required List<TeacherQuizQuestion> questions,
    required String createdAt,
    @JsonKey(
      fromJson: _phaseFromJson,
      toJson: _phaseToJson,
      includeIfNull: false,
    )
    @Default(QuizPhase.post)
    QuizPhase phase,
  }) = _TeacherQuiz;

  factory TeacherQuiz.fromJson(Map<String, dynamic> json) =>
      _$TeacherQuizFromJson(json);
}
