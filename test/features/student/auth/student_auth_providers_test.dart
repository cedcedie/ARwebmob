import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/services/auth_service.dart';
import 'package:ar_science_explorer/features/student/auth/student_auth_providers.dart';

class _TrackingAuthService extends AuthService {
  _TrackingAuthService({this.onSignInStudent}) : super(firebaseAuth: MockFirebaseAuth());

  final Future<User?> Function({required String idOrEmail, required String password})?
      onSignInStudent;

  int signInStudentCallCount = 0;
  String? lastIdOrEmail;

  @override
  Future<User?> signInStudent({
    required String idOrEmail,
    required String password,
  }) async {
    signInStudentCallCount++;
    lastIdOrEmail = idOrEmail;
    if (onSignInStudent != null) {
      return onSignInStudent!(idOrEmail: idOrEmail, password: password);
    }
    return MockUser(uid: 'uid-student', email: '$idOrEmail@arscience.school');
  }
}

void main() {
  group('StudentAuthViewModel', () {
    test('submit with a dash-formatted id calls signInStudent with that value', () async {
      final authService = _TrackingAuthService();
      final vm = StudentAuthViewModel(authService: authService)
        ..idOrEmail = '12-3456'
        ..password = 'secret';

      await vm.submit();

      expect(authService.signInStudentCallCount, 1);
      // AuthService.signInStudent is responsible for the digit/email
      // normalization (see auth_service_test.dart); the view model passes
      // the trimmed field value straight through.
      expect(authService.lastIdOrEmail, '12-3456');
      expect(vm.state.errorMessage, isNull);
      expect(vm.state.isSubmitting, false);
    });

    test('submit with a literal email calls signInStudent with that email', () async {
      final authService = _TrackingAuthService();
      final vm = StudentAuthViewModel(authService: authService)
        ..idOrEmail = 'student@arscience.school'
        ..password = 'secret';

      await vm.submit();

      expect(authService.signInStudentCallCount, 1);
      expect(authService.lastIdOrEmail, 'student@arscience.school');
      expect(vm.state.errorMessage, isNull);
    });

    test('submit with an empty id shows an error without calling AuthService', () async {
      final authService = _TrackingAuthService();
      final vm = StudentAuthViewModel(authService: authService)
        ..idOrEmail = '   '
        ..password = 'secret';

      await vm.submit();

      expect(authService.signInStudentCallCount, 0);
      expect(vm.state.errorMessage, isNotNull);
    });

    test('AuthService throwing surfaces as a displayable error message', () async {
      final authService = _TrackingAuthService(
        onSignInStudent: ({required String idOrEmail, required String password}) async {
          throw FirebaseAuthException(code: 'wrong-password', message: 'Invalid password.');
        },
      );
      final vm = StudentAuthViewModel(authService: authService)
        ..idOrEmail = '123456'
        ..password = 'bad';

      await vm.submit();

      expect(authService.signInStudentCallCount, 1);
      expect(vm.state.errorMessage, 'Invalid password.');
      expect(vm.state.isSubmitting, false);
    });
  });
}
