import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/auth_service.dart' show AuthService, isStudentEmail;

/// The signed-in teacher's email. Null while signed out or signed in as a
/// student (Phase 1's `{digits}@arscience.school` pattern).
final currentTeacherEmailProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) {
    final email = user?.email;
    if (email == null || isStudentEmail(email)) return null;
    return email;
  });
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(firebaseAuth: FirebaseAuth.instance);
});

class TeacherAuthState {
  const TeacherAuthState({
    this.email = '',
    this.password = '',
    this.errorMessage,
    this.isSubmitting = false,
  });

  final String email;
  final String password;
  final String? errorMessage;
  final bool isSubmitting;

  TeacherAuthState copyWith({
    String? email,
    String? password,
    Object? errorMessage = _sentinel,
    bool? isSubmitting,
  }) {
    return TeacherAuthState(
      email: email ?? this.email,
      password: password ?? this.password,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  static const _sentinel = Object();
}

/// Form state for the teacher sign-in screen on web.
class TeacherAuthViewModel extends StateNotifier<TeacherAuthState> {
  TeacherAuthViewModel({required AuthService authService})
      : _authService = authService,
        super(const TeacherAuthState());

  final AuthService _authService;

  String get email => state.email;
  set email(String value) => state = state.copyWith(email: value);

  String get password => state.password;
  set password(String value) => state = state.copyWith(password: value);

  String? get errorMessage => state.errorMessage;
  set errorMessage(String? value) => state = state.copyWith(errorMessage: value);

  bool get isSubmitting => state.isSubmitting;

  Future<void> submit() async {
    if (state.isSubmitting) return;

    final trimmedEmail = state.email.trim();
    if (isStudentEmail(trimmedEmail)) {
      state = state.copyWith(
        errorMessage: 'Student accounts must sign in through the student app.',
      );
      return;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      await _authService.signInTeacher(email: trimmedEmail, password: state.password);
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
    return error.message ?? 'Sign-in failed. Please check your email and password.';
  }
  return error.toString();
}

final teacherAuthViewModelProvider =
    StateNotifierProvider.autoDispose<TeacherAuthViewModel, TeacherAuthState>((ref) {
  return TeacherAuthViewModel(authService: ref.watch(authServiceProvider));
});
