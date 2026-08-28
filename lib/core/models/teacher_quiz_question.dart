import 'package:freezed_annotation/freezed_annotation.dart';

import 'question_type.dart';

part 'teacher_quiz_question.freezed.dart';
part 'teacher_quiz_question.g.dart';

QuestionType _typeFromJson(String? value) => QuestionType.fromFirestore(value);
String _typeToJson(QuestionType value) => value.firestoreValue;

@freezed
class TeacherQuizQuestion with _$TeacherQuizQuestion {
  const factory TeacherQuizQuestion({
    required String question,
    required List<String> options, // exactly 4 slots
    required int correctIndex,
    required String hint,
    @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
    @Default(QuestionType.mc)
    QuestionType type,
  }) = _TeacherQuizQuestion;

  factory TeacherQuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$TeacherQuizQuestionFromJson(json);
}
