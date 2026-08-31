import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/teacher_lesson.dart';
import '../widgets/subject_accent_cell.dart';
import 'lesson_form.dart';
import 'lessons_providers.dart';

class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVm = ref.watch(lessonsViewModelProvider);

    return asyncVm.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error loading lessons: $error')),
      data: (vm) => _LessonsBody(viewModel: vm),
    );
  }
}

class _LessonsBody extends StatelessWidget {
  const _LessonsBody({required this.viewModel});

  final LessonsViewModel viewModel;

  Future<void> _openForm(BuildContext context, {TeacherLesson? initial}) async {
    await showShadDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ShadDialog(
          title: Text(initial == null ? 'Add lesson' : 'Edit lesson'),
          child: SizedBox(
            width: 640,
            // `LessonForm` uses Material `FormBuilderTextField`s, which need
            // a `Material` ancestor — `ShadDialog` doesn't provide one (it's
            // built entirely from shadcn primitives), so supply a
            // transparent one here rather than changing every field.
            child: Material(
              type: MaterialType.transparency,
              child: LessonForm(
                initial: initial,
                quizOptions: viewModel.quizOptions,
                submitLabel: initial == null ? 'Create' : 'Save',
                refetchLesson: viewModel.fetchLessonById,
                onSubmit: (lesson) async {
                  if (initial == null) {
                    await viewModel.onCreateLesson(lesson);
                  } else {
                    await viewModel.onUpdateLesson(lesson);
                  }
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmArchive(BuildContext context, String lessonId) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Archive lesson?'),
        description: const Text(
          'Archived lessons disappear from this list but remain referenced elsewhere.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ShadButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await viewModel.onArchiveLesson(lessonId);
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
              Text('Lessons', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              ShadButton(
                onPressed: () => _openForm(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 16),
                    SizedBox(width: 8),
                    Text('Add Lesson'),
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
                  DataColumn2(label: Text('Quarter/Week'), size: ColumnSize.S),
                  DataColumn2(label: Text('AR?'), size: ColumnSize.S),
                  DataColumn2(label: Text('Built-in?'), size: ColumnSize.S),
                  DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                ],
                rows: viewModel.rows.map((row) {
                  final lesson = row.lesson;
                  final quarterWeek =
                      lesson.quarter != null && lesson.week != null
                      ? 'Q${lesson.quarter}W${lesson.week}'
                      : '—';
                  final hasAr = lesson.hasAR;

                  return DataRow(
                    cells: [
                      DataCell(
                        SubjectAccentCell(
                          subject: lesson.subject,
                          child: Text(
                            lesson.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(subjectKeyLabel(lesson.subject))),
                      DataCell(Text(quarterWeek)),
                      DataCell(Text(hasAr ? 'Yes' : 'No')),
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
                                  Tooltip(
                                    message: 'Edit',
                                    child: ShadIconButton.ghost(
                                      icon: const Icon(LucideIcons.pencil),
                                      onPressed: () => _openForm(
                                        context,
                                        initial: row.teacherLesson,
                                      ),
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Archive',
                                    child: ShadIconButton.ghost(
                                      icon: const Icon(LucideIcons.archive),
                                      onPressed: () =>
                                          _confirmArchive(context, lesson.id),
                                    ),
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
