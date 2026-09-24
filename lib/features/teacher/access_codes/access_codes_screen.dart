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

/// Viewport width below which this screen switches to a single-column,
/// stacked layout — the same breakpoint `TeacherShell` uses for its own
/// compact (drawer) layout, so the two agree on what counts as "narrow".
const _kCompactBreakpoint = 720.0;

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

    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < _kCompactBreakpoint;
    final scheme = ShadTheme.of(context).colorScheme;

    // Item 1: this used to only catch `StateError` (the eligibility-check
    // and duplicate-code failures thrown by `AccessCodeIssuanceService`
    // itself), leaving any `FirebaseException` from the underlying writes
    // (permission-denied, unavailable, etc.) uncaught — which, since every
    // call site below only flips `isSubmitting` back to false *after*
    // `await onIssue(...)` returns, permanently stranded the Issue button
    // in a disabled spinner state with no feedback at all. Catching `Object`
    // here (not just `StateError`) closes that gap; each call site's own
    // `finally` (below) is what actually guarantees the spinner always
    // clears, independent of what this function does with the error.
    //
    // Both the StateError path (a deliberate business-rule rejection, e.g.
    // "no post-test attempt yet") and any other thrown error are routed
    // through `humanizeSubmitError` so the teacher never sees a raw
    // `Error.toString()`/`error.message` — same rule this screen's error
    // ErrorState/toast usage follows elsewhere in the app.
    Future<void> handleIssue(Future<String> Function() issue) async {
      errorMessage.value = null;
      try {
        final code = await issue();
        issuedCode.value = code;
      } catch (error) {
        issuedCode.value = null;
        errorMessage.value = humanizeSubmitError(
          error,
          actionLabel: 'issue this code',
        );
      }
    }

    final segments = <ButtonSegment<int>>[
      ButtonSegment(
        value: 0,
        label: Text(isCompact ? 'Subject' : 'Subject / lesson-wide'),
      ),
      ButtonSegment(
        value: 1,
        label: Text(isCompact ? 'Lesson' : 'Lesson targeted'),
      ),
      ButtonSegment(
        value: 2,
        label: Text(isCompact ? 'Retake' : 'Quiz retake'),
      ),
    ];

    return Padding(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      // Every section below now sizes to its own content (a fixed-height
      // table card, a shrink-wrapped compact list, a form card) rather than
      // the old `Expanded`/`Flexible`-filled two-pane layout, so the whole
      // page scrolls as one column — the only layout that stays correct
      // from phone width (where the form + table stack tall) up to desktop.
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(LucideIcons.keyRound, size: 22, color: scheme.foreground),
                const SizedBox(width: 10),
                Text(
                  'Access Codes',
                  style: isCompact
                      ? Theme.of(context).textTheme.titleLarge
                      : Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Issue codes to unlock subjects, lessons, or a quiz retake for a '
              'student.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.mutedForeground),
            ),
            SizedBox(height: isCompact ? 14 : 20),
            SizedBox(
              width: double.infinity,
              child: isCompact
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<int>(
                        segments: segments,
                        selected: {tabIndex.value},
                        onSelectionChanged: (selection) {
                          tabIndex.value = selection.first;
                          errorMessage.value = null;
                        },
                      ),
                    )
                  : SegmentedButton<int>(
                      segments: segments,
                      selected: {tabIndex.value},
                      onSelectionChanged: (selection) {
                        tabIndex.value = selection.first;
                        errorMessage.value = null;
                      },
                    ),
            ),
            const SizedBox(height: 16),
            if (issuedCode.value != null)
              _IssuedCodeBanner(
                key: ValueKey(issuedCode.value),
                code: issuedCode.value!,
              ),
            // Item 7: this used to be a raw Material `MaterialBanner` — a
            // third error idiom next to `ErrorState` (full-space failed-load
            // display, used by every list screen's `asyncVm.when(error: ...)`
            // branch) and the `ShadToast.destructive` toasts items 1-4 use for
            // a mutating action's failure. Kept as an inline banner rather
            // than switched to `ErrorState` (that widget replaces this whole
            // screen's body — wrong shape for a dismissible, transient
            // issuance-form error the teacher should be able to see, correct,
            // and retry without losing the rest of the screen) or to a toast
            // (a toast auto-dismisses; the retake-eligibility/duplicate-code
            // messages this shows are often exactly the info the teacher needs
            // to read and act on while still looking at the form, not a
            // fire-and-forget notification). Restyled instead to match
            // `ErrorState`'s visual language — the same `circleAlert` icon and
            // the theme's destructive role — so it reads as the same "this
            // failed" signal as the rest of the app rather than a visually
            // distinct banner. Reads the destructive color through
            // `ShadTheme` (not a hardcoded `AppColors` constant) so it stays
            // correct in dark mode too.
            if (errorMessage.value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.destructive.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    border: Border.all(
                      color: scheme.destructive.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.circleAlert,
                        size: 20,
                        color: scheme.destructive,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage.value!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.destructive),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ShadIconButton.ghost(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () => errorMessage.value = null,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 180.ms),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: switch (tabIndex.value) {
                  0 => _SubjectCodeForm(
                    viewModel: viewModel,
                    onIssue: (issue) => handleIssue(issue),
                    isCompact: isCompact,
                  ),
                  1 => _LessonCodeForm(
                    viewModel: viewModel,
                    onIssue: (issue) => handleIssue(issue),
                    isCompact: isCompact,
                  ),
                  _ => _RetakeCodeForm(
                    viewModel: viewModel,
                    onIssue: (issue) => handleIssue(issue),
                    isCompact: isCompact,
                  ),
                },
              ),
            ),
            SizedBox(height: isCompact ? 20 : 16),
            Text(
              'Issued codes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // Item 5: same empty-state gap as the other three primary
            // tables — a brand-new teacher account (no codes issued yet)
            // previously saw a bare header row with no explanation.
            if (viewModel.issuedCodes.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.keyRound,
                          size: 32,
                          color: scheme.mutedForeground,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No access codes issued yet — issue one above to get started.',
                          style: TextStyle(color: scheme.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (isCompact)
              _IssuedCodesList(
                rows: viewModel.issuedCodes,
                onDelete: viewModel.onDeleteCode,
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 360,
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
                      DataColumn2(label: Text(''), size: ColumnSize.S),
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
                          DataCell(_StatusBadge(status: row.status)),
                          DataCell(Text(row.issuedAt)),
                          DataCell(
                            _DeleteCodeButton(
                              row: row,
                              onDelete: viewModel.onDeleteCode,
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
      ),
    );
  }
}

/// Narrow-viewport replacement for the issued-codes `DataTable2`: a
/// scrollable list of compact cards, one per code, so the table's five
/// columns don't get squeezed illegibly (or force horizontal scrolling)
/// below the 720px breakpoint.
class _IssuedCodesList extends StatelessWidget {
  const _IssuedCodesList({required this.rows, required this.onDelete});

  final List<IssuedCodeRow> rows;
  final Future<void> Function(IssuedCodeRow row) onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final row = rows[index];
          final content = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              row.code,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(status: row.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${issuedCodeTypeLabel(row.type)} · ${row.target}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        row.issuedAt,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                // Same delete affordance as the wide table — a code the
                // teacher can remove on a desktop must be removable on a
                // narrow screen too.
                _DeleteCodeButton(row: row, onDelete: onDelete),
              ],
            ),
          );
          return Card(
            clipBehavior: Clip.antiAlias,
            child: row.subject != null
                ? SubjectAccentCell(subject: row.subject!, child: content)
                : content,
          );
        },
      ),
    );
  }
}

