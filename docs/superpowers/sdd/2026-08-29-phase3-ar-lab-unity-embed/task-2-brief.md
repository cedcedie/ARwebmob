# Task 2: Marker ↔ lesson mapping

> ⚠️ Reconstructed after the fact from git history + this session's own
> record of events — the literal text of the original subagent dispatch
> prompt was not preserved verbatim. What's below is a faithful summary of
> what was actually asked and done, not invented.

**Files:** `lib/core/ar/marker_mapping.dart` (new),
`test/core/ar/marker_mapping_test.dart` (new).

**Dispatched as:** implementer subagent, `generalPurpose`,
`claude-sonnet-5-thinking-medium`, in the
`worktree-phase1-scaffold-core-auth` worktree.

## Ask

Create the marker-to-lesson mapping utility Unity's marker-found bridge
message needs to resolve to a `Lesson`. Two functions:
- `markerAssetForLesson(Lesson)` — derive the marker image asset path for
  a lesson (its `arPayload.markerImage` override if set, else a
  `assets/markers/Q{quarter}W{week}.jpg` convention path).
- A lookup function resolving a Unity bridge message back to a `Lesson`.

TDD: write the test file first, then the implementation.

## First pass (superseded)

Initial pass used `int modelIndex` from `Lesson.arPayload.modelIndex` as
the lookup key (`lessonForMarkerIndex`), matching the plan's original
design. Committed as `b4d4610`.

## Fix (`594597e`)

Later discovered `modelIndex` is not unique across lessons in
`curriculum_data.dart` (e.g. Q1W1 and Q2W1 both use `modelIndex: 0`; all
Q3 lessons share `modelIndex: 8`) — unusable as a marker identity key.
Replaced with `lessonForTrackableName(orderedLessons, trackableName)`,
which extracts a `Q<n>W<n>` pattern (case-insensitive — real Unity
trackable names are inconsistently cased, e.g.
`q3w2inclined_plane_slide_playground` vs `DemocritusAtomQ1W1`) via regex
and matches on `quarter`/`week` instead. Backed by Vuforia's
`ObserverBehaviour.TargetName`, which actually is unique per marker.
`markerAssetForLesson` was unaffected by this fix.
