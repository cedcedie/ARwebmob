# Task 5 report — `AccessCodeIssuanceService`

**Commit:** `055fce2` — `feat(teacher): add AccessCodeIssuanceService for the 3 code types`

**Files:**
- Created `lib/core/services/access_code_issuance_service.dart`
- Created `test/core/services/access_code_issuance_service_test.dart` (8 tests)

## TDD evidence

**RED** — ran `flutter test test/core/services/access_code_issuance_service_test.dart`
before implementing anything. Result: compilation failure — `Error when
reading 'lib/core/services/access_code_issuance_service.dart': The system
cannot find the file specified` and 8× `Method not found:
'AccessCodeIssuanceService'`. Confirmed failing for the expected reason
(class didn't exist yet), not a typo/setup bug.

**GREEN** — after implementing `access_code_issuance_service.dart`, re-ran
the same file: `00:00 +8: All tests passed!` — all 8 tests green (6 required
by the brief's Step 1 + 2 extra stream-smoke tests I added for the
`watchIssuedUnlockCodes`/`watchIssuedRetakeCodes` API surface, since the
proposed public API includes them).

## The 6 required test cases — each confirmed round-tripping through the real `redeem()`

1. **`issueSubjectCode` (whole-subject, no `lessonIds`)** — wrote the code via
   the issuance service, then called the real `AccessCodeService.redeem()`
   with no `targetId`/`targetType` (generic Home entry). `redeem()` returned
   `(success: true, message: 'Subject unlocked successfully!')` — this is
   `redeem()`'s step 3 branch (`type == 'subject' && subjects != null &&
   subjects.isNotEmpty`).

2. **`issueSubjectCode` with `lessonIds: ['q1w1', 'q1w2']`** — `redeem()`
   targeting `q1w9` (not in the list) with `AccessCodeTarget.lesson`
   returned `(success: false, message: contains("isn't valid for this
   lesson"))` — `redeem()`'s step 2 rejection branch. The same code targeting
   `q1w1` (in the list) returned `(success: true, ...)` — step 2's success
   path (`_unlockLessons` + `_trackUsage`).

3. **`issueLessonCode(lessonId: 'q2w2', studentId: '111111')`** —
   `redeem()` called by student `'222222'` returned `(success: false,
   message: contains('assigned to a different student'))` — the
   `targetStudentId` mismatch path near the top of `redeem()`. The same code
   redeemed by the targeted student `'111111'` with
   `targetType: AccessCodeTarget.lesson, targetId: 'q2w2'` returned
   `(success: true, ...)` — `redeem()`'s step 6 branch — and I additionally
   verified via `StudentRepository.getStudent` that `unlockedLessonIds` now
   contains `'q2w2'`, confirming `_unlockLessons` actually ran, not just that
   the boolean flipped.

4. **`issueQuizRetakeCode` with zero recorded attempts** — asserted (via
   `expectLater(..., throwsStateError)`) that the call throws, and then
   queried `/quizUnlockCodes` directly and confirmed `docs` is empty — no
   document was written before the throw. The eligibility check
   (`QuizAttemptService.checkEligibility`) runs and is checked for
   `attemptCount < 1` **before** any Firestore write, so this is
   structurally guaranteed, not just a lucky test.

5. **`issueQuizRetakeCode` after ≥1 attempt** — recorded one locked post-test
   attempt via the real `QuizAttemptService.recordAttempt`, then called
   `issueQuizRetakeCode`. The resulting code was redeemed via the real
   `redeem()` with `targetType: AccessCodeTarget.quiz, targetId: 'q1w1'` and
   returned `(success: true, message: 'Test unlocked for retake!')` —
   `redeem()`'s step 1 branch (`_findQuizUnlockCode` match → `unlockRetake`).
   I additionally confirmed `checkEligibility` now reports `canTake: true`
   (the lock actually flipped, not just a "success" string). A second
   `redeem()` call with the identical code then returned `(success: false,
   ...)` — the doc's `isUsed: true` update from the first redemption is
   respected by `_findQuizUnlockCode`'s `!used` filter.

6. **Duplicate custom code** — see decision below. Issued `'MYCODE1'`, then
   attempted to issue `'mycode1'` (case-insensitivity intentional, matching
   `redeem()`'s own `.toUpperCase()` normalization) again with a different
   subject list; asserted `throwsStateError`, then re-read the original doc
   at `/unlockCodes/MYCODE1` and confirmed `subjects` was still
   `['chemistry']` (i.e. the second call never overwrote the first).

## Duplicate custom-code decision

**Chosen behavior: reject with a thrown `StateError`, no write.** I did not
auto-suffix. Rationale: a teacher who types a specific memorable code (e.g.
for a printed handout) needs the code they end up handing out to be *exactly*
the code they typed — silently suffixing it (`'MYCODE1'` → `'MYCODE1X'`)
would create a code the teacher doesn't actually know, so they'd hand out a
code to a student that doesn't work. Failing loudly lets the calling UI
(Task 12) show a "that code is taken, try another" message and let the
teacher pick a new one they'll remember. This does not apply to
auto-generated codes (the random generator retries internally on collision,
capped at 10 attempts, and throws only in the astronomically unlikely case
all 10 collide).

## Existing test suite — unmodified and passing

- Ran `flutter test test/core/services/access_code_service_test.dart` in
  isolation: all 10 existing tests pass, unchanged.
- Confirmed via `git status --short lib/core/services/access_code_service.dart`
  that the file has zero uncommitted changes — I did not touch `redeem()` or
  any of its helpers.

## Full suite

- **Before this task's changes:** brief states 131/131 (not independently
  re-verified pre-change, per the brief's own baseline).
- **After this task's changes:** `flutter test` (full suite) → `00:36 +139:
  All tests passed!` — **139/139**, i.e. the pre-existing 131 plus this
  task's 8 new tests, zero regressions.

## `flutter analyze`

20 pre-existing issues (7 `invalid_annotation_target` warnings on unrelated
freezed models, 10 `prefer_initializing_formals` info hints on existing
service constructors, 2 `deprecated_member_use` info hints in an unrelated
quiz screen, 1 `unnecessary_import` info hint in an unrelated test file) —
all pre-existing, confirmed by the fact that `access_code_service.dart` and
every other pre-existing file appear in that same list already using the
same non-initializing-formal constructor pattern I followed in the new file.
My new file adds exactly 2 more `prefer_initializing_formals` **info**-level
hints (not warnings) for its own two constructor parameters — this matches
the codebase's established style (every existing service in this repo,
including `AccessCodeService` itself, uses the same
`required X y}) : _field = y` pattern rather than `this._field`). No new
`warning`-level issues were introduced.

## Schema notes / concerns for the review pass

- **`/unlockCodes` collision check scope:** per the brief's exact wording, the
  random-code generator is collision-checked only against `/unlockCodes`
  (not also against `/quizUnlockCodes`' `code` field). I implemented it
  exactly as specified. In principle a randomly generated retake code could
  theoretically collide with an unrelated `/unlockCodes` doc's code string
  (extremely unlikely at 36^6 ≈ 2.1B combinations, and `redeem()`'s quiz-path
  lookup runs *before* falling through to the `/unlockCodes` doc lookup, so a
  same-string collision wouldn't misfire during retake redemption for the
  intended student/quiz — but a different student typing that same string
  against the *other* code's intended target would). I judged this an
  acceptable, pre-existing-schema-shape risk given the brief's explicit
  scope, not something to silently expand my own judgment on.
- **`toJson()` null-field behavior:** `QuizUnlockCode.toJson()` (via
  `json_serializable`) includes `usedAt`/`expiresAt` as explicit `null` keys
  even when absent, matching the existing hand-written test fixtures in
  `access_code_service_test.dart` that omit those keys entirely. `redeem()`
  reads them with `as String?`, which tolerates both an absent key and an
  explicit `null` value identically, so this is not a compatibility issue,
  but I want to flag it explicitly since the brief's "exact schema" framing
  could otherwise cause a future reader to assume `toJson()`'s output must
  byte-for-byte match the brief's schema snippet (which omits `usedAt`/
  `expiresAt` entirely for the unused case) — it doesn't need to, and I
  verified this via the round-trip tests rather than assuming it.
- **No changes needed to `access_code_service.dart` or any Phase 2 file** —
  confirmed via `git status`.

## Status

**DONE** — no unresolved ambiguity found in `redeem()`'s behavior that the
brief didn't already anticipate; all 6 required round-trip cases pass
against the *real* `redeem()`, plus 2 additional stream-API smoke tests. See
"Schema notes / concerns" above for two minor, already-mitigated risk notes
worth a second pair of eyes during review, but neither blocks completion.
