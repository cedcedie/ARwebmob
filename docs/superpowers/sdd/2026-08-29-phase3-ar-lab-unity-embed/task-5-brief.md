# Task 5: Voice narration data + VoiceOverController

> ⚠️ Reconstructed after the fact (see Task 2 brief).

**Files:** `lib/core/ar/voice_scripts_data.dart` (new),
`lib/core/services/voice_over_controller.dart` (new),
`test/core/ar/voice_scripts_data_test.dart` (new),
`test/core/services/voice_over_controller_test.dart` (new).

**Dispatched as:** implementer subagent, `generalPurpose`,
`claude-sonnet-5-thinking-medium`. Committed as `9a0bdc6` (Part 6.2).

## Ask

Port hardcoded voice narration scripts (one per lesson, for the Scan tab's
"read aloud" feature) into `voice_scripts_data.dart`, and build
`VoiceOverController` as a thin wrapper around `FlutterTts` giving
play/pause/stop control with a queue of lines, backed by a fake `FlutterTts`
test double (no real TTS engine in the test environment). TDD: tests
first.

## Post-commit fix (`0203c00`, not a separate dispatch — patched directly)

Self-review after commit surfaced a real race condition: a pending
`FlutterTts` completion callback could still arrive and advance the queue
even after `stop()` had already been called, incorrectly restarting
playback. Assessed as small and low-risk enough to patch directly rather
than dispatch a fix subagent. Fix: guard `_onUtteranceComplete()` with
`if (!_isPlaying) return;` before advancing the queue index, with a
covering test added for the exact "stop() then stray callback arrives"
sequence.
