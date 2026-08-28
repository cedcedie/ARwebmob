import 'package:freezed_annotation/freezed_annotation.dart';

import 'quiz_attempt.dart';

part 'student_record.freezed.dart';
part 'student_record.g.dart';

@freezed
class StudentRecord with _$StudentRecord {
  const factory StudentRecord({
    required String id,
    String? uid,
    required String name,
    required String studentId,
    required String grade,
    required String section,
    required Map<String, num?> scores, // keyed by 'chemistry'/'biology'/'physics'
    required List<String> completedLessonIds,
    required List<String> completedLabExperimentIds,
    required List<String> completedQuizIds,
    required List<String> unlockedLessonIds,
    required List<String> unlockedQuizIds,
    required List<QuizAttempt> quizAttempts,
    @Default(false) bool isArchived,
  }) = _StudentRecord;

  factory StudentRecord.fromJson(Map<String, dynamic> json) =>
      _$StudentRecordFromJson(json);
}
