import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
        error: (error, _) => Center(child: Text('Error loading students: $error')),
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
              Text('Students', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              FilterChip(
                label: const Text('Show archived'),
                selected: viewModel.includeArchived,
                onSelected: viewModel.onToggleIncludeArchived,
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => StudentFormSheet.show(
                  context,
                  onSubmit: viewModel.onCreateStudent,
                ),
                icon: const Icon(LucideIcons.userPlus),
                label: const Text('Add Student'),
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
                  DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                ],
                rows: viewModel.students.map((student) {
                  return DataRow(
                    cells: [
                      DataCell(Text(student.name)),
                      DataCell(Text(formatStudentIdForDisplay(student.studentId))),
                      DataCell(Text(student.grade)),
                      DataCell(Text(student.section)),
                      DataCell(_ScoreChips(scores: student.scores)),
                      DataCell(
                        student.isArchived
                            ? const Text('Archived', style: TextStyle(color: Colors.grey))
                            : IconButton(
                                tooltip: 'Archive',
                                icon: const Icon(LucideIcons.archive),
                                onPressed: () => viewModel.onArchiveStudent(student.studentId),
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

class _ScoreChips extends StatelessWidget {
  const _ScoreChips({required this.scores});

  final Map<String, num?> scores;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _subjectChip('Chem', scores['chemistry']),
        _subjectChip('Bio', scores['biology']),
        _subjectChip('Phys', scores['physics']),
      ],
    );
  }

  Widget _subjectChip(String label, num? score) {
    final text = score != null ? '$label ${score.round()}' : '$label —';
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
