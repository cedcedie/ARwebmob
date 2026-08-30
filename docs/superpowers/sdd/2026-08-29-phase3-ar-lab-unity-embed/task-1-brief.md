# Task 1: Flutter dependencies for AR + voice

**Files:** Modify `pubspec.yaml`.

**Interfaces produced:** `flutter_embed_unity`, `flutter_embed_unity_6000_0_android`,
`flutter_tts` available as imports for every later task in this plan.

## Steps

1. Add under `dependencies:`:
   ```yaml
   flutter_embed_unity: ^2.0.0
   flutter_embed_unity_6000_0_android: ^2.0.0
   flutter_tts: ^4.2.0
   ```
   (Plan's original guess of `^0.7.0` for both flutter_embed_unity packages
   does not exist on pub.dev — verified real latest is `2.0.0` for both via
   a live pub.dev fetch before editing.)
2. Run `flutter pub get`, confirm clean resolution.
3. Run `flutter test`, confirm all pre-existing tests still pass (no new
   tests expected — adding a dependency with no consuming code isn't
   independently testable).
4. Commit `pubspec.yaml`/`pubspec.lock`.

**Note:** this task was executed directly by the controller (me), not
dispatched to a subagent — it's a single-file, single-command mechanical
change with no design judgment involved.
