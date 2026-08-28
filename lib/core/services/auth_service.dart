// Role is inferred purely from the email pattern used to sign in — there is
// no separate Firestore role field (PROJECT_FLOW.md Part 3.1). The student
// pattern is `/^\d+@arscience\.school$/`, ported exactly from the retired
// web app's src/lib/auth.ts.

final RegExp _studentEmailPattern = RegExp(r'^\d+@arscience\.school$');

/// True if [email] matches the student account pattern. Anything else is a
/// teacher account.
bool isStudentEmail(String email) => _studentEmailPattern.hasMatch(email);

/// Build the real Firebase Auth email for a raw student ID. Always
/// `{6 plain digits}@arscience.school` — no dash, even if a dash-formatted
/// id slips in (PROJECT_FLOW.md Part 3.2 / Design Spec Section 2, resolved
/// Q5: the dash is a UI display concern only, never part of the real email).
String studentEmailFromRawId(String rawId) {
  final digitsOnly = rawId.replaceAll(RegExp(r'\D'), '');
  return '$digitsOnly@arscience.school';
}

/// Normalize a student login field's raw input for use as a student id:
/// - If it contains '@', treat it as a literal email, unchanged.
/// - Otherwise strip everything but digits (handles both a raw 6-digit id
///   and a dash-formatted '00-0000' display string).
String normalizeStudentIdInput(String input) {
  if (input.contains('@')) return input;
  return input.replaceAll(RegExp(r'\D'), '');
}
