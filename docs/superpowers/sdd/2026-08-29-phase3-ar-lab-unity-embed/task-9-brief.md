# Task 9: Review tab

> ⚠️ Reconstructed after the fact (see Task 2 brief).

**Files:** `lib/features/student/ar_lab/review_tab.dart` (new),
`test/features/student/ar_lab/review_tab_test.dart` (new).

**Dispatched as:** implementer subagent, `generalPurpose`,
`claude-sonnet-5-thinking-medium`. Committed as `2e05bd1`.

## Ask

Display a completion summary and buttons to start the post-test or go to
the Progress screen, with real-time post-test eligibility (gated on
whatever `ArLabViewModel` exposes for eligibility, adapted from the same
`LessonDetailViewModel.checkEligibility`-equivalent logic confirmed during
Task 6 prep). Presentation-only, dispatched alongside Task 8 with no
shared-state conflicts.
