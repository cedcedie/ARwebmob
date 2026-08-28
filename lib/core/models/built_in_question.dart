import 'package:freezed_annotation/freezed_annotation.dart';

import 'question_type.dart';
import 'subject_key.dart';

part 'built_in_question.freezed.dart';
part 'built_in_question.g.dart';

SubjectKey _subjectFromJson(String value) => SubjectKey.fromFirestore(value);
String _subjectToJson(SubjectKey value) => value.firestoreValue;
QuestionType _typeFromJson(String? value) => QuestionType.fromFirestore(value);
String _typeToJson(QuestionType value) => value.firestoreValue;

@freezed
class BuiltInQuestion with _$BuiltInQuestion {
  const factory BuiltInQuestion({
    required String id,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required SubjectKey subject,
    String? topicId,
    String? lessonId,
    required String question,
    required List<String> options, // exactly 4 slots
    required int correctIndex,
    required String hint,
    @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
    @Default(QuestionType.mc)
    QuestionType type,
  }) = _BuiltInQuestion;

  factory BuiltInQuestion.fromJson(Map<String, dynamic> json) =>
      _$BuiltInQuestionFromJson(json);
}
