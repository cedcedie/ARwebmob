# Task 2 report — Marker ↔ lesson mapping

**Status:** DONE (two commits: `b4d4610` initial, `594597e` fix)

## Review findings (self-review, no separate task-reviewer subagent dispatched)

- Matches spec, all tests pass.
- **Nice-to-have, not blocking** (now tracked in
  `docs/superpowers/NICE_TO_HAVES.md`): 23 of 24 lessons in
  `curriculum_data.dart` already set an explicit `markerImage` override
  in the form `/markers/Q1W1.jpg` (root-relative, no `assets/` prefix),
  not the `assets/markers/...` scheme `markerAssetForLesson`'s fallback
  branch produces. That fallback branch is a dead path in production data
  today and nothing downstream (Task 7's `scan_tab.dart`) actually renders
  a marker image, so left as-is.

## Critical finding — bridge design bug

The plan's `int modelIndex`-based lookup design was found to be broken:
`modelIndex` is not a unique key across lessons in the real curriculum
data. This was escalated to the user (not silently patched), two options
were presented (require manual Unity Inspector edits to make `modelIndex`
unique per marker, vs. switch to Vuforia's already-unique
`ObserverBehaviour.TargetName` string), and the user picked the
trackable-name option. Fixed in `594597e`, alongside the equivalent fix
to Task 6's `ar_lab_providers.dart` (same underlying bug, both fixed in
one pass since they share the same root cause).

## Test summary

All tests in `marker_mapping_test.dart` pass both before and after the
fix (rewritten to test `lessonForTrackableName` instead of
`lessonForMarkerIndex`). Full suite green at time of commit.
