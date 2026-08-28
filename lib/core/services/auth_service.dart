// Role is inferred purely from the email pattern used to sign in — there is
// no separate Firestore role field (PROJECT_FLOW.md Part 3.1). The student
// pattern is `/^\d+@arscience\.school$/`, ported exactly from the retired
// web app's src/lib/auth.ts.

import 'package:firebase_auth/firebase_auth.dart';

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

/// Thin wrapper around [FirebaseAuth] that applies this app's student-id
/// normalization and email construction. Takes [FirebaseAuth] as a
/// constructor parameter (rather than reading `FirebaseAuth.instance`
/// directly) so callers — including tests — can inject a fake.
class AuthService {
  AuthService({required FirebaseAuth firebaseAuth}) : _firebaseAuth = firebaseAuth;

  final FirebaseAuth _firebaseAuth;

  /// Student login (Android target). Accepts either a raw/dash-formatted
  /// student id or a literal email — see [normalizeStudentIdInput] and
  /// [studentEmailFromRawId] for the exact rules.
  Future<User?> signInStudent({
    required String idOrEmail,
    required String password,
  }) async {
    final normalized = normalizeStudentIdInput(idOrEmail);
    final email = normalized.contains('@')
        ? normalized
        : studentEmailFromRawId(normalized);
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Teacher login (Web target). No transformation — teacher emails are
  /// used exactly as entered.
  Future<User?> signInTeacher({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();
}
