# Task 11: Manual Unity export, Android wiring, and phase checkpoint

**This task cannot be dispatched to a subagent or done by the controller
alone** — it requires the Unity Editor GUI and a physical Android device,
both only accessible to the user.

**Files (exact entries unknown until Step 2 runs — do not guess ahead of
it):** `android/settings.gradle`, `android/app/build.gradle`,
`MANUAL_STEPS.md`.

## Steps (per the plan, adjusted for what's actually still true)

1. **Confirm prerequisites:**
   - (a) `FlutterEmbed` Unity package imported — user already confirmed
     this earlier in the session (Package Manager → Add package from git
     URL, `Assets/FlutterEmbed` folder present).
   - (b) ~~All 23 markers' `modelIndex` Inspector fields set~~ — **no
     longer needed.** This was only required under the plan's original
     `modelIndex`-based bridge design, which was replaced with
     `Vuforia.ObserverBehaviour.TargetName` (Task 2/3/6 fix) specifically
     to avoid this manual per-marker step. Nothing to do here.
   - (c) Standalone APK still builds cleanly with the Task 3/4 C# edits —
     **not yet confirmed.** This is the same gap tracked as `t3_verify` in
     `progress.md`. Needs the user to enter Play mode / rebuild before
     proceeding to export.
2. User runs, in Unity Editor: `Flutter Embed → Export project to Flutter
   app` → Android → point at `ARwebmob/android/unityLibrary`. Report back
   whatever the plugin's own console says about `settings.gradle`/
   `build.gradle` entries.

   **Blocker hit and resolved:** export refused to run with "Can't export
   until you change the 'Application Entry Point' to 'Activity'." — Unity
   6's Android default is the newer `GameActivity` entry point;
   `flutter_embed_unity` needs the classic `Activity` entry point since it
   works by wrapping a native Activity Flutter can host. Fix: **File →
   Build Profiles → Player Settings → Android tab → Other Settings →
   Application Entry Point → `Activity`**, then retry export.
3. Wire Gradle files by hand only if Step 2's export didn't already do it
   — re-check `pub.dev/packages/flutter_embed_unity_6000_0_android` at
   this point for the exact required snippet, don't hardcode from the
   plan (written before Task 1 even ran `pub get`).
4. `flutter build apk --debug` or `flutter run` on a **real device**
   (Unity-as-a-Library requires this, not just an emulator, per
   `MANUAL_STEPS.md`). User tests: Learn → unlocked AR lesson → Scan tab
   camera feed → point at printed marker → description panel with real
   content → rotate/pinch-zoom → Read tab → Mark as Read → Review tab →
   Start Post-Test (if eligible).
5. `flutter test` once more — expected unchanged (no new Dart code this
   task).
6. Update `MANUAL_STEPS.md`: mark Unity export complete, record exactly
   what Gradle entries were needed (or that export handled it
   automatically).
7. Commit the checkpoint (`chore: Phase 3 complete...`).
