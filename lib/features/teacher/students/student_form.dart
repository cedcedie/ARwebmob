import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/student_record.dart';
import '../../../core/services/auth_service.dart' show normalizeStudentIdInput;
import 'student_id_format.dart';
import 'students_providers.dart';

/// Create-student form — roster identity fields only (name, student id,
/// grade, section). Scores and activity lists are never edited here.
class StudentFormSheet extends StatelessWidget {
  const StudentFormSheet({super.key, required this.onSubmit});

  final Future<void> Function(StudentRecord student) onSubmit;

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(StudentRecord student) onSubmit,
  }) {
    return showShadDialog<void>(
      context: context,
      builder: (context) => StudentFormSheet(onSubmit: onSubmit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormBuilderState>();

    return ShadDialog(
      title: const Text('Add Student'),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: () async {
            if (formKey.currentState?.saveAndValidate() != true) return;
            final values = formKey.currentState!.value;
            final studentId = normalizeStudentIdInput(
              values['studentId'] as String,
            );
            final student = blankStudentRecord(
              name: values['name'] as String,
              studentId: studentId,
              grade: values['grade'] as String,
              section: values['section'] as String,
            );
            await onSubmit(student);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Create'),
        ),
      ],
      child: SizedBox(
        width: 420,
        // FormBuilderTextField below is a Material widget and needs a
        // Material ancestor — ShadDialog doesn't provide one.
        child: Material(
          type: MaterialType.transparency,
          child: FormBuilder(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormBuilderTextField(
                  key: const Key('student_name'),
                  name: 'name',
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 12),
                FormBuilderTextField(
                  key: const Key('student_id'),
                  name: 'studentId',
                  decoration: const InputDecoration(
                    labelText: 'Student ID',
                    hintText: '00-0000',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [StudentIdInputFormatter()],
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    (value) {
                      if (value == null || !isValidStudentIdInput(value)) {
                        return 'Student ID must be exactly 6 digits';
                      }
                      return null;
                    },
                  ]),
                ),
                const SizedBox(height: 12),
                FormBuilderTextField(
                  key: const Key('student_grade'),
                  name: 'grade',
                  decoration: const InputDecoration(labelText: 'Grade'),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 12),
                FormBuilderTextField(
                  key: const Key('student_section'),
                  name: 'section',
                  decoration: const InputDecoration(labelText: 'Section'),
                  validator: FormBuilderValidators.required(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
