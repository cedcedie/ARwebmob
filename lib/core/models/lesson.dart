import 'package:freezed_annotation/freezed_annotation.dart';

import 'ar_payload.dart';
import 'curriculum_content.dart';
import 'subject_key.dart';

part 'lesson.freezed.dart';
part 'lesson.g.dart';

SubjectKey _subjectFromJson(String value) => SubjectKey.fromFirestore(value);
String _subjectToJson(SubjectKey value) => value.firestoreValue;

@freezed
class Lesson with _$Lesson {
  const factory Lesson({
    required String id, // e.g. 'q1w1'
    required String title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required SubjectKey subject,
    String? topicId,
    required String summary,
    required List<String> steps,
    String? labExperimentId,
    ARPayload? arPayload,
    @Default(false) bool hasAR,
    String? pdfUrl,
    @Default(false) bool isUnlockedByDefault,
    CurriculumContent? curriculum,
    int? week,
    int? quarter,
    String? linkedQuizId,
  }) = _Lesson;

  factory Lesson.fromJson(Map<String, dynamic> json) => _$LessonFromJson(json);
}
