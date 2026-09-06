import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/student_repository.dart';

final studentAuthServiceProvider = Provider<AuthService>((ref) {
  return AuthService(firebaseAuth: FirebaseAuth.instance);
});

/// Same repository/collection `students_providers.dart`'s teacher roster and
/// `main.dart`'s student services read/write — used here, pre-sign-in, only
/// to check `isArchived` before letting a student past the login screen.
final studentAuthRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(firestore: FirebaseFirestore.instance);
});

/// Message shown (and asserted on in tests) when an archived student's
/// credentials are otherwise valid but the account has been archived by a
/// teacher.
const String kArchivedStudentMessage =
    'This account has been archived. Contact your teacher.';

class StudentAuthState {
  const StudentAuthState({
    this.idOrEmail = '',
    this.password = '',
    this.errorMessage,
    this.isSubmitting = false,
  });

  final String idOrEmail;
  final String password;
  final String? errorMessage;
  final bool isSubmitting;

  StudentAuthState copyWith({
    String? idOrEmail,
    String? password,
    Object? errorMessage = _sentinel,
    bool? isSubmitting,
  }) {
    return StudentAuthState(
      idOrEmail: idOrEmail ?? this.idOrEmail,
      password: password ?? this.password,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  static const _sentinel = Object();
}

class StudentAuthViewModel extends StateNotifier<StudentAuthState> {
  StudentAuthViewModel({
    required AuthService authService,
    StudentRepository? studentRepository,
  }) : _authService = authService,
       _studentRepository = studentRepository,
       super(const StudentAuthState());

  final AuthService _authService;
  // Nullable so existing tests that don't care about archive-checking can
  // keep constructing this view model with just an AuthService; when null,
  // the archive check below is skipped (never null in production — see
  // studentAuthViewModelProvider).
  final StudentRepository? _studentRepository;

  String get idOrEmail => state.idOrEmail;
  set idOrEmail(String value) => state = state.copyWith(idOrEmail: value);

  String get password => state.password;
  set password(String value) => state = state.copyWith(password: value);

  Future<void> submit() async {
    if (state.isSubmitting) return;

    final trimmed = state.idOrEmail.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(errorMessage: 'Enter your student ID or email.');
      return;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final user = await _authService.signInStudent(
        idOrEmail: trimmed,
        password: state.password,
      );

      final email = user?.email;
      final studentId = email != null && isStudentEmail(email)
          ? email.split('@').first
          : null;
      if (studentId != null && _studentRepository != null) {
        final record = await _studentRepository.getStudent(studentId);
        if (record != null && record.isArchived) {
          // Credentials were valid, but the account has been archived —
          // undo the sign-in rather than letting main.dart's
          // currentStudentIdProvider (driven purely by auth state) route
          // this student into the app shell.
          await _authService.signOut();
          state = state.copyWith(errorMessage: kArchivedStudentMessage);
          return;
        }
      }

      state = state.copyWith(errorMessage: null);
    } catch (error) {
      state = state.copyWith(errorMessage: _authErrorMessage(error));
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}

String _authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return error.message ??
        'Sign-in failed. Check your student ID and password.';
  }
  return error.toString();
}

final studentAuthViewModelProvider =
    StateNotifierProvider.autoDispose<StudentAuthViewModel, StudentAuthState>((
      ref,
    ) {
      return StudentAuthViewModel(
        authService: ref.watch(studentAuthServiceProvider),
        studentRepository: ref.watch(studentAuthRepositoryProvider),
      );
    });
