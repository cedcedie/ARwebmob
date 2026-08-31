import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/question_type.dart';
import '../../../core/models/quiz_phase.dart';
import '../../../core/models/subject_key.dart';
import '../../../core/models/teacher_quiz.dart';
import '../../../core/models/teacher_quiz_question.dart';
import '../../../core/theme/app_theme.dart';
import '../lessons/lessons_providers.dart' show subjectKeyLabel;
import '../widgets/dynamic_string_list_field.dart';
import '../widgets/error_state.dart';

class QuizQuestionDraft {
  QuizQuestionDraft({
    this.question = '',
    List<String>? options,
    this.correctIndex = 0,
    this.hint = '',
    this.type = QuestionType.mc,
  }) : options = options ?? ['', '', '', ''];

  String question;
  List<String> options;
  int correctIndex;
  String hint;
  QuestionType type;

  factory QuizQuestionDraft.fromModel(TeacherQuizQuestion q) {
    final options = [...q.options];
    while (options.length < 4) {
      options.add('');
    }
    return QuizQuestionDraft(
      question: q.question,
      options: options.take(4).toList(),
      correctIndex: q.correctIndex,
      hint: q.hint,
      type: q.type,
    );
  }

  TeacherQuizQuestion toModel() {
    return TeacherQuizQuestion(
      question: question.trim(),
      options: options.map((o) => o.trim()).toList(),
      correctIndex: correctIndex,
      hint: hint.trim(),
      type: type,
    );
  }
}

class QuizForm extends StatefulWidget {
  const QuizForm({
    super.key,
    this.initial,
    required this.onSubmit,
    this.submitLabel = 'Save',
  });

  final TeacherQuiz? initial;
  final Future<void> Function(TeacherQuiz quiz) onSubmit;
  final String submitLabel;

  @override
  State<QuizForm> createState() => QuizFormState();
}