/// Small status pill for an issued code's `unused`/`used`/`archived` state,
/// colored via `ShadTheme` roles so it stays legible in both themes rather
/// than a hardcoded light-only text color.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final Color color = switch (status) {
      'used' => scheme.mutedForeground,
      'archived' => scheme.destructive,
      _ => scheme.primary,
    };
    return ShadBadge.outline(
      backgroundColor: color.withValues(alpha: 0.10),
      foregroundColor: color,
      shape: StadiumBorder(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(status),
    );
  }
}

class _IssuedCodeBanner extends StatelessWidget {
  const _IssuedCodeBanner({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    // The theme's `ShadColorScheme` has no dedicated "success" role (only
    // chemistry/biology/physics live in `colorScheme.custom`), so the
    // light/dark success color is picked here by the theme's actual
    // brightness rather than assuming light mode — never
    // `AppColors.success` unconditionally, which is the light-only value.
    final isDark = ShadTheme.of(context).brightness == Brightness.dark;
    final successColor = isDark ? AppColorsDark.success : AppColors.success;

    // Genuine success-confirmation moment — the one point in this screen a
    // teacher most needs unambiguous positive affect — so it uses the
    // dedicated success color rather than a neutral container color, with a
    // check icon reinforcing the "this worked" read.
    return Card(
          color: successColor.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: successColor.withValues(alpha: 0.4)),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(LucideIcons.circleCheck, color: successColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code issued — give this to your student',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        code,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: scheme.foreground,
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
        )
        .animate()
        .fadeIn(duration: 220.ms)
        .slideY(begin: -0.03, end: 0, duration: 220.ms);
  }
}

class _SubjectCodeForm extends HookWidget {
  const _SubjectCodeForm({
    required this.viewModel,
    required this.onIssue,
    required this.isCompact,
  });

