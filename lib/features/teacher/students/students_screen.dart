import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/student_record.dart';
import '../../../core/models/subject_key.dart';
import '../widgets/error_state.dart';
import 'student_form.dart';
import 'student_id_format.dart';
import 'students_providers.dart';

/// Below this viewport width the fixed-layout `DataTable2` roster no longer
/// fits without forcing horizontal scroll — matches `TeacherShell`'s own
/// compact-nav breakpoint so the whole page's layout language changes at one
/// consistent width.
const _kCompactBreakpoint = 720.0;

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVm = ref.watch(studentsViewModelProvider);

    return Scaffold(
      body: asyncVm.when(
        loading: () => const _StudentsLoadingSkeleton(),
        error: (error, _) => ErrorState(
          message: humanizeLoadError(error, subjectLabel: 'students'),
          onRetry: () => ref.invalidate(studentsViewModelProvider),
        ),
        data: (vm) => _StudentsBody(viewModel: vm),
      ),
    );
  }
}

/// Loading placeholder shaped like the eventual roster (header row skeleton
/// + a handful of row-shaped bars) rather than a bare centered spinner —
/// gives the teacher an immediate sense of "a table is about to appear
/// here" instead of a blank stall.
class _StudentsLoadingSkeleton extends StatelessWidget {
  const _StudentsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < _kCompactBreakpoint;

