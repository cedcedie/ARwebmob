import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/util/file_download.dart';
import '../widgets/error_state.dart';
import 'student_csv_import.dart';

/// Bulk roster import.
///
/// Requested at UAT ("suggested adding a bulk import feature for students").
/// The flow is deliberately three explicit steps — choose a file, review what
/// was found, then import — rather than one button that does everything:
/// creating student logins is not undoable from inside the app, so the
/// teacher sees exactly what is about to happen, including which lines are
/// wrong and why, before anything is written.
class StudentImportDialog extends StatefulWidget {
  const StudentImportDialog({
    super.key,
    required this.existingStudentIds,
    required this.onImport,
  });

  final Set<String> existingStudentIds;

  /// Performs the import and reports the outcome of each row.
  final Future<List<StudentImportOutcome>> Function(List<StudentImportRow> rows)
  onImport;

  static Future<void> show(
    BuildContext context, {
    required Set<String> existingStudentIds,
    required Future<List<StudentImportOutcome>> Function(
      List<StudentImportRow> rows,
    )
    onImport,
  }) {
    return showShadDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StudentImportDialog(
        existingStudentIds: existingStudentIds,
        onImport: onImport,
      ),
    );
  }

  @override
  State<StudentImportDialog> createState() => _StudentImportDialogState();
}

class _StudentImportDialogState extends State<StudentImportDialog> {
  StudentImportPlan? _plan;
  List<StudentImportOutcome>? _outcomes;
  String? _fileName;
  bool _isBusy = false;
  String? _pickError;

  Future<void> _pickFile() async {
    setState(() {
      _isBusy = true;
      _pickError = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt'],
        // Bytes rather than a path: on web there is no filesystem path to
        // read back from.
        withData: true,
      );
      final file = result?.files.singleOrNull;
      if (file == null) return; // cancelled
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _pickError = "That file couldn't be read. Try again.");
        return;
      }
      // allowMalformed: a roster saved from Excel may not be valid UTF-8
      // (Excel still writes cp1252 in some locales). Better to import with a
      // mangled character in one name — which the teacher can see and fix —
      // than to reject the whole file.
      final content = utf8.decode(bytes, allowMalformed: true);
      setState(() {
        _fileName = file.name;
        _plan = parseStudentImportCsv(
          content,
          existingStudentIds: widget.existingStudentIds,
        );
        _outcomes = null;
      });
    } catch (error) {
      setState(
        () => _pickError = humanizeSubmitError(
          error,
          actionLabel: 'read that file',
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _runImport() async {
    final plan = _plan;
    if (plan == null || !plan.canImport) return;
    setState(() => _isBusy = true);
    try {
      final outcomes = await widget.onImport(plan.validRows);
      if (!mounted) return;
      setState(() => _outcomes = outcomes);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _pickError = humanizeSubmitError(
          error,
          actionLabel: 'import these students',
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _downloadTemplate() {
    final saved = downloadTextFile(
      fileName: 'student-import-template.csv',
      content: studentImportTemplateCsv(),
    );
    if (!mounted) return;
    ShadToaster.of(context).show(
      saved
          ? const ShadToast(description: Text('Template downloaded'))
          : const ShadToast.destructive(
              description: Text(
                'Downloading is only available in a web browser.',
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outcomes = _outcomes;
    final plan = _plan;
    final width = MediaQuery.sizeOf(context).width;
    final dialogWidth = width < 620 ? (width - 48).clamp(240.0, 560.0) : 560.0;

    return ShadDialog(
      title: const Text('Import Students'),
      description: const Text(
        'Upload a CSV with the columns: Name, Student ID, Grade, Section, '
        'Password.',
      ),
      actions: [
        if (outcomes == null) ...[
          ShadButton.outline(
            onPressed: _isBusy ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ShadButton(
            onPressed: (_isBusy || plan == null || !plan.canImport)
                ? null
                : _runImport,
            child: Text(
              plan == null
                  ? 'Import'
                  : 'Import ${plan.validRows.length} '
                        '${plan.validRows.length == 1 ? 'student' : 'students'}',
            ),
          ),
        ] else
          ShadButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
      ],
      child: SizedBox(
        width: dialogWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.55,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (outcomes == null) ...[
                  Row(
                    children: [
                      ShadButton.outline(
                        onPressed: _isBusy ? null : _pickFile,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.upload, size: 16),
                            SizedBox(width: 8),
                            Text('Choose CSV'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ShadButton.ghost(
                        onPressed: _isBusy ? null : _downloadTemplate,
                        child: const Text('Download template'),
                      ),
                    ],
                  ),
                  if (_fileName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _fileName!,
                      style: ShadTheme.of(context).textTheme.small,
                    ),
                  ],
                  if (_pickError != null) ...[
                    const SizedBox(height: 12),
                    _Banner(text: _pickError!, isError: true),
                  ],
                  if (plan != null) ...[
                    const SizedBox(height: 12),
                    if (plan.fatalError != null)
                      _Banner(text: plan.fatalError!, isError: true)
                    else ...[
                      _Banner(
                        text:
                            '${plan.validRows.length} ready to import'
                            '${plan.invalidRows.isEmpty ? '' : ', ${plan.invalidRows.length} with problems (these are skipped)'}.',
                        isError: plan.validRows.isEmpty,
                      ),
                      const SizedBox(height: 12),
                      for (final row in plan.rows)
                        _RowTile(
                          title: '${row.name} · ${row.studentId}',
                          subtitle: row.isValid
                              ? 'Grade ${row.grade} · ${row.section}'
                              : 'Line ${row.lineNumber}: ${row.errors.join('; ')}',
                          isError: !row.isValid,
                        ),
                    ],
                  ],
                ] else ...[
                  _Banner(
                    text:
                        '${outcomes.where((o) => o.succeeded).length} imported, '
                        '${outcomes.where((o) => !o.succeeded).length} failed.',
                    isError: outcomes.any((o) => !o.succeeded),
                  ),
                  const SizedBox(height: 12),
                  for (final outcome in outcomes)
                    _RowTile(
                      title: '${outcome.row.name} · ${outcome.row.studentId}',
                      subtitle: outcome.succeeded
                          ? 'Account created'
                          : outcome.error!,
                      isError: !outcome.succeeded,
                    ),
                ],
                if (_isBusy) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isError
            ? scheme.destructive.withValues(alpha: 0.1)
            : scheme.muted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: ShadTheme.of(context).textTheme.small.copyWith(
          color: isError ? scheme.destructive : scheme.foreground,
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.title,
    required this.subtitle,
    required this.isError,
  });

  final String title;
  final String subtitle;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? LucideIcons.circleAlert : LucideIcons.circleCheck,
            size: 16,
            color: isError ? scheme.destructive : scheme.mutedForeground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ShadTheme.of(context).textTheme.small),
                Text(
                  subtitle,
                  style: ShadTheme.of(context).textTheme.small.copyWith(
                    color: isError
                        ? scheme.destructive
                        : scheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
