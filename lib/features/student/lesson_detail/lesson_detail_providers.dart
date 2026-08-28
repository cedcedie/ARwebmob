import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/quiz_id.dart';
import '../../../core/models/quiz_phase.dart';
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/quiz_attempt_service.dart';
import '../../../core/services/student_repository.dart';

class LessonDetailViewModel {
  const LessonDetailViewModel({
    required this.lessonId,
    required this.title,
    required this.summary,
    required this.isRead,
    required this.postTestEligible,
    required this.postTestReason,
    required this.onMarkAsRead,
    required this.onStartPreTest,
    required this.onStartPostTest,
  });

  final String lessonId;
  final String title;
  final String summary;
  final bool isRead;
  final bool postTestEligible;
  final String? postTestReason;
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
  required String title,
  required String summary,
  required StudentRepository studentRepository,
  required QuizAttemptService quizAttemptService,
  required void Function() onStartPreTest,
  required void Function() onStartPostTest,
}) {
  return studentRepository.watchStudent(studentId).asyncMap((student) async {
    final isRead = student?.completedLessonIds.contains(lessonId) ?? false;
    final postQuizId = builtinQuizId(lessonId, QuizPhase.post);
    final eligibility = await quizAttemptService.checkEligibility(studentId, postQuizId);

    return LessonDetailViewModel(
      lessonId: lessonId,
      title: title,
      summary: summary,
      isRead: isRead,
      postTestEligible: eligibility.canTake,
      postTestReason: eligibility.reason,
      onMarkAsRead: () => studentRepository.saveStudent(
        (student!).copyWith(completedLessonIds: {...student.completedLessonIds, lessonId}.toList()),
      ),
      onStartPreTest: onStartPreTest,
      onStartPostTest: onStartPostTest,
    );
  });
}
