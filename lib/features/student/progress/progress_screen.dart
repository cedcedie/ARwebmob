import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'progress_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncViewModel = ref.watch(progressViewModelProvider);

    return Scaffold(
      body: asyncViewModel.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load your progress: $error')),
        data: (vm) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final section in vm.subjectSections) ...[
              Text(
                section.subject.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final lesson in section.lessons)
                ListTile(
                  leading: Icon(
                    lesson.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(lesson.title),
                  trailing: Text(lesson.isCompleted ? 'Completed' : 'Not yet'),
                ),
              for (final attempt in section.quizAttempts) ...[
                ListTile(
                  title: Text(attempt.quizId),
                  subtitle: Text(
                    'Best: ${attempt.bestScore}% · Latest: ${attempt.latestScore}%',
                  ),
                ),
                // Accessible per-question indicator: icon + text label
                // together (Part 10.3) — never color-only, never
                // tooltip/hover-only.
                Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < attempt.perQuestionCorrect.length; i++)
                      Chip(
                        avatar: Icon(
                          attempt.perQuestionCorrect[i]
                              ? Icons.check
                              : Icons.close,
                          size: 16,
                        ),
                        label: Text(
                          attempt.perQuestionCorrect[i]
                              ? 'Correct'
                              : 'Incorrect',
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
