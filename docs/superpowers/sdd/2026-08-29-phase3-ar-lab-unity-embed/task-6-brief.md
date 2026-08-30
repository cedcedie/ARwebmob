# Task 6: ArLabViewModel

> ⚠️ Reconstructed after the fact (see Task 2 brief).

**Files:** `lib/features/student/ar_lab/ar_lab_providers.dart` (new),
`test/features/student/ar_lab/ar_lab_providers_test.dart` (new).

**Dispatched as:** implementer subagent, `generalPurpose`,
`claude-sonnet-5-thinking-medium`. Initial commit `0c2e536`, fixed in
`594597e` (same fix commit as Task 2).

## Ask

Build `ArLabViewModel` + `buildArLabViewModel`, adapted from the existing
`lesson_detail_providers.dart` (`LessonDetailViewModel`) — confirmed
before dispatch that its eligibility checks, quiz-id handling, lesson-
repository methods, and student-repository watch/save all match closely
enough to adapt almost verbatim — but as a mutable `ChangeNotifier`
instead of a plain immutable class, since the Scan tab needs live
`onMarkerFound`/`onMarkerLost` updates pushed into it as the AR camera
detects/loses markers, on top of the same eligibility-checking behavior
`LessonDetailViewModel` already has.

## Fix (`594597e`)

Same root cause as Task 2: `onMarkerFound(int modelIndex)` /
`onMarkerLost(int modelIndex)` relied on the non-unique `modelIndex` key.
Changed to `onMarkerFound(String trackableName)` /
`onMarkerLost(String trackableName)`, resolving through Task 2's new
`lessonForTrackableName`.
