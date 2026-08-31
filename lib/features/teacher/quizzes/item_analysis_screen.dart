import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/built_in_question.dart';
import '../../../core/models/question_type.dart';
import '../../../core/services/item_analysis_calculator.dart';
import '../../../core/theme/app_theme.dart';
import 'item_analysis_providers.dart';

class ItemAnalysisScreen extends ConsumerWidget {
  const ItemAnalysisScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  final String quizId;
  final String quizTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncViewModel = ref.watch(itemAnalysisViewModelProvider(quizId));

    return Scaffold(
      appBar: AppBar(title: Text('Item Analysis — $quizTitle')),
      body: asyncViewModel.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load item analysis: $error')),
        data: (vm) {
          if (vm.attemptCount == 0) {
            return const Center(child: Text('No attempts yet on this quiz.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${vm.attemptCount} attempts analyzed'),
              const SizedBox(height: 16),
              for (var i = 0; i < vm.questions.length; i++)
                _QuestionAnalysisCard(
                  question: vm.questions[i],
                  result: vm.results[i],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _QuestionAnalysisCard extends StatelessWidget {
  const _QuestionAnalysisCard({required this.question, required this.result});

  final BuiltInQuestion question;
  final QuestionItemAnalysis result;

  @override
  Widget build(BuildContext context) {
    final difficultyPct = (result.difficultyIndex * 100).round();
    final discriminationLabel = result.discriminationIndex >= 0
        ? '+${(result.discriminationIndex * 100).round()}%'
        : '${(result.discriminationIndex * 100).round()}%';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q${result.questionIndex + 1}: ${question.question}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Difficulty: $difficultyPct% correct'),
            Text('Discrimination: $discriminationLabel'),
            SizedBox(
              height: 110,
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: result.difficultyIndex * 100,
                          // Theme-derived (physics accent) rather than a
                          // literal Colors.blue.
                          color: AppColors.physics,
                          width: 28,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY:
                              (result.discriminationIndex.clamp(-1.0, 1.0) *
                                      100)
                                  .abs(),
                          // Theme-derived positive/negative pair (biology
                          // green / the theme's destructive red) rather than
                          // literal Colors.green/Colors.red.
                          color: result.discriminationIndex >= 0
                              ? AppColors.biology
                              : AppColors.destructive,
                          width: 28,
                        ),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final label = value == 0
                              ? 'Difficulty'
                              : 'Discrimination';
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 50,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.round()}%',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
            if (question.type == QuestionType.mc &&
                result.distractorRates.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Distractors:',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              for (final entry in result.distractorRates.entries)
                Text(
                  '  ${question.options[entry.key]}: ${(entry.value * 100).round()}%',
                ),
            ],
          ],
        ),
      ),
    );
  }
}
