# Nice-to-haves log

Single persistent file for minor, non-blocking findings noticed during
implementation/review across all phases. These are **context only** — not
acted on unless/until a task specifically needs them. When a future task
does end up touching one, note the resolution below (don't delete the
entry — mark it resolved so the history stays visible), and add a real
follow-up task to the relevant phase plan/ledger if code changes are
actually warranted.

Format per entry: what, where, why it doesn't matter yet, status.

---

## Phase 2 — Student core flow

*(None flagged as "nice to have" specifically during that session's
review — see `.superpowers/sdd/2026-08-28-phase2-student-core-flow/progress.md`
for the Critical/Important findings that *were* acted on in the two
post-completion fix waves. Nothing minor/deferred survived in the commit
history to backfill here.)*

## Phase 4 — Teacher Web

- **Mangled em-dash encoding (pre-existing in source) in `lesson_repository.dart`'s doc
  comments.** Noticed during Task 3's review — some existing doc comments
  in this file contained mojibake em-dash artifacts instead of proper em-dashes
  (a UTF-8-as-Windows-1252 mis-decode artifact, likely from an earlier edit/paste
  on this Windows machine). Pre-existing, not introduced by Task 3 (the new doc
  comments the Task 3 implementer added matched the same broken pattern, apparently
  copy-pasting the surrounding style without noticing). Purely cosmetic — doesn't
  affect compilation or behavior. Status: resolved — repo-wide find-and-replace
  completed across 5 affected files (13 instances in documentation and review-diff
  comments), replacing all misencoded em-dashes with proper U+2014 em-dashes.

- **Teacher Web is desktop-only by design; no responsive breakpoints.**
  Flagged in Round 5's UI/UX overhaul critique (item 8) as something that
  could otherwise read as an oversight. `TeacherShell`'s fixed-width
  `NavigationRail` and the `DataTable2`-based list screens it hosts have no
  adaptive/responsive layout for narrow viewports — intentional, since this
  surface targets a teacher on a laptop/desktop browser, matching
  `teacher_login_screen.dart`'s existing "Desktop-friendly teacher sign-in
  gate" comment. Now documented explicitly via a code comment on
  `TeacherShell`. Status: open by design — real responsive/breakpoint
  support was assessed and explicitly deferred as disproportionate scope
  for Round 5; revisit only if a real requirement for tablet/narrow-viewport
  teacher access emerges.

## Phase 3 — AR Lab / Unity embed

- **`markerImage` path scheme mismatch (dead fallback path).**
  `lib/core/ar/marker_mapping.dart`'s `markerAssetForLesson()` falls back
  to `assets/markers/Q{quarter}W{week}.jpg` when a lesson has no
  `arPayload.markerImage` override. But 23 of 24 lessons in
  `curriculum_data.dart` *do* set an explicit override, and those
  overrides use a different, root-relative scheme (`/markers/Q1W1.jpg`,
  no `assets/` prefix). If the fallback branch is ever exercised for a
  lesson that's missing an override, the resulting path likely won't
  resolve. Currently harmless because (a) it's a dead path in production
  data today, and (b) `scan_tab.dart` (Task 7) never actually renders a
  marker image at all — Unity handles marker detection, Flutter only
  shows `title`/`subtitle`/`description`/`keyIdeas` text. Status: open,
  low priority — worth a real fix (either normalize the data or the
  fallback scheme) only if something starts consuming `markerImage` for
  real, e.g. a marker-preview thumbnail somewhere.

- **`android:configChanges` on `MainActivity` needs `orientation` added.**
  Noted while reviewing Task 7 (`scan_tab.dart`)'s `EmbedUnity` widget
  usage — Unity embeds typically need the host Activity to declare
  `orientation` (and usually `screenSize`) in `configChanges` so a device
  rotation doesn't tear down/recreate the Unity view. **Status: resolved —
  already correctly wired.** Verified during Task 11's Gradle pass:
  `android/app/src/main/AndroidManifest.xml`'s `MainActivity` already has
  `android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"`
  — matches `flutter_embed_unity`'s documented recommendation exactly.
  Nothing to change.

- **`Lesson.hasAR` field is dead data.** `curriculum_data.dart` never
  actually sets `hasAR: true` on any lesson, even ones with real AR
  content (`arPayload != null`). Task 6's implementer correctly worked
  around this by deriving AR-availability from `arPayload != null`
  instead of trusting the `hasAR` field. Not fixed at the data-model level
  (i.e. `hasAR` itself is still unused/misleading in the source data).
  Status: open, cosmetic — only worth touching if something else in a
  later phase starts trusting `hasAR` directly instead of deriving from
  `arPayload`.

- **`ArLabScreen` never stops/disposes its `VoiceOverController`.**
  `_ArLabScreenState` creates a `VoiceOverController(tts: FlutterTts())` in
  `initState()` but has no `dispose()` override, so leaving the screen
  (e.g. navigating back to Learn) doesn't call `stop()` on it — if voice
  narration is mid-playback, the TTS engine may keep speaking after the
  screen is gone. Matches the plan's own sample code exactly (the plan's
  Task 10 Step 3 sample also has no `dispose()`), so not a Task 10
  implementation deviation — it's a gap in the plan itself. Status: open,
  low priority — worth a one-line fix (`@override void dispose() {
  _voiceOverController.stop(); super.dispose(); }`) whenever `ArLabScreen`
  is next touched.

