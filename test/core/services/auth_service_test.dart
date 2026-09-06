import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:ar_science_explorer/core/services/auth_service.dart';

void main() {
  _authServiceTests();

  group('isStudentEmail', () {
    test('matches the student pattern {digits}@arscience.school', () {
      expect(isStudentEmail('123456@arscience.school'), true);
      expect(isStudentEmail('7@arscience.school'), true); // any digit count
    });

    test('rejects anything else as a teacher email', () {
      expect(isStudentEmail('teacher@school.edu'), false);
      expect(isStudentEmail('123456@gmail.com'), false);
      expect(isStudentEmail('abc@arscience.school'), false);
    });
  });

  group('studentEmailFromRawId', () {
    test('builds the plain-digit email with no dash', () {
      expect(studentEmailFromRawId('123456'), '123456@arscience.school');
    });

    test('strips a dash if the caller passes a formatted id by mistake', () {
      expect(studentEmailFromRawId('12-3456'), '123456@arscience.school');
    });
  });

  group('normalizeStudentIdInput', () {
    test('passes a literal email through unchanged', () {
      expect(
        normalizeStudentIdInput('123456@arscience.school'),
        '123456@arscience.school',
      );
    });

    test('strips non-digits from a raw or dash-formatted id', () {
      expect(normalizeStudentIdInput('12-3456'), '123456');
      expect(normalizeStudentIdInput('123456'), '123456');
    });
  });
}

void _authServiceTests() {
  group('AuthService.signInStudent', () {
    test('signs in with the constructed email for a raw id', () async {
      final mockUser = MockUser(
        uid: 'uid-123456',
        email: '123456@arscience.school',
      );
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: false);
      final authService = AuthService(firebaseAuth: mockAuth);

      final user = await authService.signInStudent(
        idOrEmail: '123456',
        password: 'secret',
      );

      expect(user, isNotNull);
      expect(user!.email, '123456@arscience.school');
    });

    test('accepts a literal email input unchanged', () async {
      final mockUser = MockUser(
        uid: 'uid-123456',
        email: '123456@arscience.school',
      );
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: false);
      final authService = AuthService(firebaseAuth: mockAuth);

      final user = await authService.signInStudent(
        idOrEmail: '123456@arscience.school',
        password: 'secret',
      );

      expect(user, isNotNull);
    });
  });

  group('AuthService.signInTeacher', () {
    test('signs in with the email as given, no transformation', () async {
      final mockUser = MockUser(
        uid: 'uid-teacher',
        email: 'teacher@school.edu',
      );
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: false);
      final authService = AuthService(firebaseAuth: mockAuth);

      final user = await authService.signInTeacher(
        email: 'teacher@school.edu',
        password: 'secret',
      );

      expect(user, isNotNull);
      expect(user!.email, 'teacher@school.edu');
    });
  });

  group('AuthService.signOut and authStateChanges', () {
    test('signOut clears the current user', () async {
      final mockUser = MockUser(
        uid: 'uid-123456',
        email: '123456@arscience.school',
      );
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      final authService = AuthService(firebaseAuth: mockAuth);

      expect(mockAuth.currentUser, isNotNull);
      await authService.signOut();
      expect(mockAuth.currentUser, isNull);
    });

    test('authStateChanges emits the signed-in user', () async {
      final mockUser = MockUser(
        uid: 'uid-123456',
        email: '123456@arscience.school',
      );
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      final authService = AuthService(firebaseAuth: mockAuth);

      final user = await authService.authStateChanges().first;
      expect(user?.email, '123456@arscience.school');
    });
  });
}
