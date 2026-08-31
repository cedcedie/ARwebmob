import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/student_record.dart';
import '../../../core/models/subject_key.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/error_state.dart';
import 'student_form.dart';
import 'student_id_format.dart';
import 'students_providers.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVm = ref.watch(studentsViewModelProvider);

    return Scaffold(
      body: asyncVm.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: humanizeLoadError(error, subjectLabel: 'students'),
          onRetry: () => ref.invalidate(studentsViewModelProvider),
        ),
        data: (vm) => _StudentsBody(viewModel: vm),
      ),
    );
  }
}

class _StudentsBody extends HookWidget {
  const _StudentsBody({required this.viewModel});

  final StudentsViewModel viewModel;

  Future<void> _archiveSelected(
    BuildContext context,
    Set<String> selectedIds,
    ValueNotifier<Set<String>> selection,
  ) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: Text('Archive ${selectedIds.length} student(s)?'),
        description: const Text(
          'Archived students disappear from the default roster but remain '
          'referenced elsewhere.',
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
    if (confirmed != true) return;

    // Item 4 (bulk-archive feedback): every other mutating action on this
    // surface gives feedback (create-student's success toast, item 3's
    // error toasts) — this loop previously had none at all, and any
    // mid-loop throw would silently abandon the rest with no sign anything
    // went wrong.
    //
    // Partial-failure choice: keep archiving the remaining selected
    // students even after one fails (best-effort), rather than aborting the
    // whole batch on the first error. A single bad student (e.g. a
    // Firestore doc that's already been deleted elsewhere) shouldn't block
    // a teacher from archiving the rest of a large selection — that failure
    // mode is worse than "some archived, one reported as failed, retry just
    // that one".
    var succeededCount = 0;
    final failedIds = <String>{};
    for (final studentId in selectedIds) {
      try {
        await viewModel.onArchiveStudent(studentId);
        succeededCount++;
      } catch (_) {
        failedIds.add(studentId);
      }
    }

    // Only the students that actually archived leave the selection — a
    // failed one stays selected so "Archive selected" can be retried
    // against just the students that didn't go through.
    selection.value = failedIds;

    if (!context.mounted) return;
    if (failedIds.isEmpty) {
      ShadToaster.of(context).show(
        ShadToast(
          description: Text(
            succeededCount == 1
                ? '1 student archived'
                : '$succeededCount students archived',
          ),
        ),
      );
    } else {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            succeededCount == 0
                ? "Couldn't archive ${failedIds.length} student(s) — check "
                      'your connection and try again.'
                : '$succeededCount archived, but ${failedIds.length} '
                      "couldn't be archived — check your connection and try "
                      'again.',
          ),
        ),
      );
    }
  }

  // Item 4: the single-row archive action used to skip confirmation
  // entirely and had no try/catch/toast — inconsistent with the bulk path
  // above, which confirms first and always gives feedback. Mirrors that
  // same pattern for a single student.
  Future<void> _archiveOne(BuildContext context, String studentId) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Archive student?'),
        description: const Text(
          'Archived students disappear from the default roster but remain '
          'referenced elsewhere.',
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
    if (confirmed != true) return;

    try {
      await viewModel.onArchiveStudent(studentId);
      if (!context.mounted) return;
      ShadToaster.of(
        context,
      ).show(const ShadToast(description: Text('Student archived')));
    } catch (error) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            humanizeSubmitError(error, actionLabel: 'archive this student'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Column sorting (heuristic 7 — acceleration for a teacher managing a
    // roster over a semester): index 0 = Name (alphabetical), index 2 =
    // Grade (numeric where possible).
    final sortColumnIndex = useState<int?>(null);
    final sortAscending = useState(true);
    // Bulk-archive selection — keyed by studentId, cleared after an archive
    // action or when the roster's underlying data changes shape.
    final selection = useState<Set<String>>(const {});

    final students = [...viewModel.students];
    if (sortColumnIndex.value == 0) {
      students.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else if (sortColumnIndex.value == 2) {
      students.sort((a, b) {
        final gradeA = num.tryParse(a.grade);
        final gradeB = num.tryParse(b.grade);
        if (gradeA != null && gradeB != null) return gradeA.compareTo(gradeB);
        return a.grade.compareTo(b.grade);
      });
    }
    final displayStudents = sortAscending.value
        ? students
        : students.reversed.toList();

    void handleSort(int columnIndex, bool ascending) {
      sortColumnIndex.value = columnIndex;
      sortAscending.value = ascending;
    }

    final selectableIds = displayStudents
        .where((s) => !s.isArchived)
        .map((s) => s.studentId)
        .toSet();
    final validSelection = selection.value.intersection(selectableIds);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Students',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              if (validSelection.isNotEmpty) ...[
                ShadButton.outline(
                  leading: const Icon(LucideIcons.archive, size: 16),
                  onPressed: () =>
                      _archiveSelected(context, validSelection, selection),
                  child: Text('Archive selected (${validSelection.length})'),
                ),
                const SizedBox(width: 12),
              ],
              // `FilterChip` has no direct shadcn_ui equivalent (no
              // chip/toggle component in this package version) — themed via
              // appMaterialTheme's chipTheme to match the palette instead of
              // forcing a bad shadcn fit.
              FilterChip(
                label: const Text('Show archived'),
                selected: viewModel.includeArchived,
                onSelected: viewModel.onToggleIncludeArchived,
              ),
              const SizedBox(width: 12),
              ShadButton(
                onPressed: () => StudentFormSheet.show(
                  context,
                  onSubmit: viewModel.onCreateStudent,
                ),
                leading: const Icon(LucideIcons.userPlus, size: 16),
                child: const Text('Add Student'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              // Item 5: same empty-state gap as lessons/quizzes — no rows
              // previously meant a bare header row with no explanation
              // (e.g. every student archived and "Show archived" is off).
              child: displayStudents.isEmpty
                  ? const Center(
                      child: Text(
                        'No students yet — add your first student to get started.',
                        style: TextStyle(color: AppColors.inkMuted),
                      ),
                    )
                  : DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 16,
                      minWidth: 900,
                      showCheckboxColumn: true,
                      sortColumnIndex: sortColumnIndex.value,
                      sortAscending: sortAscending.value,
                      onSelectAll: (selectAll) {
                        selection.value = selectAll == true
                            ? selectableIds
                            : {};
                      },
                      columns: [
                        DataColumn2(
                          label: const Text('Name'),
                          size: ColumnSize.L,
                          onSort: handleSort,
                        ),
                        const DataColumn2(
                          label: Text('Student ID'),
                          size: ColumnSize.S,
                        ),
                        DataColumn2(
                          label: const Text('Grade'),
                          size: ColumnSize.S,
                          onSort: handleSort,
                        ),
                        const DataColumn2(
                          label: Text('Section'),
                          size: ColumnSize.S,
                        ),
                        const DataColumn2(
                          label: Text('Scores'),
                          size: ColumnSize.M,
                        ),
                        const DataColumn2(
                          label: Text('Progress'),
                          size: ColumnSize.M,
                        ),
                        const DataColumn2(
                          label: Text('Actions'),
                          size: ColumnSize.M,
                        ),
                      ],
                      rows: displayStudents.map((student) {
                        final canSelect = !student.isArchived;
                        return DataRow(
                          selected: selection.value.contains(student.studentId),
                          onSelectChanged: canSelect
                              ? (value) {
                                  final next = {...selection.value};
                                  if (value == true) {
                                    next.add(student.studentId);
                                  } else {
                                    next.remove(student.studentId);
                                  }
                                  selection.value = next;
                                }
                              : null,
                          cells: [
                            DataCell(Text(student.name)),
                            DataCell(
                              Text(
                                formatStudentIdForDisplay(student.studentId),
                              ),
                            ),
                            DataCell(Text(student.grade)),
                            DataCell(Text(student.section)),
                            DataCell(_ScoreChips(scores: student.scores)),
                            DataCell(_ProgressSummary(student: student)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _CompactIconButton(
                                    tooltip: 'View progress details',
                                    icon: LucideIcons.listChecks,
                                    onPressed: () =>
                                        _showProgressDetails(context, student),
                                  ),
                                  if (!student.isArchived)
                                    _CompactIconButton(
                                      tooltip: 'Archive',
                                      icon: LucideIcons.archive,
                                      onPressed: () => _archiveOne(
                                        context,
                                        student.studentId,
                                      ),
                                    )
                                  else
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        'Archived',
                                        style: TextStyle(
                                          color: AppColors.inkMuted,
                                          fontSize: 12,
                                        ),
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

/// Narrower `ShadIconButton` (the default touch target is roomier) so two of
/// them plus an "Archived" label fit inside the roster's Actions column
/// without overflowing.
class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ShadIconButton.ghost(
        width: 32,
        height: 32,
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
      ),
    );
  }
}

void _showProgressDetails(BuildContext context, StudentRecord student) {
  showShadDialog<void>(
    context: context,
    builder: (context) => _ProgressDetailsDialog(student: student),
  );
}

/// Compact roster-cell summary of a student's actual activity — lesson
/// completion count and quiz-attempt count — surfaced alongside `scores` so
/// a teacher isn't limited to the latest post-test score per subject.
///
/// Static, non-interactive labels — `ShadBadge`, the app's one treatment for
/// a tag/label (matching the "Built-in" badge on the lessons/quizzes
/// tables), not a `Chip` (that stays reserved for the "Show archived"
/// toggle, the only genuinely interactive chip on this surface).
class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.student});

  final StudentRecord student;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ShadBadge.secondary(
          child: Text('Lessons: ${student.completedLessonIds.length}'),
        ),
        ShadBadge.secondary(
          child: Text('Quizzes taken: ${student.quizAttempts.length}'),
        ),
      ],
    );
  }
}

/// Per-student drill-down showing the full `quizAttempts` history (score,
/// attempt number, timestamp) plus completed-lesson count, so a teacher can
/// see what a student has actually done, not just their latest score.
class _ProgressDetailsDialog extends StatelessWidget {
  const _ProgressDetailsDialog({required this.student});

  final StudentRecord student;

  @override
  Widget build(BuildContext context) {
    final attempts = [...student.quizAttempts]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ShadDialog(
      title: Text('${student.name} — Progress'),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lessons completed: ${student.completedLessonIds.length}'),
            const SizedBox(height: 12),
            Text(
              'Quiz attempts (${attempts.length})',
              style: ShadTheme.of(context).textTheme.small,
            ),
            const SizedBox(height: 8),
            if (attempts.isEmpty)
              const Text('No quiz attempts yet.')
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Material(
                  type: MaterialType.transparency,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: attempts.length,
                    itemBuilder: (context, index) {
                      final attempt = attempts[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${attempt.quizId} — attempt ${attempt.attemptNumber}',
                        ),
                        subtitle: Text(
                          'Score ${attempt.correctAnswers}/${attempt.totalQuestions} '
                          '(${attempt.score.round()}) · ${attempt.timestamp}'
                          '${attempt.locked ? ' · locked' : ''}',
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreChips extends StatelessWidget {
  const _ScoreChips({required this.scores});

  final Map<String, num?> scores;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _subjectChip('Chem', scores['chemistry'], SubjectKey.chemistry),
        _subjectChip('Bio', scores['biology'], SubjectKey.biology),
        _subjectChip('Phys', scores['physics'], SubjectKey.physics),
      ],
    );
  }

  // Static per-subject score label — a `ShadBadge.outline`, the app's one
  // treatment for a tag, rather than a second hand-rolled chip style;
  // still colored by subject via `subjectColor()`, just through the shared
  // badge widget instead of a bespoke alpha-blended `Chip`.
  Widget _subjectChip(String label, num? score, SubjectKey subject) {
    final text = score != null ? '$label ${score.round()}' : '$label —';
    final accent = subjectColor(subject);
    return ShadBadge.outline(
      backgroundColor: accent.withValues(alpha: 0.10),
      foregroundColor: accent,
      shape: StadiumBorder(
        side: BorderSide(color: accent.withValues(alpha: 0.4)),
      ),
      child: Text(text),
    );
  }
}
