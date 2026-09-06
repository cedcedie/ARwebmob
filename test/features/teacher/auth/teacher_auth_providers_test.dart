import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/services/auth_service.dart';
import 'package:ar_science_explorer/core/services/teacher_directory_service.dart';
import 'package:ar_science_explorer/features/teacher/auth/teacher_auth_providers.dart';

class _TrackingAuthService extends AuthService {
  _TrackingAuthService({this.onSignInTeacher})
    : super(firebaseAuth: MockFirebaseAuth());

  final Future<User?> Function({
    required String email,
    required String password,
  })?
  onSignInTeacher;

  int signInTeacherCallCount = 0;

  @override
  Future<User?> signInTeacher({
    required String email,
    required String password,
  }) async {
    signInTeacherCallCount++;
    if (onSignInTeacher != null) {
      return onSignInTeacher!(email: email, password: password);
    }
    return MockUser(uid: 'uid-teacher', email: email);
  }
}

/// A directory whose allowlist is seeded with the address the tests sign in
/// with, so these tests exercise sign-in itself rather than authorization.
/// The refusal path gets its own test at the bottom.
TeacherDirectoryService _directoryAllowing(List<String> emails) {
  final firestore = FakeFirebaseFirestore();
  for (final email in emails) {
    firestore.collection('teachers').doc(email.toLowerCase()).set({
      'email': email.toLowerCase(),
    });
  }
  return TeacherDirectoryService(firestore: firestore);
}

void main() {
  group('TeacherAuthViewModel', () {
    test(
      'submit with valid credentials calls signInTeacher and clears prior error',
      () async {
        final authService = _TrackingAuthService();
        final vm =
            TeacherAuthViewModel(
                authService: authService,
                teacherDirectory: _directoryAllowing(const [
                  'teacher@school.edu',
                ]),
              )
              ..email = 'teacher@school.edu'
              ..password = 'secret';
        vm.errorMessage = 'Old error';

        await vm.submit();

        expect(authService.signInTeacherCallCount, 1);
        expect(vm.errorMessage, isNull);
        expect(vm.isSubmitting, false);
      },
    );

    test(
      'submit with a student-pattern email is rejected without calling AuthService',
      () async {
        final authService = _TrackingAuthService();
        final vm =
            TeacherAuthViewModel(
                authService: authService,
                teacherDirectory: _directoryAllowing(const [
                  'teacher@school.edu',
                ]),
              )
              ..email = '123456@arscience.school'
              ..password = 'secret';

        await vm.submit();

        expect(authService.signInTeacherCallCount, 0);
        expect(vm.errorMessage, isNotNull);
        expect(vm.errorMessage, contains('student app'));
        expect(vm.isSubmitting, false);
      },
    );

    test(
      'AuthService throwing surfaces as a displayable error message',
      () async {
        final authService = _TrackingAuthService(
          onSignInTeacher:
              ({required String email, required String password}) async {
                throw FirebaseAuthException(
                  code: 'wrong-password',
                  message: 'Invalid password.',
                );
              },
        );
        final vm =
            TeacherAuthViewModel(
                authService: authService,
                teacherDirectory: _directoryAllowing(const [
                  'teacher@school.edu',
                ]),
              )
              ..email = 'teacher@school.edu'
              ..password = 'bad';

        await vm.submit();

        expect(authService.signInTeacherCallCount, 1);
        expect(vm.errorMessage, 'Invalid password.');
        expect(vm.isSubmitting, false);
      },
    );

    test('an authenticated account that is NOT on the teacher allowlist is '
        'signed back out and told why', () async {
      // Authentication is not authorization. Before the allowlist existed,
      // any account that merely wasn't a student email was handed the full
      // teacher portal — and since Firebase sign-up is open, that meant
      // anyone at all.
      final authService = _TrackingAuthService();
      final vm =
          TeacherAuthViewModel(
              authService: authService,
              teacherDirectory: _directoryAllowing(const []),
            )
            ..email = 'stranger@gmail.com'
            ..password = 'secret';

      await vm.submit();

      expect(authService.signInTeacherCallCount, 1);
      expect(vm.errorMessage, kNotATeacherMessage);
      expect(vm.isSubmitting, false);
    });

    test('the project owner is admitted with no allowlist document', () async {
      // There must always be one account that can get in to repair the list.
      final authService = _TrackingAuthService();
      final vm =
          TeacherAuthViewModel(
              authService: authService,
              teacherDirectory: _directoryAllowing(const []),
            )
            ..email = kBootstrapTeacherEmail
            ..password = 'secret';

      await vm.submit();

      expect(vm.errorMessage, isNull);
    });
  });
}
