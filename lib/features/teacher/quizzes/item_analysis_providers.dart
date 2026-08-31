import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/data/curriculum_data.dart';
import '../../../core/models/built_in_question.dart';
import '../../../core/quiz_id.dart';
import '../../../core/services/item_analysis_calculator.dart';
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
}) {
  final parsed = parseBuiltinId(quizId);
  final questions = parsed.isBuiltin && parsed.lessonId != null
      ? (parsed.phase.name == 'pre'
          ? kPreTestQuestionsByLesson[parsed.lessonId!] ?? const <BuiltInQuestion>[]
          : kPostTestQuestionsByLesson[parsed.lessonId!] ?? const <BuiltInQuestion>[])
      : const <BuiltInQuestion>[]; // teacher-linked quiz question resolution — see Task 2 note below

  return studentRepository.watchAllStudents(includeArchived: true).map((students) {
    final attempts = [
      for (final student in students)
        for (final attempt in student.quizAttempts)
          if (attempt.quizId == quizId) attempt,
    ];

    return ItemAnalysisViewModel(
      quizTitle: quizTitle,
      questions: questions,
      results: computeItemAnalysis(questions: questions, attempts: attempts),
      attemptCount: attempts.length,
    );
  });
}
