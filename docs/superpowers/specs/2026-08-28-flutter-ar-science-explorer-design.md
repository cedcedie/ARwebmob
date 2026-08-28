# AR Science Explorer — Flutter Rewrite: Design Spec

Source of truth for full functional detail: `PROJECT_FLOW.md` (repo root). This
document captures the architectural decisions made on top of it, resolved open
questions, and the concrete project structure to build against. Read
`PROJECT_FLOW.md` first — this doc doesn't repeat curriculum content, data
shapes, or business rules already fully specified there.

## 1. Scope

One new Flutter/Dart project, two build targets from one codebase:

- **Flutter Android** — student experience (login, Home, Learn, AR Lab
  [Scan/Read/Review], Quiz player, Progress).
- **Flutter Web** — teacher/admin experience (lesson CRUD, quiz CRUD, student
  roster, access codes, analytics/item analysis).
- Both targets share one Firebase project (Firestore + Auth) — same
  collections, same accounts, no migration, no sync layer.
- iOS explicitly out of scope for now.

## 2. Resolved decisions (supersede/clarify PROJECT_FLOW.md Part 13)

| # | Question | Resolution | Source |
|---|---|---|---|
| 5 | Auth email construction from raw student ID | Actual Firebase Auth email is always `{6 plain digits}@arscience.school` — **no dash**. The `00-0000` format is a display-only mask on the input field; strip to digits before constructing the email or deriving `studentId`. | `ar-science-explorer/src/lib/firebaseAuth.ts` |
| 6 | Quiz-attempt write source of truth | Write **both** on every attempt: the `/students/{id}/quizAttempts/{attemptId}` subcollection doc, and `arrayUnion` onto the parent student doc's embedded `quizAttempts[]` array. Reads use the embedded array as primary source; the subcollection is a fallback query path and is what bulk delete/archive operates on. | `ar-science-explorer/src/lib/storage.ts` |
| 7 | Does Unity already do rotate/zoom on the model? | Yes — confirmed in the actual Unity project (`C:\Users\cedri\VuforiaAR\Assets\Scripts\MobileARController.cs`). One-finger rotate + two-finger pinch-zoom, smoothed (Slerp/Lerp), reset on marker-lost. Nothing to build on the Flutter or Unity side for this interaction. | Direct inspection of `MobileARController.cs` |
| 1 | Item analysis → Teacher Web only | **Still open** — needs client/user confirmation. Default assumption (teacher-only, per PROJECT_FLOW.md's own flagged default) will be followed unless told otherwise. |  |
| 2 | PPT support via slide-image conversion at import time | **Still open** — needs client/user confirmation. Default assumption (convert PPTX → slide images/PDF at teacher upload time, no native on-device PPTX renderer) will be followed unless told otherwise. |  |

## 3. The Unity/Vuforia project

Location: `C:\Users\cedri\VuforiaAR` (outside this repo, left in place — decided
deliberately, see below). Currently builds as a **standalone Android app**
(there's an existing `VuforiaTest.apk`); it has **not** yet been exported as an
Android library or wired into any Flutter shell. Treat "embed the existing
Unity project" as a real integration task, not a done one.

**Decision: leave the Unity project where it is, do not move it into this
repo.** There is no functional advantage either way — Unity and Flutter are
separate build toolchains with no live sync in either direction; a Unity-side
change never appears in the Flutter app until it's manually re-exported. Since
co-location buys only bookkeeping convenience and this project doesn't need
that, the Unity source stays external and this repo documents the dependency
instead (`BUILD.md`, to be written during scaffolding).

**Build chain (documented here for the implementation plan to follow):**

1. In Unity: File → Build Settings → Android → check "Export Project" → Export
   to a scratch folder.
2. This produces a `unityLibrary` Gradle module (ignore the accompanying
   `launcher` folder — Flutter's embed plugins don't need it).
3. Copy `unityLibrary` into `ARwebmob/android/unityLibrary/`.
4. `ARwebmob/android/settings.gradle` and `android/app/build.gradle` need
   one-time entries (added during scaffolding) that link the module in.
5. Every subsequent Unity change repeats steps 1–3, then a normal
   `flutter build apk`/`flutter run`.

**Embed architecture (from PROJECT_FLOW.md Part 6.0, restated for the plan):**

- One Unity instance for the app's lifetime — initialized once, shown/hidden
  per AR Lab entry/exit, never destroyed/recreated per scan.
- Unity owns: camera feed, marker tracking, 3D rendering, rotate/zoom (already
  implemented, see resolved Q7).
- Flutter owns: everything else — back button, "point your camera" prompt,
  the description/keyIdeas overlay (populated from Flutter's own lesson data,
  not from Unity), hint chips, layered in a `Stack` above the embedded Unity
  view.
- Bridge payload, in both directions:
  - Flutter → Unity: which marker/model set to load for *this* lesson (derived
    `Q{quarter}W{week}` key, per PROJECT_FLOW.md 6.1).
  - Unity → Flutter: `"marker found"` / `"marker lost"` only. No content
    crosses this bridge — Flutter already has the lesson's `arPayload` in
    memory before the Unity view even appears.
- Package: `flutter_embed_unity` (fallback `flutter_unity_widget` if the first
  proves unworkable) — accepted as a "delicate," version-sensitive embed per
  the plugin's own documentation; test this integration early in the plan, not
  near a demo deadline.

## 4. Project structure

Repo root (`ARwebmob/`) is the Flutter project root.

```
ARwebmob/
  PRODUCT.md, PROJECT_FLOW.md, docs/          (specs, kept/added)
  assets/{markers,models,lessons}/            (kept as-is; wired into pubspec)
  BUILD.md                                     (Unity export steps, written during scaffolding)
  lib/
    main.dart                # entry point; branches student vs teacher shell via kIsWeb
    core/                     # shared by both targets — single source of truth
      models/                 # Lesson, ARPayload, StudentRecord, QuizAttempt, TeacherQuiz,
                               # TeacherLesson, QuizUnlockCode, BuiltInQuestion — verbatim
                               # field-for-field port of PROJECT_FLOW.md Part 4.1
      curriculum/              # static compiled-in 24 lessons + built-in question banks,
                               # ported verbatim from curriculum.ts/lessons.ts/q{N}QuizTemplates.ts
      services/                # AuthService (email-pattern role inference, Part 3.1/3.2),
                               # FirestoreRepositories (students/lessons/quizzes/codes)
      quiz_rules/              # scoring formula, 50% pass threshold, pre/post retake
                               # eligibility (Part 7) — one implementation, both targets
      access_codes/            # the 3-type / 6-step validation order (Part 9) — one
                               # implementation, both targets
    student/                   # Android-only screens
      home/, learn/, ar_lab/, quiz/, progress/
      ar_lab/unity_bridge.dart # wraps flutter_embed_unity: show/hide, marker found/lost stream
    teacher/                   # Web-only screens
      lessons/, quizzes/, students/, access_codes/, analytics/  # item analysis (pending Q1)
  unity/                       # NOT created — Unity project stays external, see Section 3
  android/unityLibrary/        # generated by Unity's export step; gitignored
  test/, web/, android/, pubspec.yaml
```

Rule enforced by this structure: nothing in `core/` imports from `student/` or
`teacher/`. The two most drift-prone rules in the whole spec — quiz retake
eligibility and access-code validation order — each live in exactly one file,
imported by both targets, so there is no way for one target to silently drift
from the other's enforcement.

## 5. Defaults not yet objected to (used unless told otherwise)

- **State management**: Riverpod — testable providers shareable across both
  targets, no BuildContext-coupling for the shared `core/` logic.
- **Model codegen**: `freezed` + `json_serializable` for the `core/models/`
  types — matches PROJECT_FLOW.md Part 4's own instruction to "translate
  directly into Dart classes/freezed models."
- **Firebase packages**: `firebase_core`, `firebase_auth`, `cloud_firestore`,
  `firebase_storage` (the last for Part 8's PPT/PDF storage move).

## 5.1 UI stack — confirmed (Phase 2+, not needed until real screens exist)

Two design systems, one per target, deliberately not shared — the two
targets already share zero UI code (only `core/` is shared per Section 4),
so this carries no cross-target risk. Chosen from a deliberate pass over
`awesome-flutter`'s recommendations, mapped to actual requirements in
PROJECT_FLOW.md rather than picked generically.

**Base design systems:**

- **Student (Android)**: Material 3 — Flutter's own default since 3.16
  (`useMaterial3` needs no explicit opt-in anymore). Kept as the structural
  base specifically because the AR Lab screen embeds Unity as a native
  platform view (Part 6.0, already flagged as a "delicate" integration) —
  building everything *around* that embed from Flutter's own rendering
  pipeline, rather than a third-party kit with custom render objects, avoids
  stacking a second variable onto an already fragile embed.
- **Teacher (Web)**: `shadcn_ui` as the component base.

**Structure / navigation (both targets):**

| Package | Why |
|---|---|
| `go_router` | Neither target had a router picked. Standard for the multi-screen nav on both sides; gives Teacher Web real bookmarkable URLs (`/lessons`, `/students`). |
| `hooks_riverpod` + `flutter_hooks` | Cuts `StatefulWidget` boilerplate in screens mixing local UI state (quiz-in-progress, AR overlay visibility) with Riverpod providers. |
| `google_fonts` | Typography for both targets — avoids the default system-font look. |

**Delight — mapped to specific spec-called-out moments:**

| Package | Where it's used |
|---|---|
| `lottie` | First-run "how AR scanning works" explainer (Part 1.2); pass-screen positive framing (Part 7.4). |
| `flutter_animate` | Card-unlock reveal, quiz result reveal, general transitions. |
| `confetti` | The access-code unlock moment (Part 9.4 — "a genuine acknowledgment beat, not a form silently closing"). |

**Student (Android) specifics:**

| Package | Why |
|---|---|
| `flutter_embed_unity` (fallback `flutter_unity_widget`) | The AR embed itself — Part 6.0. |
| `flutter_tts` | Part 6.2's scripted TTS voice-over, togglable English/Filipino. |
| `pin_code_fields` | The access-code entry box (Part 9) — used in four places per the spec, one well-built widget pays for itself. |
| `shared_preferences` | Remembering last TTS language, last active subject tab. |
| `skeletonizer` | Loading states for Firestore-backed lists (Learn, Progress) — reads more polished than a spinner given how often this app hits Firestore. |

**Teacher (Web) specifics:**

| Package | Why |
|---|---|
| `data_table_2` | Dense sortable/fixed-column tables — stock `DataTable` doesn't handle desktop density well (Part 2.2). |
| `lucide_icons_flutter` | Matches `shadcn_ui`'s own icon ecosystem. |
| `fl_chart` | Item analysis difficulty/discrimination-index visualizations (Part 7.5, pending Q1). |
| `flutter_form_builder` + `form_builder_validators` | The teacher CRUD forms (lesson editor, quiz question editor with dynamic option lists) are exactly the repetitive validated-form case these remove boilerplate from. |
| `model_viewer_plus` | Lets a teacher preview a lesson's `.glb` model directly in the browser when assigning it — no need to open Unity or a student device to check the right model is attached. |
| `cached_network_image` | Once Part 8 moves lesson content to Firebase Storage, thumbnails/previews in the roster and lesson list benefit from real caching. |

**Still pending Q2 (Part 8's PPT question):** the student-side lesson-content
viewer package — `syncfusion_flutter_pdfviewer` if content is exported as a
PDF at import time, or a plain image viewer (`photo_view`) if exported as a
slide-image sequence instead. Not decided until Q2 is confirmed.

Any actual screen-building work goes through the **`/impeccable`** skill for
the design/polish pass rather than wiring up default widget styling by hand.

## 6. Build phasing

Each phase produces working, testable software on its own — no phase ships
UI polish before the logic underneath it is proven. Detailed
`writing-plans`-style task breakdowns are written one phase at a time,
immediately before that phase starts, since each phase's exact plan depends
on what the previous phase actually produced (types, method names, provider
shapes). Phase 1's plan already exists in full; Phases 2–5 are written when
reached.

### Phase 1 — Foundation (plan written: `docs/superpowers/plans/2026-08-28-phase1-scaffold-core-auth.md`)

`flutter create`, Firebase bootstrap, `core/models` (freezed), `quiz_id.dart`,
`AuthService` (role inference + login), `StudentRepository`. No screens beyond
one placeholder shell, no UI packages — this phase is pure data-layer and is
fully unit-testable without a live Firebase project.

### Phase 2 — Student core flow (no AR yet)

Home, Learn, Progress screens; the quiz player with the full pre/post-test
retake rule (Part 7 — "the single most important behavior to get exactly
right"); the access-code system (Part 9) end-to-end. Deliberately built and
proven *before* AR complexity is layered in.
**UI packages introduced:** Material 3 theme (color scheme, typography via
`google_fonts`), `go_router`, `hooks_riverpod` + `flutter_hooks`,
`shared_preferences`, `skeletonizer`, `pin_code_fields`, `confetti`,
`flutter_animate`.

### Phase 3 — AR Lab / Unity embed

Unity export → `android/unityLibrary` wiring (Section 3) → the marker
found/lost message bridge → the three-phase Scan/Read/Review screen (Part
6.2) → voice narration. Rotate/zoom is inherited free from the existing
Unity project (resolved Q7) — nothing to build there. Tested early per the
"delicate embed" warning, not near a deadline.
**UI/AR packages introduced:** `flutter_embed_unity` (fallback
`flutter_unity_widget`), `flutter_tts`, `lottie` (first-run AR explainer).

### Phase 4 — Teacher Web

Lesson/quiz CRUD, student roster, access-code issuance, desktop-appropriate
layouts (Part 2.2 — real tables and keyboard-friendly forms, not a stretched
phone screen).
**UI packages introduced:** `shadcn_ui`, `data_table_2`,
`lucide_icons_flutter`, `flutter_form_builder` + `form_builder_validators`,
`model_viewer_plus`, `cached_network_image`.

### Phase 5 — Item analysis + PPT pipeline (pending Q1/Q2 confirmation)

Item analysis reporting (Part 7.5) on Teacher Web, and the PPTX → slide-image
conversion pipeline (Part 8). Held until Q1/Q2 are confirmed so this phase
isn't built against the wrong target/approach.
**UI packages introduced:** `fl_chart`; the student-side content viewer
(`syncfusion_flutter_pdfviewer` or `photo_view`, decided by Q2's answer).

## 7. Still open — needs your/client confirmation before that phase is built

- Q1: item analysis on Teacher Web only, not shown to students — confirm.
- Q2: PPTX → slide-images-at-import-time approach — confirm.

No other item in PROJECT_FLOW.md Parts 3, 7, 9, or Part 5's curriculum content
is open for reinterpretation — those are replicate-exactly requirements.
