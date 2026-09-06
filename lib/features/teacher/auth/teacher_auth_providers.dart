import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/auth_service.dart'
    show AuthService, isStudentEmail;
import '../../../core/services/teacher_directory_service.dart';

/// Message shown when a real, successfully authenticated account is not on
/// the teacher allowlist. Deliberately says nothing about whether the
/// address exists or what the list contains.
const kNotATeacherMessage =
    'This account does not have teacher access. Ask an existing teacher to '
    'add your email address in Teacher Access.';

final teacherDirectoryServiceProvider = Provider<TeacherDirectoryService>((
  ref,
) {
  return TeacherDirectoryService(firestore: FirebaseFirestore.instance);
});

/// The signed-in teacher's email. Null while signed out, signed in as a
/// student (Phase 1's `{digits}@arscience.school` pattern), or signed in as
/// an account that is not on the teacher allowlist.
///
/// The allowlist check is the client half of `firestore.rules`' `isTeacher()`
/// — the rules are what actually protect the data, but without this check a
/// non-teacher who signed in would be shown the portal shell and then hit
/// permission errors on every panel, which reads like the app is broken
/// rather than like access being refused. An unauthorized account is signed
/// straight back out so it cannot linger in a half-authenticated state.
final currentTeacherEmailProvider = StreamProvider<String?>((ref) async* {
  final directory = ref.watch(teacherDirectoryServiceProvider);
  await for (final user in FirebaseAuth.instance.authStateChanges()) {
    final email = user?.email;
    if (email == null || isStudentEmail(email)) {
      yield null;
      continue;
    }
    if (await directory.isAuthorizedTeacher(email)) {
      yield email;
      continue;
    }
    await FirebaseAuth.instance.signOut();
    yield null;
  }
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
  TeacherAuthViewModel({
    required AuthService authService,
    required TeacherDirectoryService teacherDirectory,
  }) : _authService = authService,
       _teacherDirectory = teacherDirectory,
       super(const TeacherAuthState());

  final AuthService _authService;
  final TeacherDirectoryService _teacherDirectory;

  /// Signs an authenticated-but-unauthorized account back out and reports
  /// why. Authentication only proves who someone is; teacher *access* is
  /// membership of the allowlist, and this is where the two are separated
  /// on the sign-in screen so the refusal is explained rather than showing
  /// up later as permission errors inside the portal.
  ///
  /// Returns true when the account is allowed to continue.
  Future<bool> _ensureAuthorized(String? signedInEmail) async {
    if (signedInEmail == null) return false;
    if (await _teacherDirectory.isAuthorizedTeacher(signedInEmail)) return true;
    await _authService.signOut();
    state = state.copyWith(errorMessage: kNotATeacherMessage);
    return false;
  }

  String get email => state.email;
  set email(String value) => state = state.copyWith(email: value);

  String get password => state.password;
  set password(String value) => state = state.copyWith(password: value);

  String? get errorMessage => state.errorMessage;
  set errorMessage(String? value) =>
      state = state.copyWith(errorMessage: value);

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
      final user = await _authService.signInTeacher(
        email: trimmedEmail,
        password: state.password,
      );
      if (!await _ensureAuthorized(user?.email ?? trimmedEmail)) return;
      state = state.copyWith(errorMessage: null);
    } catch (error) {
      state = state.copyWith(errorMessage: _authErrorMessage(error));
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<void> signInWithGoogle() =>
      _signInWithOAuth(_authService.signInTeacherWithGoogle);

  Future<void> signInWithMicrosoft() =>
      _signInWithOAuth(_authService.signInTeacherWithMicrosoft);

  Future<void> _signInWithOAuth(Future<User?> Function() signIn) async {
    if (state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final user = await signIn();
      final signedInEmail = user?.email;
      if (signedInEmail != null && isStudentEmail(signedInEmail)) {
        // A student-pattern email somehow signed in through the teacher OAuth
        // flow — reject it the same way the plain email/password path does.
        await _authService.signOut();
        state = state.copyWith(
          errorMessage:
              'Student accounts must sign in through the student app.',
        );
        return;
      }
      if (!await _ensureAuthorized(signedInEmail)) return;
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
        'Sign-in failed. Please check your email and password.';
  }
  // Other raw-error-display sweep (item 2): never surface a raw
  // exception's toString() to a teacher — fall back to a generic,
  // plain-English sentence instead.
  return 'Sign-in failed. Check your connection and try again.';
}

final teacherAuthViewModelProvider =
    StateNotifierProvider.autoDispose<TeacherAuthViewModel, TeacherAuthState>((
      ref,
    ) {
      return TeacherAuthViewModel(
        authService: ref.watch(authServiceProvider),
        teacherDirectory: ref.watch(teacherDirectoryServiceProvider),
      );
    });
