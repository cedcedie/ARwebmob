import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/auth_service.dart';

final studentAuthServiceProvider = Provider<AuthService>((ref) {
  return AuthService(firebaseAuth: FirebaseAuth.instance);
});

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
  StudentAuthViewModel({required AuthService authService})
      : _authService = authService,
        super(const StudentAuthState());

  final AuthService _authService;

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
      await _authService.signInStudent(
        idOrEmail: trimmed,
        password: state.password,
      );
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
    return error.message ?? 'Sign-in failed. Check your student ID and password.';
  }
  return error.toString();
}

final studentAuthViewModelProvider =
    StateNotifierProvider.autoDispose<StudentAuthViewModel, StudentAuthState>((ref) {
  return StudentAuthViewModel(authService: ref.watch(studentAuthServiceProvider));
});
