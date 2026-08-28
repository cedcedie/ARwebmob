# Manual Steps — Things Only You Can Do

This tracks everything the implementation needs from you directly — installs,
credentials, Unity Editor actions, and open decisions. I'll update this file
as the build progresses; treat it as a living checklist, not a one-time list.

## Before scaffolding starts

- [ ] **Confirm Q1** (PROJECT_FLOW.md Part 13): item analysis is Teacher Web
      only, not shown to students. (Default: yes, proceeding as such unless
      you say otherwise.)
- [ ] **Confirm Q2** (PROJECT_FLOW.md Part 13): PPTX support is satisfied by
      converting to slide images/PDF at teacher-upload time, not a native
      on-device PPTX renderer. (Default: yes, proceeding as such unless you
      say otherwise.)
- [ ] **Flutter SDK installed** and on PATH (`flutter doctor` should run
      clean, or close to it — Android toolchain in particular). If you
      already have it, no action needed; if you're not sure, run
      `flutter doctor` yourself and let me know what it reports.
- [ ] **Android SDK / Android Studio installed**, with at least one Android
      SDK platform + build-tools version matching what the Unity export will
      target.

## Firebase — needs your account access, I can't self-serve this

- [ ] Confirm which Firebase project is the existing one (`ar-science-explorer`
      uses one already — same project must back the new Flutter app, per
      PROJECT_FLOW.md's "no migration" requirement). Give me the Firebase
      project ID, or run `flutterfire configure` yourself once the project is
      scaffolded and pick that project when prompted.
- [ ] Either:
      - You run `flutterfire configure` (recommended — it writes the correct
        `firebase_options.dart`, `google-services.json`, etc. for you), **or**
      - You hand me the existing project's `google-services.json` (Android)
        and web Firebase config (apiKey/authDomain/etc., from the Firebase
        console → Project Settings) and I wire them in manually.
- [ ] Confirm you (or whoever owns the Firebase console) can grant Firestore
      security-rule changes if any are needed later — I can draft rule
      changes, but applying them requires console/CLI access tied to your
      account.

## Unity — Editor actions only you can perform

- [ ] Confirm the Unity Editor version used for `C:\Users\cedri\VuforiaAR`
      (Unity Hub → the project's version) so I can check
      `flutter_embed_unity`/`flutter_unity_widget` compatibility before we
      pick one.
- [ ] Confirm Android Build Support (+ Android SDK & NDK Tools, OpenJDK) is
      installed for that Unity version via Unity Hub's module list — needed
      for the Android export in Section 3 of the design spec.
- [ ] When we reach the AR-integration phase: perform the actual **Build
      Settings → Android → Export Project** step in the Unity Editor
      yourself (I can't drive the Unity Editor UI), then hand me the
      resulting `unityLibrary` folder path so I can wire it into
      `android/`.
- [x] Verify in the Unity Editor whether the existing `SampleScene.unity`
      already has all 23 markers/models set up as separate trackable
      configurations the app can switch between at runtime, or whether that
      still needs building — **Confirmed 2026-08-29: already set up and
      working, verified via a standalone APK export.** No scene-building
      work needed for Phase 3; it's an embed-and-wire job.

## Ongoing / as we go

- [ ] Any time the Unity project changes, you (or a build script we set up
      later) re-run the export → copy → rebuild sequence documented in
      `BUILD.md` (added once scaffolding starts).
- [ ] Real device or emulator for testing the Android build — Unity-as-a-
      Library embeds are known to behave differently across devices/OS
      versions; worth testing on an actual phone early, not just an emulator.
- [ ] A signing keystore for the Android build, whenever we get to a release
      (not needed for early development builds).

## Not needed from you

- Repo structure, Dart/Flutter code, the Unity C#/bridge glue code, the
  curriculum data port, quiz/access-code logic — all of that is mine to
  write.
