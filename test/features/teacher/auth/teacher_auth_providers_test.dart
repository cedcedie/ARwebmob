import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/services/auth_service.dart';
import 'package:ar_science_explorer/features/teacher/auth/teacher_auth_providers.dart';

class _TrackingAuthService extends AuthService {
  _TrackingAuthService({this.onSignInTeacher})
      : super(firebaseAuth: MockFirebaseAuth());

  final Future<User?> Function({required String email, required String password})? onSignInTeacher;

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

void main() {
  group('TeacherAuthViewModel', () {
    test('submit with valid credentials calls signInTeacher and clears prior error', () async {
      final authService = _TrackingAuthService();
      final vm = TeacherAuthViewModel(authService: authService)
        ..email = 'teacher@school.edu'
        ..password = 'secret';
      vm.errorMessage = 'Old error';

      await vm.submit();

      expect(authService.signInTeacherCallCount, 1);
      expect(vm.errorMessage, isNull);
      expect(vm.isSubmitting, false);
    });

    test('submit with a student-pattern email is rejected without calling AuthService', () async {
      final authService = _TrackingAuthService();
      final vm = TeacherAuthViewModel(authService: authService)
        ..email = '123456@arscience.school'
        ..password = 'secret';

      await vm.submit();

      expect(authService.signInTeacherCallCount, 0);
      expect(vm.errorMessage, isNotNull);
      expect(vm.errorMessage, contains('student app'));
      expect(vm.isSubmitting, false);
    });

    test('AuthService throwing surfaces as a displayable error message', () async {
      final authService = _TrackingAuthService(
        onSignInTeacher: ({required String email, required String password}) async {
          throw FirebaseAuthException(code: 'wrong-password', message: 'Invalid password.');
        },
      );
      final vm = TeacherAuthViewModel(authService: authService)
        ..email = 'teacher@school.edu'
        ..password = 'bad';

      await vm.submit();

      expect(authService.signInTeacherCallCount, 1);
      expect(vm.errorMessage, 'Invalid password.');
      expect(vm.isSubmitting, false);
    });
  });
}
