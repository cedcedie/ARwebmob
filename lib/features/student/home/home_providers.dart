import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/lesson.dart';
import '../../../core/models/quiz_attempt.dart';
import '../../../core/services/access_code_service.dart';
import '../../../core/services/progress_calculator.dart';
import '../../../core/services/student_repository.dart';

class HomeViewModel {
  const HomeViewModel({
    required this.studentDisplayName,
    required this.currentQuarter,
    required this.currentWeek,
    required this.percentComplete,
    required this.continueLesson,
    required this.lessonsCompletedCount,
    required this.quizzesTakenCount,
    required this.lastAttempts,
    required this.onRedeemCode,
  });

  final String studentDisplayName;
  final int? currentQuarter;
  final int? currentWeek;
  final double percentComplete;
  final Lesson? continueLesson;
  final int lessonsCompletedCount;
  final int quizzesTakenCount;
  final List<QuizAttempt> lastAttempts;
  final Future<AccessCodeResult> Function(String rawCode) onRedeemCode;
}

/// Overridden in tests (see Step 1); in the real app this is provided by a
/// ProviderScope override at app startup once the signed-in student id is
/// known (wired alongside AuthService in a later task/screen, not repeated
/// here to avoid duplicating Phase 1's auth wiring).
final homeViewModelProvider = StreamProvider.autoDispose<HomeViewModel>((ref) {
  throw UnimplementedError(
    'homeViewModelProvider must be overridden with a real student-scoped '
    'stream at app startup — see home_providers_test.dart for the shape.',
  );
});

/// Builds the real streaming view model for a signed-in student. Called from
/// the app-startup override, not from HomeScreen directly.
Stream<HomeViewModel> buildHomeViewModel({
  required String studentId,
  required StudentRepository studentRepository,
  required AccessCodeService accessCodeService,
  required List<Lesson> orderedLessons,
}) {
  return studentRepository.watchStudent(studentId).map((student) {
    if (student == null) {
      return HomeViewModel(
        studentDisplayName: studentId,
        currentQuarter: null,
        currentWeek: null,
        percentComplete: 0,
        continueLesson: orderedLessons.isNotEmpty ? orderedLessons.first : null,
        lessonsCompletedCount: 0,
        quizzesTakenCount: 0,
        lastAttempts: const [],
        onRedeemCode: (code) => accessCodeService.redeem(studentId: studentId, rawCode: code),
      );
    }
    final quarterWeek = currentQuarterWeek(orderedLessons, student);
    return HomeViewModel(
      studentDisplayName: student.name.isNotEmpty ? student.name.split(' ').first : studentId,
      currentQuarter: quarterWeek?.quarter,
      currentWeek: quarterWeek?.week,
      percentComplete: percentComplete(student),
      continueLesson: nextIncompleteLesson(orderedLessons, student),
      lessonsCompletedCount: student.completedLessonIds.length,
      quizzesTakenCount: student.quizAttempts.length,
      lastAttempts: lastNAttempts(student),
      onRedeemCode: (code) => accessCodeService.redeem(studentId: studentId, rawCode: code),
    );
  });
}
