# SDD ledger — plan: docs/superpowers/plans/2026-08-29-phase3-ar-lab-unity-embed.md

## Setup

- Prior session (context/limit lost) wrote the plan file but executed nothing —
  confirmed by checking out this worktree fresh: no `ar_lab/` directory, no
  `flutter_embed_unity` dependency, `lesson_detail/` still present and
  un-retired. Resuming from Task 1, not from wherever the prior session's
  narration implied.
- Plan file copied into this worktree and committed (`85406a8`) — it had only
  been committed on `main` (docs-only), not on this worktree's branch, which
  is where all the actual app code lives (Phase 1/2 were never merged to
  `main`).
- Merged `main`'s three Phase-3-prep docs commits (`d3bd23d`, `c2ad18a`,
  `0fe6ff5` — Unity version confirmation, embed package choice, bridge
  simplification) into this worktree branch first (`531a7ce`), so the spec/
  MANUAL_STEPS.md corrections from the pre-planning session are available
  here too.
- No pre-flight conflict scan table was produced before starting (deviation
  from the skill's recommended pre-flight step) — tasks were dispatched
  sequentially task-by-task instead, and the one real conflict that existed
  (see Task 3 entry below) was caught organically during Task 3 prep, not by
  an upfront scan. Noting this gap rather than backfilling a scan after the
  fact.

## Task log

Task 1: complete (commit `36f5eaa`) — added `flutter_embed_unity ^2.0.0`,
  `flutter_embed_unity_6000_0_android ^2.0.0` (plan's guessed `^0.7.0`
  versions didn't exist on pub.dev; resolved to real latest), `flutter_tts
  ^4.2.0`. 93/93 pre-existing tests still passing after `pub get`.

Task 2: complete (commit `b4d4610`) — `markerAssetForLesson`/
  `lessonForMarkerIndex` in `lib/core/ar/marker_mapping.dart`. 99/99 passing.
  Superseded later — see Task-2/6 fix below.

Task 5: complete (commits `9a0bdc6`, `0203c00`) — `kVoiceScripts` data port +
  `VoiceOverController`. Fix-on-review: implementer's own test surfaced that
  `stop()` didn't guard against a stray TTS completion callback arriving
  after stop, which would silently resume playback — patched with an
  `if (!_isPlaying) return;` guard in `_onUtteranceComplete`, test added,
  amended into the same task (not yet reviewed/finalized at that point).
  105/105 passing after fix.

Task 3 — design bug found before implementation (blocking, resolved with
  user): the plan's bridge design has Unity send a `modelIndex` int, Flutter
  reverse-looks-up the lesson via `arPayload.modelIndex`. Real curriculum
  data (`lib/core/data/curriculum_data.dart`) has `modelIndex` NOT unique per
  lesson — q1w1/q2w1 both `0`; ALL of q3w1..q3w8 share `modelIndex: 8`. This
  would make 16/24 lessons resolve to the wrong lesson's AR content.
  Root cause: `modelIndex` was originally a "which 3D model" field, never a
  "which lesson" identifier — Unity never bridged anything lesson-identifying
  to Flutter before this phase, so nothing caught the non-uniqueness earlier.
  Found instead: Vuforia's `ObserverBehaviour.TargetName` (confirmed via
  `DefaultObserverEventHandler.cs` in the installed Vuforia package) is
  already globally unique per marker and already encodes `Q<n>W<n>` (e.g.
  `DemocritusAtomQ1W1`) — verified directly against all 23 `mTrackableName`
  entries in `SampleScene.unity`.
  **Ruling (user-approved, Option A of two presented):** switch the bridge to
  send/match on the Vuforia trackable name string instead of the int. Zero
  manual Unity Inspector work needed (vs. the original plan's per-marker
  manual `modelIndex` field, which this removes entirely) since the name is
  read via existing Vuforia API at runtime, not hand-entered.
  Cost of the rejected alternative (fix modelIndex data instead): would have
  required 23 manual Inspector edits with no test coverage to catch a
  mistake, and risked breaking modelIndex's original "which 3D model to show"
  meaning if anything else depends on it (unverified, so higher risk).

Task 2 + 6 fix: complete (commit `594597e`) — replaced
  `lessonForMarkerIndex(int)` with `lessonForTrackableName(String)` (regex
  `Q<n>W<n>` extraction, matched against `quarter`/`week`) in
  `marker_mapping.dart`; `ArLabViewModel.onMarkerFound`/`onMarkerLost` in
  `ar_lab_providers.dart` changed from `int` to `String trackableName`
  params. 109/109 passing, including a test proving the exact q3w1/q3w2
  disambiguation case that `modelIndex` could not resolve.

Task 6: complete (commit `0c2e536`, then fixed by `594597e` above) —
  `ArLabViewModel` + `buildArLabViewModel`. Implementer found `Lesson.hasAR`
  is dead data in `curriculum_data.dart` (never set `true`, even on lessons
  with populated `arPayload`) — used `arPayload != null` as the real "has
  AR" signal instead of the unused field. 108/108 passing before the Task
  2+6 fix above brought it to 109/109.

Task 3 (Unity C#): complete — edited
  `C:\Users\cedri\VuforiaAR\Assets\Scripts\ARTargetVisibilityAndInteraction.cs`
  directly (this Unity project is NOT a git repo — confirmed no `.git`
  folder — so no commit exists for this change; verified by reading the file
  back from disk after the edit). Added `using Vuforia;`, cached
  `ObserverBehaviour _observer` in `Awake()`, replaced
  `_modelInfo.DisplayInfo()/HideInfo()` calls with
  `SendToFlutter.Send("{\"event\":\"markerFound|markerLost\",\"trackableName\":\"...\"}")`
  using `_observer.TargetName`. `ModelInfo`/`UIManager`/`InteractiveLabel`
  left untouched elsewhere, per the plan's Global Constraints.
  Manual verification (Play mode / Console check) done by the user before
  this task — confirmed 0 compile errors after the `FlutterEmbed` package
  import, prior to this edit.
  **Re-verified in Play mode (2026-08-29, post-Task 10):** user entered Play
  mode, Console showed zero compile errors (only pre-existing, unrelated
  `CS0618` obsolete-API warnings in `MobileARController.cs`/
  `SetupARModel.cs`/`GenerateARUI.cs` — none in the files this task
  touched). Console also showed `SendToFlutter - {"event":"markerLost",
  "trackableName":"CellAnatomyQ2W2"}`-style log lines firing correctly for
  every trackable at startup (each with the correct real trackable name),
  confirming the edit executes correctly. These appear as plain
  `Debug.Log` lines because Editor Play mode has no real Flutter embed
  host listening — `SendToFlutter.Send()`'s Editor-mode stub logs instead
  of transmitting, which is the plugin's own expected fallback, not a
  bug. `t3_verify` closed.

Task 4 (Unity C#): complete — created
  `C:\Users\cedri\VuforiaAR\Assets\Scripts\ModelHotspotLegend.cs` (not wired
  to any GameObject/model, per the plan — scaffold only). Implementer's
  first draft used `modelIndex` to identify which model a hotspot tap
  belongs to, same bug class as the Task 3 finding above — caught and fixed
  directly (not via a subagent, small enough) to use
  `GetComponentInParent<ObserverBehaviour>().TargetName` instead, for
  consistency with the corrected Task 3 pattern. No commit (not a git repo).

Task 7: complete (commit `0a79afb`) — `ScanTab`. Confirmed real
  `flutter_embed_unity` widget API (`EmbedUnity(onMessageFromUnity: ...)`)
  against the package's own README before dispatch, matching the plan's
  assumption. Implementer verified (by actually running the test, not
  guessing) that `EmbedUnity` mounts fine in a plain widget test —
  `flutter_test`'s binding defaults to `TargetPlatform.android`, hitting the
  `AndroidView` branch, no platform-channel mock needed. 112/112 passing.

Task 8: complete (commit `8cd7b1c`) — `ReadTab`, presentation-only over
  already-tested `ArLabViewModel` logic, implemented verbatim per plan (field
  names matched exactly, no deviation needed). 114/114 passing.

Task 9: complete (commit `2e05bd1`) — `ReviewTab`, completion summary +
  real-time post-test eligibility, presentation-only over `ArLabViewModel`.
  No deviation from plan.

## Backfill note (2026-08-29, later in the session)

Per-task brief/report `.md` files for Tasks 1–9 were written retroactively
into this same folder (`task-N-brief.md`/`task-N-report.md`), reconstructed
from git history + this ledger rather than the literal original dispatch
prompts (which weren't preserved verbatim) — each file says so at the top.
This ledger and the whole `docs/superpowers/sdd/` folder were also moved
here from `.claude/worktrees/.../.superpowers/sdd/` (git-ignored scratch)
so they actually persist in git going forward. (Correction: the user clarified shortly after that subagent-driven-
development should continue as before — Task 10 onward is still
dispatched to implementer subagents, with the controller doing prep/
verification and review, same pattern as Tasks 2-9.)

Task 10: complete (commit `9a0a085`) — `ArLabScreen` (Scan/Read/Review
  `TabBarView`), `arLabOverrideFor` replacing `lessonDetailOverrideFor` in
  `student_providers.dart`, `/lesson/:lessonId` route swapped in
  `router.dart`, `LessonDetailScreen`/`LessonDetailViewModel` and their
  tests deleted (`git rm`, 317 lines removed). Both retired provider test
  cases ported to `arLabOverrideFor` rather than dropped. 115/115
  passing, `flutter analyze` 17 pre-existing issues (0 new). One
  deviation (omitted an unreferenced `arLabViewModelProviderRef` getter
  from the plan's Step 5 sample — genuinely dead code, confirmed
  unreferenced anywhere) and one opportunistic comment fix (stale
  `LessonDetailScreen` reference in a `router.dart` doc comment, renamed
  to `ArLabScreen`), both reviewed and accepted. New nice-to-have logged:
  `ArLabScreen` never disposes its `VoiceOverController` (matches the
  plan's own sample — a plan gap, not a task deviation).

Task 11 (manual Unity export + Gradle wiring + device test): in progress.
  Unity export completed by the user (Application Entry Point ->
  `Activity`, Export Project ticked, ARMv7 unchecked/ARM64-only —
  required a local patch to `flutter_embed_unity_6000_0_android`'s
  `ProjectExportChecker.cs` in `Library/PackageCache` since it hard-required
  ARMv7+ARM64 both, conflicting with Vuforia's ARM64-only requirement; see
  `NICE_TO_HAVES.md`). `android/unityLibrary/` populated.
  Gradle wiring done and committed (`310fdf3`): `include(":unityLibrary")`
  in `settings.gradle.kts`; `flatDir` repo + `implementation(project(":unityLibrary"))`
  + `androidResources`/`noCompress` block in `app/build.gradle.kts`;
  `ndkVersion`/`minSdk`/`compileSdk` bumped to match `unityLibrary/gradle.properties`'
  `unity.androidNdkVersion`/`unity.minSdkVersion`/`unity.compileSdkVersion`;
  `unityStreamingAssets` value copied into `android/gradle.properties`.
  `android:configChanges` on `MainActivity` was checked and already
  correct (no change needed — see `NICE_TO_HAVES.md`).
  First `flutter build apk --debug` hit two local-machine issues, both
  fixed and logged in `NICE_TO_HAVES.md` (both live in gitignored,
  Unity-regenerated locations — will need reapplying after any future
  re-export): a corrupted local NDK 28.2.13676358 install (deleted, let
  Gradle re-download cleanly), and Unity's exported
  `proguard-unity.txt` shipping a global `-ignorewarnings` line AGP 9.0.1
  rejects in a consumer proguard file (removed the one line). IL2CPP
  native compile itself succeeded cleanly (~24 min, arm64-v8a). Second
  build attempt (after the proguard fix) succeeded cleanly: `flutter
  build apk --debug` exit code 0, `build\app\outputs\flutter-apk\app-debug.apk`
  (846,204,844 bytes — large as expected for an unstripped debug build
  with Unity/IL2CPP bundled in). `t11`'s build half is done; on-device
  install/scan test with the user is still the one remaining step to
  fully close `t11`.