  final AccessCodesViewModel viewModel;
  final Future<void> Function(Future<String> Function() issue) onIssue;
  final bool isCompact;

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
              label: Text(lessonPickerLabel(lesson)),
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
          alignment: isCompact ? Alignment.center : Alignment.centerRight,
          child: SizedBox(
            width: isCompact ? double.infinity : null,
            child: ShadButton(
              onPressed: isSubmitting.value
                  ? null
                  : () async {
                      isSubmitting.value = true;
                      // try/finally (not just the try/catch inside
                      // `handleIssue`) so the spinner clears no matter what —
                      // belt-and-suspenders against any future change to
                      // `handleIssue` that lets an exception escape (item 1).
                      try {
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
                      } finally {
                        isSubmitting.value = false;
                      }
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
        ),
      ],
    );
  }
}

class _LessonCodeForm extends HookWidget {
  const _LessonCodeForm({
    required this.viewModel,
    required this.onIssue,
    required this.isCompact,
  });

  final AccessCodesViewModel viewModel;
  final Future<void> Function(Future<String> Function() issue) onIssue;
  final bool isCompact;

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
                  child: Text(
                    lessonPickerLabel(lesson),
                    overflow: TextOverflow.ellipsis,
                  ),
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
          alignment: isCompact ? Alignment.center : Alignment.centerRight,
          child: SizedBox(
            width: isCompact ? double.infinity : null,
            child: ShadButton(
              onPressed:
                  isSubmitting.value ||
                      studentId.value == null ||
                      lessonId.value == null
                  ? null
                  : () async {
                      isSubmitting.value = true;
                      try {
                        await onIssue(
                          () => viewModel.onIssueLessonCode(
                            lessonId: lessonId.value!,
                            studentId: studentId.value!,
                            customCode: customCode.value.trim().isEmpty
                                ? null
                                : customCode.value.trim(),
                          ),
                        );
                      } finally {
                        isSubmitting.value = false;
                      }
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
        ),
      ],
    );
  }
}

class _RetakeCodeForm extends HookWidget {
  const _RetakeCodeForm({
    required this.viewModel,
    required this.onIssue,
    required this.isCompact,
  });

  final AccessCodesViewModel viewModel;
  final Future<void> Function(Future<String> Function() issue) onIssue;
  final bool isCompact;

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
      viewModel
          .checkRetakeEligible(studentId: sid, lessonId: lid)
          .then((eligible) {
            if (!cancelled) {
              isEligible.value = eligible;
              isChecking.value = false;
            }
          })
          // Without this, a failed eligibility read (offline blip, or a
          // student doc that doesn't exist) left `isChecking` true forever:
          // the panel showed "Checking post-test eligibility..." with no
          // error, and "Issue retake code" stayed permanently disabled with
          // no way to retry short of reloading the page.
          .catchError((Object _) {
            if (!cancelled) {
              isEligible.value = null;
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
                  child: Text(
                    lessonPickerLabel(lesson),
                    overflow: TextOverflow.ellipsis,
                  ),
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
          alignment: isCompact ? Alignment.center : Alignment.centerRight,
          child: SizedBox(
            width: isCompact ? double.infinity : null,
            child: ShadButton(
              onPressed: canSubmit
                  ? () async {
                      isSubmitting.value = true;
                      try {
                        await onIssue(
                          () => viewModel.onIssueQuizRetakeCode(
                            lessonId: lessonId.value!,
                            studentId: studentId.value!,
                          ),
                        );
                      } finally {
                        isSubmitting.value = false;
                      }
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
        ),
      ],
    );
  }
}

/// Deletes one issued code, after an explicit confirmation.
///
/// Deletion is permanent and separate from archiving: archiving invalidates a
/// code while keeping the record of it, whereas this removes the row outright
/// — which is what a teacher wants for a typo, a test code, or a batch issued
/// to the wrong section, none of which should sit in the table forever.
class _DeleteCodeButton extends StatelessWidget {
  const _DeleteCodeButton({required this.row, required this.onDelete});

  final IssuedCodeRow row;
  final Future<void> Function(IssuedCodeRow row) onDelete;

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (dialogContext) => ShadDialog.alert(
        title: const Text('Delete this code?'),
        description: Text(
          'Code ${row.code} will be removed permanently. If a student has '
          'already been given it, it will stop working. This cannot be '
          'undone.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete code'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ShadToaster.of(context);
    try {
      await onDelete(row);
    } catch (error) {
      messenger.show(
        ShadToast.destructive(
          description: Text(
            humanizeSubmitError(error, actionLabel: 'delete this code'),
          ),
        ),
      );
      return;
    }
    messenger.show(ShadToast(description: Text('Code ${row.code} deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Delete code',
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        LucideIcons.trash2,
        color: ShadTheme.of(context).colorScheme.destructive,
      ),
      onPressed: () => _confirmAndDelete(context),
    );
  }
}
