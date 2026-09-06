import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'progress_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncViewModel = ref.watch(progressViewModelProvider);

    return Scaffold(
      body: asyncViewModel.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ProgressError(error: error),
        data: (vm) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            for (var i = 0; i < vm.subjectSections.length; i++)
              _SubjectSection(
                section: vm.subjectSections[i],
                delay: (i * 60).ms,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressError extends StatelessWidget {
  const _ProgressError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AppColors.inkMuted,
            ),
            const SizedBox(height: 12),
            Text(
              "Couldn't load your progress",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectSection extends StatelessWidget {
  const _SubjectSection({required this.section, required this.delay});

  final SubjectProgressSection section;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final accent = section.subject.accentColor;
    final label =
        '${section.subject.name[0].toUpperCase()}${section.subject.name.substring(1)}';
    final completedCount = section.lessons.where((l) => l.isCompleted).length;

    return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (section.lessons.isNotEmpty)
                    Text(
                      '$completedCount/${section.lessons.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (section.lessons.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No lessons in this subject yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < section.lessons.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _LessonRow(lesson: section.lessons[i], accent: accent),
                      ],
                    ],
                  ),
                ),
              if (section.quizAttempts.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final attempt in section.quizAttempts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _QuizAttemptCard(attempt: attempt, accent: accent),
                  ),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 260.ms, delay: delay, curve: Curves.easeOut)
        .slideY(
          begin: 0.03,
          end: 0,
          duration: 260.ms,
          delay: delay,
          curve: Curves.easeOut,
        );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, required this.accent});

  final LessonProgressRow lesson;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        lesson.isCompleted
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked,
        color: lesson.isCompleted ? AppColors.success : AppColors.inkMuted,
      ),
      title: Text(lesson.title),
      trailing: lesson.isCompleted
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Completed',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : Text(
              'Not yet',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
    );
  }
}

class _QuizAttemptCard extends StatelessWidget {
  const _QuizAttemptCard({required this.attempt, required this.accent});

  final QuizAttemptRow attempt;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: accent.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attempt.quizId,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              'Best: ${attempt.bestScore}% · Latest: ${attempt.latestScore}%',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 6),
            // Running totals (client request): the per-question chips below
            // show *which* items were right, but a student/teacher scanning
            // the card had to count the chips by hand to answer "how many
            // did I get right?" — this states it outright.
            Builder(
              builder: (context) {
                final correctCount = attempt.perQuestionCorrect
                    .where((isCorrect) => isCorrect)
                    .length;
                final incorrectCount =
                    attempt.perQuestionCorrect.length - correctCount;
                return Text(
                  '$correctCount correct · $incorrectCount incorrect '
                  '(out of ${attempt.perQuestionCorrect.length})',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                );
              },
            ),
            const SizedBox(height: 10),
            // Accessible per-question indicator: icon + text label together
            // (Part 10.3) — never color-only, never tooltip/hover-only.
            // Kept exactly that shape here, just colored to match its
            // meaning instead of the flat default chip. Each chip is now
            // numbered too, so "item 3 was wrong" is readable straight off
            // the card instead of counting chip positions.
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < attempt.perQuestionCorrect.length; i++)
                  _QuestionChip(
                    questionNumber: i + 1,
                    correct: attempt.perQuestionCorrect[i],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionChip extends StatelessWidget {
  const _QuestionChip({required this.questionNumber, required this.correct});

  /// 1-based item number, shown on the chip so a student can tell *which*
  /// question each result belongs to without counting positions.
  final int questionNumber;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.success : AppColors.destructive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(correct ? Icons.check : Icons.close, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$questionNumber. ${correct ? 'Correct' : 'Incorrect'}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
