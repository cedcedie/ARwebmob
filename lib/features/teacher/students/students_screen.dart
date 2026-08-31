import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
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

class _StudentsBody extends StatelessWidget {
  const _StudentsBody({required this.viewModel});

  final StudentsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
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
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 16,
                minWidth: 900,
                columns: const [
                  DataColumn2(label: Text('Name'), size: ColumnSize.L),
                  DataColumn2(label: Text('Student ID'), size: ColumnSize.S),
                  DataColumn2(label: Text('Grade'), size: ColumnSize.S),
                  DataColumn2(label: Text('Section'), size: ColumnSize.S),
                  DataColumn2(label: Text('Scores'), size: ColumnSize.M),
                  DataColumn2(label: Text('Progress'), size: ColumnSize.M),
                  DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                ],
                rows: viewModel.students.map((student) {
                  return DataRow(
                    cells: [
                      DataCell(Text(student.name)),
                      DataCell(
                        Text(formatStudentIdForDisplay(student.studentId)),
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
                                onPressed: () => viewModel.onArchiveStudent(
                                  student.studentId,
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
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
