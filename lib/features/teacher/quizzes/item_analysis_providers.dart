import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/data/curriculum_data.dart';
import '../../../core/models/built_in_question.dart';
import '../../../core/models/quiz_phase.dart';
import '../../../core/quiz_id.dart';
import '../../../core/services/item_analysis_calculator.dart';
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/quiz_repository.dart';
import '../../../core/services/student_repository.dart';

class ItemAnalysisViewModel {
  const ItemAnalysisViewModel({
    required this.quizTitle,
    required this.questions,
    required this.results,
    required this.attemptCount,
  });

  final String quizTitle;
  final List<BuiltInQuestion> questions;
  final List<QuestionItemAnalysis> results;
  final int attemptCount;
}

final itemAnalysisViewModelProvider =
    StreamProvider.autoDispose.family<ItemAnalysisViewModel, String>((ref, quizId) {
  throw UnimplementedError(
    'itemAnalysisViewModelProvider must be overridden at app startup with a '
    'real stream for the given quizId.',
  );
});

Stream<ItemAnalysisViewModel> buildItemAnalysisViewModel({
  required String quizId,
  required String quizTitle,
  required StudentRepository studentRepository,
  required QuizRepository quizRepository,
  required LessonRepository lessonRepository,
}) async* {
  final parsed = parseBuiltinId(quizId);
  List<BuiltInQuestion> questions;
  // Attempts on a linked teacher-authored quiz's post-test are always
  // recorded under the synthesized `builtin-{lessonId}-post` id (see
  // router.dart's `/quiz/:lessonId/:phase` route and quiz_id.dart), never
  // under the teacher quiz's own Firestore doc id — even when this
  // `quizId` IS that doc id (i.e. the teacher opened item analysis from
  // the authored-quiz row in quizzes_screen.dart). Default to filtering
  // attempts by `quizId` itself and only widen to the resolved builtin id
  // below when a lesson actually links to this quiz.
  var attemptQuizId = quizId;
  if (parsed.isBuiltin && parsed.lessonId != null) {
    questions = parsed.phase == QuizPhase.pre
        ? kPreTestQuestionsByLesson[parsed.lessonId!] ?? const <BuiltInQuestion>[]
        : kPostTestQuestionsByLesson[parsed.lessonId!] ?? const <BuiltInQuestion>[];
  } else {
    final teacherQuiz = await quizRepository.fetchQuizById(quizId);
    questions = teacherQuiz == null
        ? const <BuiltInQuestion>[]
        : quizRepository.questionsFromTeacherQuiz(teacherQuiz, lessonId: quizId);

    final teacherLessons = await lessonRepository.fetchTeacherLessons();
    for (final lesson in teacherLessons) {
      if (lesson.linkedQuizId == quizId) {
        attemptQuizId = builtinQuizId(lesson.id, QuizPhase.post);
        break;
      }
    }
  }

  yield* studentRepository.watchAllStudents(includeArchived: true).map((students) {
    final attempts = [
      for (final student in students)
        for (final attempt in student.quizAttempts)
          if (attempt.quizId == attemptQuizId) attempt,
    ];

    return ItemAnalysisViewModel(
      quizTitle: quizTitle,
      questions: questions,
      results: computeItemAnalysis(questions: questions, attempts: attempts),
      attemptCount: attempts.length,
    );
  });
}
