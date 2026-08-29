import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../core/ar/model_assets.dart';
import '../../../core/models/ar_payload.dart';
import '../../../core/models/subject_key.dart';
import '../../../core/models/teacher_lesson.dart';
import '../../../core/models/teacher_quiz.dart';
import '../widgets/dynamic_string_list_field.dart';
import 'lessons_providers.dart';

class LessonForm extends StatefulWidget {
  const LessonForm({
    super.key,
    this.initial,
    required this.quizOptions,
    required this.onSubmit,
    this.submitLabel = 'Save',
  });

  final TeacherLesson? initial;
  final List<TeacherQuiz> quizOptions;
  final Future<void> Function(TeacherLesson lesson) onSubmit;
  final String submitLabel;

  @override
  State<LessonForm> createState() => LessonFormState();
}

class LessonFormState extends State<LessonForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  late List<String> _steps;
  int? _modelIndex;
  int? _quarter;
  int? _week;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _steps = [...?initial?.steps];
    if (_steps.isEmpty) _steps = [''];
    _modelIndex = initial?.arPayload?.modelIndex ?? initial?.arModelIndex;
    _quarter = initial?.quarter;
    _week = initial?.week;
  }

  String? get _previewPath => resolveGlbPreviewPath(
        quarter: _quarter,
        week: _week,
        modelIndex: _modelIndex,
      );

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

    final lesson = TeacherLesson(
      id: widget.initial?.id ?? 'teacher-${DateTime.now().millisecondsSinceEpoch}',
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
              child: FilledButton(
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
