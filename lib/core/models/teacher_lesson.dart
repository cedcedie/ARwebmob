import 'package:freezed_annotation/freezed_annotation.dart';

import 'ar_payload.dart';
import 'curriculum_content.dart';
import 'subject_key.dart';

part 'teacher_lesson.freezed.dart';
part 'teacher_lesson.g.dart';

SubjectKey _subjectFromJson(String value) => SubjectKey.fromFirestore(value);
String _subjectToJson(SubjectKey value) => value.firestoreValue;

@freezed
class TeacherLesson with _$TeacherLesson {
  const factory TeacherLesson({
    required String id,
    required String title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required SubjectKey subject,
    String? content,
    String? createdAt,
    String? linkedQuizId,
    String? summary,
    List<String>? steps,
    String? labExperimentId,
    ARPayload? arPayload,
    bool? isPredefined,
    int? quarter,
    int? week,
    String? pdfUrl,
    List<String>? contentImageUrls,
    String? contentStatus, // 'processing' | 'ready' | null
    List<String>? learningObjectives,
    List<String>? keyLearningSteps,
    List<String>? keyVocabulary,
    int? arModelIndex,
    String? arContext,
    bool? hasAR,
    CurriculumContent? curriculum,
    @Default(false) bool isArchived,
  }) = _TeacherLesson;

  factory TeacherLesson.fromJson(Map<String, dynamic> json) =>
      _$TeacherLessonFromJson(json);
}