- **Stale `router.dart` comment fixed opportunistically during Task 10.**
  A doc comment in the `/quiz/:lessonId/:phase` no-bank fallback path
  referenced `LessonDetailScreen's vm.hasPreTest`, which no longer exists
  after Task 10 retired that class. The Task 10 implementer updated the
  comment to say `ArLabScreen's vm.hasPreTest` instead — comment-only,
  logged here just as a record, not because anything is still open.
  Status: resolved in Task 10 (commit `9a0a085`).

- **Pre-existing Unity `CS0618` obsolete-API warnings, unrelated to Phase 3.**
  Console showed warnings in `MobileARController.cs` (`FindObjectOfType`),
  `SetupARModel.cs` (`FindObjectsByType(FindObjectsSortMode)`), and
  `GenerateARUI.cs` (`TMP_Text.enableWordWrapping`) while checking Task
  3/4's compile — all obsolete-but-still-functional Unity API usage, none
  in files this phase touched (`ARTargetVisibilityAndInteraction.cs`/
  `ModelHotspotLegend.cs` compiled with zero warnings or errors). Status:
  open, cosmetic — only worth touching if someone's doing a general Unity-
  version-upgrade cleanup pass; not a Phase 3 concern.

- **`flutter_embed_unity`'s ARMv7+ARM64 export precheck conflicts with Vuforia's ARM64-only requirement — patched locally.**
  `ProjectExportChecker.cs` (inside
  `com.learntoflutter.flutter_embed_unity_6000_0`'s package cache at
  `C:\Users\cedri\VuforiaAR\Library\PackageCache\com.learntoflutter.flutter_embed_unity_6000_0@<hash>\Editor\ProjectExportChecker.cs`)
  hard-required both `ARMv7` and `ARM64` target architecture flags before
  allowing an export. Vuforia Engine deprecated ARMv7 and throws
  `BuildFailedException` if it's enabled at all (requires ARM64-only +
  IL2CPP) — the two plugins' requirements were mutually exclusive as
  shipped. Patched the check locally to only require `ARM64` (line ~65),
  since ARM64-only + IL2CPP is the actually-correct modern config per
  Vuforia's own docs, not a workaround that sacrifices anything.
  **Caveat:** this lives in `Library/PackageCache`, a local Unity build
  cache — **not git-tracked**, and will be wiped/re-fetched fresh
  (re-introducing the bug) if the package is ever reinstalled, the
  `Library` folder deleted, or "Reset Packages to defaults" is run. If the
  ARMv7 error resurfaces, reapply: in `PreCheckAndroid()`, change
  `if (!architectures.HasFlag(AndroidArchitecture.ARMv7) || !architectures.HasFlag(AndroidArchitecture.ARM64))`
  to `if (!architectures.HasFlag(AndroidArchitecture.ARM64))` (and update
  the error message to drop the ARMv7 mention). Status: resolved for this
  machine/session, open risk of recurrence noted.

- **`unityLibrary/proguard-unity.txt`'s `-ignorewarnings` line breaks AGP
  9's consumer-proguard-file validation — patched locally.** After the
  first successful `flutter build apk --debug` compiled IL2CPP (~24 min,
  Task 11), the build failed at `:unityLibrary:mergeDebugConsumerProguardFiles`
  with `Global keep option -ignorewarnings was specified as a
  consumerProguardFile... It should not be used in a consumer
  configuration file.` Unity's own export always emits this line in
  `proguard-unity.txt`, and AGP 9.0.1 (this project's version, `android/settings.gradle.kts`)
  enforces the restriction strictly — AGP 8.x reportedly only warned.
  Removed the single `-ignorewarnings` line (the `-dontwarn ...` lines
  immediately below it are unaffected — those are fine in a consumer
  file, only the global `-ignorewarnings` option isn't).
  **Caveat:** same category as the ARMv7 patch above — `android/unityLibrary/`
  is gitignored and fully regenerated by every `Flutter Embed -> Export
  project to Flutter app` run, so this one-line removal must be reapplied
  after every future re-export if the build starts failing on this same
  error again. Status: resolved for this machine/session, open risk of
  recurrence noted.

---

## How to use this file going forward

- When a task/review turns up something minor that isn't worth stopping
  to fix (wrong but harmless, inconsistent-but-unused, stylistic, "would
  be nice but not required by the spec"), add an entry here under the
  current phase's heading. No code changes needed just for logging it.
- When a later task's brief happens to touch the same area and it makes
  sense to actually fix it, do the fix as part of that task's normal
  work, then come back and mark the entry `Status: resolved in Task N
  (commit <hash>)` instead of deleting it.
- Keep this the *only* file for this purpose — don't create per-phase or
  per-task nice-to-have files.
