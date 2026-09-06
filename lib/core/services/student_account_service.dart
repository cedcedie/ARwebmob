import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/student_record.dart';
import 'auth_service.dart' show studentEmailFromRawId;
import 'student_repository.dart';

/// Creates the *login* for a student, not just their roster row.
///
/// UAT finding: "hindi rin gumana yung pag add namin ng student kahit nasa db
/// na" — Add Student only wrote a Firestore document, so the student existed
/// in the roster but had no Firebase Auth account and could never sign in.
/// The client's requirement is that the teacher sets the password at the
/// moment they add the student.
///
/// The delicate part is that `createUserWithEmailAndPassword` signs the *new*
/// user in on whichever `FirebaseAuth` instance it is called on — calling it
/// on the default instance would silently kick the teacher out of their own
/// session mid-task. So account creation runs on a short-lived **secondary
/// FirebaseApp**, which has its own auth state; the teacher's session on the
/// default app is never touched.
class StudentAccountService {
  StudentAccountService({
    required this.studentRepository,
    required FirebaseOptions firebaseOptions,
    FirebaseFunctions? functions,
  }) : _options = firebaseOptions,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final StudentRepository studentRepository;
  final FirebaseOptions _options;
  final FirebaseFunctions _functions;

  /// Name of the throwaway app used for provisioning. Reused across calls —
  /// `Firebase.initializeApp` throws `duplicate-app` if the same name is
  /// initialized twice, so an existing instance is looked up first.
  static const _provisioningAppName = 'studentProvisioning';

  /// Raised when a login already exists, so the caller can tell a
  /// first-time provision apart from a true password reset.
  static const kStudentAlreadyHasLogin =
      'This student already has a login. Changing an existing password needs '
      'the password service (Cloud Functions) to be deployed.';

  /// Minimum Firebase Auth will accept. Surfaced here so the form can state
  /// the same rule instead of the teacher discovering it via a raw error.
  static const minPasswordLength = 6;

  /// Creates the Firestore roster row and the Firebase Auth login for
  /// [student], using [password] as the student's sign-in password.
  ///
  /// Order matters: the Firestore row is written first, because
  /// `createStudent` is the check that rejects a duplicate student id with a
  /// message the teacher can act on. If the Auth step then fails, the roster
  /// row is rolled back so the teacher isn't left with a half-created student
  /// that looks fine in the table but can't log in — which is exactly the
  /// bug this class exists to fix.
  Future<void> createStudentWithLogin({
    required StudentRecord student,
    required String password,
  }) async {
    if (password.length < minPasswordLength) {
      throw ArgumentError(
        'Password must be at least $minPasswordLength characters.',
      );
    }

    await studentRepository.createStudent(student);

    FirebaseApp? app;
    try {
      app = await _provisioningApp();
      final auth = FirebaseAuth.instanceFor(app: app);
      await auth.createUserWithEmailAndPassword(
        email: studentEmailFromRawId(student.studentId),
        password: password,
      );
      // Leave no signed-in user behind on the secondary app.
      await auth.signOut();
    } catch (error) {
      // Roll the roster row back, but never let a cleanup failure mask the
      // real error the teacher needs to see.
      try {
        await studentRepository.deleteStudent(student.studentId);
      } catch (_) {}
      rethrow;
    }
  }

  /// Resets a student's password to [newPassword], without needing to know
  /// the old one — which is the whole point, since a student asking for a
  /// reset is precisely a student who has forgotten it.
  ///
  /// No client SDK can set another account's password, and the synthetic
  /// `<id>@arscience.school` addresses have no mailbox for a reset email to
  /// reach, so this goes through the `setStudentPassword` callable function,
  /// which re-checks that the caller is an allowlisted teacher server-side.
  Future<void> resetPassword({
    required String studentId,
    required String newPassword,
  }) async {
    if (newPassword.length < minPasswordLength) {
      throw ArgumentError(
        'Password must be at least $minPasswordLength characters.',
      );
    }
    await _callFunction('setStudentPassword', {
      'studentId': studentId,
      'newPassword': newPassword,
    });
  }

  /// Creates a login for a student who has a roster row but no Auth account.
  ///
  /// Every student added before Add Student began provisioning accounts is
  /// in exactly this state: visible in the roster, unable to sign in. This
  /// is how a teacher fixes them without deleting and re-adding.
  ///
  /// Done on the secondary app rather than through a Cloud Function on
  /// purpose: *creating* an account needs no elevated privilege, so this
  /// keeps working on a project that has no Cloud Functions available
  /// (Firebase's free Spark plan). Only overwriting an *existing* account's
  /// password genuinely requires the Admin SDK — see [resetPassword].
  ///
  /// Throws [StateError] with a teacher-readable message if the student
  /// already has a login.
  Future<void> createLoginForExistingStudent({
    required String studentId,
    required String password,
  }) async {
    if (password.length < minPasswordLength) {
      throw ArgumentError(
        'Password must be at least $minPasswordLength characters.',
      );
    }
    final app = await _provisioningApp();
    final auth = FirebaseAuth.instanceFor(app: app);
    try {
      await auth.createUserWithEmailAndPassword(
        email: studentEmailFromRawId(studentId),
        password: password,
      );
      await auth.signOut();
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        throw StateError(kStudentAlreadyHasLogin);
      }
      rethrow;
    }
  }

  /// Calls a callable function and turns its failure modes into messages a
  /// teacher can act on. A raw `FirebaseFunctionsException` surfaces as
  /// "[firebase_functions/internal] ...", which tells them nothing.
  Future<void> _callFunction(String name, Map<String, dynamic> payload) async {
    try {
      await _functions.httpsCallable(name).call<dynamic>(payload);
    } on FirebaseFunctionsException catch (error) {
      final message = error.message;
      if (message != null && message.isNotEmpty) {
        throw StateError(message);
      }
      if (error.code == 'unavailable' || error.code == 'not-found') {
        throw StateError(
          'The password service is unavailable. It may not be deployed yet — '
          'ask your developer to deploy the Cloud Functions.',
        );
      }
      throw StateError('That did not work. Please try again.');
    }
  }

  Future<FirebaseApp> _provisioningApp() async {
    try {
      return Firebase.app(_provisioningAppName);
    } on FirebaseException {
      return Firebase.initializeApp(
        name: _provisioningAppName,
        options: _options,
      );
    }
  }
}
