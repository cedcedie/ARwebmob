import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/data/curriculum_data.dart';
import '../../../core/models/quiz_phase.dart';
import '../../../core/models/teacher_quiz.dart';
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/quiz_repository.dart';

class QuizzesViewModel {
  const QuizzesViewModel({
    required this.rows,
    required this.onCreateQuiz,
    required this.onUpdateQuiz,
    required this.onDeleteQuiz,
  });

  final List<DisplayQuiz> rows;
  final Future<void> Function(TeacherQuiz quiz) onCreateQuiz;
  final Future<void> Function(TeacherQuiz quiz) onUpdateQuiz;
  final Future<void> Function(String quizId) onDeleteQuiz;
}

final quizzesViewModelProvider = StreamProvider.autoDispose<QuizzesViewModel>((ref) {
  throw UnimplementedError(
    'quizzesViewModelProvider must be overridden at app startup — see '
    'teacherProviderOverridesFor.',
  );
});

Stream<QuizzesViewModel> buildQuizzesViewModel({
  required LessonRepository lessonRepository,
  required QuizRepository quizRepository,
}) {
  return quizRepository.watchTeacherQuizzes().asyncMap((teacherQuizzes) async {
    final teacherLessons = await lessonRepository.fetchTeacherLessons();
    final lessons = lessonRepository.mergedLessons(teacherLessons);

    final rows = quizRepository.mergedQuizzes(
      teacherQuizzes: teacherQuizzes,
      lessons: lessons,
      preTestQuestionsByLesson: kPreTestQuestionsByLesson,
      postTestQuestionsByLesson: kPostTestQuestionsByLesson,
    );

    return QuizzesViewModel(
      rows: rows,
      onCreateQuiz: quizRepository.createQuiz,
      onUpdateQuiz: quizRepository.updateQuiz,
      onDeleteQuiz: quizRepository.deleteQuiz,
    );
  });
}

String quizPhaseLabel(QuizPhase phase) {
  switch (phase) {
    case QuizPhase.pre:
      return 'Pre-Test';
    case QuizPhase.post:
      return 'Post-Test';
  }
}
