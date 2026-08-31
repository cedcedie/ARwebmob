import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/quiz_phase.dart';
import '../../../core/models/teacher_quiz.dart';
import '../lessons/lessons_providers.dart' show subjectKeyLabel;
import '../widgets/error_state.dart';
import '../widgets/subject_accent_cell.dart';
import 'quiz_form.dart';
import 'quizzes_providers.dart';

class QuizzesScreen extends ConsumerWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVm = ref.watch(quizzesViewModelProvider);

    return asyncVm.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: humanizeLoadError(error, subjectLabel: 'quizzes'),
        onRetry: () => ref.invalidate(quizzesViewModelProvider),
      ),
      data: (vm) => _QuizzesBody(viewModel: vm),
    );
  }
}

class _QuizzesBody extends StatelessWidget {
  const _QuizzesBody({required this.viewModel});

  final QuizzesViewModel viewModel;

  Future<void> _openForm(BuildContext context, {TeacherQuiz? initial}) async {
    final isCreate = initial == null;
    await showShadDialog<void>(
      context: context,
      // Require the explicit Cancel action (or a successful submit) to
      // close — an accidental outside click shouldn't silently discard an
      // in-progress multi-question quiz edit.
      barrierDismissible: false,
      builder: (dialogContext) {
        return ShadDialog(
          title: Text(isCreate ? 'Add quiz' : 'Edit quiz'),
          child: SizedBox(
            width: 720,
            // See lessons_screen.dart's `_openForm` for why the transparent
            // Material ancestor is needed here.
            child: Material(
              type: MaterialType.transparency,
              child: QuizForm(
                initial: initial,
                submitLabel: isCreate ? 'Create' : 'Save',
                onSubmit: (quiz) async {
                  if (isCreate) {
                    await viewModel.onCreateQuiz(quiz);
                  } else {
                    await viewModel.onUpdateQuiz(quiz);
                  }
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    ShadToaster.of(context).show(
                      ShadToast(
                        description: Text(
                          isCreate ? 'Quiz created' : 'Quiz saved',
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String quizId) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Delete quiz?'),
        description: const Text(
          'This permanently removes the teacher-authored quiz.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
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
                minWidth: 960,
                columns: const [
                  DataColumn2(label: Text('Title'), size: ColumnSize.L),
                  DataColumn2(label: Text('Subject'), size: ColumnSize.S),
                  DataColumn2(label: Text('Phase'), size: ColumnSize.S),
                  DataColumn2(label: Text('Questions'), size: ColumnSize.S),
                  DataColumn2(label: Text('Built-in?'), size: ColumnSize.S),
                  DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                ],
                rows: viewModel.rows.map((row) {
                  final quiz = row.quiz;
                  final phaseLabel = quiz.phase == QuizPhase.pre
                      ? 'Pre-Test'
                      : 'Post-Test';

                  return DataRow(
                    cells: [
                      DataCell(
                        SubjectAccentCell(
                          subject: quiz.subject,
                          child: Text(
                            quiz.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(subjectKeyLabel(quiz.subject))),
                      DataCell(Text(phaseLabel)),
                      DataCell(Text('${quiz.questions.length}')),
                      DataCell(
                        row.isBuiltIn
                            ? const ShadBadge(child: Text('Built-in'))
                            : const Text('—'),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: 'Item analysis',
                              child: ShadIconButton.ghost(
                                icon: const Icon(LucideIcons.barChart),
                                onPressed: () => context.push(
                                  '/teacher/quizzes/${quiz.id}/item-analysis',
                                  extra: quiz.title,
                                ),
                              ),
                            ),
                            if (!row.isBuiltIn) ...[
                              Tooltip(
                                message: 'Edit',
                                child: ShadIconButton.ghost(
                                  icon: const Icon(LucideIcons.pencil),
                                  onPressed: () =>
                                      _openForm(context, initial: quiz),
                                ),
                              ),
                              Tooltip(
                                message: 'Delete',
                                child: ShadIconButton.ghost(
                                  icon: const Icon(LucideIcons.trash2),
                                  onPressed: () =>
                                      _confirmDelete(context, quiz.id),
                                ),
                              ),
                            ],
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
