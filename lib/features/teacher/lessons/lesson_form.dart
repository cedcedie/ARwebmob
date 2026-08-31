import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/ar/model_assets.dart';
import '../../../core/models/ar_payload.dart';
import '../../../core/models/subject_key.dart';
import '../../../core/models/teacher_lesson.dart';
import '../../../core/models/teacher_quiz.dart';
import '../../../core/services/lesson_content_upload_service.dart';
import '../widgets/dynamic_string_list_field.dart';
import 'lessons_providers.dart';

class LessonForm extends StatefulWidget {
  const LessonForm({
    super.key,
    this.initial,
    required this.quizOptions,
    required this.onSubmit,
    this.submitLabel = 'Save',
    this.uploadContentOverride, // test-only injection point
    this.refetchLesson,
  });

  final TeacherLesson? initial;
  final List<TeacherQuiz> quizOptions;
  final Future<void> Function(TeacherLesson lesson) onSubmit;
  final String submitLabel;
  final Future<({String url, bool isConversionNeeded})> Function(
    String lessonId,
    String fileName,
    Uint8List bytes,
  )? uploadContentOverride;

  /// Re-fetches a lesson doc's current server state by id, right before
  /// submit — guards against the save-after-conversion race (final
  /// whole-branch review Fix 5): if the Cloud Function finishes converting
  /// an uploaded PPTX (Firestore `contentStatus` -> 'ready' with real slide
  /// URLs) before the teacher clicks Save, this form's own in-memory state
  /// is still the stale 'processing' + raw-upload-URL snapshot taken at
  /// upload time. `LessonRepository.updateLesson` does a full `.set()`
  /// overwrite, so submitting that stale snapshot would permanently
  /// clobber the real conversion result. `null` (e.g. in widget tests that
  /// don't exercise this path) simply skips the check.
  final Future<TeacherLesson?> Function(String lessonId)? refetchLesson;

  @override
  State<LessonForm> createState() => LessonFormState();
}

