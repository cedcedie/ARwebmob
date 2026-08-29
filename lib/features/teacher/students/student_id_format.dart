import 'package:flutter/services.dart';

import '../../../core/services/auth_service.dart' show normalizeStudentIdInput;

/// Formats a plain 6-digit student id for display as `00-0000` (Part 3.2).
String formatStudentIdForDisplay(String studentId) {
  final digits = normalizeStudentIdInput(studentId);
  if (digits.length != 6) return studentId;
  return '${digits.substring(0, 2)}-${digits.substring(2)}';
}

/// Input mask matching the Android login field: up to 6 digits shown as
/// `00-0000` while the teacher types.
class StudentIdInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 6) return oldValue;

    final formatted = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}-${digits.substring(2)}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// True when [input] normalizes to exactly six digits.
bool isValidStudentIdInput(String input) {
  final digits = normalizeStudentIdInput(input);
  return RegExp(r'^\d{6}$').hasMatch(digits);
}
