# Task 6 report — ArLabViewModel

**Status:** DONE (`0c2e536` initial, 108/108 tests; `594597e` fix).

## Review findings

- **Real data-interpretation bug caught by the implementer subagent
  itself**, not by review: `Lesson.hasAR` in `curriculum_data.dart` is
  dead data — it's never actually set to `true`, even on lessons with
  real `arPayload` content. The subagent correctly worked around this by
  deriving AR-availability from `arPayload != null` instead of trusting
  `hasAR`. Judged correct and left as-is (not "fixed" at the data-model
  level — logged as a nice-to-have in
  `docs/superpowers/NICE_TO_HAVES.md` instead, since nothing requires
  `hasAR` itself to be accurate).
- **Critical, escalated to the user**: this task's `int markerIndex`
  design was directly affected by the same modelIndex-ambiguity bug
  flagged during Task 2's review. Held pending the user's decision on the
  fix (Option A: unique-`modelIndex` Inspector edits per marker, vs.
  Option B: switch to `TargetName`) rather than guessing. Fixed together
  with Task 2 in `594597e` once the user picked Option B.

## Test summary

108/108 passing at initial commit; suite re-verified green after the
trackable-name fix (tests rewritten to use `String trackableName`
throughout).
