import 'package:cloud_firestore/cloud_firestore.dart';

/// The account that owns the Firebase project. Mirrors the same constant in
/// `firestore.rules`/`storage.rules`, and exists for the same reason: there
/// must always be one account that can sign in and manage the allowlist, so
/// an empty or mis-edited `/teachers` collection can never lock every
/// teacher out of the portal.
const kBootstrapTeacherEmail = 'nadinevictoria17@gmail.com';

/// One entry on the teacher allowlist.
class TeacherAccount {
  const TeacherAccount({
    required this.email,
    this.displayName,
    this.addedBy,
    this.addedAt,
  });

  final String email;
  final String? displayName;
  final String? addedBy;
  final String? addedAt;

  /// True for the project owner, who is a teacher by definition and cannot
  /// be removed from the list (there would be no way back in).
  bool get isBootstrap => email == kBootstrapTeacherEmail;

  Map<String, dynamic> toJson() => {
    'email': email,
    if (displayName != null) 'displayName': displayName,
    if (addedBy != null) 'addedBy': addedBy,
    if (addedAt != null) 'addedAt': addedAt,
  };

  static TeacherAccount fromDoc(String id, Map<String, dynamic>? data) {
    return TeacherAccount(
      email: (data?['email'] as String?) ?? id,
      displayName: data?['displayName'] as String?,
      addedBy: data?['addedBy'] as String?,
      addedAt: data?['addedAt'] as String?,
    );
  }
}

/// Reads and maintains the teacher allowlist (`/teachers/{email}`).
///
/// Role used to be inferred purely from the shape of the signed-in email
/// address — anything that wasn't `<digits>@arscience.school` counted as a
/// teacher. Since Firebase's web API key is public and email/password
/// sign-up must be enabled for students to exist, that let *any* account
/// registered against the project read and write every student record. The
/// allowlist replaces that inference with explicit membership: a teacher is
/// someone an existing teacher has added.
class TeacherDirectoryService {
  TeacherDirectoryService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _teachers =>
      _firestore.collection('teachers');

  /// Document ids are the email address, lowercased — Firebase reports
  /// emails in their original case, so normalizing here keeps
  /// `Teacher@x.com` and `teacher@x.com` from becoming two entries that the
  /// rules' exact-match `exists()` would treat differently.
  static String normalizeEmail(String email) => email.trim().toLowerCase();

  /// Whether [email] may use the teacher portal.
  ///
  /// Fails closed: if the membership read throws (offline, permission
  /// denied), the caller is treated as not a teacher rather than waved
  /// through.
  Future<bool> isAuthorizedTeacher(String email) async {
    final normalized = normalizeEmail(email);
    if (normalized == kBootstrapTeacherEmail) return true;
    try {
      final doc = await _teachers.doc(normalized).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  Stream<List<TeacherAccount>> watchTeachers() {
    return _teachers.snapshots().map((snapshot) {
      final accounts = [
        for (final doc in snapshot.docs)
          TeacherAccount.fromDoc(doc.id, doc.data()),
      ];
      // The bootstrap owner is a teacher whether or not a document exists
      // for them, so surface them in the list rather than letting the UI
      // imply they could be removed.
      if (!accounts.any((a) => a.isBootstrap)) {
        accounts.add(
          const TeacherAccount(
            email: kBootstrapTeacherEmail,
            displayName: 'Project owner',
          ),
        );
      }
      accounts.sort((a, b) => a.email.compareTo(b.email));
      return accounts;
    });
  }

  /// Adds [email] to the allowlist. [addedBy] is recorded so there is a
  /// trail of who granted access.
  Future<void> addTeacher({
    required String email,
    String? displayName,
    required String addedBy,
  }) async {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw ArgumentError('Enter a valid email address.');
    }
    if (RegExp(r'^[0-9]+@arscience\.school$').hasMatch(normalized)) {
      throw ArgumentError(
        'That is a student login, not a teacher account. Student accounts '
        'can never be given teacher access.',
      );
    }
    final existing = await _teachers.doc(normalized).get();
    if (existing.exists) {
      throw StateError('$normalized already has teacher access.');
    }
    await _teachers
        .doc(normalized)
        .set(
          TeacherAccount(
            email: normalized,
            displayName: displayName,
            addedBy: addedBy,
            addedAt: DateTime.now().toIso8601String(),
          ).toJson(),
        );
  }

  /// Revokes [email]'s access.
  ///
  /// Two guards, both about not stranding the school: the project owner can
  /// never be removed, and a teacher cannot remove themselves (which would
  /// drop them out of the portal mid-session with no way back).
  Future<void> removeTeacher({
    required String email,
    required String requestedBy,
  }) async {
    final normalized = normalizeEmail(email);
    if (normalized == kBootstrapTeacherEmail) {
      throw StateError(
        'The project owner\'s access cannot be removed — it is the account '
        'that can always restore teacher access.',
      );
    }
    if (normalized == normalizeEmail(requestedBy)) {
      throw StateError(
        'You cannot remove your own access. Ask another teacher to do it.',
      );
    }
    await _teachers.doc(normalized).delete();
  }
}