class LessonFormState extends State<LessonForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  late List<String> _steps;
  int? _modelIndex;
  int? _quarter;
  int? _week;
  String? _uploadedContentUrl;
  bool _uploadedContentNeedsConversion = false;
  late final String _lessonId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _steps = [...?initial?.steps];
    if (_steps.isEmpty) _steps = [''];
    _modelIndex = initial?.arPayload?.modelIndex ?? initial?.arModelIndex;
    _quarter = initial?.quarter;
    _week = initial?.week;
    // Derived exactly once, here, for the lifetime of this form session —
    // not separately in _pickAndUploadContent and _handleSubmit, which for
    // a brand-new lesson (initial == null) used to each stamp their own
    // `DateTime.now()`-based id at different wall-clock moments, uploading
    // Storage content under one lesson id while submitting the Firestore
    // doc under a different one.
    _lessonId = initial?.id ?? 'teacher-${DateTime.now().millisecondsSinceEpoch}';
  }

  String? get _previewPath => resolveGlbPreviewPath(
        quarter: _quarter,
        week: _week,
        modelIndex: _modelIndex,
      );

  Future<void> _pickAndUploadContent() async {
    final ({String url, bool isConversionNeeded}) uploadResult;

    // Test-only injection point: when provided, skip the real
    // file_picker/Storage round trip entirely so widget tests can simulate
    // "a file was picked and uploaded" without a platform channel handler.
    if (widget.uploadContentOverride != null) {
      uploadResult = await widget.uploadContentOverride!(_lessonId, 'content', Uint8List(0));
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pptx', 'pdf'],
        withData: true,
      );
      final file = result?.files.single;
      if (file?.bytes == null) return;

      final isConversionNeeded = file!.extension?.toLowerCase() == 'pptx';
      final service = LessonContentUploadService(uploader: FirebaseStorageUploader());
      final url = await service.uploadLessonContent(
        lessonId: _lessonId, fileName: file.name, bytes: file.bytes!,
      );
      uploadResult = (url: url, isConversionNeeded: isConversionNeeded);
    }

    setState(() {
      _uploadedContentUrl = uploadResult.url;
      _uploadedContentNeedsConversion = uploadResult.isConversionNeeded;
    });
  }

  Future<void> _handleSubmit() async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.saveAndValidate()) return;

    final values = formState.value;
    final subject = values['subject'] as SubjectKey;
    final title = (values['title'] as String).trim();
    final summary = (values['summary'] as String?)?.trim();
    final content = (values['content'] as String?)?.trim();
    final quarter = int.tryParse('${values['quarter'] ?? ''}');
    final week = int.tryParse('${values['week'] ?? ''}');
    final linkedQuizId = values['linkedQuizId'] as String?;
    final modelIndexRaw = int.tryParse('${values['modelIndex'] ?? ''}');
    final steps = _steps.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    var contentImageUrls = _uploadedContentUrl != null
        ? [_uploadedContentUrl!]
        : widget.initial?.contentImageUrls;
    var contentStatus = _uploadedContentUrl == null
        ? widget.initial?.contentStatus
        : (_uploadedContentNeedsConversion ? 'processing' : 'ready');

    // Save-after-conversion race guard (Fix 5): a PPTX conversion may have
    // finished server-side (contentStatus -> 'ready' with real slide URLs)
    // in the time between upload and this submit. Re-fetch the current
    // doc and prefer it over our stale local snapshot when that happened,
    // so the full `.set()` in LessonRepository.updateLesson doesn't
    // permanently clobber a completed conversion back to "processing".
    if (_uploadedContentNeedsConversion && widget.refetchLesson != null) {
      final current = await widget.refetchLesson!(_lessonId);
      if (current != null && current.contentStatus == 'ready') {
        contentImageUrls = current.contentImageUrls;
        contentStatus = current.contentStatus;
      }
    }

    final lesson = TeacherLesson(
      id: _lessonId,
      title: title,
      subject: subject,
      summary: summary?.isEmpty == true ? null : summary,
      content: content?.isEmpty == true ? null : content,
      steps: steps.isEmpty ? null : steps,
      quarter: quarter,
      week: week,
      linkedQuizId: linkedQuizId?.isEmpty == true ? null : linkedQuizId,
      createdAt: widget.initial?.createdAt ?? DateTime.now().toUtc().toIso8601String(),
      arModelIndex: modelIndexRaw,
      arPayload: modelIndexRaw == null
          ? widget.initial?.arPayload
          : ARPayload(
              modelIndex: modelIndexRaw,
              detectionMode: widget.initial?.arPayload?.detectionMode ?? 'marker',
              anchorHint: widget.initial?.arPayload?.anchorHint ?? 'Scan the lesson marker.',
              lessonSteps: steps.isEmpty ? const ['View the 3D model'] : steps,
            ),
      hasAR: modelIndexRaw != null || widget.initial?.hasAR == true,
      isArchived: widget.initial?.isArchived ?? false,
      contentImageUrls: contentImageUrls,
      contentStatus: contentStatus,
    );

    await widget.onSubmit(lesson);
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initial;

    return FormBuilder(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormBuilderTextField(
              key: const Key('lesson-title'),
              name: 'title',
              initialValue: initial?.title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: FormBuilderValidators.required(),
            ),
            const SizedBox(height: 12),
            FormBuilderDropdown<SubjectKey>(
              name: 'subject',
              initialValue: initial?.subject ?? SubjectKey.chemistry,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: SubjectKey.values
                  .map(
                    (subject) => DropdownMenuItem(
                      value: subject,
                      child: Text(subjectKeyLabel(subject)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            FormBuilderTextField(
              key: const Key('lesson-summary'),
              name: 'summary',
              initialValue: initial?.summary,
              decoration: const InputDecoration(labelText: 'Summary'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            FormBuilderTextField(
              name: 'content',
              initialValue: initial?.content,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            DynamicStringListField(
              label: 'Steps',
              values: _steps,
              addLabel: 'Add step',
              onChanged: (values) => setState(() => _steps = values.isEmpty ? [''] : values),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    key: const Key('lesson-quarter'),
                    name: 'quarter',
                    initialValue: initial?.quarter?.toString(),
                    decoration: const InputDecoration(labelText: 'Quarter'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => _quarter = int.tryParse(value ?? '')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderTextField(
                    key: const Key('lesson-week'),
                    name: 'week',
                    initialValue: initial?.week?.toString(),
                    decoration: const InputDecoration(labelText: 'Week'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => _week = int.tryParse(value ?? '')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FormBuilderDropdown<String?>(
              name: 'linkedQuizId',
              initialValue: initial?.linkedQuizId,
              decoration: const InputDecoration(labelText: 'Linked quiz (optional)'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('None')),
                ...widget.quizOptions.map(
                  (quiz) => DropdownMenuItem(
                    value: quiz.id,
                    child: Text(quiz.title, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FormBuilderTextField(
              name: 'modelIndex',
              initialValue: _modelIndex?.toString(),
              decoration: const InputDecoration(
                labelText: 'AR model index (optional)',
                helperText: 'Read-only preview — does not change the Unity mapping.',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() => _modelIndex = int.tryParse(value ?? '')),
            ),
            const SizedBox(height: 12),
            ShadButton.outline(
              key: const Key('lesson-upload-content'),
              onPressed: _pickAndUploadContent,
              leading: const Icon(LucideIcons.upload, size: 16),
              child: Text(_uploadedContentUrl == null ? 'Upload PPTX or PDF' : 'Content uploaded'),
            ),
            if (_previewPath != null) ...[
              const SizedBox(height: 12),
              Text('3D model preview', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 240,
                child: _LessonModelPreview(assetPath: _previewPath!),
              ),
            ],
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ShadButton(
                key: const Key('lesson-submit'),
                onPressed: _handleSubmit,
                child: Text(widget.submitLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonModelPreview extends StatelessWidget {
  const _LessonModelPreview({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (isTest) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text('Model preview: $assetPath')),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ModelViewer(
        src: assetPath,
        alt: 'Lesson 3D model preview',
        ar: false,
        autoRotate: true,
        cameraControls: true,
      ),
    );
  }
}
