import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/quiz_phase.dart';
import '../../../core/models/teacher_quiz.dart';
import '../lessons/lessons_providers.dart' show subjectKeyLabel;
import 'quiz_form.dart';
import 'quizzes_providers.dart';

class QuizzesScreen extends ConsumerWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVm = ref.watch(quizzesViewModelProvider);

    return asyncVm.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error loading quizzes: $error')),
      data: (vm) => _QuizzesBody(viewModel: vm),
    );
  }
}

class _QuizzesBody extends StatelessWidget {
  const _QuizzesBody({required this.viewModel});

  final QuizzesViewModel viewModel;

  Future<void> _openForm(
    BuildContext context, {
    TeacherQuiz? initial,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(initial == null ? 'Add quiz' : 'Edit quiz'),
          content: SizedBox(
            width: 720,
            child: QuizForm(
              initial: initial,
              submitLabel: initial == null ? 'Create' : 'Save',
              onSubmit: (quiz) async {
                if (initial == null) {
                  await viewModel.onCreateQuiz(quiz);
                } else {
                  await viewModel.onUpdateQuiz(quiz);
                }
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String quizId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete quiz?'),
        content: const Text('This permanently removes the teacher-authored quiz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await viewModel.onDeleteQuiz(quizId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Quizzes', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              ShadButton(
                onPressed: () => _openForm(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 16),
                    SizedBox(width: 8),
                    Text('Add Quiz'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 16,
                minWidth: 900,
                columns: const [
                  DataColumn2(label: Text('Title'), size: ColumnSize.L),
                  DataColumn2(label: Text('Subject'), size: ColumnSize.S),
                  DataColumn2(label: Text('Phase'), size: ColumnSize.S),
                  DataColumn2(label: Text('Questions'), size: ColumnSize.S),
                  DataColumn2(label: Text('Built-in?'), size: ColumnSize.S),
                  DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                ],
                rows: viewModel.rows.map((row) {
                  final quiz = row.quiz;
                  final phaseLabel = quiz.phase == QuizPhase.pre ? 'Pre-Test' : 'Post-Test';

                  return DataRow(
                    cells: [
                      DataCell(Text(quiz.title, overflow: TextOverflow.ellipsis)),
                      DataCell(Text(subjectKeyLabel(quiz.subject))),
                      DataCell(Text(phaseLabel)),
                      DataCell(Text('${quiz.questions.length}')),
                      DataCell(
                        row.isBuiltIn
                            ? const ShadBadge(child: Text('Built-in'))
                            : const Text('—'),
                      ),
                      DataCell(
                        row.isBuiltIn
                            ? const SizedBox.shrink()
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    icon: const Icon(LucideIcons.pencil),
                                    onPressed: () => _openForm(context, initial: quiz),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(LucideIcons.trash2),
                                    onPressed: () => _confirmDelete(context, quiz.id),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
