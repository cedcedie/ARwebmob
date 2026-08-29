# Task 6 brief — Teacher auth: sign-in screen + view model

(Copied verbatim from `docs/superpowers/plans/2026-08-29-phase4-teacher-web.md`, Task 6.)

**Files:**
- Create: `lib/features/teacher/auth/teacher_auth_providers.dart`
- Create: `lib/features/teacher/auth/teacher_login_screen.dart`
- Test: `test/features/teacher/auth/teacher_auth_providers_test.dart`

**Interfaces:**
- Produces: `currentTeacherEmailProvider` (`StreamProvider<String?>`,
  mirrors `student_providers.dart`'s `currentStudentIdProvider` exactly but
  inverted — null while signed out *or* while the signed-in email matches
  the student pattern), `TeacherAuthViewModel` (email/password fields,
  submit, error message state).
- Consumes: `AuthService.signInTeacher` (Phase 1, already exists, unused
  until now), `isStudentEmail` (Phase 1).

```dart
final currentTeacherEmailProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) {
    final email = user?.email;
    if (email == null || isStudentEmail(email)) return null;
    return email;
  });
});
```

- [ ] **Step 1: Write failing tests** for `TeacherAuthViewModel`: submit
  with valid credentials calls `AuthService.signInTeacher` and clears any
  prior error; submit with a student-pattern email is rejected client-side
  before even calling `AuthService` (fast, clear feedback — "use the
  student app to sign in" style message, not a generic auth error);
  `AuthService` throwing surfaces as a displayable error message, not an
  unhandled exception.
- [ ] **Step 2:** Run the test — expect FAIL.
- [ ] **Step 3:** Implement `TeacherAuthViewModel` + `teacher_login_screen.dart`
  (email/password `TextField`s + submit button, `shadcn_ui` components,
  centered card layout appropriate for a desktop browser tab, not a mobile
  full-bleed form).
- [ ] **Step 4:** Run again — expect PASS.
- [ ] **Step 5:** Commit: `feat(teacher): add teacher sign-in screen and view model`.
