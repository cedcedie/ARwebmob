import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/teacher_lesson.dart';
import '../widgets/error_state.dart';
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
      error: (error, _) => ErrorState(
        message: humanizeLoadError(error, subjectLabel: 'lessons'),
        onRetry: () => ref.invalidate(lessonsViewModelProvider),
      ),
      data: (vm) => _LessonsBody(viewModel: vm),
    );
  }
}

class _LessonsBody extends HookWidget {
  const _LessonsBody({required this.viewModel});

  final LessonsViewModel viewModel;

  Future<void> _openForm(BuildContext context, {TeacherLesson? initial}) async {
    final isCreate = initial == null;
    await showShadDialog<void>(
      context: context,
      // An in-progress multi-field lesson edit is expensive to lose to an
      // accidental outside click — require the explicit Cancel action (or
      // a successful submit) to close instead.
      barrierDismissible: false,
      builder: (dialogContext) {
        return ShadDialog(
          title: Text(isCreate ? 'Add lesson' : 'Edit lesson'),
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
                submitLabel: isCreate ? 'Create' : 'Save',
                refetchLesson: viewModel.fetchLessonById,
                onSubmit: (lesson) async {
                  if (isCreate) {
                    await viewModel.onCreateLesson(lesson);
                  } else {
                    await viewModel.onUpdateLesson(lesson);
                  }
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    ShadToaster.of(context).show(
                      ShadToast(
                        description: Text(
                          isCreate ? 'Lesson created' : 'Lesson saved',
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
    // Column sorting (heuristic 7 — acceleration for a teacher managing a
    // growing lesson list): index 0 = Title (alphabetical), index 2 =
    // Quarter/Week (curriculum order) — the two orderings a teacher
    // actually reaches for for this table.
    final sortColumnIndex = useState<int?>(null);
    final sortAscending = useState(true);

    final rows = [...viewModel.rows];
    if (sortColumnIndex.value == 0) {
      rows.sort(
        (a, b) => a.lesson.title.toLowerCase().compareTo(
          b.lesson.title.toLowerCase(),
        ),
      );
    } else if (sortColumnIndex.value == 2) {
      int key(DisplayLesson row) =>
          (row.lesson.quarter ?? 0) * 100 + (row.lesson.week ?? 0);
      rows.sort((a, b) => key(a).compareTo(key(b)));
    }
    final displayRows = sortAscending.value ? rows : rows.reversed.toList();

    void handleSort(int columnIndex, bool ascending) {
      sortColumnIndex.value = columnIndex;
      sortAscending.value = ascending;
    }

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
                sortColumnIndex: sortColumnIndex.value,
                sortAscending: sortAscending.value,
                columns: [
                  DataColumn2(
                    label: const Text('Title'),
                    size: ColumnSize.L,
                    onSort: handleSort,
                  ),
                  const DataColumn2(label: Text('Subject'), size: ColumnSize.S),
                  DataColumn2(
                    label: const Text('Quarter/Week'),
                    size: ColumnSize.S,
                    onSort: handleSort,
                  ),
                  const DataColumn2(label: Text('AR?'), size: ColumnSize.S),
                  const DataColumn2(label: Text('Built-in?'), size: ColumnSize.S),
                  const DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                ],
                rows: displayRows.map((row) {
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
