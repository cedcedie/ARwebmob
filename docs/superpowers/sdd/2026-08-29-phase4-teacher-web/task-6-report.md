# Task 6–8 report — Teacher auth, TeacherServices, shell, router, main.dart wire-up

**Commit:** _(filled after commit)_

## Task 6 — Teacher auth (sign-in screen + view model)

**Files created:**
- `lib/features/teacher/auth/teacher_auth_providers.dart`
- `lib/features/teacher/auth/teacher_login_screen.dart`
- `test/features/teacher/auth/teacher_auth_providers_test.dart`

**Interfaces delivered:**
- `currentTeacherEmailProvider` — `StreamProvider<String?>`; null when signed out or when the Firebase email matches the student pattern (`isStudentEmail`).
- `TeacherAuthViewModel` — `StateNotifier<TeacherAuthState>` with email/password setters, `submit()`, `errorMessage`, and `isSubmitting`.
- Client-side rejection of student-pattern emails before calling `AuthService.signInTeacher` with a clear "use the student app" message.
- `AuthService` failures caught into `errorMessage` (including `FirebaseAuthException.message`).

**Login screen:** `TeacherLoginScreen` wrapped in `ShadApp`, centered `ShadCard` (max-width 420), `ShadInput` fields, `ShadButton` submit — desktop card layout, not full-bleed mobile.

### TDD evidence (Task 6)

**RED** — `flutter test test/features/teacher/auth/teacher_auth_providers_test.dart` before implementation: compilation failure (files missing).

**GREEN** — after implementation: `00:00 +3: All tests passed!`

Three required cases:
1. Valid submit calls `signInTeacher` and clears prior error.
2. Student-pattern email rejected without calling auth (`signInTeacherCallCount == 0`).
3. Auth throw surfaces as displayable error message (`Invalid password.`).

---

## Task 7 — `TeacherServices` bundle + provider overrides

**File:** `lib/features/teacher/app/teacher_providers.dart`

**Delivered:**
- `TeacherServices` bundling `lessonRepository`, `quizRepository`, `studentRepository`, `accessCodeIssuanceService`, and `quizAttemptService` (required by access-code issuance eligibility checks wired in Task 12).
- `teacherProviderOverridesFor({required TeacherServices services})` wiring all four screen view-model providers via their `build*ViewModel` helpers (Tasks 9–12 implementations present in the worktree).
- `teacherServicesFromFirestore(FirebaseFirestore)` factory used by `main.dart` and screen tests.

Placeholder `UnimplementedError` throwers live in:
- `lib/features/teacher/lessons/lessons_providers.dart`
- `lib/features/teacher/quizzes/quizzes_providers.dart`
- `lib/features/teacher/students/students_providers.dart`
- `lib/features/teacher/access_codes/access_codes_providers.dart`

---

## Task 8 — Teacher shell + router + `main.dart`

**Files created/modified:**
- `lib/features/teacher/app/teacher_shell.dart` — `NavigationRail` with Lessons, Quizzes, Students, Access Codes, plus disabled **Item Analysis** entry (tooltip: "Coming in Phase 5").
- `lib/features/teacher/app/router.dart` — `buildTeacherRouter({required TeacherServices services})`, `ShellRoute`, routes `/teacher/lessons`, `/teacher/quizzes`, `/teacher/students`, `/teacher/access-codes`, `initialLocation: /teacher/lessons`.
- `lib/main.dart` — web branch watches `currentTeacherEmailProvider`: null → `TeacherLoginScreen`; signed-in → cached `TeacherServices`/`GoRouter` + `ProviderScope` overrides + `MaterialApp.router`.
- `test/widget_test.dart` — updated smoke test: web shows "Teacher sign in" instead of the old placeholder.

Minimal placeholder screens were superseded by Tasks 9–12 full screen implementations already present in the worktree; router imports the real screens.

---

## Verification

```text
flutter test test/features/teacher/auth/teacher_auth_providers_test.dart  → 3 passed
flutter test                                                            → 168 passed
```

No new analyzer errors introduced in Task 6–8 files.
