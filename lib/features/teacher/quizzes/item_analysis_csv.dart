import '../../../core/util/csv.dart';
import 'item_analysis_providers.dart';

/// Builds the downloadable item-analysis report for one quiz.
///
/// The point of the export is the client's stated reason for wanting item
/// analysis at all — "para hindi na raw sila mag-compute". So every figure is
/// given both ways: as a headcount and as a percentage, with the totals
/// stated on the row rather than implied by a header somewhere above it.
String buildItemAnalysisCsv(ItemAnalysisViewModel vm) {
  final rows = <List<Object?>>[
    ['Quiz', vm.quizTitle],
    ['Attempts analyzed', vm.attemptCount],
    // Blank spacer row, so the table below reads as its own block when the
    // file is opened in Excel.
    const [],
    const [
      'Item',
      'Question',
      'Correct answer',
      'Students correct',
      'Students total',
      '% correct',
      'Discrimination %',
      'Most-chosen wrong answer',
      'All wrong answers chosen',
    ],
  ];

  for (var i = 0; i < vm.questions.length; i++) {
    final question = vm.questions[i];
    final result = vm.results[i];
    final correctCount = (result.difficultyIndex * vm.attemptCount).round();

    // Distractors, worst first — the teacher's actual question is "which
    // wrong answer is pulling students away", so the ordering answers it
    // without them having to scan.
    final distractors = result.distractorRates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String describe(MapEntry<int, double> entry) {
      final label = entry.key < question.options.length
          ? question.options[entry.key]
          : 'Option ${entry.key + 1}';
      final count = (entry.value * vm.attemptCount).round();
      return '$label ($count, ${(entry.value * 100).round()}%)';
    }

    rows.add([
      i + 1,
      question.question,
      question.correctIndex < question.options.length
          ? question.options[question.correctIndex]
          : '',
      correctCount,
      vm.attemptCount,
      (result.difficultyIndex * 100).round(),
      (result.discriminationIndex * 100).round(),
      distractors.isEmpty ? '' : describe(distractors.first),
      distractors.map(describe).join('; '),
    ]);
  }

  return encodeCsv(rows);
}

/// Filename for the export — the quiz title, reduced to characters every
/// filesystem accepts, plus the date so repeated exports don't overwrite
/// each other in the teacher's Downloads folder.
String itemAnalysisCsvFileName(String quizTitle, {DateTime? now}) {
  final date = now ?? DateTime.now();
  final stamp =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
  final safeTitle = quizTitle
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '')
      .toLowerCase();
  final base = safeTitle.isEmpty ? 'quiz' : safeTitle;
  return 'item-analysis-$base-$stamp.csv';
}
