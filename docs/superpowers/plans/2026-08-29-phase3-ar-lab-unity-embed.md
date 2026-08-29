# Phase 3: AR Lab / Unity Embed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Embed the existing, working Unity/Vuforia project into the Flutter
app via `flutter_embed_unity`, and build the real three-phase Scan/Read/Review
lesson screen (PROJECT_FLOW.md Part 6.2) that replaces Phase 2's temporary
"Mark as Read" stand-in (`LessonDetailScreen`). Unity owns camera, marker
tracking, and 3D rendering only; Flutter owns every piece of on-screen text
and chrome, reacting to a minimal `markerFound`/`markerLost` signal from
Unity.

**Architecture:** A `SendToFlutter.Send(...)` call added to the existing
Unity C# scripts replaces Unity's own now-unwired description-panel UI
(`UIManager`/`InteractiveLabel`). The Dart side mounts a fresh `EmbedUnity`
widget per Scan-tab visit — the plugin handles single-instance
detach/reattach itself, no hand-rolled global bridge singleton is needed.
Scanning is unrestricted (all 23 markers are already simultaneously active in
the Unity scene, confirmed by direct inspection): Flutter reacts to whichever
marker index Unity reports, looked up against the full curriculum, not
gated to "only this lesson's marker." Progress/eligibility logic reuses
Phase 2's `QuizAttemptService`/`StudentRepository`/`AccessCodeService`
unchanged — this phase adds no new business rules, only the AR presentation
layer and the screen that replaces the stand-in.

**Tech Stack:** `flutter_embed_unity` + `flutter_embed_unity_6000_0_android`
(Unity 6000.4.0f1, confirmed), `flutter_tts` (voice narration), Unity C#
(existing `VuforiaAR` project at `C:\Users\cedri\VuforiaAR`, external to this
repo). Everything from Phase 1/2 (Riverpod, go_router, freezed models,
`fake_cloud_firestore`) continues unchanged.

**Spec:** `PROJECT_FLOW.md` Part 6 (all subsections); design spec
`docs/superpowers/specs/2026-08-28-flutter-ar-science-explorer-design.md`
Sections 2–4 (updated 2026-08-29 with this phase's resolved decisions — read
the resolved-decisions table there before starting, it has the exact
`flutter_embed_unity` API names and the real Unity export mechanism). This
plan does not restate their content, only implements it.

## Global Constraints

- **Bridge is one-directional: Unity → Flutter only.** No `loadMarker` or any
  other Flutter → Unity call exists in this plan. All 23 markers are already
  simultaneously trackable in the Unity scene (confirmed by direct
  inspection of `SampleScene.unity` — 23 `ImageTargetBehaviour` references,
  only 1 inactive GameObject in the whole scene). A student scanning a
  different lesson's marker sheet sees *that marker's* real content — this
  is the confirmed, intentional behavior (2026-08-29 decision), not a bug to
  fix.
- **Unity's own description-panel UI (`UIManager`/`InteractiveLabel`) is
  unwired, not deleted.** `ARTargetVisibilityAndInteraction.cs`'s
  `HandleTargetFound`/`HandleTargetLost` call `SendToFlutter.Send(...)`
  instead of `_modelInfo.DisplayInfo()/HideInfo()`. Do not remove
  `UIManager.cs`/`InteractiveLabel.cs`/`ModelInfo.cs` from the Unity
  project — other scene references may exist; leave them in place with a
  comment noting they're superseded.
- **Rotate/zoom (`MobileARController.cs`) is untouched.** Already correct,
  entirely Unity-internal (resolved Q7, PROJECT_FLOW.md Part 6.3). Nothing
  in this plan modifies that file.
- **Marker → lesson mapping is always derived, never hardcoded per-lesson**:
  `Q{quarter}W{week}` from the lesson's own `quarter`/`week` fields
  (PROJECT_FLOW.md Part 6.1). `Lesson.arPayload?.markerImage` overrides the
  derived path when explicitly set; otherwise derive it.
- **Q1W5 has no AR** (`hasAR: false`, no `arPayload`, per Task 1 of Phase 2's
  curriculum port) — the only such lesson among the 24. The Scan tab must
  degrade gracefully for it (Global Constraint checked in Task 6), not crash
  or show an empty camera view with no explanation.
- **`flutter_embed_unity`'s Unity-side setup is a prerequisite, not something
  this plan's tasks perform.** Before Task 3 (the C# bridge edit) can be
  implemented, you (the user) must import the `FlutterEmbed` Unity package
  into `C:\Users\cedri\VuforiaAR` — Package Manager → Add package from git
  URL →
  `https://github.com/learntoflutter/flutter_embed_unity.git?path=example_unity_6000_0_project/Assets/FlutterEmbed`
  (the `6000_0` path, matching the confirmed Unity 6000.4.0f1). This is
  tracked in `MANUAL_STEPS.md`. **Confirm with the user this is done before
  dispatching Task 3** — the C# code in that task calls `SendToFlutter.Send`,
  a class the package provides; without it, the Unity project won't compile.
