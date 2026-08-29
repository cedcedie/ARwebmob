# Task 12 report — Access Codes screen (issue 3 types, issued-codes table)

**Commit:** `3b7e79a` — bundled in `feat(teacher): add lessons and quizzes screens` (includes Tasks 9–12 teacher UI)

**Files:**
- `lib/features/teacher/access_codes/access_codes_providers.dart`
- `lib/features/teacher/access_codes/access_codes_screen.dart`
- `test/features/teacher/access_codes/access_codes_screen_test.dart`

## Deliverables

Three issuance forms via `SegmentedButton`:
1. **Subject / lesson-wide** — subject dropdown, optional lesson multi-select (empty = whole subject), optional custom code → `issueSubjectCode`.
2. **Lesson targeted** — student + lesson dropdowns, optional custom code → `issueLessonCode`.
3. **Quiz retake** — student + lesson dropdowns → `issueQuizRetakeCode`; inline eligibility warning and disabled submit when `checkRetakeEligible` returns false (uses `QuizAttemptService` via provider).

**Success UX (Part 9.4):** prominent `_IssuedCodeBanner` with large copyable code + clipboard button.

**Error UX:** all three issuance paths wrapped in `try/catch` on `StateError` (duplicate custom code, ineligible retake per Task 5 review note).

**Issued-codes table:** merges `watchIssuedUnlockCodes` + `watchIssuedRetakeCodes` into `IssuedCodeRow` list (Code, Type, Target, Status, Issued At).

## TDD evidence

**Widget tests** (`access_codes_screen_test.dart`, 6 tests):
1. Subject form issues a code and displays it prominently (real `AccessCodeIssuanceService` + Firestore).
2. Lesson targeted form writes correct `/unlockCodes` doc shape.
3. Retake form disables submit when no post-test attempt (distinct eligibility message).
4. Retake form issues after a recorded post-test attempt (real `QuizAttemptService.recordAttempt` + issuance).
5. Duplicate custom code surfaces `StateError` message (`already exists`), not generic error.
6. Issued-codes table renders merged unlock + retake rows.

All 6 pass.

## Provider wiring

`accessCodesViewModelProvider` registered in `teacherProviderOverridesFor`, with `QuizAttemptService` injected for retake eligibility UI guard.

## Full suite

168/168 tests passing (`flutter test --reporter compact`).

## Status

**DONE**
