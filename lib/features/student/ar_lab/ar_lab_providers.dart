import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/ar/marker_mapping.dart';
import '../../../core/data/curriculum_data.dart';
import '../../../core/quiz_id.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/quiz_phase.dart';
import '../../../core/services/access_code_service.dart';
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/quiz_attempt_service.dart';
import '../../../core/services/student_repository.dart';

class ArLabViewModel extends ChangeNotifier {
  ArLabViewModel({
    required this.lessonId,
    required this.title,
    required this.summary,
    required this.hasAR,
    required this.markerIndex,
    required this.isRead,
    required this.hasPreTest,
    required this.postTestEligible,
    required this.postTestReason,
    required this.studentId,
    required this.accessCodeService,
    required this.onMarkAsRead,
    required this.onStartPreTest,
    required this.onStartPostTest,
  });

  final String lessonId;
  final String title;
  final String summary;
  final bool hasAR;

  /// This lesson's own `arPayload?.modelIndex` — the marker the AR camera
  /// should be looking for while this lesson's lab is open. `null` when
  /// `hasAR` is false.
  final int? markerIndex;

  final bool isRead;
  final bool hasPreTest;
  final bool postTestEligible;
  final String? postTestReason;

  final String studentId;
  final AccessCodeService accessCodeService;

  final Future<void> Function() onMarkAsRead;
  final void Function() onStartPreTest;
  final void Function() onStartPostTest;

  /// The lesson currently recognized by the AR camera, if any — distinct
  /// from [markerIndex] (this screen's own lesson), since a camera scan can
  /// detect any marker in the curriculum, not just this lesson's.
  Lesson? detectedLesson;

  void onMarkerFound(String trackableName) {
    detectedLesson = lessonForTrackableName(kBuiltInLessons, trackableName);
    notifyListeners();
  }

  void onMarkerLost(String trackableName) {
    final lostLesson = lessonForTrackableName(kBuiltInLessons, trackableName);
    if (lostLesson?.id != detectedLesson?.id) return;
    detectedLesson = null;
    notifyListeners();
  }
}

final arLabViewModelProvider =
    StreamProvider.autoDispose.family<ArLabViewModel, String>((ref, lessonId) {
  throw UnimplementedError(
    'arLabViewModelProvider must be overridden at app startup with a '
    'real stream for the given lessonId.',
  );
});

Stream<ArLabViewModel> buildArLabViewModel({
  required String studentId,
  required String lessonId,
  required LessonRepository lessonRepository,
  required StudentRepository studentRepository,
  required QuizAttemptService quizAttemptService,
  required AccessCodeService accessCodeService,
  required Set<String> preTestLessonIds,
  required void Function() onStartPreTest,
  required void Function() onStartPostTest,
}) {
  return studentRepository.watchStudent(studentId).asyncMap((student) async {
    final teacherLessons = await lessonRepository.fetchTeacherLessons();
    final merged = lessonRepository.mergedLessons(teacherLessons);

    Lesson? lesson;
    for (final candidate in merged) {
      if (candidate.id == lessonId) {
        lesson = candidate;
        break;
      }
    }
    if (lesson == null) {
      throw StateError('Lesson "$lessonId" could not be found.');
    }

    final isRead = student?.completedLessonIds.contains(lessonId) ?? false;
    final postQuizId = builtinQuizId(lessonId, QuizPhase.post);
    final eligibility = await quizAttemptService.checkEligibility(studentId, postQuizId);

    return ArLabViewModel(
      lessonId: lessonId,
      title: lesson.title,
      summary: lesson.summary,
      hasAR: lesson.hasAR,
      markerIndex: lesson.arPayload?.modelIndex,
      isRead: isRead,
      hasPreTest: preTestLessonIds.contains(lessonId),
      postTestEligible: eligibility.canTake,
      postTestReason: eligibility.reason,
      studentId: studentId,
      accessCodeService: accessCodeService,
      onMarkAsRead: student == null
          ? () async {}
          : () => studentRepository.saveStudent(
                student.copyWith(completedLessonIds: {...student.completedLessonIds, lessonId}.toList()),
              ),
      onStartPreTest: onStartPreTest,
      onStartPostTest: onStartPostTest,
    );
  });
}
