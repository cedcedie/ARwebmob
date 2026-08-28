import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/quiz_id.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/quiz_phase.dart';
import '../../../core/services/access_code_service.dart';
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/quiz_attempt_service.dart';
import '../../../core/services/student_repository.dart';

class LessonDetailViewModel {
  const LessonDetailViewModel({
    required this.lessonId,
    required this.title,
    required this.summary,
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
  final bool isRead;

  /// Whether `kPreTestQuestionsByLesson` has a bank for this lesson — most
  /// built-in lessons don't (Task 1's data is intentionally sparse). The
  /// screen must hide/disable its Pre-Test action when this is false; the
  /// `/quiz/:lessonId/:phase` route also degrades gracefully as
  /// defense-in-depth (router.dart), but the button should never be shown
  /// as a live affordance in the first place.
  final bool hasPreTest;
  final bool postTestEligible;
  final String? postTestReason;

  /// Threaded through so the screen can open the shared access-code sheet
  /// (redeeming a retake code for this lesson's post-test) without needing
  /// its own provider wiring.
  final String studentId;
  final AccessCodeService accessCodeService;

  final Future<void> Function() onMarkAsRead;
  final void Function() onStartPreTest;
  final void Function() onStartPostTest;
}

final lessonDetailViewModelProvider =
    StreamProvider.autoDispose.family<LessonDetailViewModel, String>((ref, lessonId) {
  throw UnimplementedError(
    'lessonDetailViewModelProvider must be overridden at app startup with a '
    'real stream for the given lessonId.',
  );
});

/// TEMPORARY (Phase 2 only): `onMarkAsRead` performs the same
/// `completedLessonIds` write Phase 3's real AR Review-phase completion will
/// perform instead. Replace the caller of this function's `onMarkAsRead`
/// wiring in Phase 3 — do not delete `QuizAttemptService`/`StudentRepository`
/// usage, only the UI trigger changes.
Stream<LessonDetailViewModel> buildLessonDetailViewModel({
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
    // One-shot fetch (not a fresh `snapshots()` subscription per emission —
    // `watchStudent` above is already this stream's live-update trigger).
    final teacherLessons = await lessonRepository.fetchTeacherLessons();
    final merged = lessonRepository.mergedLessons(teacherLessons);

    // Resolve through the merged (built-in + teacher-authored) list, not
    // just the built-in curriculum — a teacher-authored lesson id must
    // resolve here too (it's reachable from any unlocked Learn lesson
    // card). A genuinely-unknown id surfaces as this stream's `error` case
    // (LessonDetailScreen already renders that), rather than throwing
    // synchronously out of provider construction.
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

    return LessonDetailViewModel(
      lessonId: lessonId,
      title: lesson.title,
      summary: lesson.summary,
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