- **The physical Unity export (`Flutter Embed → Export project to Flutter
  app` menu item) and the resulting `android/unityLibrary` Gradle wiring are
  Task 11's manual steps** — everything before that is testable via
  `flutter test` alone (fakes/mocks for the bridge, same pattern as Phase
  1/2's `fake_cloud_firestore`), no physical Android build required until
  then.
- All new Firestore-touching classes take their dependency as a constructor
  parameter (Phase 1/2's established pattern) so tests inject fakes.
- Visual design is free to redesign (PROJECT_FLOW.md Part 12) as long as
  every documented requirement (readable text sizes, description visible
  concurrently with the model, rotate/zoom, autoplay animations, voice
  narration) is met — see Part 6.3's exact list, not restated here.

---

## File Structure

```
Unity project (C:\Users\cedri\VuforiaAR\Assets\Scripts\ — external to this repo):
  ARTargetVisibilityAndInteraction.cs   # MODIFIED — sends SendToFlutter.Send(...)
                                         # instead of calling UIManager/InteractiveLabel
  ModelHotspotLegend.cs                 # NEW — generic multi-part-model hotspot/legend
                                         # mechanism, wired to zero models this phase

lib/
  core/
    ar/
      marker_mapping.dart              # markerIndexForLesson / lessonForMarkerIndex
      voice_scripts_data.dart          # ported voiceScripts.ts (onboarding + q1w1-q1w5)
    services/
      voice_over_controller.dart       # flutter_tts wrapper: play/replay/stop, EN/Filipino
  features/
    student/
      ar_lab/
        ar_lab_providers.dart          # ArLabViewModel + buildArLabViewModel (replaces
                                        # lesson_detail_providers.dart's role)
        ar_lab_screen.dart             # 3-tab Scaffold: Scan / Read / Review
        scan_tab.dart                  # EmbedUnity + Stack overlay (instructions,
                                        # description panel, voice controls)
        read_tab.dart                  # curriculum content + Mark Complete
        review_tab.dart                # completion summary + Start Post-Test / Go to Progress
      lesson_detail/                    # RETIRED this phase — see Task 10
        (lesson_detail_providers.dart, lesson_detail_screen.dart deleted)
      app/
        router.dart                    # MODIFIED — /lesson/:lessonId now builds ArLabScreen
        student_providers.dart         # MODIFIED — lessonDetailOverrideFor replaced by
                                        # arLabOverrideFor
test/
  core/
    ar/
      marker_mapping_test.dart
      voice_scripts_data_test.dart
    services/
      voice_over_controller_test.dart
  features/
    student/
      ar_lab/
        ar_lab_providers_test.dart
        scan_tab_test.dart
        ar_lab_screen_test.dart
```

---

### Task 1: Flutter dependencies for AR + voice

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:**
- Produces: `flutter_embed_unity`, `flutter_embed_unity_6000_0_android`,
  `flutter_tts` available as imports for every later task in this plan.

- [ ] **Step 1: Add dependencies**

Edit `pubspec.yaml`, add under `dependencies:`:
```yaml
  flutter_embed_unity: ^0.7.0
  flutter_embed_unity_6000_0_android: ^0.7.0
  flutter_tts: ^4.2.0
```
(Bump to the latest mutually-compatible versions if `flutter pub outdated`
shows conflicts — same policy as every prior phase's Task 1.)

- [ ] **Step 2: Fetch dependencies**

Run: `flutter pub get`
Expected: resolves cleanly.

- [ ] **Step 3: Run the full suite to confirm nothing broke**

Run: `flutter test`
Expected: all existing tests still pass (this task adds no new test —
adding a dependency with no code using it yet is not independently
testable; the next task is where real code appears).

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add flutter_embed_unity and flutter_tts dependencies"
```

---

### Task 2: Marker ↔ lesson mapping

**Files:**
- Create: `lib/core/ar/marker_mapping.dart`
- Test: `test/core/ar/marker_mapping_test.dart`

**Interfaces:**
- Consumes: `Lesson`, `kBuiltInLessons` (Phase 2 Task 1).
- Produces: `String markerAssetForLesson(Lesson lesson)` — the `.jpg` path
  under `assets/markers/`, derived `Q{quarter}W{week}.jpg` unless
  `lesson.arPayload?.markerImage` overrides it. `Lesson? lessonForMarkerIndex(List<Lesson> orderedLessons, int markerIndex)`
  — the reverse lookup Unity's `markerFound(markerIndex)` message needs, where
  `markerIndex` is each lesson's `arPayload!.modelIndex` (already a field on
  the Phase 1 `ARPayload` model, already populated per-lesson in Phase 2's
  curriculum port — e.g. Q1W1's is `0`). Consumed by Task 6's view model.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/ar/marker_mapping_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/ar/marker_mapping.dart';
import 'package:ar_science_explorer/core/data/curriculum_data.dart';

void main() {
  group('markerAssetForLesson', () {
    test('derives Q{quarter}W{week}.jpg when no explicit override', () {
      final q1w1 = kBuiltInLessons.firstWhere((l) => l.id == 'q1w1');
      expect(markerAssetForLesson(q1w1), 'assets/markers/Q1W1.jpg');
    });

    test('derives correctly for double-digit-safe week numbers', () {
      final q3w8 = kBuiltInLessons.firstWhere((l) => l.id == 'q3w8');
      expect(markerAssetForLesson(q3w8), 'assets/markers/Q3W8.jpg');
    });
  });

  group('lessonForMarkerIndex', () {
    test('finds the lesson whose arPayload.modelIndex matches', () {
      final q1w1 = kBuiltInLessons.firstWhere((l) => l.id == 'q1w1');
      final found = lessonForMarkerIndex(kBuiltInLessons, q1w1.arPayload!.modelIndex);
      expect(found?.id, 'q1w1');
    });

    test('returns null for an index no lesson uses', () {
      final found = lessonForMarkerIndex(kBuiltInLessons, 9999);
      expect(found, isNull);
    });

    test('Q1W5 has no arPayload and is correctly excluded from the index map', () {
      final q1w5 = kBuiltInLessons.firstWhere((l) => l.id == 'q1w5');
      expect(q1w5.arPayload, isNull);
      expect(q1w5.hasAR, false);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/ar/marker_mapping_test.dart`
Expected: FAIL — `lib/core/ar/marker_mapping.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/core/ar/marker_mapping.dart
import '../models/lesson.dart';

/// The reference marker image path for a lesson — PROJECT_FLOW.md Part 6.1:
/// derive `Q{quarter}W{week}.jpg` from the lesson's own quarter/week fields;
/// `arPayload.markerImage` overrides when explicitly set.
String markerAssetForLesson(Lesson lesson) {
  final override = lesson.arPayload?.markerImage;
  if (override != null) return override;
  final key = 'Q${lesson.quarter}W${lesson.week}';
  return 'assets/markers/$key.jpg';
}

/// Reverse lookup for Unity's `markerFound(markerIndex)` bridge message —
/// which lesson (if any) uses this `modelIndex`. Q1W5 (no AR) has no
/// `arPayload` and is correctly never matched by any index.
Lesson? lessonForMarkerIndex(List<Lesson> orderedLessons, int markerIndex) {
  for (final lesson in orderedLessons) {
    if (lesson.arPayload?.modelIndex == markerIndex) return lesson;
  }
  return null;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/ar/marker_mapping_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/ar/marker_mapping.dart test/core/ar/marker_mapping_test.dart
git commit -m "feat: marker-to-lesson mapping (Part 6.1)"
```

---

### Task 3: Unity — bridge the marker found/lost signal to Flutter

**Files (external Unity project — `C:\Users\cedri\VuforiaAR\Assets\Scripts\`):**
- Modify: `ARTargetVisibilityAndInteraction.cs`

**Interfaces:**
- Consumes: `SendToFlutter.Send(string)` — provided by the `FlutterEmbed`
  Unity package (a prerequisite manual step, see Global Constraints; confirm
  with the user it's imported before starting this task).
- Produces: a JSON string sent to Flutter on every marker found/lost event,
  of the shape `{"event":"markerFound","modelIndex":<int>}` /
  `{"event":"markerLost","modelIndex":<int>}` — consumed by Task 6's
  `onMessageFromUnity` handler. `modelIndex` comes from a new
  `[SerializeField] private int modelIndex` field on this component, set per
  `ImageTargetBehaviour` in the Inspector to match that marker's
  `ARPayload.modelIndex` (the same integers already in
  `kBuiltInLessons`/Phase 2's curriculum port — e.g. Q1W1 is `0`). Setting
  these 23 Inspector values is a manual step (tracked below), since I can't
  drive the Unity Editor's Inspector UI.

**⚠️ Before starting this task:** confirm with the user that the
`FlutterEmbed` Unity package has been imported into
`C:\Users\cedri\VuforiaAR` (Global Constraints, above) — the code below
references `SendToFlutter`, a class that package provides. If it's not
confirmed, stop and ask before editing.

- [ ] **Step 1: Add the `modelIndex` field and JSON send calls**

```csharp
// C:\Users\cedri\VuforiaAR\Assets\Scripts\ARTargetVisibilityAndInteraction.cs
using UnityEngine;

public class ARTargetVisibilityAndInteraction : MonoBehaviour
{
    [Header("Assign model root under this ImageTarget")]
    public GameObject modelRoot;

    // Set in the Inspector per marker to match this lesson's
    // ARPayload.modelIndex (Flutter's core/data/curriculum_data.dart) — e.g.
    // 0 for Q1W1's Democritus Atom marker. This is what Flutter's
    // lessonForMarkerIndex() (lib/core/ar/marker_mapping.dart) looks up.
    [Header("Bridge — must match this lesson's ARPayload.modelIndex in Flutter")]
    [SerializeField] private int modelIndex;

    private MobileARController _gesture;
    private ModelInfo _modelInfo;

    private void Awake()
    {
        if (modelRoot == null)
        {
            return;
        }

        _gesture = modelRoot.GetComponent<MobileARController>();
        _modelInfo = modelRoot.GetComponent<ModelInfo>();
        modelRoot.SetActive(false);

        if (_gesture != null)
        {
            _gesture.enabled = false;
        }
    }

    // Hook this in DefaultObserverEventHandler -> OnTargetFound
    public void HandleTargetFound()
    {
        if (modelRoot == null)
        {
            return;
        }

        modelRoot.SetActive(true);

        if (_gesture == null)
        {
            _gesture = modelRoot.GetComponent<MobileARController>();
        }

        if (_modelInfo == null)
        {
            _modelInfo = modelRoot.GetComponent<ModelInfo>();
        }

        if (_gesture != null)
        {
            _gesture.enabled = true;
            _gesture.ResetState();
        }

        // Restart particle systems
        foreach (var ps in modelRoot.GetComponentsInChildren<ParticleSystem>(true))
        {
            ps.Play();
        }

        // Restart animators
        foreach (var anim in modelRoot.GetComponentsInChildren<Animator>(true))
        {
            anim.enabled = true;
            anim.Rebind();
            anim.Play(0, -1, 0f); // Force play from beginning
            anim.Update(0f);
        }

        // Flutter owns the description panel now (PROJECT_FLOW.md Part 6.0)
        // — UIManager/InteractiveLabel are superseded, left unwired below.
        SendToFlutter.Send("{\"event\":\"markerFound\",\"modelIndex\":" + modelIndex + "}");
    }

    // Hook this in DefaultObserverEventHandler -> OnTargetLost
    public void HandleTargetLost()
    {
        if (modelRoot == null)
        {
            return;
        }

        if (_gesture == null)
        {
            _gesture = modelRoot.GetComponent<MobileARController>();
        }

        if (_modelInfo == null)
        {
            _modelInfo = modelRoot.GetComponent<ModelInfo>();
        }

        if (_gesture != null)
        {
            _gesture.enabled = false;
        }

        // Stop particle systems
        foreach (var ps in modelRoot.GetComponentsInChildren<ParticleSystem>(true))
        {
            ps.Stop();
        }

        // Disable animators
        foreach (var anim in modelRoot.GetComponentsInChildren<Animator>(true))
        {
            anim.enabled = false;
        }

        modelRoot.SetActive(false);

        // Superseded by the Flutter bridge (see HandleTargetFound above) —
        // _modelInfo.HideInfo() no longer called; UIManager/InteractiveLabel
        // are dead code, left in place, not deleted.
        SendToFlutter.Send("{\"event\":\"markerLost\",\"modelIndex\":" + modelIndex + "}");
    }
}
```

- [ ] **Step 2: Manual step — set `modelIndex` per marker in the Unity Inspector**

Tell the user: for each of the 23 `ARTargetVisibilityAndInteraction`
components in `SampleScene.unity` (one per `ImageTargetBehaviour`), set the
new `Model Index` Inspector field to match that marker's lesson's
`ARPayload.modelIndex` from `lib/core/data/curriculum_data.dart` (e.g. Q1W1
→ `0`). This is a one-time Unity Editor task — I can't drive the Inspector
UI. Provide the user the full Q{quarter}W{week} → `modelIndex` table pulled
from `curriculum_data.dart` so they can fill it in without cross-referencing
files themselves.

- [ ] **Step 3: Verify in Unity Editor (manual, by the user)**

Ask the user to enter Play mode in the Unity Editor (or run the standalone
APK build they already confirmed works) and confirm no compile errors, and
that `HandleTargetFound`/`HandleTargetLost` still visually work (model
appears/disappears, animations play) — this task's C# has no automated test
harness available in this project; verification is manual, by design (see
this plan's Global Constraints on the Unity export/testing boundary).

- [ ] **Step 4: Commit (Unity project — outside this Flutter repo's git history)**

This Unity project may or may not have its own git history — if it does,
commit there with a message like `feat: bridge marker found/lost to Flutter via SendToFlutter`.
If it doesn't, no commit action is needed; the change is simply saved in the
Unity project's Assets folder.

---

### Task 4: Unity — generic multi-part-model hotspot/legend mechanism (scaffold only)

**Files (external Unity project):**
- Create: `C:\Users\cedri\VuforiaAR\Assets\Scripts\ModelHotspotLegend.cs`

**Interfaces:**
- Produces: a reusable `MonoBehaviour` component that any model's root
  GameObject can carry, defining named hotspot points with labels; when a
  hotspot is tapped, it sends a bridge message the same way Task 3 does.
  **Not wired to any of the 23 models this phase** (2026-08-29 decision) —
  this task only builds the capability for future use.

- [ ] **Step 1: Implement the generic component**

```csharp
// C:\Users\cedri\VuforiaAR\Assets\Scripts\ModelHotspotLegend.cs
using System;
using UnityEngine;

/// Generic tappable-hotspot legend for a multi-part model (PROJECT_FLOW.md
/// Part 6.3 — "complex multi-part models need an in-app guide", client's
/// example: a heart model). Not wired to any model yet (2026-08-29 decision)
/// — attach this component and populate `hotspots` on a per-model basis
/// once a specific model is flagged as needing it.
public class ModelHotspotLegend : MonoBehaviour
{
    [Serializable]
    public class Hotspot
    {
        public string partName;      // e.g. "Left Ventricle"
        public string label;         // short label shown in the legend
        public Transform anchor;     // where on the model this hotspot sits
        public Collider tapCollider; // what registers the tap
    }

    [SerializeField] private Hotspot[] hotspots = Array.Empty<Hotspot>();
    [SerializeField] private int modelIndex; // matches this model's ARPayload.modelIndex

    private void OnMouseDown()
    {
        // Placeholder tap entry point for editor/desktop testing; real touch
        // input on Android goes through each hotspot's own collider — see
        // HandleHotspotTap below, called by a per-collider trigger script
        // once specific hotspot colliders are wired for a flagged model.
    }

    public void HandleHotspotTap(string partName)
    {
        foreach (var hotspot in hotspots)
        {
            if (hotspot.partName == partName)
            {
                SendToFlutter.Send(
                    "{\"event\":\"hotspotTapped\",\"modelIndex\":" + modelIndex +
                    ",\"partName\":\"" + hotspot.partName + "\"" +
                    ",\"label\":\"" + hotspot.label + "\"}"
                );
                return;
            }
        }
    }
}
```

- [ ] **Step 2: Verify it compiles (manual, by the user)**

Ask the user to confirm the Unity Editor shows no compile errors after
adding this file — it's not attached to any GameObject in the scene yet, so
there's nothing to functionally test beyond compilation.

- [ ] **Step 3: Commit (Unity project)**

Same note as Task 3 Step 4 — commit in the Unity project's own history if it
has one.

---

### Task 5: Voice narration — script data + `VoiceOverController`

**Files:**
- Create: `lib/core/ar/voice_scripts_data.dart`
- Create: `lib/core/services/voice_over_controller.dart`
- Test: `test/core/ar/voice_scripts_data_test.dart`
- Test: `test/core/services/voice_over_controller_test.dart`

**Interfaces:**
- Produces: `const Map<String, Map<String, List<String>>> kVoiceScripts` —
  keyed `'onboarding'` or a lesson id (`'q1w1'`..`'q1w5'`, the only 5 with
  content), then by language (`'en'`/`'Filipino'`), then the ordered list of
  narration lines. `class VoiceOverController` with constructor
  `VoiceOverController({required FlutterTts tts})`, methods
  `Future<void> playAll(List<String> lines, String language)`,
  `Future<void> replay()`, `Future<void> stop()`, getter `bool get isPlaying`.
  Consumed by Task 7 (Scan tab).

- [ ] **Step 1: Write the failing data test**

```dart
// test/core/ar/voice_scripts_data_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/ar/voice_scripts_data.dart';

void main() {
  test('onboarding script has both languages with matching line counts', () {
    final en = kVoiceScripts['onboarding']!['en']!;
    final fil = kVoiceScripts['onboarding']!['Filipino']!;
    expect(en, hasLength(6));
    expect(fil, hasLength(6));
    expect(en.first, contains('AR Science Explorer'));
  });

  test('only q1w1 through q1w5 have lesson narration scripts', () {
    final lessonKeys = kVoiceScripts.keys.where((k) => k != 'onboarding').toSet();
    expect(lessonKeys, {'q1w1', 'q1w2', 'q1w3', 'q1w4', 'q1w5'});
  });

  test('q1w1 script matches the real source content verbatim', () {
    final lines = kVoiceScripts['q1w1']!['en']!;
    expect(lines, hasLength(3));
    expect(
      lines.first,
      "Scientists use models to explain things too small to see directly. "
      "Let's explore how the particle model helps us understand matter.",
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/ar/voice_scripts_data_test.dart`
Expected: FAIL — file doesn't exist yet.

- [ ] **Step 3: Port the data verbatim**

Source: `src/data/voiceScripts.ts` in the retired
`C:\Users\cedri\OneDrive\Documents\GitHub\AR\ar-science-explorer` repo (83
lines total — small enough to transcribe directly here, unlike Phase 2's
curriculum port).

```dart
// lib/core/ar/voice_scripts_data.dart
//
// Ported verbatim from the retired ar-science-explorer web app's
// src/data/voiceScripts.ts. Only 5 lessons (q1w1-q1w5) plus onboarding have
// written narration content — do not invent scripts for other lessons.

const Map<String, Map<String, List<String>>> kVoiceScripts = {
  'onboarding': {
    'en': [
      'Welcome to AR Science Explorer. This app will help you learn science through augmented reality.',
      'Use the AR camera to scan colored objects and see 3D models of scientific concepts.',
      'You can rotate, zoom, and interact with the models to understand better.',
      'Complete tests to unlock new subjects and check your knowledge.',
      'Conduct virtual experiments in the lab section.',
      'Try out the AR camera now by pointing it at any colored surface.',
    ],
    'Filipino': [
      'Maligayang pagdating sa AR Science Explorer. Ang app na ito ay tutulong sa iyo na matuto ng agham sa pamamagitan ng augmented reality.',
      'Gamitin ang AR camera upang i-scan ang mga kulay na bagay at makita ang 3D na mga modelo ng mga konsepto sa agham.',
      'Maaari mong i-rotate, i-zoom, at makipag-ugnayan sa mga modelo upang mas maunawaan nang mabuti.',
      'Kumpletuhin ang mga pagsusulit upang i-unlock ang mga bagong paksa at subukan ang iyong kaalaman.',
      'Magsagawa ng mga virtual na eksperimento sa lab section.',
      'Subukan ang AR camera ngayon sa pamamagitan ng pagtutok nito sa anumang makulay na ibabaw.',
    ],
  },
  'q1w1': {
    'en': [
      'Scientists use models to explain things too small to see directly. Let\'s explore how the particle model helps us understand matter.',
      'The Particle Model of Matter states that all matter is made up of tiny particles. Each pure substance has its own unique particles.',
      'In solids, particles are tightly packed and vibrate in place. In liquids, they move freely but stay close. In gases, they spread far apart.',
    ],
    'Filipino': [
      'Gumagamit ang mga siyentipiko ng mga modelo upang ipaliwanag ang mga bagay na masyadong maliit upang makita nang direkta. Tuklasin natin kung paano nakakatulong ang particle model sa atin na maunawaan ang materia.',
      'Ang Particle Model of Matter ay nagsasaad na ang lahat ng materia ay binubuo ng mga miligang maliliit na partikula. Bawat purong sangkap ay may sariling natatanging mga partikula.',
      'Sa mga solido, ang mga partikula ay mahigpit na nakabalot at gumagalaw sa lugar. Sa mga likido, sila ay kumakalat nang malaya ngunit manatiling malapit. Sa mga gas, sila ay kumalat nang malayo.',
    ],
  },
  'q1w2': {
    'en': [
      'A pure substance contains only one type of particle. Elements are pure substances made of one type of atom, while compounds have two or more.',
      'The Kinetic Molecular Theory explains that particles are always in constant, random motion. The warmer the substance, the faster the particles move.',
      'Temperature directly affects particle motion. When you heat a substance, the particles move faster and take up more space, causing expansion.',
    ],
    'Filipino': [
      'Ang isang purong sangkap ay naglalaman lamang ng isang uri ng partikula. Ang mga elemento ay mga purong sangkap na gawa sa isang uri ng atomo, habang ang mga compound ay may dalawa o higit pa.',
      'Ang Kinetic Molecular Theory ay nagpapaliwanag na ang mga partikula ay palaging nasa patuloy na, random na paggalaw. Mas mainit ang sangkap, mas mabilis na gumagalaw ang mga partikula.',
      'Ang temperatura ay direktang nakakaapekto sa paggalaw ng partikula. Kapag pinainit mo ang isang sangkap, ang mga partikula ay gumagalaw nang mas mabilis at sumasaklaw ng mas maraming espasyo.',
    ],
  },
  'q1w3': {
    'en': [
      'Let\'s examine how particles are arranged differently in solids, liquids, and gases. Understanding particle arrangement helps explain the properties of each state.',
      'In the solid state, particles vibrate but stay in fixed positions creating a rigid structure. Liquids have particles that can flow freely while maintaining close contact.',
      'Gas particles have the most freedom. They move rapidly in all directions, spreading far apart to fill any container. Changes of state involve rearranging these particles.',
    ],
    'Filipino': [
      'Tingnan natin kung paano ang mga partikula ay inayos nang iba sa mga solido, likido, at gas. Ang pag-unawa sa arrangement ng partikula ay tumutulong na ipaliwanag ang mga katangian ng bawat estado.',
      'Sa solid state, ang mga partikula ay gumagalaw ngunit manatiling nasa nakatatag na mga posisyon na lumilikha ng matatag na istraktura. Ang mga likido ay may mga partikula na maaaring lumabas nang malaya habang pinapanatili ang malapit na kontak.',
      'Ang gas particles ay may pinakamaraming kalayaan. Sila ay mabilis na gumagalaw sa lahat ng direksyon, kumalat nang malayo upang mapuno ang anumang lalagyan. Ang mga pagbabago ng estado ay nagsasangkot ng pag-aayos ng mga partikula na ito.',
    ],
  },
  'q1w4': {
    'en': [
      'A scientific investigation starts with identifying the aim or problem you want to solve. This guides the entire experiment and helps you stay focused.',
      'Next, list all the materials and equipment you\'ll need. Being thorough ensures you have everything required before beginning the experiment.',
      'Finally, outline your procedures step by step. Clear instructions allow others to replicate your experiment and verify your results independently.',
    ],
    'Filipino': [
      'Ang isang scientific investigation ay nagsisimula sa pagkilala sa layunin o problema na nais mong malutas. Ito ay gumagabay sa buong eksperimento at tumutulong sa iyo na manatiling nakatuon.',
      'Susunod, listahan ang lahat ng mga materyales at kagamitan na kailangan mo. Ang pagiging komprehensibo ay nagsisiguro na mayroon kang lahat ng kinakailangan bago magsimula ng eksperimento.',
      'Sa wakas, balangkasin ang iyong mga pamamaraan nang hakbang-hakbang. Ang mga malinaw na tagubilin ay nagpapahintulot sa iba na ulitin ang iyong eksperimento at i-verify ang iyong mga resulta nang independyente.',
    ],
  },
  'q1w5': {
    'en': [
      'In any experiment, the independent variable is what you deliberately change or manipulate. This is the factor you\'re testing to see its effect.',
      'The dependent variable is what you measure or observe. It "depends" on the independent variable. This is where you collect your data.',
      'Controlled variables are factors you keep constant. By controlling these, you ensure that any changes in the dependent variable are due solely to your independent variable.',
    ],
    'Filipino': [
      'Sa anumang eksperimento, ang independent variable ay kung ano ang layunin mong baguhin o i-manipulate. Ito ang salik na sinusubukan mo upang makita ang epekto nito.',
      'Ang dependent variable ay kung ano ang sinusukat o sinusundan mo. Ito ay "nakadepende" sa independent variable. Dito mo kinokolekta ang iyong datos.',
      'Ang mga controlled variables ay mga salik na pinapanatili mong pare-pareho. Sa pamamagitan ng pagkontrol sa mga ito, tinitiyak mo na ang anumang pagbabago sa dependent variable ay dahil lamang sa iyong independent variable.',
    ],
  },
};
```

- [ ] **Step 4: Run the data test to verify it passes**

Run: `flutter test test/core/ar/voice_scripts_data_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Write the failing `VoiceOverController` test**

```dart
// test/core/services/voice_over_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ar_science_explorer/core/services/voice_over_controller.dart';

class _FakeFlutterTts implements FlutterTts {
  final List<String> spoken = [];
  bool stopped = false;
  String? lastLanguage;

  @override
  Future<dynamic> speak(String text) async {
    spoken.add(text);
    return 1;
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    lastLanguage = language;
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    stopped = true;
    return 1;
  }

  @override
  void setCompletionHandler(void Function() handler) {
    _onComplete = handler;
  }

  void Function()? _onComplete;

  /// Test helper: simulate the platform reporting one utterance finished.
  void completeCurrentUtterance() => _onComplete?.call();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('playAll speaks each line in order, setting the language once', () async {
    final fakeTts = _FakeFlutterTts();
    final controller = VoiceOverController(tts: fakeTts);

    final future = controller.playAll(['Line one.', 'Line two.'], 'en');
    // Simulate each utterance completing to advance the queue.
    fakeTts.completeCurrentUtterance();
    fakeTts.completeCurrentUtterance();
    await future;

    expect(fakeTts.spoken, ['Line one.', 'Line two.']);
    expect(fakeTts.lastLanguage, 'en');
    expect(controller.isPlaying, false);
  });

  test('stop cancels playback and sets isPlaying false', () async {
    final fakeTts = _FakeFlutterTts();
    final controller = VoiceOverController(tts: fakeTts);

    unawaited(controller.playAll(['Line one.'], 'en'));
    await controller.stop();

    expect(fakeTts.stopped, true);
    expect(controller.isPlaying, false);
  });
}

void unawaited(Future<void> future) {}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/core/services/voice_over_controller_test.dart`
Expected: FAIL — `lib/core/services/voice_over_controller.dart` doesn't
exist yet.

- [ ] **Step 7: Implement `VoiceOverController`**

```dart
// lib/core/services/voice_over_controller.dart
import 'package:flutter_tts/flutter_tts.dart';

/// Wraps FlutterTts for the AR Lab's Scan-phase narration — ported from the
/// retired web app's src/hooks/useVoiceOver.ts (Web Speech API) onto
/// on-device TTS. Language is 'en' or 'Filipino', matching
/// kVoiceScripts's keys and the student's toggle.
class VoiceOverController {
  VoiceOverController({required FlutterTts tts}) : _tts = tts {
    _tts.setCompletionHandler(_onUtteranceComplete);
  }

  final FlutterTts _tts;
  List<String> _queue = const [];
  int _index = 0;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> playAll(List<String> lines, String language) async {
    await _tts.setLanguage(language == 'en' ? 'en-US' : 'fil-PH');
    _queue = lines;
    _index = 0;
    if (_queue.isEmpty) return;
    _isPlaying = true;
    await _tts.speak(_queue[_index]);
  }

  Future<void> replay() async {
    if (_queue.isEmpty) return;
    _index = 0;
    _isPlaying = true;
    await _tts.speak(_queue[_index]);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
  }

  void _onUtteranceComplete() {
    _index += 1;
    if (_index < _queue.length) {
      _tts.speak(_queue[_index]);
    } else {
      _isPlaying = false;
    }
  }
}
```

- [ ] **Step 8: Run test to verify it passes**

Run: `flutter test test/core/services/voice_over_controller_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 9: Commit**

```bash
git add lib/core/ar/voice_scripts_data.dart lib/core/services/voice_over_controller.dart \
        test/core/ar/voice_scripts_data_test.dart test/core/services/voice_over_controller_test.dart
git commit -m "feat: voice narration data port + VoiceOverController (Part 6.2)"
```

---

### Task 6: `ArLabViewModel` and `buildArLabViewModel` — replaces Lesson Detail's role

**Files:**
- Create: `lib/features/student/ar_lab/ar_lab_providers.dart`
- Test: `test/features/student/ar_lab/ar_lab_providers_test.dart`

**Interfaces:**
- Consumes: `LessonRepository`, `QuizAttemptService`, `StudentRepository`,
  `AccessCodeService` (Phase 2, all unchanged); `lessonForMarkerIndex` (Task
  2); `kBuiltInLessons`.
- Produces: `class ArLabViewModel` (title, summary, `hasAR`, `isRead`,
  `hasPreTest`, `postTestEligible`, `postTestReason`, the currently-detected
  marker's lesson if any, `onMarkerFound`/`onMarkerLost` handlers, and
  everything `LessonDetailViewModel` had — `studentId`, `accessCodeService`,
  `onMarkAsRead`, `onStartPreTest`, `onStartPostTest`). `arLabViewModelProvider`
  (`.family<ArLabViewModel, String>`, keyed on lessonId) and
  `buildArLabViewModel(...)`, following the exact same
  override-at-app-startup pattern `lessonDetailViewModelProvider` used.

This task is a direct evolution of Phase 2's
`lib/features/student/lesson_detail/lesson_detail_providers.dart` — reuse
its lesson-resolution, eligibility, and mark-as-read logic verbatim, adding
only the marker-found/lost reactive state Scan phase needs.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/student/ar_lab/ar_lab_providers_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/lesson_repository.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/features/student/ar_lab/ar_lab_providers.dart';

StudentRecord _blankStudent(String id) => StudentRecord(
      id: id, name: 'Test Student', studentId: id, grade: '7', section: 'Rizal',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [], completedLabExperimentIds: const [],
      completedQuizIds: const [], unlockedLessonIds: const [], unlockedQuizIds: const [],
      quizAttempts: const [],
    );

void main() {
  test('q1w1 view model reports hasAR true and the right marker index', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    await studentRepo.saveStudent(_blankStudent('111111'));
    final quizAttemptService = QuizAttemptService(firestore: firestore);

    final stream = buildArLabViewModel(
      studentId: '111111',
      lessonId: 'q1w1',
      lessonRepository: LessonRepository(firestore: firestore),
      studentRepository: studentRepo,
      quizAttemptService: quizAttemptService,
      accessCodeService: AccessCodeService(firestore: firestore, quizAttemptService: quizAttemptService),
      preTestLessonIds: const {'q1w1'},
      onStartPreTest: () {},
      onStartPostTest: () {},
    );

    final vm = await stream.first;
    expect(vm.hasAR, true);
    expect(vm.markerIndex, isNotNull);
    expect(vm.title, 'Scientific Models and the Particle Model of Matter');
  });

  test('q1w5 view model reports hasAR false and a null marker index', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    await studentRepo.saveStudent(_blankStudent('111111'));
    final quizAttemptService = QuizAttemptService(firestore: firestore);

    final stream = buildArLabViewModel(
      studentId: '111111',
      lessonId: 'q1w5',
      lessonRepository: LessonRepository(firestore: firestore),
      studentRepository: studentRepo,
      quizAttemptService: quizAttemptService,
      accessCodeService: AccessCodeService(firestore: firestore, quizAttemptService: quizAttemptService),
      preTestLessonIds: const {},
      onStartPreTest: () {},
      onStartPostTest: () {},
    );

    final vm = await stream.first;
    expect(vm.hasAR, false);
    expect(vm.markerIndex, isNull);
  });

  test('onMarkerFound/onMarkerLost update detectedMarkerLessonId', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    await studentRepo.saveStudent(_blankStudent('111111'));
    final quizAttemptService = QuizAttemptService(firestore: firestore);

    final stream = buildArLabViewModel(
      studentId: '111111',
      lessonId: 'q1w1',
      lessonRepository: LessonRepository(firestore: firestore),
      studentRepository: studentRepo,
      quizAttemptService: quizAttemptService,
      accessCodeService: AccessCodeService(firestore: firestore, quizAttemptService: quizAttemptService),
      preTestLessonIds: const {'q1w1'},
      onStartPreTest: () {},
      onStartPostTest: () {},
    );

    final vm = await stream.first;
    expect(vm.detectedLesson, isNull);

    vm.onMarkerFound(0); // Q1W1's modelIndex
    expect(vm.detectedLesson?.id, 'q1w1');

    vm.onMarkerFound(999); // an index no lesson uses
    expect(vm.detectedLesson, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/student/ar_lab/ar_lab_providers_test.dart`
Expected: FAIL — file doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/features/student/ar_lab/ar_lab_providers.dart
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/ar/marker_mapping.dart';
import '../../../core/data/curriculum_data.dart';
import '../../../core/models/lesson.dart';
import '../../../core/quiz_id.dart';
import '../../../core/models/quiz_phase.dart';
import '../../../core/services/access_code_service.dart';
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/quiz_attempt_service.dart';
import '../../../core/services/student_repository.dart';

class ArLabViewModel extends ChangeNotifier {
  ArLabViewModel({
    required this.lessonId,
    required this.title,
    required this.summary,
    required this.hasAR,
    required this.markerIndex,
    required this.isRead,
    required this.hasPreTest,
    required this.postTestEligible,
    required this.postTestReason,
    required this.studentId,
    required this.accessCodeService,
    required this.onMarkAsRead,
    required this.onStartPreTest,
    required this.onStartPostTest,
  });

  final String lessonId;
  final String title;
  final String summary;

  /// False only for Q1W5 (Part 6.1) — the Scan tab must degrade gracefully.
  final bool hasAR;

  /// This lesson's own ARPayload.modelIndex — what the Scan tab expects to
  /// see reported back once the student scans the matching printed marker.
  /// Null when `hasAR` is false.
  final int? markerIndex;

  final bool isRead;
  final bool hasPreTest;
  final bool postTestEligible;
  final String? postTestReason;
  final String studentId;
  final AccessCodeService accessCodeService;
  final Future<void> Function() onMarkAsRead;
  final void Function() onStartPreTest;
  final void Function() onStartPostTest;

  /// The lesson whose marker is currently detected by Unity — may differ
  /// from `lessonId` if the student scanned a different lesson's sheet
  /// (2026-08-29 decision: shown as-is, not blocked). Null when no marker
  /// is currently in view.
  Lesson? detectedLesson;

  void onMarkerFound(int foundMarkerIndex) {
    detectedLesson = lessonForMarkerIndex(kBuiltInLessons, foundMarkerIndex);
    notifyListeners();
  }

  void onMarkerLost(int lostMarkerIndex) {
    if (detectedLesson?.arPayload?.modelIndex == lostMarkerIndex) {
      detectedLesson = null;
      notifyListeners();
    }
  }
}

final arLabViewModelProvider =
    StreamProvider.autoDispose.family<ArLabViewModel, String>((ref, lessonId) {
  throw UnimplementedError(
    'arLabViewModelProvider must be overridden at app startup with a real '
    'stream for the given lessonId.',
  );
});

Stream<ArLabViewModel> buildArLabViewModel({
  required String studentId,
  required String lessonId,
  required LessonRepository lessonRepository,
  required StudentRepository studentRepository,
  required QuizAttemptService quizAttemptService,
  required AccessCodeService accessCodeService,
  required Set<String> preTestLessonIds,
  required void Function() onStartPreTest,
  required void Function() onStartPostTest,
}) {
  return studentRepository.watchStudent(studentId).asyncMap((student) async {
    final teacherLessons = await lessonRepository.fetchTeacherLessons();
    final merged = lessonRepository.mergedLessons(teacherLessons);

    Lesson? lesson;
    for (final candidate in merged) {
      if (candidate.id == lessonId) {
        lesson = candidate;
        break;
      }
    }
    if (lesson == null) {
      throw StateError('Lesson "$lessonId" could not be found.');
    }

    final isRead = student?.completedLessonIds.contains(lessonId) ?? false;
    final postQuizId = builtinQuizId(lessonId, QuizPhase.post);
    final eligibility = await quizAttemptService.checkEligibility(studentId, postQuizId);

    return ArLabViewModel(
      lessonId: lessonId,
      title: lesson.title,
      summary: lesson.summary,
      hasAR: lesson.hasAR,
      markerIndex: lesson.arPayload?.modelIndex,
      isRead: isRead,
      hasPreTest: preTestLessonIds.contains(lessonId),
      postTestEligible: eligibility.canTake,
      postTestReason: eligibility.reason,
      studentId: studentId,
      accessCodeService: accessCodeService,
      onMarkAsRead: student == null
          ? () async {}
          : () => studentRepository.saveStudent(
                student.copyWith(completedLessonIds: {...student.completedLessonIds, lessonId}.toList()),
              ),
      onStartPreTest: onStartPreTest,
      onStartPostTest: onStartPostTest,
    );
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/student/ar_lab/ar_lab_providers_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/student/ar_lab/ar_lab_providers.dart \
        test/features/student/ar_lab/ar_lab_providers_test.dart
git commit -m "feat: ArLabViewModel — replaces LessonDetailViewModel's role, adds AR state"
```

---

### Task 7: Scan tab — `EmbedUnity` view + Flutter overlay chrome

**Files:**
- Create: `lib/features/student/ar_lab/scan_tab.dart`
- Test: `test/features/student/ar_lab/scan_tab_test.dart`

**Interfaces:**
- Consumes: `ArLabViewModel` (Task 6); `VoiceOverController` (Task 5);
  `kVoiceScripts`; `markerAssetForLesson` (Task 2).
- Produces: `class ScanTab extends StatefulWidget` taking `vm: ArLabViewModel`
  and `voiceOverController: VoiceOverController`, rendering the `EmbedUnity`
  widget as the bottom layer of a `Stack` with Flutter chrome on top.

**Requirements from PROJECT_FLOW.md Part 6.3 this task must satisfy:**
readable text sized for arm's-length viewing (use `Theme.of(context).textTheme.titleMedium`
or larger, never a hardcoded small font); the description panel visible
concurrently with the model (not behind a tap); a "point your camera at the
marker" instruction shown when nothing is detected.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/student/ar_lab/scan_tab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/voice_over_controller.dart';
import 'package:ar_science_explorer/features/student/ar_lab/ar_lab_providers.dart';
import 'package:ar_science_explorer/features/student/ar_lab/scan_tab.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  testWidgets('shows the point-camera prompt when no marker is detected', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final vm = ArLabViewModel(
      lessonId: 'q1w1',
      title: 'Scientific Models and the Particle Model of Matter',
      summary: 'summary',
      hasAR: true,
      markerIndex: 0,
      isRead: false,
      hasPreTest: true,
      postTestEligible: false,
      postTestReason: null,
      studentId: '111111',
      accessCodeService: AccessCodeService(
        firestore: firestore,
        quizAttemptService: QuizAttemptServiceForTest(firestore),
      ),
      onMarkAsRead: () async {},
      onStartPreTest: () {},
      onStartPostTest: () {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanTab(vm: vm, voiceOverController: VoiceOverController(tts: _NoopTts())),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Point your camera'), findsOneWidget);
  });

  testWidgets('shows the description panel once a marker is detected', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final vm = ArLabViewModel(
      lessonId: 'q1w1',
      title: 'Scientific Models and the Particle Model of Matter',
      summary: 'summary',
      hasAR: true,
      markerIndex: 0,
      isRead: false,
      hasPreTest: true,
      postTestEligible: false,
      postTestReason: null,
      studentId: '111111',
      accessCodeService: AccessCodeService(
        firestore: firestore,
        quizAttemptService: QuizAttemptServiceForTest(firestore),
      ),
      onMarkAsRead: () async {},
      onStartPreTest: () {},
      onStartPostTest: () {},
    )..onMarkerFound(0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanTab(vm: vm, voiceOverController: VoiceOverController(tts: _NoopTts())),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Democritus Atom'), findsOneWidget);
    expect(find.textContaining('Point your camera'), findsNothing);
  });
}
```

```dart
// Add at the bottom of the test file — shared test doubles.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';

QuizAttemptService QuizAttemptServiceForTest(FirebaseFirestore firestore) =>
    QuizAttemptService(firestore: firestore);

class _NoopTts implements FlutterTts {
  @override
  Future<dynamic> speak(String text) async => 1;
  @override
  Future<dynamic> setLanguage(String language) async => 1;
  @override
  Future<dynamic> stop() async => 1;
  @override
  void setCompletionHandler(void Function() handler) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/student/ar_lab/scan_tab_test.dart`
Expected: FAIL — `lib/features/student/ar_lab/scan_tab.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/features/student/ar_lab/scan_tab.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';

import '../../../core/ar/voice_scripts_data.dart';
import '../../../core/services/voice_over_controller.dart';
import 'ar_lab_providers.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({super.key, required this.vm, required this.voiceOverController});

  final ArLabViewModel vm;
  final VoiceOverController voiceOverController;

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  String _voiceLanguage = 'en';

  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_onVmChanged);
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onVmChanged);
    super.dispose();
  }

  void _onVmChanged() => setState(() {});

  void _handleUnityMessage(String message) {
    final decoded = jsonDecode(message) as Map<String, dynamic>;
    final event = decoded['event'] as String?;
    final modelIndex = decoded['modelIndex'] as int?;
    if (modelIndex == null) return;
    if (event == 'markerFound') {
      widget.vm.onMarkerFound(modelIndex);
    } else if (event == 'markerLost') {
      widget.vm.onMarkerLost(modelIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.vm.hasAR) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'This lesson doesn\'t have an AR model — continue to the Read tab.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final detected = widget.vm.detectedLesson;
    final scripts = kVoiceScripts[widget.vm.lessonId];

    return Stack(
      children: [
        Positioned.fill(child: EmbedUnity(onMessageFromUnity: _handleUnityMessage)),
        if (detected == null)
          Positioned(
            top: 24,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Point your camera at the printed marker for this lesson.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      detected.arPayload?.title ?? detected.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (detected.arPayload?.subtitle != null)
                      Text(
                        detected.arPayload!.subtitle!,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    const SizedBox(height: 8),
                    if (detected.arPayload?.description != null)
                      Text(
                        detected.arPayload!.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    if (detected.arPayload?.keyIdeas != null) ...[
                      const SizedBox(height: 8),
                      for (final idea in detected.arPayload!.keyIdeas!)
                        Text('• $idea', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (scripts != null)
          Positioned(
            top: 24,
            right: 16,
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _voiceLanguage,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'Filipino', child: Text('Filipino')),
                  ],
                  onChanged: (lang) => setState(() => _voiceLanguage = lang ?? 'en'),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => widget.voiceOverController.playAll(
                    scripts[_voiceLanguage] ?? const [],
                    _voiceLanguage,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/student/ar_lab/scan_tab_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/student/ar_lab/scan_tab.dart test/features/student/ar_lab/scan_tab_test.dart
git commit -m "feat: Scan tab — EmbedUnity view + description overlay + voice controls"
```

---

### Task 8: Read tab

**Files:**
- Create: `lib/features/student/ar_lab/read_tab.dart`

**Interfaces:**
- Consumes: `ArLabViewModel` (Task 6).
- Produces: `class ReadTab extends StatelessWidget` taking `vm: ArLabViewModel`.

- [ ] **Step 1: Implement**

No new business logic here — `onMarkAsRead` is already fully implemented
and tested in Task 6; this is presentation only, so it's not TDD'd as a
separate task per this plan's usual pattern (matching how Phase 2 treated
some pure-render tasks).

```dart
// lib/features/student/ar_lab/read_tab.dart
import 'package:flutter/material.dart';

import 'ar_lab_providers.dart';

class ReadTab extends StatelessWidget {
  const ReadTab({super.key, required this.vm});

  final ArLabViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(vm.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(vm.summary, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        if (!vm.isRead)
          FilledButton(
            onPressed: () async => vm.onMarkAsRead(),
            child: const Text('Mark as Read'),
          )
        else
          const Chip(label: Text('Read'), avatar: Icon(Icons.check)),
      ],
    );
  }
}
```

- [ ] **Step 2: Manually verify via the Scan tab's existing test harness**

Run: `flutter test test/features/student/ar_lab/`
Expected: still all passing (this file has no dedicated test, but Task 10's
`ar_lab_screen_test.dart` exercises it as part of the tabbed screen).

- [ ] **Step 3: Commit**

```bash
git add lib/features/student/ar_lab/read_tab.dart
git commit -m "feat: Read tab — curriculum content + Mark as Read"
```

---

### Task 9: Review tab

**Files:**
- Create: `lib/features/student/ar_lab/review_tab.dart`

**Interfaces:**
- Consumes: `ArLabViewModel` (Task 6).
- Produces: `class ReviewTab extends StatelessWidget` taking `vm: ArLabViewModel`
  and `onGoToProgress: VoidCallback`.

**Requirement (PROJECT_FLOW.md Part 6.2, Phase 3):** "Start Post-Test" must
check real-time Firestore eligibility, not a cached/stale unlock state —
`vm.postTestEligible` is already computed fresh on every `ArLabViewModel`
stream emission (Task 6's `buildArLabViewModel` re-checks
`quizAttemptService.checkEligibility` every time `watchStudent` emits), so
this requirement is already satisfied by construction; this task only needs
to render that state correctly, not re-implement the check.

- [ ] **Step 1: Implement**

```dart
// lib/features/student/ar_lab/review_tab.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'ar_lab_providers.dart';

class ReviewTab extends StatelessWidget {
  const ReviewTab({super.key, required this.vm});

  final ArLabViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.celebration, size: 48),
          const SizedBox(height: 12),
          Text('Lesson Complete', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: vm.postTestEligible
                ? () {
                    vm.onStartPostTest();
                    context.push('/quiz/${vm.lessonId}/post');
                  }
                : null,
            child: Text(vm.postTestEligible ? 'Start Post-Test' : (vm.postTestReason ?? 'Post-Test locked')),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => context.go('/progress'),
            child: const Text('Go to Progress'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/student/ar_lab/review_tab.dart
git commit -m "feat: Review tab — completion summary, real-time post-test eligibility"
```

---

### Task 10: `ArLabScreen` — retire `LessonDetailScreen`, wire the route

**Files:**
- Create: `lib/features/student/ar_lab/ar_lab_screen.dart`
- Modify: `lib/features/student/app/router.dart`
- Modify: `lib/features/student/app/student_providers.dart`
- Delete: `lib/features/student/lesson_detail/lesson_detail_providers.dart`
- Delete: `lib/features/student/lesson_detail/lesson_detail_screen.dart`
- Delete: `test/features/student/lesson_detail/lesson_detail_screen_test.dart`
- Delete: `test/features/student/app/student_providers_test.dart`'s
  lesson-detail-specific test cases (keep the rest — see Step 4)
- Test: `test/features/student/ar_lab/ar_lab_screen_test.dart`

**Interfaces:**
- Consumes: `ArLabViewModel`, `arLabViewModelProvider`, `buildArLabViewModel`
  (Task 6); `ScanTab` (Task 7); `ReadTab` (Task 8); `ReviewTab` (Task 9).
- Produces: `class ArLabScreen extends ConsumerStatefulWidget` taking
  `lessonId: String`, a 3-tab `TabBar`/`TabBarView` (Scan / Read / Review),
  owning one `VoiceOverController` instance for the screen's lifetime.
  `arLabOverrideFor(...)` in `student_providers.dart` — same shape as the
  retired `lessonDetailOverrideFor`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/student/ar_lab/ar_lab_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/features/student/ar_lab/ar_lab_providers.dart';
import 'package:ar_science_explorer/features/student/ar_lab/ar_lab_screen.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  testWidgets('renders three tabs: Scan, Read, Review', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final quizAttemptService = QuizAttemptService(firestore: firestore);
    final vm = ArLabViewModel(
      lessonId: 'q1w1',
      title: 'Scientific Models and the Particle Model of Matter',
      summary: 'summary',
      hasAR: true,
      markerIndex: 0,
      isRead: false,
      hasPreTest: true,
      postTestEligible: false,
      postTestReason: 'Complete the lesson first.',
      studentId: '111111',
      accessCodeService: AccessCodeService(firestore: firestore, quizAttemptService: quizAttemptService),
      onMarkAsRead: () async {},
      onStartPreTest: () {},
      onStartPostTest: () {},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          arLabViewModelProvider('q1w1').overrideWith((ref) => Stream.value(vm)),
        ],
        child: const MaterialApp(home: ArLabScreen(lessonId: 'q1w1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/student/ar_lab/ar_lab_screen_test.dart`
Expected: FAIL — `lib/features/student/ar_lab/ar_lab_screen.dart` doesn't
exist yet.

- [ ] **Step 3: Implement `ArLabScreen`**

```dart
// lib/features/student/ar_lab/ar_lab_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/voice_over_controller.dart';
import 'ar_lab_providers.dart';
import 'read_tab.dart';
import 'review_tab.dart';
import 'scan_tab.dart';

class ArLabScreen extends ConsumerStatefulWidget {
  const ArLabScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<ArLabScreen> createState() => _ArLabScreenState();
}

class _ArLabScreenState extends ConsumerState<ArLabScreen> {
  late final VoiceOverController _voiceOverController;

  @override
  void initState() {
    super.initState();
    _voiceOverController = VoiceOverController(tts: FlutterTts());
  }

  @override
  Widget build(BuildContext context) {
    final asyncViewModel = ref.watch(arLabViewModelProvider(widget.lessonId));

    return asyncViewModel.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Could not load this lesson: $error'))),
      data: (vm) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(vm.title),
            bottom: const TabBar(
              tabs: [Tab(text: 'Scan'), Tab(text: 'Read'), Tab(text: 'Review')],
            ),
          ),
          body: TabBarView(
            children: [
              ScanTab(vm: vm, voiceOverController: _voiceOverController),
              ReadTab(vm: vm),
              ReviewTab(vm: vm),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/student/ar_lab/ar_lab_screen_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Wire `arLabOverrideFor` into `student_providers.dart`**

Read `lib/features/student/app/student_providers.dart` first — replace
`lessonDetailOverrideFor` with the equivalent for `ArLabViewModel`:

```dart
// Replace lessonDetailOverrideFor in student_providers.dart with:
StreamProviderFamily<ArLabViewModel, String> get arLabViewModelProviderRef =>
    arLabViewModelProvider;

Override arLabOverrideFor(
  String studentId,
  String lessonId, {
  required StudentServices services,
  required void Function() onStartPreTest,
  required void Function() onStartPostTest,
}) {
  return arLabViewModelProvider(lessonId).overrideWith(
    (ref) => buildArLabViewModel(
      studentId: studentId,
      lessonId: lessonId,
      lessonRepository: services.lessonRepository,
      studentRepository: services.studentRepository,
      quizAttemptService: services.quizAttemptService,
      accessCodeService: services.accessCodeService,
      preTestLessonIds: kPreTestQuestionsByLesson.keys.toSet(),
      onStartPreTest: onStartPreTest,
      onStartPostTest: onStartPostTest,
    ),
  );
}
```
Remove the now-unused `lessonDetailOverrideFor` function and its
`LessonDetailViewModel`/`lesson_detail_providers.dart` import. Add the
import for `ar_lab_providers.dart` and `curriculum_data.dart` (for
`kPreTestQuestionsByLesson`) if not already present.

- [ ] **Step 6: Update `router.dart`'s `/lesson/:lessonId` route**

Read `lib/features/student/app/router.dart` first (the real current file —
it has the `invalidateQuizSession` helper and `lessonDetailOverrideFor` call
shown in this plan's research). Replace the route's `builder` body: swap
`lessonDetailOverrideFor(...)` for `arLabOverrideFor(...)`, and
`LessonDetailScreen(lessonId: lessonId)` for `ArLabScreen(lessonId: lessonId)`.
Update the import at the top of the file from
`../lesson_detail/lesson_detail_screen.dart` to `../ar_lab/ar_lab_screen.dart`.
Everything else in that route builder (the `Consumer`, the
`currentStudentIdProvider` watch, `invalidateQuizSession`) stays exactly as
it is — this is a swap of which screen/override gets used, not a
restructuring of the route.

- [ ] **Step 7: Delete the retired Lesson Detail files**

```bash
rm lib/features/student/lesson_detail/lesson_detail_providers.dart
rm lib/features/student/lesson_detail/lesson_detail_screen.dart
rm test/features/student/lesson_detail/lesson_detail_screen_test.dart
rmdir lib/features/student/lesson_detail test/features/student/lesson_detail 2>/dev/null || true
```

Also remove `student_providers_test.dart`'s test case(s) that specifically
exercised `lessonDetailOverrideFor`/`lessonDetailViewModelProvider` (read
the file first — Phase 2's version has a case named along the lines of "C4:
lessonDetailOverrideFor resolves a teacher-authored lesson id without
throwing"). Replace it with an equivalent case for `arLabOverrideFor`
proving the same property (a teacher-authored lesson id resolves without
throwing) — do not just delete coverage, port it to the new function.

- [ ] **Step 8: Run the full suite**

Run: `flutter test`
Expected: all tests pass — this is the task most likely to reveal a missed
reference to the deleted files (a stray import, a stale route link from
Home/Learn screens still pointing at `/lesson/:lessonId` is fine since the
*route path* is unchanged, only what it renders changed — but double check
`home_screen.dart`'s "Continue where you left off" and `lesson_card.dart`'s
`context.push('/lesson/${...}')` calls still compile and still make sense
pointed at the same route).

- [ ] **Step 9: Commit**

```bash
git add lib/features/student/ar_lab/ lib/features/student/app/router.dart \
        lib/features/student/app/student_providers.dart \
        test/features/student/ar_lab/ test/features/student/app/student_providers_test.dart
git rm lib/features/student/lesson_detail/lesson_detail_providers.dart \
       lib/features/student/lesson_detail/lesson_detail_screen.dart \
       test/features/student/lesson_detail/lesson_detail_screen_test.dart
git commit -m "feat: ArLabScreen retires LessonDetailScreen — real Scan/Read/Review flow"
```

---

### Task 11: Manual Unity export, Android wiring, and phase checkpoint

**Files:**
- Modify: `android/settings.gradle`, `android/app/build.gradle` (exact
  entries depend on what the Unity export step actually produces — see Step
  2 below; do not guess these ahead of running the export)
- Modify: `MANUAL_STEPS.md`
- None else — this task is the manual bridge between everything built so
  far (fully testable via `flutter test` without a live Unity library) and
  an actual runnable Android build.

**Interfaces:**
- Consumes: everything from Tasks 1–10.
- Produces: a real, physically-buildable Android APK with the AR Lab
  embedded and functional.

- [ ] **Step 1: Confirm prerequisites with the user**

Before this task starts, confirm: (a) the `FlutterEmbed` Unity package is
imported (Task 3's prerequisite), (b) all 23 markers' `modelIndex` Inspector
fields are set (Task 3 Step 2), (c) the standalone APK (already confirmed
working earlier) still builds cleanly with these changes.

- [ ] **Step 2: User runs the Unity export**

Ask the user to run, in the Unity Editor: `Flutter Embed → Export project to
Flutter app` → select Android → point it at `ARwebmob/android/unityLibrary`.
Ask them to report back what the plugin's own console output says about any
additional `settings.gradle`/`build.gradle` entries it needs (per this
plan's Global Constraints, the plugin may patch these itself as part of its
own export tooling — confirm rather than assume before hand-editing).

- [ ] **Step 3: Wire the Gradle files, if the export didn't already**

Only if Step 2 confirms manual entries are still needed: add the
`unityLibrary` module reference to `android/settings.gradle` and the
dependency line to `android/app/build.gradle`, following exactly what the
`flutter_embed_unity`/`flutter_embed_unity_6000_0_android` package
documentation specifies for these two files (re-check
`pub.dev/packages/flutter_embed_unity_6000_0_android` at this point in
execution — its exact required Gradle snippet is a implementation detail of
a package version, not something to hardcode speculatively in this plan
written before Task 1 even ran `flutter pub get`).

- [ ] **Step 4: Build and test on a real device**

Run: `flutter build apk --debug` (or `flutter run` targeting a connected
device — MANUAL_STEPS.md already tracks "real device, not just emulator" as
a requirement for Unity-as-a-Library embeds specifically).
Ask the user to test: Learn → tap an unlocked AR lesson card → Scan tab
shows the camera feed → point at the lesson's printed marker → description
panel appears with real content → rotate/pinch-zoom works → switch to Read
tab → Mark as Read → Review tab → Start Post-Test (if eligible) launches
the quiz. Report back what worked and what didn't — this is real-device
verification a test suite cannot substitute for.

- [ ] **Step 5: Run the full Flutter test suite one more time**

Run: `flutter test`
Expected: everything from Tasks 1–10 still passes (this task added no new
Dart code, only native wiring, so this should be unchanged — confirms
nothing about the Gradle/build changes broke the Dart build).

- [ ] **Step 6: Update `MANUAL_STEPS.md`**

Mark the Unity export item complete, and add a note recording exactly what
Gradle entries were needed (or that the export handled it automatically) so
a future re-export doesn't require re-discovering this.

- [ ] **Step 7: Commit the checkpoint**

```bash
git add android/ MANUAL_STEPS.md
git commit -m "chore: Phase 3 complete — AR Lab embedded, Scan/Read/Review live" --allow-empty
```
