# Task 7: Scan tab (EmbedUnity + overlay)

> ⚠️ Reconstructed after the fact (see Task 2 brief).

**Files:** `lib/features/student/ar_lab/scan_tab.dart` (new),
`test/features/student/ar_lab/scan_tab_test.dart` (new).

**Dispatched as:** implementer subagent, `generalPurpose`,
`claude-sonnet-5-thinking-medium`. Committed as `0a79afb`.

## Ask

Display the `EmbedUnity` widget plus overlays: instructions when no
marker is detected, or the detected lesson's `title`/`subtitle`/
`description`/`keyIdeas` (from `ArPayload`) plus voice narration controls
when one is. Before dispatch, verified the real `flutter_embed_unity`
widget API directly from the package's pub.dev page rather than trusting
the plan's sample code given the pattern of the plan not matching reality
so far — confirmed `EmbedUnity(onMessageFromUnity: (String message) {...})`
matches the plan exactly, and that mounting a fresh `EmbedUnity` instance
per Scan-tab visit (rather than keeping one alive across tab switches) is
fine because the plugin handles reattachment itself.

Message parsing corrected at dispatch time to consume the trackable-name
JSON shape from the Task 3 fix (`{"event":"markerFound","trackableName":
"..."}`), not the plan's original `modelIndex`-based shape.

**Noted, not acted on here:** `android:configChanges` needs `orientation`
added on `MainActivity` for Unity embeds to survive rotation — a Task 11
(Gradle/manifest) concern, logged in
`docs/superpowers/NICE_TO_HAVES.md`.
