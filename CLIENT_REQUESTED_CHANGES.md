# Client Requested Changes — 2026-09-02

Relayed by the client partly as typed notes, partly as a voice message (transcribed manually). Covers two repos:

- **`ARwebmob`** (this repo) — Flutter app: teacher side + student side (auth, quizzes, progress, lesson/marker management).
- **`VuforiaAR`** (sibling repo, `C:\Users\cedri\VuforiaAR`) — Unity project: Vuforia AR marker tracking + 3D model rendering, embedded into Flutter via `FlutterEmbed`. Owns model animation, rotate, and zoom behavior.

Top two complaints driving priority: **AR models have no scan-in animation**, and **zoom in/out is buggy** (rotate is fine).

---

## 1. Auth (ARwebmob — teacher side)

- [ ] Teacher sign-in must be **Google / Microsoft / email sign-in directly** — buttons for Google and Microsoft sign-in.
- [ ] **Not** a Firebase-console-style "add account" flow — client was explicit that this is wrong as currently built.
- [ ] Student accounts are **added by the teacher**, not self-signup:
  - Teacher adds a student → system generates a student ID.
  - Teacher sets/gives the student a password out of band.
- [ ] Password field needs a **show/hide icon** (eye icon) on both teacher and student sign-in forms. (Student side is explicitly spec'd in the client's paper docs; teacher side implied by the voice message.)

## 2. Teacher side features

