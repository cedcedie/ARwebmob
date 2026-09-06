import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/built_in_question.dart';
import '../../../core/models/question_type.dart';
import '../../../core/models/subject_key.dart';
import '../../../core/services/item_analysis_calculator.dart';
import '../widgets/error_state.dart';
import '../../../core/util/file_download.dart';
import 'item_analysis_csv.dart';
import 'item_analysis_providers.dart';

/// Narrow-viewport breakpoint — matches `TeacherShell`'s and
/// `quizzes_screen.dart`'s own `<720` collapse point, applied here to switch
/// each question card's stats/chart from a side-by-side row to a stacked
/// column so numbers never get squeezed unreadably thin.
const _kCompactBreakpoint = 720.0;

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
    final isCompact = MediaQuery.sizeOf(context).width < _kCompactBreakpoint;

    // No own `AppBar`/top-level `Scaffold` chrome — like every other screen
    // nested under `TeacherShell`, the shell's persistent side nav is the
    // app's chrome. A plain `Navigator.maybePop` back arrow (rather than a
    // `go_router` `context.pop()`) covers this screen still being reached
    // by push from the quiz table, without requiring a `GoRouter` ancestor
    // in isolated widget tests.
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(isCompact ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ShadIconButton.ghost(
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item Analysis',
                        style: ShadTheme.of(context).textTheme.muted.copyWith(
                          color: ShadTheme.of(
                            context,
                          ).colorScheme.mutedForeground,
                        ),
                      ),
                      Text(
                        quizTitle,
                        style: ShadTheme.of(context).textTheme.h3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Export is only offered once there is something to export —
                // an empty CSV is worse than no button.
                if (asyncViewModel.valueOrNull case final vm?
                    when vm.attemptCount > 0)
                  _ExportCsvButton(viewModel: vm, isCompact: isCompact),
              ],
            ),
            SizedBox(height: isCompact ? 16 : 20),
            Expanded(
              child: asyncViewModel.when(
                loading: () => const _ItemAnalysisSkeleton(),
                error: (error, stack) => ErrorState(
                  message: humanizeLoadError(
                    error,
                    subjectLabel: 'item analysis',
                  ),
                  onRetry: () =>
                      ref.invalidate(itemAnalysisViewModelProvider(quizId)),
                ),
                data: (vm) {
                  if (vm.attemptCount == 0) {
                    return const _NoAttemptsState();
                  }
                  return ListView(
                    children: [
                      _AttemptCountBanner(count: vm.attemptCount),
                      const SizedBox(height: 16),
                      for (var i = 0; i < vm.questions.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child:
                              _QuestionAnalysisCard(
                                question: vm.questions[i],
                                result: vm.results[i],
                                attemptCount: vm.attemptCount,
                                isCompact: isCompact,
                              ).animate().fadeIn(
                                duration: 220.ms,
                                delay: (i * 30).ms,
                              ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttemptCountBanner extends StatelessWidget {
  const _AttemptCountBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Row(
      children: [
        Icon(LucideIcons.users, size: 16, color: scheme.mutedForeground),
        const SizedBox(width: 8),
        Text(
          '$count ${count == 1 ? 'attempt' : 'attempts'} analyzed',
          style: ShadTheme.of(
            context,
          ).textTheme.small.copyWith(color: scheme.mutedForeground),
        ),
      ],
    );
  }
}

class _NoAttemptsState extends StatelessWidget {
  const _NoAttemptsState();

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return ShadCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.muted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.barChart,
                  size: 28,
                  color: scheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No attempts yet',
                style: ShadTheme.of(context).textTheme.h4,
              ),
              const SizedBox(height: 4),
              Text(
                'Item analysis appears once students start taking this quiz.',
                style: ShadTheme.of(
                  context,
                ).textTheme.muted.copyWith(color: scheme.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

/// Loading placeholder shaped like the eventual question-card stack, rather
/// than a bare centered spinner.
class _ItemAnalysisSkeleton extends StatelessWidget {
  const _ItemAnalysisSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    // A ListView, not a Column: three 180px placeholders overflow a short
    // viewport (and a teacher's browser window can be short).
    return ListView(
      children: [
        for (var i = 0; i < 3; i++) ...[
          ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: ColoredBox(color: scheme.muted),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 700.ms, begin: 0.5),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _QuestionAnalysisCard extends StatelessWidget {
  const _QuestionAnalysisCard({
    required this.question,
    required this.result,
    required this.attemptCount,
    required this.isCompact,
  });

  final BuiltInQuestion question;
  final QuestionItemAnalysis result;

  /// How many attempts this analysis was computed over. Kept alongside the
  /// rates so every percentage can also be stated as a headcount — UAT
  /// feedback was that teachers want "how many students got this right",
  /// not only a percentage they'd have to convert back themselves.
  final int attemptCount;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final difficultyPct = (result.difficultyIndex * 100).round();
    // `difficultyIndex` is exactly correctCount / attemptCount, so this
    // recovers the original headcount without rounding drift.
    final correctCount = (result.difficultyIndex * attemptCount).round();
    final discriminationLabel = result.discriminationIndex >= 0
        ? '+${(result.discriminationIndex * 100).round()}%'
        : '${(result.discriminationIndex * 100).round()}%';
    // Theme-derived (physics accent) via the dark-mode-aware `custom` map —
    // never `AppColors.physics` directly, which stays pinned to the light
    // palette regardless of the active theme.
    final physicsAccent = _subjectAccent(context, SubjectKey.physics);
    final biologyAccent = _subjectAccent(context, SubjectKey.biology);

    final stats = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatRow(
          label: 'Difficulty',
          value: '$difficultyPct% correct',
          color: physicsAccent,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            '$correctCount of $attemptCount '
            '${attemptCount == 1 ? 'student' : 'students'} answered correctly',
            style: ShadTheme.of(
              context,
            ).textTheme.small.copyWith(color: scheme.mutedForeground),
          ),
        ),
        const SizedBox(height: 8),
        _StatRow(
          label: 'Discrimination',
          value: discriminationLabel,
          color: result.discriminationIndex >= 0
              ? biologyAccent
              : scheme.destructive,
        ),
        if (question.type == QuestionType.mc &&
            result.distractorRates.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Distractors',
            style: ShadTheme.of(
              context,
            ).textTheme.small.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          for (final entry in result.distractorRates.entries)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${question.options[entry.key]}: '
                '${(entry.value * 100).round()}% '
                '(${(entry.value * attemptCount).round()} '
                '${(entry.value * attemptCount).round() == 1 ? 'student' : 'students'})',
                style: ShadTheme.of(
                  context,
                ).textTheme.small.copyWith(color: scheme.mutedForeground),
              ),
            ),
        ],
      ],
    );

    final chart = SizedBox(
      height: 130,
      child: BarChart(
        BarChartData(
          maxY: 100,
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: result.difficultyIndex * 100,
                  color: physicsAccent,
                  width: 28,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: (result.discriminationIndex.clamp(-1.0, 1.0) * 100)
                      .abs(),
                  color: result.discriminationIndex >= 0
                      ? biologyAccent
                      : scheme.destructive,
                  width: 28,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
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
                  final label = value == 0 ? 'Difficulty' : 'Discrimination';
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.mutedForeground,
                      ),
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
                  style: TextStyle(fontSize: 10, color: scheme.mutedForeground),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${result.questionIndex + 1}',
            style: ShadTheme.of(
              context,
            ).textTheme.small.copyWith(color: scheme.mutedForeground),
          ),
          const SizedBox(height: 2),
          Text(question.question, style: ShadTheme.of(context).textTheme.p),
          const SizedBox(height: 12),
          // Side-by-side on a wide viewport (stats column left, chart
          // right); stacked on a narrow one so the chart's fixed-width bars
          // and stat text never fight for the same cramped row.
          if (isCompact) ...[
            stats,
            const SizedBox(height: 12),
            chart,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: stats),
                const SizedBox(width: 20),
                Expanded(flex: 5, child: chart),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$label: ',
            style: ShadTheme.of(
              context,
            ).textTheme.small.copyWith(color: scheme.mutedForeground),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Flexible: in a narrow card the label + value can exceed the row's
        // width, which used to clip the number itself.
        Flexible(
          child: Text(
            value,
            style: ShadTheme.of(
              context,
            ).textTheme.small.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Theme-aware subject accent lookup — see `lessons_screen.dart`'s and
/// `quizzes_screen.dart`'s identical helper. Prefer this over
/// `subjectColor()`/`.accentColor` (`app_theme.dart`), which always resolve
/// to the *light* palette regardless of the active theme mode.
Color _subjectAccent(BuildContext context, SubjectKey subject) {
  final custom = ShadTheme.of(context).colorScheme.custom;
  final key = switch (subject) {
    SubjectKey.chemistry => 'chemistry',
    SubjectKey.biology => 'biology',
    SubjectKey.physics => 'physics',
  };
  // Fall back to the static palette when the active ShadThemeData carries
  // no `custom` map (a bare `ShadApp` with no theme, as in widget tests) —
  // a missing accent must never crash a whole screen.
  return custom[key] ?? subjectColor(subject);
}

/// Downloads the item-analysis table as a CSV the teacher can open in Excel
/// or print. Requested at UAT: the teachers wanted the numbers to take away,
/// not just to read on screen.
class _ExportCsvButton extends StatelessWidget {
  const _ExportCsvButton({required this.viewModel, required this.isCompact});

  final ItemAnalysisViewModel viewModel;
  final bool isCompact;

  void _export(BuildContext context) {
    final saved = downloadTextFile(
      fileName: itemAnalysisCsvFileName(viewModel.quizTitle),
      content: buildItemAnalysisCsv(viewModel),
    );
    if (!context.mounted) return;
    if (saved) {
      ShadToaster.of(
        context,
      ).show(const ShadToast(description: Text('Item analysis downloaded')));
    } else {
      // Non-web build: say so rather than leaving the button looking broken.
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text(
            "Downloading isn't supported here. Open the teacher portal in a "
            'web browser to export.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return ShadIconButton.outline(
        icon: const Icon(LucideIcons.download),
        onPressed: () => _export(context),
      );
    }
    return ShadButton.outline(
      onPressed: () => _export(context),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.download, size: 16),
          SizedBox(width: 8),
          Text('Export CSV'),
        ],
      ),
    );
  }
}
