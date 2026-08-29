# Task 1 brief — Add Phase 4 dependencies

(Copied verbatim from `docs/superpowers/plans/2026-08-29-phase4-teacher-web.md`, Task 1.)

**Files:** Modify `pubspec.yaml`.

**Interfaces:** None — this task adds no code, only makes packages
resolvable for later tasks. Not independently testable (same rationale as
Phase 3 Task 1: a dependency with no code using it yet has nothing to
assert against).

- [ ] **Step 1:** Add to `pubspec.yaml` dependencies: `shadcn_ui: ^0.x.x`,
  `data_table_2: ^2.x.x`, `lucide_icons_flutter: ^3.x.x`,
  `flutter_form_builder: ^9.x.x`, `form_builder_validators: ^11.x.x`,
  `model_viewer_plus: ^1.x.x` — check pub.dev for each package's actual
  latest version before writing it in (Phase 3 hit a real version mismatch
  doing this from memory; don't repeat that).
- [ ] **Step 2:** Run `flutter pub get`, confirm it resolves with no
  conflicts against the existing Riverpod/Firebase/go_router versions.
- [ ] **Step 3:** Run `flutter test` (full suite) — expect all existing
  tests still pass unchanged; this step only proves the dependency add
  didn't break anything already built.
- [ ] **Step 4:** Commit: `deps: add Teacher Web UI packages (Phase 4)`.
