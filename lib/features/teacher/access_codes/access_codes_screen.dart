import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/subject_key.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/error_state.dart';
import '../widgets/subject_accent_cell.dart';
import 'access_codes_providers.dart';

class AccessCodesScreen extends HookConsumerWidget {
  const AccessCodesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVm = ref.watch(accessCodesViewModelProvider);

    return Scaffold(
      body: asyncVm.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: humanizeLoadError(error, subjectLabel: 'access codes'),
          onRetry: () => ref.invalidate(accessCodesViewModelProvider),
        ),
        data: (vm) => _AccessCodesBody(viewModel: vm),
      ),
    );
  }
}

class _AccessCodesBody extends HookWidget {
  const _AccessCodesBody({required this.viewModel});

  final AccessCodesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final tabIndex = useState(0);
    final issuedCode = useState<String?>(null);
    final errorMessage = useState<String?>(null);

    Future<void> handleIssue(Future<String> Function() issue) async {
      errorMessage.value = null;
      try {
        final code = await issue();
        issuedCode.value = code;
      } on StateError catch (error) {
        issuedCode.value = null;
        errorMessage.value = error.message;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Access Codes',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Subject / lesson-wide')),
              ButtonSegment(value: 1, label: Text('Lesson targeted')),
              ButtonSegment(value: 2, label: Text('Quiz retake')),
            ],
            selected: {tabIndex.value},
            onSelectionChanged: (selection) {
              tabIndex.value = selection.first;
              errorMessage.value = null;
            },
          ),
          const SizedBox(height: 16),
          if (issuedCode.value != null)
            _IssuedCodeBanner(code: issuedCode.value!),
          if (errorMessage.value != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MaterialBanner(
                content: Text(errorMessage.value!),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                actions: [
                  TextButton(
                    onPressed: () => errorMessage.value = null,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
          Flexible(
            flex: 2,
            child: SingleChildScrollView(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: switch (tabIndex.value) {
                    0 => _SubjectCodeForm(
                      viewModel: viewModel,
                      onIssue: (issue) => handleIssue(issue),
                    ),
                    1 => _LessonCodeForm(
                      viewModel: viewModel,
                      onIssue: (issue) => handleIssue(issue),
                    ),
                    _ => _RetakeCodeForm(
                      viewModel: viewModel,
                      onIssue: (issue) => handleIssue(issue),
                    ),
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Issued codes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 16,
                minWidth: 800,
                columns: const [
                  DataColumn2(label: Text('Code'), size: ColumnSize.S),
                  DataColumn2(label: Text('Type'), size: ColumnSize.S),
                  DataColumn2(label: Text('Target'), size: ColumnSize.S),
                  DataColumn2(label: Text('Status'), size: ColumnSize.S),
                  DataColumn2(label: Text('Issued At'), size: ColumnSize.M),
                ],
                rows: viewModel.issuedCodes.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(
                        // Every issued code belongs to a subject/lesson (or,
                        // for a multi-subject code, to none in particular) —
                        // accent the row the same way lesson/quiz tables do
                        // when a single subject is resolvable.
                        row.subject != null
                            ? SubjectAccentCell(
                                subject: row.subject!,
                                child: Text(row.code),
                              )
                            : Text(row.code),
                      ),
                      DataCell(Text(issuedCodeTypeLabel(row.type))),
                      DataCell(Text(row.target)),
                      DataCell(Text(row.status)),
                      DataCell(Text(row.issuedAt)),
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

class _IssuedCodeBanner extends StatelessWidget {
  const _IssuedCodeBanner({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    // Genuine success-confirmation moment — the one point in this screen a
    // teacher most needs unambiguous positive affect — so it uses the
    // dedicated `AppColors.success` role rather than a neutral container
    // color, with a check icon reinforcing the "this worked" read.
    return Card(
      color: AppColors.success.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        side: BorderSide(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(LucideIcons.circleCheck, color: AppColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code issued — give this to your student',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    code,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: 'Copy code',
              child: ShadIconButton.ghost(
                icon: const Icon(LucideIcons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  // This app's ShadApp/ShadApp.router shell has no
                  // ScaffoldMessenger ancestor — `ShadToaster.of(context)` is
                  // the app's actual toast mechanism (same pattern as
                  // lesson_form.dart/quiz_form.dart/student_form.dart).
                  ShadToaster.of(context).show(
                    const ShadToast(
                      description: Text('Code copied to clipboard'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCodeForm extends HookWidget {
  const _SubjectCodeForm({required this.viewModel, required this.onIssue});

  final AccessCodesViewModel viewModel;
  final Future<void> Function(Future<String> Function() issue) onIssue;

  @override
  Widget build(BuildContext context) {
    final subject = useState(SubjectKey.chemistry);
    final selectedLessonIds = useState(<String>{});
    final customCode = useState('');
    final isSubmitting = useState(false);

    final subjectLessons = viewModel.lessons
        .where((lesson) => lesson.subject == subject.value)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<SubjectKey>(
          initialValue: subject.value,
          decoration: const InputDecoration(labelText: 'Subject'),
          items: SubjectKey.values
              .map(
                (s) =>
                    DropdownMenuItem(value: s, child: Text(subjectKeyLabel(s))),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            subject.value = value;
            selectedLessonIds.value = {};
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Optional lesson scope (empty = whole subject)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: subjectLessons.map((lesson) {
            final selected = selectedLessonIds.value.contains(lesson.id);
            return FilterChip(
              label: Text(lesson.id),
              selected: selected,
              onSelected: (value) {
                final next = {...selectedLessonIds.value};
                if (value) {
                  next.add(lesson.id);
                } else {
                  next.remove(lesson.id);
                }
                selectedLessonIds.value = next;
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Custom code (optional)',
            hintText: 'Leave blank to auto-generate',
          ),
          onChanged: (value) => customCode.value = value,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ShadButton(
            onPressed: isSubmitting.value
                ? null
                : () async {
                    isSubmitting.value = true;
                    await onIssue(
                      () => viewModel.onIssueSubjectCode(
                        subjects: [subject.value.firestoreValue],
                        lessonIds: selectedLessonIds.value.isEmpty
                            ? null
                            : selectedLessonIds.value.toList(),
                        customCode: customCode.value.trim().isEmpty
                            ? null
                            : customCode.value.trim(),
                      ),
                    );
                    isSubmitting.value = false;
                  },
            child: isSubmitting.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Issue subject code'),
          ),
        ),
      ],
    );
  }
}

class _LessonCodeForm extends HookWidget {
  const _LessonCodeForm({required this.viewModel, required this.onIssue});

  final AccessCodesViewModel viewModel;
  final Future<void> Function(Future<String> Function() issue) onIssue;

  @override
  Widget build(BuildContext context) {
    final studentId = useState<String?>(null);
    final lessonId = useState<String?>(null);
    final customCode = useState('');
    final isSubmitting = useState(false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: studentId.value,
          decoration: const InputDecoration(labelText: 'Student'),
          items: viewModel.students
              .where((s) => !s.isArchived)
              .map(
                (s) => DropdownMenuItem(
                  value: s.studentId,
                  child: Text('${s.name} (${s.studentId})'),
                ),
              )
              .toList(),
          onChanged: (value) => studentId.value = value,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: lessonId.value,
          decoration: const InputDecoration(labelText: 'Lesson'),
          items: viewModel.lessons
              .map(
                (lesson) => DropdownMenuItem(
                  value: lesson.id,
                  child: Text(lesson.id, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) => lessonId.value = value,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Custom code (optional)',
            hintText: 'Leave blank to auto-generate',
          ),
          onChanged: (value) => customCode.value = value,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ShadButton(
            onPressed:
                isSubmitting.value ||
                    studentId.value == null ||
                    lessonId.value == null
                ? null
                : () async {
                    isSubmitting.value = true;
                    await onIssue(
                      () => viewModel.onIssueLessonCode(
                        lessonId: lessonId.value!,
                        studentId: studentId.value!,
                        customCode: customCode.value.trim().isEmpty
                            ? null
                            : customCode.value.trim(),
                      ),
                    );
                    isSubmitting.value = false;
                  },
            child: isSubmitting.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Issue lesson code'),
          ),
        ),
      ],
    );
  }
}

class _RetakeCodeForm extends HookWidget {
  const _RetakeCodeForm({required this.viewModel, required this.onIssue});

  final AccessCodesViewModel viewModel;
  final Future<void> Function(Future<String> Function() issue) onIssue;

  @override
  Widget build(BuildContext context) {
    final studentId = useState<String?>(null);
    final lessonId = useState<String?>(null);
    final isSubmitting = useState(false);
    final isEligible = useState<bool?>(null);
    final isChecking = useState(false);

    useEffect(() {
      final sid = studentId.value;
      final lid = lessonId.value;
      if (sid == null || lid == null) {
        isEligible.value = null;
        return null;
      }
      isChecking.value = true;
      var cancelled = false;
      viewModel.checkRetakeEligible(studentId: sid, lessonId: lid).then((
        eligible,
      ) {
        if (!cancelled) {
          isEligible.value = eligible;
          isChecking.value = false;
        }
      });
      return () {
        cancelled = true;
      };
    }, [studentId.value, lessonId.value]);

    final canSubmit =
        studentId.value != null &&
        lessonId.value != null &&
        isEligible.value == true &&
        !isSubmitting.value &&
        !isChecking.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: studentId.value,
          decoration: const InputDecoration(labelText: 'Student'),
          items: viewModel.students
              .where((s) => !s.isArchived)
              .map(
                (s) => DropdownMenuItem(
                  value: s.studentId,
                  child: Text('${s.name} (${s.studentId})'),
                ),
              )
              .toList(),
          onChanged: (value) => studentId.value = value,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: lessonId.value,
          decoration: const InputDecoration(labelText: 'Lesson'),
          items: viewModel.lessons
              .map(
                (lesson) => DropdownMenuItem(
                  value: lesson.id,
                  child: Text(lesson.id, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) => lessonId.value = value,
        ),
        if (studentId.value != null && lessonId.value != null) ...[
          const SizedBox(height: 12),
          if (isChecking.value)
            const Text('Checking post-test eligibility…')
          else if (isEligible.value == false)
            Text(
              'This student has no recorded post-test attempt for the selected lesson yet. '
              'A retake code cannot be issued until they complete the post-test at least once.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ShadButton(
            onPressed: canSubmit
                ? () async {
                    isSubmitting.value = true;
                    await onIssue(
                      () => viewModel.onIssueQuizRetakeCode(
                        lessonId: lessonId.value!,
                        studentId: studentId.value!,
                      ),
                    );
                    isSubmitting.value = false;
                  }
                : null,
            child: isSubmitting.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Issue retake code'),
          ),
        ),
      ],
    );
  }
}