    Widget bar({double width = double.infinity, double height = 14}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: scheme.muted,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              bar(width: 100, height: 24),
              const Spacer(),
              bar(width: 120, height: 36),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ShadCard(
              padding: const EdgeInsets.all(16),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) => Row(
                  children: [
                    bar(width: 36, height: 36),
                    const SizedBox(width: 12),
                    Expanded(child: bar(height: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
      duration: 700.ms,
      begin: 0.55,
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

    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < _kCompactBreakpoint;
    final scheme = ShadTheme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StudentsHeader(
            isCompact: isCompact,
            selectedCount: validSelection.length,
            includeArchived: viewModel.includeArchived,
            onToggleIncludeArchived: viewModel.onToggleIncludeArchived,
            onArchiveSelected: () =>
                _archiveSelected(context, validSelection, selection),
            onAddStudent: () => StudentFormSheet.show(
              context,
              onSubmit: viewModel.onCreateStudent,
            ),
          ),
          SizedBox(height: isCompact ? 12 : 16),
          Expanded(
            child: displayStudents.isEmpty
                ? ShadCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.users,
                              size: 32,
                              color: scheme.mutedForeground,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No students yet — add your first student to '
                              'get started.',
                              textAlign: TextAlign.center,
                              style: ShadTheme.of(context).textTheme.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : isCompact
                ? _StudentsCardList(
                    students: displayStudents,
                    selection: selection.value,
                    onSelectionChanged: (next) => selection.value = next,
                    onArchive: (id) => _archiveOne(context, id),
                    onViewProgress: (student) =>
                        _showProgressDetails(context, student),
                  )
                : ShadCard(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 16,
                        minWidth: 900,
                        showCheckboxColumn: true,
                        sortColumnIndex: sortColumnIndex.value,
                        sortAscending: sortAscending.value,
                        headingRowColor: WidgetStatePropertyAll(scheme.muted),
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
                            selected: selection.value.contains(
                              student.studentId,
                            ),
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
                                  formatStudentIdForDisplay(
                                    student.studentId,
                                  ),
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
                                      onPressed: () => _showProgressDetails(
                                        context,
                                        student,
                                      ),
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
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          'Archived',
                                          style: TextStyle(
                                            color: scheme.mutedForeground,
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
          ),
        ],
      ),
    );
  }
}

/// Page header: title + actions. Wraps onto a second line below the compact
/// breakpoint instead of forcing the "Add Student" button to shrink or the
/// row to overflow horizontally.
class _StudentsHeader extends StatelessWidget {
  const _StudentsHeader({
    required this.isCompact,
    required this.selectedCount,
    required this.includeArchived,
    required this.onToggleIncludeArchived,
    required this.onArchiveSelected,
    required this.onAddStudent,
  });

  final bool isCompact;
  final int selectedCount;
  final bool includeArchived;
  final ValueChanged<bool> onToggleIncludeArchived;
  final VoidCallback onArchiveSelected;
  final VoidCallback onAddStudent;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      'Students',
      style: Theme.of(context).textTheme.headlineSmall,
    );

    final actions = <Widget>[
      if (selectedCount > 0)
        ShadButton.outline(
          leading: const Icon(LucideIcons.archive, size: 16),
          onPressed: onArchiveSelected,
          child: Text('Archive selected ($selectedCount)'),
        ),
      // `FilterChip` has no direct shadcn_ui equivalent (no
      // chip/toggle component in this package version) — themed via
      // appMaterialTheme's chipTheme to match the palette instead of
      // forcing a bad shadcn fit.
      FilterChip(
        label: const Text('Show archived'),
        selected: includeArchived,
        onSelected: onToggleIncludeArchived,
      ),
      ShadButton(
        onPressed: onAddStudent,
        leading: const Icon(LucideIcons.userPlus, size: 16),
        child: const Text('Add Student'),
      ),
    ];

    if (!isCompact) {
      return Row(
        children: [
          title,
          const Spacer(),
          for (final action in actions) ...[
            action,
            if (action != actions.last) const SizedBox(width: 12),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title,
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions,
        ),
      ],
    );
  }
}

/// Narrow-viewport (<720px) replacement for the roster `DataTable2` — one
/// `ShadCard` per student instead of forcing horizontal scroll on a
/// fixed-width table. Keeps the same bulk-select/archive affordances via a
/// leading checkbox and an overflow menu per row.
class _StudentsCardList extends StatelessWidget {
  const _StudentsCardList({
    required this.students,
    required this.selection,
    required this.onSelectionChanged,
    required this.onArchive,
    required this.onViewProgress,
  });

  final List<StudentRecord> students;
  final Set<String> selection;
  final ValueChanged<Set<String>> onSelectionChanged;
  final ValueChanged<String> onArchive;
  final ValueChanged<StudentRecord> onViewProgress;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;

    return ListView.separated(
      itemCount: students.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final student = students[index];
        final canSelect = !student.isArchived;
        final isSelected = selection.contains(student.studentId);

        return ShadCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: canSelect
                        ? (value) {
                            final next = {...selection};
                            if (value == true) {
                              next.add(student.studentId);
                            } else {
                              next.remove(student.studentId);
                            }
                            onSelectionChanged(next);
                          }
                        : null,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: ShadTheme.of(
                            context,
                          ).textTheme.h4.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatStudentIdForDisplay(student.studentId)} · '
                          'Grade ${student.grade} · ${student.section}',
                          style: ShadTheme.of(context).textTheme.muted,
                        ),
                      ],
                    ),
                  ),
                  if (student.isArchived)
                    ShadBadge.secondary(child: const Text('Archived')),
                  PopupMenuButton<String>(
                    tooltip: 'More actions',
                    icon: Icon(
                      LucideIcons.ellipsisVertical,
                      size: 18,
                      color: scheme.mutedForeground,
                    ),
                    onSelected: (value) {
                      if (value == 'progress') onViewProgress(student);
                      if (value == 'archive') onArchive(student.studentId);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'progress',
                        child: Text('View progress details'),
                      ),
                      if (!student.isArchived)
                        const PopupMenuItem(
                          value: 'archive',
                          child: Text('Archive'),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ScoreChips(scores: student.scores),
              const SizedBox(height: 6),
              _ProgressSummary(student: student),
            ],
          ),
        ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.03, end: 0);
      },
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

    // Narrow viewports (e.g. a phone in the compact shell layout) can't
    // accommodate a fixed 420-logical-pixel dialog — clamp to the available
    // width instead of overflowing off-screen.
    final maxWidth = MediaQuery.sizeOf(context).width - 48;

    return ShadDialog(
      title: Text('${student.name} — Progress'),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
      child: SizedBox(
        width: maxWidth < 420 ? maxWidth.clamp(240, 420) : 420,
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
        _subjectChip(context, 'Chem', scores['chemistry'], SubjectKey.chemistry),
        _subjectChip(context, 'Bio', scores['biology'], SubjectKey.biology),
        _subjectChip(context, 'Phys', scores['physics'], SubjectKey.physics),
      ],
    );
  }

  // Static per-subject score label — a `ShadBadge.outline`, the app's one
  // treatment for a tag, rather than a second hand-rolled chip style;
  // colored by subject via the active theme's `colorScheme.custom` map
  // (never `subjectColor()`/`.accentColor` directly — those always return
  // the light-mode palette regardless of the active theme) so the accent
  // correctly swaps to its dark-mode variant.
  Widget _subjectChip(
    BuildContext context,
    String label,
    num? score,
    SubjectKey subject,
  ) {
    final text = score != null ? '$label ${score.round()}' : '$label —';
    final custom = ShadTheme.of(context).colorScheme.custom;
    final accent = custom[subject.name] ?? ShadTheme.of(context).colorScheme.primary;
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
