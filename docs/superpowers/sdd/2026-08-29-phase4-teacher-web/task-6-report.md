# Task 6–8 report — Teacher auth, TeacherServices, shell, router, main.dart wire-up

**Commit:** `3b7e79a` — `feat(teacher): add lessons and quizzes screens` (Tasks 6–8 auth/shell/router/main wiring landed in this commit alongside Tasks 9–10 screen work from a parallel agent in the same worktree push)

**Files (Tasks 6–8 scope):**
- `lib/features/teacher/auth/teacher_auth_providers.dart`
- `lib/features/teacher/auth/teacher_login_screen.dart`
- `test/features/teacher/auth/teacher_auth_providers_test.dart`
- `lib/features/teacher/app/teacher_providers.dart`
- `lib/features/teacher/app/teacher_shell.dart`
- `lib/features/teacher/app/router.dart`
- `lib/main.dart` (web branch wire-up)
- `test/widget_test.dart` (updated smoke test)

## Task 6 — Teacher auth

**Interfaces delivered:**
- `currentTeacherEmailProvider` — null when signed out or student-pattern email.
- `TeacherAuthViewModel` / `TeacherAuthState` — email, password, `submit()`, `errorMessage`, `isSubmitting`.
- Student-pattern emails rejected client-side before `AuthService.signInTeacher`.
- Auth errors surfaced in `errorMessage`.

**Login screen:** `ShadApp` + centered `ShadCard`, `ShadInput`, `ShadButton`.

### TDD (3 tests — all green)

1. Valid submit calls `signInTeacher`, clears prior error.
2. Student email rejected without calling auth.
3. Auth throw → displayable error message.

## Task 7 — TeacherServices

- `TeacherServices` bundle: `lessonRepository`, `quizRepository`, `studentRepository`, `accessCodeIssuanceService`, `quizAttemptService`.
- `teacherProviderOverridesFor` wires lessons/quizzes/students/access-codes view-model providers.
- `teacherServicesFromFirestore` factory for app startup and tests.

## Task 8 — Shell + router + main.dart

- `TeacherShell`: side `NavigationRail` — Lessons, Quizzes, Students, Access Codes; disabled Item Analysis ("Coming in Phase 5").
- `buildTeacherRouter`: `ShellRoute`, `/teacher/lessons` initial, four routes.
- `main.dart` web branch: `currentTeacherEmailProvider` → login or cached `TeacherServices` + `MaterialApp.router`.

## Verification

```text
flutter test test/features/teacher/auth/teacher_auth_providers_test.dart  → 3 passed
flutter test                                                            → 168 passed
```