class QuizFormState extends State<QuizForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  late List<QuizQuestionDraft> _questions;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    final initialQuestions = widget.initial?.questions ?? const [];
    _questions = initialQuestions.isEmpty
        ? [QuizQuestionDraft()]
        : initialQuestions.map(QuizQuestionDraft.fromModel).toList();
  }

  String? _validateQuestions() {
    if (_questions.isEmpty) {
      return 'Add at least one question.';
    }
    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.question.trim().isEmpty) {
        return 'Question ${i + 1} needs question text.';
      }
      for (var j = 0; j < 4; j++) {
        if (q.options[j].trim().isEmpty) {
          return 'Question ${i + 1}, option ${j + 1} is required.';
        }
      }
      if (q.correctIndex < 0 || q.correctIndex > 3) {
        return 'Question ${i + 1} needs a correct option selected.';
      }
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.saveAndValidate()) return;

    final questionError = _validateQuestions();
    if (questionError != null) {
      setState(() => _validationMessage = questionError);
      return;
    }
    setState(() => _validationMessage = null);

    final values = formState.value;
    final quiz = TeacherQuiz(
      id: widget.initial?.id ?? 'quiz-${DateTime.now().millisecondsSinceEpoch}',
      title: (values['title'] as String).trim(),
      subject: values['subject'] as SubjectKey,
      phase: values['phase'] as QuizPhase,
      topicId: (values['topicId'] as String?)?.trim().isEmpty == true
          ? null
          : (values['topicId'] as String?)?.trim(),
      createdAt:
          widget.initial?.createdAt ?? DateTime.now().toUtc().toIso8601String(),
      questions: _questions.map((q) => q.toModel()).toList(),
    );

    // See lesson_form.dart's `_handleSubmit` for why this is wrapped: the
    // owning dialog only pops on success, so a throwing `onSubmit` must be
    // caught here and surfaced, not left as a silent, stuck-open dialog.
    try {
      await widget.onSubmit(quiz);
    } catch (error) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            humanizeSubmitError(error, actionLabel: 'save this quiz'),
          ),
        ),
      );
    }
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
              key: const Key('quiz-title'),
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
            FormBuilderDropdown<QuizPhase>(
              name: 'phase',
              initialValue: initial?.phase ?? QuizPhase.post,
              decoration: const InputDecoration(labelText: 'Phase'),
              items: QuizPhase.values
                  .map(
                    (phase) => DropdownMenuItem(
                      value: phase,
                      child: Text(
                        phase == QuizPhase.pre ? 'Pre-Test' : 'Post-Test',
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            FormBuilderTextField(
              key: const Key('quiz-topic-id'),
              name: 'topicId',
              initialValue: initial?.topicId,
              decoration: const InputDecoration(
                labelText: 'Topic ID (optional)',
              ),
            ),
            const SizedBox(height: 16),
            Text('Questions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < _questions.length; i++) ...[
              _QuestionEditor(
                key: ValueKey('question-$i'),
                index: i,
                draft: _questions[i],
                canRemove: _questions.length > 1,
                onChanged: (draft) => setState(() => _questions[i] = draft),
                onRemove: () => setState(() => _questions.removeAt(i)),
              ),
              const Divider(height: 24),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: ShadButton.ghost(
                key: const Key('quiz-add-question'),
                onPressed: () =>
                    setState(() => _questions.add(QuizQuestionDraft())),
                leading: const Icon(LucideIcons.plus, size: 16),
                child: const Text('Add question'),
              ),
            ),
            if (_validationMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _validationMessage!,
                style: TextStyle(
                  color: ShadTheme.of(context).colorScheme.destructive,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ShadButton(
                key: const Key('quiz-submit'),
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

class _QuestionEditor extends StatefulWidget {
  const _QuestionEditor({
    super.key,
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final QuizQuestionDraft draft;
  final bool canRemove;
  final ValueChanged<QuizQuestionDraft> onChanged;
  final VoidCallback onRemove;

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  late TextEditingController _questionController;
  late TextEditingController _hintController;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.draft.question);
    _hintController = TextEditingController(text: widget.draft.hint);
  }

  @override
  void didUpdateWidget(covariant _QuestionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_questionController.text != widget.draft.question) {
      _questionController.text = widget.draft.question;
    }
    if (_hintController.text != widget.draft.hint) {
      _hintController.text = widget.draft.hint;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  void _syncDraft(VoidCallback mutate) {
    mutate();
    widget.onChanged(widget.draft);
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final index = widget.index;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Question ${index + 1}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            if (widget.canRemove)
              Tooltip(
                message: 'Remove question',
                child: ShadIconButton.ghost(
                  key: Key('quiz-q$index-remove'),
                  onPressed: widget.onRemove,
                  icon: const Icon(LucideIcons.trash2),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        FormBuilderTextField(
          key: Key('quiz-question-$index-text'),
          name: 'question-$index-text',
          controller: _questionController,
          decoration: const InputDecoration(labelText: 'Question text'),
          onChanged: (value) => _syncDraft(() => draft.question = value ?? ''),
        ),
        const SizedBox(height: 8),
        DynamicStringListField(
          label: 'Options',
          fieldKeyPrefix: 'quiz-q$index-option',
          values: draft.options,
          minItems: 4,
          addLabel: 'Add option',
          itemLabelBuilder: (i) => 'Option ${i + 1}',
          onChanged: (values) => _syncDraft(() {
            final next = [...values];
            while (next.length < 4) {
              next.add('');
            }
            draft.options = next.take(4).toList();
          }),
        ),
        const SizedBox(height: 8),
        Text('Correct option', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (optionIndex) {
              final isSelected = draft.correctIndex == optionIndex;
              return InkWell(
                onTap: () => _syncDraft(() => draft.correctIndex = optionIndex),
                borderRadius: optionIndex == 0
                    ? const BorderRadius.vertical(top: Radius.circular(8))
                    : optionIndex == 3
                    ? const BorderRadius.vertical(bottom: Radius.circular(8))
                    : BorderRadius.zero,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.muted : null,
                    border: optionIndex == 0
                        ? null
                        : const Border(
                            top: BorderSide(color: AppColors.border),
                          ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Radio<int>(
                        key: Key('quiz-q$index-correct-$optionIndex'),
                        value: optionIndex,
                        groupValue: draft.correctIndex,
                        activeColor: AppColors.ink,
                        onChanged: (value) {
                          if (value == null) return;
                          _syncDraft(() => draft.correctIndex = value);
                        },
                      ),
                      Text(
                        'Option ${optionIndex + 1}',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        FormBuilderTextField(
          key: Key('quiz-question-$index-hint'),
          name: 'question-$index-hint',
          controller: _hintController,
          decoration: const InputDecoration(labelText: 'Hint'),
          onChanged: (value) => _syncDraft(() => draft.hint = value ?? ''),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<QuestionType>(
          initialValue: draft.type,
          decoration: const InputDecoration(labelText: 'Type'),
          items: const [
            DropdownMenuItem(
              value: QuestionType.mc,
              child: Text('Multiple choice'),
            ),
            DropdownMenuItem(
              value: QuestionType.tf,
              child: Text('True / false'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            _syncDraft(() => draft.type = value);
          },
        ),
      ],
    );
  }
}
