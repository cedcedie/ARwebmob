import '../models/built_in_question.dart';
import '../models/quiz_attempt.dart';

/// Per-question item analysis result — PROJECT_FLOW.md Part 7.5.
class QuestionItemAnalysis {
  const QuestionItemAnalysis({
    required this.questionIndex,
    required this.difficultyIndex,
    required this.discriminationIndex,
    required this.distractorRates,
  });

  final int questionIndex;
  final double difficultyIndex;
  final double discriminationIndex;

  /// Wrong-option index -> fraction of all students who chose it. The
  /// correct option is never a key here.
  final Map<int, double> distractorRates;
}

/// Computes per-question item analysis across every attempt on one quiz.
/// [questions] and each attempt's `answers[i]` must be index-aligned —
/// callers are responsible for resolving the right question bank for the
/// quiz (built-in or teacher-authored) before calling this.
List<QuestionItemAnalysis> computeItemAnalysis({
  required List<BuiltInQuestion> questions,
  required List<QuizAttempt> attempts,
}) {
  final total = attempts.length;
  if (total == 0) {
    return [
      for (var i = 0; i < questions.length; i++)
        QuestionItemAnalysis(
          questionIndex: i,
          difficultyIndex: 0.0,
          discriminationIndex: 0.0,
          distractorRates: const {},
        ),
    ];
  }

  final sortedByScore = [...attempts]
    ..sort((a, b) => b.score.compareTo(a.score));
  final groupSize = (total * 0.27).ceil().clamp(1, total);
  final topGroup = sortedByScore.take(groupSize).toList();
  final bottomGroup = sortedByScore.reversed.take(groupSize).toList();

  return [
    for (var i = 0; i < questions.length; i++)
      _analyzeQuestion(i, questions[i], attempts, topGroup, bottomGroup, total),
  ];
}

QuestionItemAnalysis _analyzeQuestion(
  int questionIndex,
  BuiltInQuestion question,
  List<QuizAttempt> attempts,
  List<QuizAttempt> topGroup,
  List<QuizAttempt> bottomGroup,
  int total,
) {
  bool answeredCorrectly(QuizAttempt a) =>
      questionIndex < a.answers.length &&
      a.answers[questionIndex] == question.correctIndex;

  final correctCount = attempts.where(answeredCorrectly).length;
  final difficultyIndex = correctCount / total;

  final topCorrectRate = topGroup.isEmpty
      ? 0.0
      : topGroup.where(answeredCorrectly).length / topGroup.length;
  final bottomCorrectRate = bottomGroup.isEmpty
      ? 0.0
      : bottomGroup.where(answeredCorrectly).length / bottomGroup.length;
  final discriminationIndex = topCorrectRate - bottomCorrectRate;

  final distractorCounts = <int, int>{};
  for (final attempt in attempts) {
    if (questionIndex >= attempt.answers.length) continue;
    final chosen = attempt.answers[questionIndex];
    if (chosen == question.correctIndex) continue;
    if (chosen < 0 || chosen >= question.options.length)
      continue; // unanswered (-1) or invalid
    distractorCounts[chosen] = (distractorCounts[chosen] ?? 0) + 1;
  }
  final distractorRates = {
    for (final entry in distractorCounts.entries)
      entry.key: entry.value / total,
  };

  return QuestionItemAnalysis(
    questionIndex: questionIndex,
    difficultyIndex: difficultyIndex,
    discriminationIndex: discriminationIndex,
    distractorRates: distractorRates,
  );
}