- [ ] Can **edit** lesson/quiz content after it's already been added.
- [ ] Can **add a quiz**.
- [ ] **"Reset progress for all"** button (already specced in the client's paper docs — check those for exact scope/confirmation wording).
- [ ] Can **add an AR marker** tied to a specific lesson.

## 3. Student side features / bugs

- [ ] AR models feel too "childish" (*pang-bata*) — visual polish pass wanted.
- [ ] Password show/hide icon (paper-spec'd).
- [ ] **Rotate** — currently working, keep as-is.
- [ ] **Zoom in / zoom out** — currently **buggy**. Suspected root cause: each `.glb` model was authored at a different real-world scale, so an absolute zoom range doesn't behave consistently across models. Fix direction: normalize model scale on load, or make zoom relative-per-model rather than an absolute clamp.
- [ ] Models should **animate when scanned** — currently static on marker detection.

## 4. AR / Unity (`VuforiaAR`)

- [ ] On marker scan, models should animate in (e.g. scale-in with slight overshoot/bounce), not just appear.
- [ ] **Democritus atom model** specifically called out as too dull/plain — wants a continuous animation, e.g. electrons orbiting the nucleus (*"umiikot-ikot"*). Suggested workflow: animate in **Blender** (Blender MCP available) then bring the result into Unity, rather than hand-keyframing in Unity.
- [ ] Start with **~2 polished animations** (scan-in scale for all models + the Democritus orbit), then decide whether to extend idle-loop animations to the rest of the 23–24 models.
- [ ] Unity → Flutter integration currently **blocks/interferes with Flutter UI** — needs reworking so Unity processing doesn't block the Flutter side (`FlutterEmbed` threading/rendering path).

---

## Model inventory & recommended animation (from `VuforiaAR/Assets/Models`)

24 `.glb` files found (client said ~23). Universal baseline for every model: **scale-in on scan** (0→1 with slight bounce). Table below is the *additional* idle-loop suggestion per model — proposals only, confirm before building.

### Quarter 1 — Matter / chemistry
| Model | Recommended animation |
|---|---|
| `DemocritusAtom_Model01.glb` | Electrons orbit nucleus continuously, nucleus gently pulses (client's top priority) |
| `Q1W2waterpolarity.glb` | Molecule slowly rotates; δ+/δ− charges pulse in sequence |
| `Q1W3solid_liquid_gas.glb` | Particle jitter speed cycles solid→liquid→gas |
| `Q1W4_particle_motion_temperature.glb` | Particle vibration speed loops with a heat-up/cool-down cycle |
| `Q1W6beakers.glb` | Liquid level/pour animation between beakers |
| `Q1W7_saturated_unsaturated.glb` | Particles dissolve then settle/crystallize, looped |
| `Q1W8salt_dissolving_in_water.glb` | Salt crystal shrinks, particles disperse into water |

### Quarter 2 — Biology / cells
| Model | Recommended animation |
|---|---|
| `Q2W1Microscope.glb` | Focus knob turns, stage/lens shifts slightly |
| `Q2W1_prokaryotic_bacterial_cell.glb` | Flagellum whips, slow full-cell rotation |
| `Q2W2plant_cell.glb` | Organelles pulse gently, slow rotation |
| `Q2W3prokaryoticCell.glb` | Same family as above — internal pulse + rotation |
| `Q2W4_mitosis_phases.glb` | Plays through phases prophase→telophase as a timeline (not idle-loop) |
| `Q2W5Fertilization_Model_Light.glb` | Sperm approaches/enters egg, looped |
| `Q2W6_amoeba_binary_fission.glb` | Cell stretches and splits into two, looped |
| `Q2W7_biological_organization.glb` | Zoom/scale sequence cell→tissue→organ→organism |
| `Q2W8_food_web.glb` | Energy-flow arrows pulse sequentially along the web |

### Quarter 3 — Force & motion / simple machines
| Model | Recommended animation |
|---|---|
| `Q3W1spring.glb` | Compress/extend oscillation loop |
| `Q3W2inclined_plane_slide_playground.glb` | Object rolls/slides down the ramp, looped |
| `Q3W3seesaw.glb` | Up-down rocking loop |
| `Q3W4compass.glb` | Needle spins then settles pointing north |
| `Q3W5Car.glb` | Wheels spin, idle drive-in-place loop |
| `Q3W6jeepney.glb` | Same as car |
| `Q3W7Termometer.glb` | Mercury/liquid column rises and falls, looped |
| `Q3W8Spoon.glb` | No natural motion — rely on the universal scan-in scale animation |

---

## Animation build log & standing rules

Live status of the per-model animation pass (built via Blender MCP, wired into Unity via UnityMCP — see [[ar-science-app-project-pair]]):

- ✅ `DemocritusAtom_Model01.glb` — scan-in + 30s electron orbit. Done, wired into Unity, verified, zoom-safe.
- ✅ `Q1W2waterpolarity.glb` — scan-in + slow molecule rotation + oxygen/hydrogen charge pulse. Wired into Unity, zoom-safe. Known issue: the Blender re-export corrupts two static wrapper node scales to 0 (patched directly in the Unity scene instance for now) — needs a Blender-side fix before the next re-export of this model.
- ✅ `Q1W3solid_liquid_gas.glb` — scan-in + per-phase idle motion (solid=vibration, liquid=sway, gas=jitter). Wired into Unity, zoom-safe. The stray embedded `DemocritusAtom` armature/mesh contamination was removed from the scene instance.
- ✅ `Q1W4_particle_motion_temperature.glb` — rebuilt as an orbit (8 particles on individual tilted pivots around a shared center, blue slow/wide = cold, red fast/tight = hot) after the first jitter-in-place pass was rejected (straight-line source layout made it look like twitching on a rail). Wired into Unity, zoom-safe.
- ✅ `Q1W6beakers.glb` — pointer line + staggered breathing pulse per beaker (100/250/500mL). Wired into Unity, zoom-safe.
- ✅ `Q1W7_saturated_unsaturated.glb` — saturated cup's 3 crystals settle once and stay static, unsaturated cup's 3 crystals continuously dissolve/reform on a staggered cycle. Wired into Unity, zoom-safe. Required unparenting the 6 crystals from a shared `SoluteArmature` first — see bug note below.
- ✅ `Q1W8salt_dissolving_in_water.glb` — group-level only (heavy ~98-piece model): crystal lattice (`green`/`purple` groups) shrinks over the loop, dispersed ion fragments (`group1`) get a gentle synchronized drift. Wired into Unity, zoom-safe. A pre-existing baked "Take 001" clip in the source file (reads as a Sketchfab "exploded view" animation, ~35+ unit swings) was excluded as contamination, same as the DemocritusAtom/ParticleArmature/SoluteArmature pattern below.

**Quarter 1 (chemistry, 7 models) complete as of 2026-09-02.**

- ✅ `Q2W1Microscope.glb` — scan-in + gentle ±8° swivel (single fused mesh, no separate parts). Wired into Unity, zoom-safe.
- ✅ `Q2W2plant_cell.glb` — scan-in + gentle membrane breathing pulse (initial rotation removed per client feedback). Wired into Unity, zoom-safe.
- ✅ `Q2W3prokaryoticCell.glb` — scan-in only, no idle motion (single fused mesh). Source asset was a 1.2M-vertex/1.37M-polygon mesh, decimated to ~54.8k polygons (~96% reduction) before animating — see Performance note below, not yet visually verified on-device. Wired into Unity, zoom-safe.
- 🟡 `Q2W4_mitosis_phases.glb` — see dedicated note below.
- ✅ `Q2W5Fertilization_Model_Light.glb` — 82 individual sperm each swim out-and-back toward the ovum's surface with randomized per-sperm timing (staggered, not synchronized). Wired into Unity, zoom-safe, Play-mode performance-checked (77-116fps across a 43s run, no hitching, no dip at the loop wrap). Ovum's intended breathing pulse hit the same unresolved bug as Q2W4 below — shipped static as a fallback per client call.
- ✅ `Q2W6_amoeba_binary_fission.glb` — 4-panel diagram (whole amoeba → nucleus dividing → fission pinching → two daughters), scale-pulse only (no position drift, learned from Q2W4) at increasing intensity across the panels. Wired into Unity, zoom-safe, confirmed genuinely oscillating for the full clip.
- ✅ `Q2W7_biological_organization.glb` — scan-in only, no idle motion (client's call — it's a static 13-level pyramid diagram, Biosphere→Atom). Source file has 3 complete duplicate cube sets stacked at the same position (contamination, not intentional) — flagged for Unity to strip if desired.
- ✅ `Q2W8_food_web.glb` — only the 3 food-chain arrow pairs pulse in a staggered sequence (energy-flow suggestion); all 5 creatures (bird/frog/snake/2 grasshoppers, 3 armatures) left untouched given the bone-parenting risk (grasshoppers use the same setup that caused the Q1W7 bug). Exported; not yet confirmed wired in Unity as of this writing.

**Quarter 2 (biology, 9 models) complete as of 2026-09-02**, pending final Unity confirmation on Q2W8.

- ✅ `Q3W1spring.glb` — continuous compress/extend bounce along the coil axis. Wired into Unity, zoom-safe, verified.
- ✅ `Q3W2inclined_plane_slide_playground.glb` — added a ball (no ball existed in the source) that repeatedly slides down the incline and resets. Path corrected once after the first guess was wrong direction — re-verified good by client.
- ✅ `Q3W3seesaw.glb` — whole assembly rocks ±12°, base/plank couldn't be reliably told apart from geometry. Wired into Unity, zoom-safe, verified.
- 🔁 `Q3W5Car.glb` — 4 named wheel objects spin + wheel-base smoke puffs added per client request. Went through several correction rounds: (1) rotation looked wrong to client, traced to wheels using `rotation_quaternion` with a baked 90° base tilt that got silently discarded when the animation script switched to Euler rotation; (2) a quaternion-based fix using only 2 keyframes turned out mathematically identical to no rotation (quaternion slerp only takes the shortest path, so N full 360° turns between 2 keyframes collapses to zero visible motion) — fixed with many fine-grained intermediate keyframes instead; (3) separately, Unity found every clip's first real keyframe started at t=1.033s not t=0, freezing wheels/smoke for ~2s after scan-in (same bug class as Q1W4). Client confirmed the rotation direction/axis is correct; startup-offset fix pending final confirmation.
- ✅ `Q3W4compass.glb` — needle spins twice then settles pointing north (part of intro), then a subtle continuous wobble. Wired into Unity, zoom-safe, verified. Source file has a stale duplicate clip on the needle, correctly excluded.
- ✅ `Q3W6jeepney.glb` — no separable wheel objects (fused body mesh), so whole-vehicle idle bob + sway instead. Wired into Unity, zoom-safe, verified.
- 🟡 `Q3W7Termometer.glb` — the animatable part is a flat "Display" quad (not a glass tube) — built as a level-gauge bar that fills/empties from one anchored edge. Exported, not yet confirmed wired in Unity.
- ✅ `Q3W8Spoon.glb` — scan-in only, no idle motion (single fused mesh, no natural motion). Exported, not yet confirmed wired in Unity.

**Quarter 3 (force & motion, 8 models) all built as of 2026-09-02.** Full 24-model animation pass now complete pending final Q3W7/Q3W8 Unity confirmations (Q3W5 fully resolved).

### Handover builds (2026-09-02)

- **Web (Teacher portal):** deployed to https://ar-science-explorer-57de3.web.app
- **Android APK:** `build/app/outputs/flutter-apk/app-debug.apk` (~827 MB, debug build)
- Both include: all 24 animated AR models, the zoom-in/out fix, Google/Microsoft teacher sign-in, password show/hide (both sides), reset-progress-for-all, AR marker upload (built-in + custom lessons), and a UI polish pass on the student home/learn/progress/quiz screens and the teacher dashboard.
- Google/Microsoft sign-in requires enabling those providers in Firebase Console (Authentication → Sign-in method) before they'll work — not yet done as of this build. Microsoft additionally needs an Azure AD app registration (client ID/secret) first; see chat history for exact steps.
- **Getting Unity's exported library to build inside this Flutter project required 3 Gradle config fixes**, each documented with inline comments at the fix site since Unity will re-introduce some of these on every future re-export:
  1. `android/unityLibrary/build.gradle` — Unity's own re-declared plugin versions conflicted with the root project's; stripped the version numbers, letting them resolve from the root.
  2. `android/settings.gradle.kts` — the real AAR-producing library module is nested one level deeper (`unityLibrary/unityLibrary/`) than what was included; added a `projectDir` remap.
  3. `android/gradle.properties` — the nested module needs several `unity.*` properties (SDK/NDK/JDK paths, versions) that only existed in the outer wrapper's own `gradle.properties`, which the remap in #2 stopped reading; copied them into the root file.
  4. `android/unityLibrary/unityLibrary/proguard-unity.txt` — Unity's `-ignorewarnings` line isn't allowed in a library's *consumer* proguard file under this AGP version; removed it.

### Verification gap: Editor-only testing, not the real embedded runtime

Every animation/zoom-safety/no-replay check done so far has happened **inside the Unity Editor** (Play mode or edit-mode sampling) — none of it has been verified through the actual `flutter_embed_unity` bridge running inside the real Flutter app on a device/emulator. Editor Play mode is a different runtime path than the embedded APK context (different lifecycle, input routing, and in some cases rendering pipeline). Before calling this build "done," a real end-to-end pass is required: Unity Android build export → drop into `android/unityLibrary` → build the Flutter APK → manually verify on a real device that animations play and rotate/zoom interactivity works through the actual embed, not just in the Editor in isolation.

### Lesson learned: quaternion vs Euler rotation animation

Objects imported with `rotation_mode = 'QUATERNION'` and a non-trivial base orientation (common for parts nested under rotated parents) **must stay in quaternion mode** when animated — switching to `'XYZ'` Euler and writing `rotation_euler` directly discards the base orientation silently. When animating a quaternion-mode object's spin: (1) capture and preserve the base quaternion, (2) compose the spin via quaternion multiplication (`base_quat @ Quaternion(axis, angle)`), and (3) use **many small-angle intermediate keyframes**, never just start/end — quaternion interpolation (slerp) only ever takes the shortest path between two keyframe values, so two keyframes spanning N full rotations are mathematically identical to zero rotation and produce no visible motion at all.

### Q2W4 mitosis — known unresolved bug

5-panel side-by-side diagram (interphase/prophase/metaphase/anaphase/telophase). Interphase/prophase/metaphase panels animate correctly (chromatin/chromosome/spindle-fiber pulses, confirmed oscillating for the full 30s clip in Unity). Anaphase and telophase's position-based "drift apart" motion (8 objects: `Nucleus.002`/`.003`, `CellMembrane.004`/`.005`, `Chromatin`×4) could not be made to work — an extensive debugging session (5+ full rebuild attempts, ruling out export-optimization flags, channel population, and cross-call state loss) confirmed the pre-bake keyframes are correct and all 3 position channels are fully populated in the export, but the *baked* curve values still collapse to a single settle-and-hold instead of oscillating, for reasons not root-caused. Shipped with those 8 objects **static** post-scan-in as a fallback (same treatment as models with no natural motion, e.g. the Q3W8 spoon) rather than keep chasing it. Worth a fresh look later with more budget.

**Quarter 1 (chemistry, 7 models) complete as of 2026-09-02.** Quarter 2 (biology, 9 models) starts with `Q2W1Microscope.glb`, pending client go-ahead.

### Known Blender/Unity bugs hit so far (fixed, but worth knowing the pattern)

1. **Sine-modifier collapse** (hit Q1W2, Q1W6): Blender's `FNGENERATOR` FCurve modifier defaults to *replacing* the base keyframed value instead of adding to it. Any "breathing pulse" animation using this modifier must explicitly set `use_additive = True`, or the pulse collapses toward/through zero instead of oscillating around the base value.
2. **Shared-armature curve merging** (hit Q1W7): source files sometimes bone-parent multiple objects to identically-named bones on one shared armature (e.g. 6 `Crystal_N` objects → 6 bones named `Crystal_N` on one `SoluteArmature`). This causes their exported/imported animation curves to merge/duplicate instead of staying independent. Fix: unparent the objects from the armature (keep transform) and delete the armature before animating.
3. **Stray contaminated rigs/clips** (hit Q1W3, Q1W4, Q1W8): several source files carry an unused leftover armature or a pre-existing baked animation clip (a "DemocritusAtom" armature+mesh, a "ParticleArmature," a "Take 001" exploded-view clip) that has nothing to do with the actual model content. These get deleted/excluded, not exported.
4a. **Leaf-object scale silently zeroed on re-export** (hit Q2W7, Q2W8, likely others not yet audited): in files with a single top-level scan-in clip and many *untouched* child/leaf objects, those untouched objects' own rest scale (and sometimes position) gets silently zeroed by the Blender→glTF re-export, even though nothing in the animation script ever touches them and the original source file has correct values. Confirmed via direct diff against the original un-animated asset. On Q2W8 specifically this was severe enough that reparenting an **armature** object under a new wrapper caused Blender's own glTF *importer* to crash on re-import with a division-by-zero (bone length ÷ armature scale, when that scale was zeroed to 0) — Unity's importer tolerated it after a full recursive diff-patch (down through bones), but this is fragile. Currently patched per-model on the Unity side by a recursive diff-and-restore against the original asset. **This and #4 below are almost certainly the same root cause** (Blender's exporter mishandling "rest" transforms whenever a new parent node is introduced above existing content) manifesting at different depths depending on the file's structure — the single most recurring bug category across this whole build. Worth a dedicated root-cause pass rather than continued per-model patching.
4. **Corrupted wrapper-node scale on re-export** (hit Q1W2, Q1W8, Q2W1 so far, worsening each time — 197/202 nodes affected on Q1W8): Blender's glTF importer (`io_scene_gltf2`) always inserts an extra organizational wrapper node on import that isn't present in the original file (a `Sketchfab_model` empty, even on Q2W1Microscope whose real, un-Blender-touched glb has no such node at all — so this is a Blender-importer behavior, not specific to Sketchfab-sourced assets as first suspected). Re-exporting through that extra wrapper level zeroes out the static (non-animated) scale of some descendant node(s) one level deeper. Currently patched per-model in the Unity scene instance by diffing against the original un-animated glb and restoring correct values. **Not yet root-caused at the source** — worth investigating Blender's glTF export settings (possibly an "export at root" / apply-transform option) when there's time for a proper fix; the workaround holds for now.

### Performance note

`Q2W3prokaryoticCell.glb`'s source asset was a single 1.2-million-vertex / 1.37-million-polygon mesh — dramatically heavier than every other model (which top out ~30k-100k). Decimated in Blender to ~54.8k polygons (~96% reduction) before animating. Worth a real on-device check once wired up to confirm it still looks acceptable — geometry reduction this aggressive can visibly soften fine detail depending on the model, and this wasn't verified visually beyond the vertex/polygon counts. If it looks bad on-device, worth re-decimating at a gentler ratio or asking the client for a lighter source asset.

### Rest of the queue

⏳ Quarter 2 (biology, 9 models) + Quarter 3 (force & motion, 8 models) — not started; going in file order, one at a time, proposing animation options to the client before building each.

**Standing rule (confirmed 2026-09-02): the scan-in must play exactly once per marker detection, never replay on every loop of the idle animation.** In Unity this means every animated model needs a 2-state Animator, not one merged clip:
- A one-shot **ScanIn** state (`loopTime = false`).
- Transitions (exit-time = 1.0, duration = 0) into a looping **Idle** state (`loopTime = true`) that holds the model's resting pose forever after.
- The idle clip must explicitly hold/redrive any transform property the scan-in clip animated (e.g. root scale = 1, rotation = identity) — Mecanim resets any property not driven by the *current* state's clip back to bind pose on a state switch, so an idle clip that's silent on a property the intro touched will snap it back to its bind-pose value (this bit us once on the Democritus nucleus scale, which silently zeroed out). Apply this same pattern to every model going forward, not just Democritus.

**Second standing rule (confirmed 2026-09-02): Animator curves must never target the prefab's root transform (path `""`), only a child named `VisualRoot`.** The root transform is `MobileARController`'s territory — it writes `transform.localScale = _initialScale * zoomMultiplier` there every frame for pinch-zoom. An Animator curve animating that same root scale fights the zoom system: the animation's absolute 0→1 curve overrides the per-model zoom baseline captured in `Awake()`, breaking zoom on that model. Convention going forward: all visual content is reparented one level down under a child object literally named `VisualRoot`; ScanIn/Idle clips animate `VisualRoot`, never the root. (Democritus happened to be safe by accident because its scan-in already targeted a child, `DemocritusAtom_Root`, not the prefab root — Q1W2/Q1W3 were not, and got fixed after the fact.)

---

## Notes on source

Some detail above (esp. the Unity/Flutter blocking issue and the zoom-bug root cause) came from a voice message the client sent that was manually transcribed into chat by the developer, not a written spec — confirm exact wording/scope against the client's paper docs before treating it as final.

---

## 2026-09-04 — Round 2 test feedback

Relayed by the client as Taglish typed notes after a live test pass. Translated/organized here; not yet actioned.

- [ ] **Model info descriptions**: only the `Beaker` model currently shows its (text) description on scan. The other models are scaled too large to zoom out far enough to see it — likely the same root cause as the existing zoom bug (see item 3, section "Student side features / bugs" above). Audio description does play correctly for all of them already.
- [ ] **PDF upload broken**: tried every function on the client's end, upload of the PDF fails outright. (Content-upload path, not the AR scanner — likely `lib/features/teacher/lessons/lesson_form.dart` or the new `builtin_lesson_marker_sheet.dart`.)
- [ ] **Some models fail to scan entirely** — separate bug from the PDF upload issue and from the per-lesson restriction feature below.
- [ ] **New feature: per-lesson model restriction.** The scanner should only accept the marker matching the lesson currently open — e.g. in Lesson 1 (topic: Atom), only the `DemocritusAtom_Model01` target should scan; every other target should be rejected while that lesson is active.
- [ ] **New feature: wrong-model error message.** If the student scans a marker that isn't the active lesson's model, show an explicit message (e.g. "Sorry, this isn't your lesson's model") instead of silently failing or doing nothing.
- [ ] Non-matching models are currently **not visible/readable and not animated** — expected for now, tracked by the existing per-model animation build log above; will resolve as that restriction feature (previous bullet) and the animation pass both land.
- [ ] **Remove the debug banner top-right of the app.** Professor noticed it during a demo. Almost certainly Flutter's default red "DEBUG" corner ribbon (`debugShowCheckedModeBanner` isn't set anywhere in `lib/` — confirmed via search) — one-line fix (`debugShowCheckedModeBanner: false`) on each `MaterialApp` (`lib/main.dart`, `lib/features/student/auth/student_login_screen.dart`, and wherever `student_theme.dart`'s app shell is built).
- [ ] **Re-insert target image into the system, student side** — same as a previous handover step; client wants it done again for this test round.

### Round 2 fixes shipped (2026-09-04, Flutter-only, tests passing)

- ✅ Debug banner removed from both student-side `MaterialApp`s (`lib/main.dart`, `student_login_screen.dart`) — teacher side (`ShadApp`) already had it off by default.
- ✅ PDF/PPTX upload no longer hangs forever on a stalled transfer — `FirebaseStorageUploader.upload()` now times out at 60s with a clear, retryable error toast.
- ✅ The lesson's printable marker image now shows in the Scan tab's "Point your camera..." overlay, so students see what to scan before anything's detected.

## 2026-09-04 — Round 3 feedback (Messenger, UAT with teachers)

- [ ] **Access code redemption is broken** — client/teachers tried it during UAT and it didn't work. No repro details yet (which code type — lesson unlock, subject unlock, quiz retake; which screen; what error or behavior was seen). `AccessCodeService.redeem()` (`lib/core/services/access_code_service.dart`) has 6 separate code-type branches — need specifics before touching it, this is stateful Firestore logic with real blast radius if changed blind.
- ✅ **Item analysis — already built, matches the ask exactly.** `lib/features/teacher/quizzes/item_analysis_screen.dart` already shows per-question difficulty %, discrimination index, distractor rates, and a bar chart, driven by `item_analysis_calculator.dart` — this is what the client tested in UAT and is asking to keep ("*huwag niyo po tanggalin yung graph don*" — don't remove the graph there). Treat as a **do-not-regress** item, not a new build.
- [ ] Teachers' other UAT suggestions on item analysis — not yet detailed beyond "keep the graph"; ask for the specific suggestions list before changing anything on this screen.

## 2026-09-04 — VuforiaAR root cause found + fixed (only Beaker scanned/showed a description)

**Root cause:** every one of the 23 `ImageTarget` GameObjects in `Assets/Scenes/SampleScene.unity` carries an `ARTargetVisibilityAndInteraction` component whose `modelRoot` field must point at that target's own model child. Only `Quarter1Week6` (the Beaker lesson) had it wired up; the other 22 were left `null`. That component's `HandleTargetFound`/`HandleTargetLost` both early-return when `modelRoot` is null — so for every other marker: the model never activated, its Animators never restarted, and critically `SendToFlutter.Send(...)` never fired, meaning Flutter's `detectedLesson` never updated and the description overlay never appeared. This explained every symptom (not visible, not animated, no description) with one cause — not a Vuforia recognition problem, not a naming problem, not a Flutter bug. The target database (`my-ar-targets.xml`) and the trackable-name→lesson regex (`marker_mapping.dart`) were both independently verified correct beforehand.

**Fix (via Unity MCP, live Editor):** every `ImageTarget` already had its own model as an inactive-by-default child (e.g. `Q1W8salt_dissolving_in_water`, `DemocritusAtom_Model01`) alongside a `ImageTargetPreviewRoot` placeholder — same shape as the working Beaker reference. Programmatically wired `modelRoot` on all 22 remaining targets to their own model child, saved the scene, and confirmed on disk (all 23 now hold a real `fileID`, none `{fileID: 0}`). Verified live: calling `HandleTargetFound()`/`HandleTargetLost()` on a previously-broken target (`Quarter1Week1` / Democritus) now correctly activates/deactivates its model, with no console errors.

**Not yet verified:** on a real device through the actual Vuforia camera pipeline + the live `flutter_embed_unity` bridge — this fix has only been confirmed by directly invoking the handler methods in the Editor, not by physically scanning a printed marker. Needs a real build to fully close out.

**Side note on the "models too large / can't zoom out" complaint:** the earlier build log above already recorded per-model zoom-safety verification for all 24 models (search "zoom-safe" above) before this `modelRoot` regression happened — the presence of an `Assets/_Recovery/` folder full of old scene copies suggests a scene crash/recovery event is the likely point where 22 of 23 `modelRoot` references got reset to null. If that's what happened, restoring `modelRoot` should have restored the already-verified zoom behavior for free, not left a separate zoom bug behind — but this is inferred from evidence, not confirmed by a device test, so don't treat it as closed until someone actually re-scans a previously "too large" marker.

## 2026-09-04 — Per-lesson scan restriction + wrong-model error (built, both repos)

Implements the client's explicit ask: "for Lesson 1 (Atom), only the Atom marker should scan — every other marker should be rejected while that lesson is open," plus the wrong-model error message.

- **Unity (`VuforiaAR`):** new `ARSessionManager.cs` (attached to a scene GameObject of the same name) holds the currently-allowed marker fragment (e.g. `"Q1W1"`), settable from Flutter via `sendToUnity("ARSessionManager", "SetActiveLesson", ...)`. `ARTargetVisibilityAndInteraction.HandleTargetFound`/`HandleTargetLost` now check it before doing anything — a mismatched marker never activates its model/animation and instead sends a new `{"event":"wrongModel","trackableName":"..."}` message to Flutter; an empty/null fragment means no restriction (unchanged behavior for lessons with no curriculum placement). Verified live in the Editor: right lesson → model activates normally; wrong lesson → stays inactive and gated; no restriction set → both scan normally. No console errors.
- **Flutter (`ARwebmob`):** `ArLabViewModel` now exposes `quarter`/`week` and a computed `activeLessonFragment` (`"Q<quarter>W<week>"`, `null` when the lesson has no placement). `ScanTab` sends that fragment to Unity once camera permission is granted (and clears it on dispose, so leaving a lesson doesn't leak its restriction into the next one), and shows a new self-dismissing red banner — "Sorry, that's not this lesson's model." — on a `wrongModel` event.
- **Tests:** 8 new tests added (`ar_lab_providers_test.dart`, `scan_tab_test.dart`) covering the fragment computation, the exact Unity bridge calls sent/cleared, and the wrong-model banner showing/auto-dismissing. Full suite: 265 passing, same 14 pre-existing unrelated failures as before.
- **Not yet verified on a real device** — same caveat as the `modelRoot` fix above.

**Scoping question the client asked (answered by dev, not the client):** whether to bring in Unity MCP / Blender MCP against `VuforiaAR` now, since that's where the scanner/APK-side behavior (per-lesson restriction, model visibility, wrong-model error, description panel scaling) actually lives. Decision: **hold off on VuforiaAR/Unity MCP for now — focus on `ARwebmob` (Flutter: mobile + teacher) first** per the client's explicit ask; revisit VuforiaAR once the Flutter-side items (PDF upload, debug banner, target-image re-insertion) are handled, since several of the AR-behavior items (per-lesson restriction, wrong-model error, description-panel zoom) need Unity-side work regardless and should be scoped together rather than piecemeal.
