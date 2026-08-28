# Phase 1: Scaffold, Core Models, Auth — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the Flutter project skeleton, the shared `core/` data layer
(models, quiz-id scheme, role-inferred auth, student repository), all wired to
a real Firebase project — with no screens beyond a placeholder shell yet. This
is the foundation every later phase (student flow, AR embed, teacher web)
builds on.

**Architecture:** Feature-first `lib/` layout with a `core/` package shared by
both build targets (`student/`, `teacher/`, not created until Phase 2/4).
Models are `freezed` + `json_serializable`, field names copied verbatim from
the existing production schema so they round-trip with the real Firestore
documents already in use. Auth role inference and the student-ID → email
construction are pure functions, unit-tested without touching real Firebase.
The student repository uses `cloud_firestore`, unit-tested against
`fake_cloud_firestore` so the whole phase is testable without a live project.

**Tech Stack:** Flutter (stable channel), Dart ^3.12, `firebase_core`,
`firebase_auth`, `cloud_firestore`, `freezed`, `json_serializable`,
`flutter_riverpod`, `build_runner`; dev/test only: `fake_cloud_firestore`,
`firebase_auth_mocks`.

**Spec:** `docs/superpowers/specs/2026-08-28-flutter-ar-science-explorer-design.md`
(also read `PROJECT_FLOW.md` at repo root — it is the field-for-field data
model and business-rule source; this plan does not restate its content, only
implements it).

## Global Constraints

- Project root for `flutter create` is the repo root (`ARwebmob/`) — do not
  nest the Flutter project in a subfolder.
- Package/app name: `ar_science_explorer`.
- Model field names must exactly match `PROJECT_FLOW.md` Part 4.1's TypeScript
  types (camelCase, e.g. `modelIndex`, `isUnlockedByDefault`,
  `completedLessonIds`) — these are live production Firestore field names,
  not free to rename.
- Student email construction is always `{6 plain digits}@arscience.school` —
  no dash, ever, in the actual Auth email (Design Spec Section 2, resolved
  Q5). The `NN-NNNN` display format is a UI concern for a later phase, not
  built here.
- `/students/{studentId}` — the Firestore document ID is the plain
  `studentId` string, not the Firebase Auth `uid` (confirmed against
  `ar-science-explorer/src/lib/storage.ts`'s `saveStudent`).
- No AR/Unity work in this phase — `student/ar_lab/` does not get created
  here.
- This phase does not require Firestore security-rule changes or the actual
  Unity project; the only external dependency is a working Firebase project
  connection, tracked as a manual step (see below).
- **Manual step required before Task 2 can be verified against a real
  project:** running `flutterfire configure` (or being handed
  `google-services.json`) is tracked in `MANUAL_STEPS.md` — do not duplicate
  that checklist here. Task 2 stubs a placeholder `firebase_options.dart` so
  the rest of the phase's tests (which use fakes, not a live project) are not
  blocked on it.

---

## File Structure

```
pubspec.yaml                         # deps: firebase_core, firebase_auth, cloud_firestore,
                                      #       freezed_annotation, json_annotation, flutter_riverpod
                                      # dev: build_runner, freezed, json_serializable,
                                      #      fake_cloud_firestore, firebase_auth_mocks
lib/
  main.dart                          # Firebase.initializeApp + kIsWeb shell branch (placeholder screens)
  firebase_options.dart              # placeholder (manual flutterfire configure replaces it later)
  core/
    models/
      subject_key.dart               # SubjectKey enum
      question_type.dart             # QuestionType enum
      quiz_phase.dart                 # QuizPhase enum
      curriculum_content.dart        # CurriculumContent (freezed)
      ar_payload.dart                 # ARPayload (freezed)
      lesson.dart                     # Lesson (freezed)
      quiz_attempt.dart               # QuizAttempt (freezed)
      quiz_unlock_code.dart          # QuizUnlockCode (freezed)
      teacher_quiz_question.dart     # TeacherQuizQuestion (freezed)
      teacher_quiz.dart               # TeacherQuiz (freezed)
      teacher_lesson.dart            # TeacherLesson (freezed)
      built_in_question.dart         # BuiltInQuestion (freezed)
      student_record.dart            # StudentRecord (freezed)
    quiz_id.dart                      # parseBuiltinId / builtinQuizId
    services/
      auth_service.dart               # role inference, email construction, Firebase Auth wrapper
      student_repository.dart        # Firestore CRUD for /students/{studentId}
test/
  core/
    quiz_id_test.dart
    models/
      lesson_test.dart
      student_record_test.dart
    services/
      auth_service_test.dart
      student_repository_test.dart
  widget_test.dart                    # smoke test for main.dart shell branch
```

---

### Task 1: Scaffold the Flutter project and dependencies

**Files:**
- Create: `pubspec.yaml` (via `flutter create`, then edited)
- Create: (generated) `lib/main.dart`, `android/`, `web/`, `test/widget_test.dart`

**Interfaces:**
- Produces: a runnable `flutter create` skeleton at repo root, with
  dependencies available for every later task in this plan.

- [ ] **Step 1: Run `flutter create` at the repo root**

Run:
```bash
flutter create --project-name ar_science_explorer --org com.arscience --platforms android,web .
```
Run this from `ARwebmob/` itself (the `.` target). This will not overwrite
`PRODUCT.md`, `PROJECT_FLOW.md`, `MANUAL_STEPS.md`, `docs/`, or `assets/` —
`flutter create` only adds Flutter scaffolding files, it does not delete
existing ones.

- [ ] **Step 2: Verify the scaffold builds**

Run: `flutter pub get`
Expected: completes with no errors, `pubspec.lock` created.

- [ ] **Step 3: Add production dependencies**

Edit `pubspec.yaml`, add under `dependencies:`:
```yaml
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  flutter_riverpod: ^2.6.1
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
```

- [ ] **Step 4: Add dev/test dependencies**

Edit `pubspec.yaml`, add under `dev_dependencies:`:
```yaml
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  fake_cloud_firestore: ^3.1.0
  firebase_auth_mocks: ^0.14.1
```

- [ ] **Step 5: Fetch dependencies**

Run: `flutter pub get`
Expected: resolves cleanly. If `fake_cloud_firestore`/`firebase_auth_mocks`
version conflicts appear, run `flutter pub outdated` and bump to the latest
mutually-compatible versions — the exact patch numbers above are a known-good
starting point, not a hard pin.

- [ ] **Step 6: Add the assets to pubspec.yaml**

Edit `pubspec.yaml`'s `flutter:` section:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/markers/
    - assets/models/
    - assets/lessons/
```

- [ ] **Step 7: Commit**

```bash
git init
git add .
git commit -m "chore: scaffold ar_science_explorer Flutter project"
```

(This repo had no git history yet — `git init` here is the first commit for
the whole project. If a `.git` already exists by the time this runs, skip
`git init` and just commit.)

---

### Task 2: Firebase bootstrap (placeholder config, real init call)

**Files:**
- Create: `lib/firebase_options.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- Produces: `DefaultFirebaseOptions.currentPlatform` (a `FirebaseOptions`
  getter) and an app entry point that calls
  `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
  before `runApp`.
- Consumes: nothing from earlier tasks.

- [ ] **Step 1: Write a placeholder `firebase_options.dart`**

This file is normally generated by `flutterfire configure` against the real
Firebase project (tracked in `MANUAL_STEPS.md`). Until that's run, use a
placeholder so the rest of the app compiles; every later task's tests use
fakes and do not depend on these values being real.

```dart
// lib/firebase_options.dart
//
// PLACEHOLDER — replace by running `flutterfire configure` and selecting
// the existing ar-science-explorer Firebase project (see MANUAL_STEPS.md).
// Do not fill these in by hand; flutterfire configure generates the exact
// values (including platform-specific appId/apiKey) correctly.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'firebase_options.dart is a placeholder — run `flutterfire configure` '
        '(see MANUAL_STEPS.md) before running the web target.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'firebase_options.dart is a placeholder — run `flutterfire configure` '
          '(see MANUAL_STEPS.md) before running the Android target.',
        );
      default:
        throw UnsupportedError(
          '${defaultTargetPlatform.name} is not a supported platform for this app.',
        );
    }
  }
}
```

- [ ] **Step 2: Wire Firebase init into `main.dart`**

```dart
// lib/main.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ArScienceExplorerApp());
}

class ArScienceExplorerApp extends StatelessWidget {
  const ArScienceExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Science Explorer',
      home: Scaffold(
        body: Center(
          child: Text(
            kIsWeb ? 'Teacher shell (placeholder)' : 'Student shell (placeholder)',
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Update the smoke test**

`flutter create` generated `test/widget_test.dart` referencing a counter app
that no longer exists — replace its contents:

```dart
// test/widget_test.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/main.dart';

void main() {
  testWidgets('shows a placeholder shell without crashing', (tester) async {
    await tester.pumpWidget(const ArScienceExplorerApp());

    final expectedText = kIsWeb
        ? 'Teacher shell (placeholder)'
        : 'Student shell (placeholder)';
    expect(find.text(expectedText), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS (1 test). Note this test does not call `Firebase.initializeApp`
(it pumps `ArScienceExplorerApp` directly without running `main()`), so the
placeholder `firebase_options.dart` throwing is never hit here.

- [ ] **Step 5: Commit**

```bash
git add lib/firebase_options.dart lib/main.dart test/widget_test.dart
git commit -m "feat: Firebase bootstrap with placeholder options and smoke test"
```

---

### Task 3: Core enums — `SubjectKey`, `QuestionType`, `QuizPhase`

**Files:**
- Create: `lib/core/models/subject_key.dart`
- Create: `lib/core/models/question_type.dart`
- Create: `lib/core/models/quiz_phase.dart`
- Test: `test/core/models/subject_key_test.dart`

**Interfaces:**
- Produces: `enum SubjectKey { chemistry, biology, physics }` with
  `SubjectKey.fromFirestore(String)` and `String get firestoreValue`.
  `enum QuestionType { mc, tf }` with the same pair of methods, where an
  unrecognized/missing value defaults to `QuestionType.mc` (Design Spec /
  PROJECT_FLOW.md Part 4.1: "Absent type is treated as 'mc' everywhere").
  `enum QuizPhase { pre, post }` with the same pair, where an
  unrecognized/missing value defaults to `QuizPhase.post` (PROJECT_FLOW.md
  Part 4.1: "Absent ⇒ treated as 'post' for legacy quizzes").
- Consumes: nothing.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/models/subject_key_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/question_type.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';

void main() {
  group('SubjectKey', () {
    test('round-trips known values', () {
      expect(SubjectKey.fromFirestore('chemistry'), SubjectKey.chemistry);
      expect(SubjectKey.chemistry.firestoreValue, 'chemistry');
      expect(SubjectKey.fromFirestore('biology'), SubjectKey.biology);
      expect(SubjectKey.fromFirestore('physics'), SubjectKey.physics);
    });
  });

  group('QuestionType', () {
    test('defaults to mc when absent or unrecognized', () {
      expect(QuestionType.fromFirestore(null), QuestionType.mc);
      expect(QuestionType.fromFirestore('bogus'), QuestionType.mc);
      expect(QuestionType.fromFirestore('tf'), QuestionType.tf);
      expect(QuestionType.tf.firestoreValue, 'tf');
    });
  });

  group('QuizPhase', () {
    test('defaults to post when absent or unrecognized', () {
      expect(QuizPhase.fromFirestore(null), QuizPhase.post);
      expect(QuizPhase.fromFirestore('bogus'), QuizPhase.post);
      expect(QuizPhase.fromFirestore('pre'), QuizPhase.pre);
      expect(QuizPhase.pre.firestoreValue, 'pre');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/models/subject_key_test.dart`
Expected: FAIL — files under `lib/core/models/` don't exist yet.

- [ ] **Step 3: Implement the three enums**

```dart
// lib/core/models/subject_key.dart
enum SubjectKey {
  chemistry,
  biology,
  physics;

  static SubjectKey fromFirestore(String value) {
    return SubjectKey.values.firstWhere(
      (v) => v.name == value,
      orElse: () => throw ArgumentError('Unknown SubjectKey: $value'),
    );
  }

  String get firestoreValue => name;
}
```

```dart
// lib/core/models/question_type.dart
enum QuestionType {
  mc,
  tf;

  /// Absent or unrecognized ⇒ 'mc' (back-compat with existing data —
  /// PROJECT_FLOW.md Part 4.1).
  static QuestionType fromFirestore(String? value) {
    return QuestionType.values.firstWhere(
      (v) => v.name == value,
      orElse: () => QuestionType.mc,
    );
  }

  String get firestoreValue => name;
}
```

```dart
// lib/core/models/quiz_phase.dart
enum QuizPhase {
  pre,
  post;

  /// Absent or unrecognized ⇒ 'post' (legacy quizzes — PROJECT_FLOW.md
  /// Part 4.1).
  static QuizPhase fromFirestore(String? value) {
    return QuizPhase.values.firstWhere(
      (v) => v.name == value,
      orElse: () => QuizPhase.post,
    );
  }

  String get firestoreValue => name;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/models/subject_key_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/models/subject_key.dart lib/core/models/question_type.dart \
        lib/core/models/quiz_phase.dart test/core/models/subject_key_test.dart
git commit -m "feat: SubjectKey, QuestionType, QuizPhase enums with back-compat defaults"
```

---

### Task 4: `quiz_id.dart` — `builtinQuizId` / `parseBuiltinId`

**Files:**
- Create: `lib/core/quiz_id.dart`
- Test: `test/core/quiz_id_test.dart`

**Interfaces:**
- Consumes: `QuizPhase` (Task 3).
- Produces: `String builtinQuizId(String lessonId, QuizPhase phase)` and
  `ParsedBuiltinId parseBuiltinId(String quizId)`, where
  `ParsedBuiltinId` is `({bool isBuiltin, String? lessonId, QuizPhase phase})`
  — a Dart record type. Later tasks (Phase 2's quiz screens) call
  `parseBuiltinId` to recover a lesson id and phase from a quiz id string.

- [ ] **Step 1: Write the failing test**

Ported directly from `ar-science-explorer/src/lib/quizId.ts`'s scheme
(`builtin-{lessonId}-pre` / `-post`, unsuffixed legacy ids treated as post):

```dart
// test/core/quiz_id_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/quiz_id.dart';

void main() {
  test('builtinQuizId builds phase-scoped ids', () {
    expect(builtinQuizId('q1w1', QuizPhase.pre), 'builtin-q1w1-pre');
    expect(builtinQuizId('q1w1', QuizPhase.post), 'builtin-q1w1-post');
  });

  test('parseBuiltinId parses a pre-test id', () {
    final parsed = parseBuiltinId('builtin-q1w1-pre');
    expect(parsed.isBuiltin, true);
    expect(parsed.lessonId, 'q1w1');
    expect(parsed.phase, QuizPhase.pre);
  });

  test('parseBuiltinId parses a post-test id', () {
    final parsed = parseBuiltinId('builtin-q2w5-post');
    expect(parsed.isBuiltin, true);
    expect(parsed.lessonId, 'q2w5');
    expect(parsed.phase, QuizPhase.post);
  });

  test('parseBuiltinId treats a legacy unsuffixed id as post', () {
    final parsed = parseBuiltinId('builtin-q1w1');
    expect(parsed.isBuiltin, true);
    expect(parsed.lessonId, 'q1w1');
    expect(parsed.phase, QuizPhase.post);
  });

  test('parseBuiltinId reports non-builtin ids with a null lessonId', () {
    final parsed = parseBuiltinId('teacher-quiz-abc123');
    expect(parsed.isBuiltin, false);
    expect(parsed.lessonId, null);
    expect(parsed.phase, QuizPhase.post);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/quiz_id_test.dart`
Expected: FAIL — `lib/core/quiz_id.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/core/quiz_id.dart
import 'models/quiz_phase.dart';

/// Result of parsing a quiz id string. Non-builtin (teacher-authored) quiz
/// ids return `lessonId: null`; `phase` still defaults to `post` in that case
/// but callers should check `isBuiltin` before relying on it.
typedef ParsedBuiltinId = ({bool isBuiltin, String? lessonId, QuizPhase phase});

const String _prefix = 'builtin-';
const String _preSuffix = '-pre';
const String _postSuffix = '-post';

/// Build a phase-scoped built-in quiz id for a lesson, e.g.
/// `builtinQuizId('q1w1', QuizPhase.pre)` → `'builtin-q1w1-pre'`.
String builtinQuizId(String lessonId, QuizPhase phase) {
  return '$_prefix$lessonId-${phase.firestoreValue}';
}

/// Parse a quiz id string. Mirrors `parseBuiltinId` from the retired web
/// app's `src/lib/quizId.ts` exactly — a legacy unsuffixed built-in id
/// (`builtin-{lessonId}`, no `-pre`/`-post`) is treated as a post-test.
ParsedBuiltinId parseBuiltinId(String quizId) {
  if (!quizId.startsWith(_prefix)) {
    return (isBuiltin: false, lessonId: null, phase: QuizPhase.post);
  }
  final rest = quizId.substring(_prefix.length);
  if (rest.endsWith(_preSuffix)) {
    return (
      isBuiltin: true,
      lessonId: rest.substring(0, rest.length - _preSuffix.length),
      phase: QuizPhase.pre,
    );
  }
  if (rest.endsWith(_postSuffix)) {
    return (
      isBuiltin: true,
      lessonId: rest.substring(0, rest.length - _postSuffix.length),
      phase: QuizPhase.post,
    );
  }
  // Legacy unsuffixed id — the whole remainder is the lessonId.
  return (isBuiltin: true, lessonId: rest, phase: QuizPhase.post);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/quiz_id_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/quiz_id.dart test/core/quiz_id_test.dart
git commit -m "feat: port builtinQuizId/parseBuiltinId scheme from retired web app"
```

---

### Task 5: `CurriculumContent` and `ARPayload` models

**Files:**
- Create: `lib/core/models/curriculum_content.dart`
- Create: `lib/core/models/ar_payload.dart`
- Test: `test/core/models/ar_payload_test.dart`

**Interfaces:**
- Produces: `CurriculumContent` and `ARPayload` freezed classes, each with
  generated `fromJson`/`toJson`. Consumed by `Lesson` and `TeacherLesson`
  (Tasks 6 and 8).
- Consumes: nothing beyond `freezed_annotation`/`json_annotation`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/models/ar_payload_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/ar_payload.dart';
import 'package:ar_science_explorer/core/models/curriculum_content.dart';

void main() {
  test('ARPayload round-trips the Q1W1 Democritus Atom payload verbatim', () {
    // Real data from PROJECT_FLOW.md Part 6.0.1.
    final json = {
      'modelIndex': 0,
      'detectionMode': 'marker',
      'anchorHint': 'q1w1',
      'lessonSteps': <String>[],
      'title': 'Democritus Atom',
      'subtitle': 'Ancient Greek Atomic Theory (c. 400 BCE)',
      'description':
          'Democritus proposed that all matter consists of tiny, indivisible '
              'particles called "atomos".',
      'keyIdeas': [
        'Smallest, indestructible building blocks of matter',
        'Particles in constant, random motion',
        'Differ in shape and size',
        'Form all materials in the universe',
      ],
    };

    final payload = ARPayload.fromJson(json);

    expect(payload.modelIndex, 0);
    expect(payload.detectionMode, 'marker');
    expect(payload.title, 'Democritus Atom');
    expect(payload.keyIdeas, hasLength(4));
    expect(payload.historicalImpact, isNull);
    expect(payload.toJson()['title'], 'Democritus Atom');
  });

  test('CurriculumContent round-trips with all-optional fields absent', () {
    final content = CurriculumContent.fromJson(const {});
    expect(content.standards, isNull);
    expect(content.learningCompetencies, isNull);
    expect(content.integration, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/models/ar_payload_test.dart`
Expected: FAIL — files don't exist yet.

- [ ] **Step 3: Implement `CurriculumContent`**

```dart
// lib/core/models/curriculum_content.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'curriculum_content.freezed.dart';
part 'curriculum_content.g.dart';

@freezed
class CurriculumIntegration with _$CurriculumIntegration {
  const factory CurriculumIntegration({
    List<String>? qualities,
    String? description,
  }) = _CurriculumIntegration;

  factory CurriculumIntegration.fromJson(Map<String, dynamic> json) =>
      _$CurriculumIntegrationFromJson(json);
}

@freezed
class CurriculumContent with _$CurriculumContent {
  const factory CurriculumContent({
    String? standards,
    String? performanceStandards,
    List<String>? learningCompetencies,
    List<String>? objectives,
    String? contentDetails,
    CurriculumIntegration? integration,
  }) = _CurriculumContent;

  factory CurriculumContent.fromJson(Map<String, dynamic> json) =>
      _$CurriculumContentFromJson(json);
}
```

- [ ] **Step 4: Implement `ARPayload`**

```dart
// lib/core/models/ar_payload.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ar_payload.freezed.dart';
part 'ar_payload.g.dart';

@freezed
class ARPayload with _$ARPayload {
  const factory ARPayload({
    required int modelIndex,
    required String detectionMode, // 'marker' | 'surface'
    required String anchorHint,
    required List<String> lessonSteps,
    String? markerImage,
    String? title,
    String? subtitle,
    String? description,
    List<String>? keyIdeas,
    List<String>? historicalImpact,
  }) = _ARPayload;

  factory ARPayload.fromJson(Map<String, dynamic> json) =>
      _$ARPayloadFromJson(json);
}
```

- [ ] **Step 5: Generate freezed/json_serializable code**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: generates `curriculum_content.freezed.dart`,
`curriculum_content.g.dart`, `ar_payload.freezed.dart`, `ar_payload.g.dart`
with no errors.

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/core/models/ar_payload_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/core/models/curriculum_content.dart lib/core/models/curriculum_content.freezed.dart \
        lib/core/models/curriculum_content.g.dart lib/core/models/ar_payload.dart \
        lib/core/models/ar_payload.freezed.dart lib/core/models/ar_payload.g.dart \
        test/core/models/ar_payload_test.dart
git commit -m "feat: CurriculumContent and ARPayload models"
```

---

### Task 6: `Lesson` model

**Files:**
- Create: `lib/core/models/lesson.dart`
- Test: `test/core/models/lesson_test.dart`

**Interfaces:**
- Consumes: `SubjectKey` (Task 3), `ARPayload`, `CurriculumContent` (Task 5).
- Produces: `Lesson` freezed class with `fromJson`/`toJson`. Consumed by
  Phase 2's curriculum data and lesson-browsing screens.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/models/lesson_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/lesson.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';

void main() {
  test('Lesson round-trips the Q1W1 shape from PROJECT_FLOW.md Part 5', () {
    final json = {
      'id': 'q1w1',
      'title': 'Scientific Models and the Particle Model of Matter',
      'subject': 'chemistry',
      'summary': 'summary text',
      'steps': <String>[],
      'hasAR': true,
      'isUnlockedByDefault': true,
      'week': 1,
      'quarter': 1,
    };

    final lesson = Lesson.fromJson(json);

    expect(lesson.id, 'q1w1');
    expect(lesson.subject, SubjectKey.chemistry);
    expect(lesson.hasAR, true);
    expect(lesson.isUnlockedByDefault, true);
    expect(lesson.arPayload, isNull);
    expect(lesson.toJson()['subject'], 'chemistry');
  });

  test('Lesson defaults hasAR/isUnlockedByDefault to false when absent', () {
    final lesson = Lesson.fromJson(const {
      'id': 'q1w5',
      'title': 'Planning and Recording Scientific Investigations',
      'subject': 'chemistry',
      'summary': 'summary text',
      'steps': <String>[],
    });

    expect(lesson.hasAR, false);
    expect(lesson.isUnlockedByDefault, false);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/models/lesson_test.dart`
Expected: FAIL — `lib/core/models/lesson.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/core/models/lesson.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'ar_payload.dart';
import 'curriculum_content.dart';
import 'subject_key.dart';

part 'lesson.freezed.dart';
part 'lesson.g.dart';

SubjectKey _subjectFromJson(String value) => SubjectKey.fromFirestore(value);
String _subjectToJson(SubjectKey value) => value.firestoreValue;

@freezed
class Lesson with _$Lesson {
  const factory Lesson({
    required String id, // e.g. 'q1w1'
    required String title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required SubjectKey subject,
    String? topicId,
    required String summary,
    required List<String> steps,
    String? labExperimentId,
    ARPayload? arPayload,
    @Default(false) bool hasAR,
    String? pdfUrl,
    @Default(false) bool isUnlockedByDefault,
    CurriculumContent? curriculum,
    int? week,
    int? quarter,
  }) = _Lesson;

  factory Lesson.fromJson(Map<String, dynamic> json) => _$LessonFromJson(json);
}
```

- [ ] **Step 4: Generate code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: generates `lesson.freezed.dart` and `lesson.g.dart` with no errors.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/models/lesson_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/core/models/lesson.dart lib/core/models/lesson.freezed.dart \
        lib/core/models/lesson.g.dart test/core/models/lesson_test.dart
git commit -m "feat: Lesson model"
```

---

### Task 7: `QuizAttempt` and `QuizUnlockCode` models

**Files:**
- Create: `lib/core/models/quiz_attempt.dart`
- Create: `lib/core/models/quiz_unlock_code.dart`
- Test: `test/core/models/quiz_attempt_test.dart`

**Interfaces:**
- Consumes: nothing beyond `freezed_annotation`/`json_annotation`.
- Produces: `QuizAttempt`, `QuizUnlockCode` freezed classes, consumed by
  `StudentRecord` (Task 9) and Phase 2's quiz player/results screens.

- [ ] **Step 1: Write the failing test**

Using the exact example document from PROJECT_FLOW.md Part 4.3:

```dart
// test/core/models/quiz_attempt_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/models/quiz_unlock_code.dart';

void main() {
  test('QuizAttempt round-trips the example attempt from PROJECT_FLOW.md 4.3', () {
    final json = {
      'id': 'attempt-abc123',
      'quizId': 'builtin-q1w1-post',
      'studentId': '123456',
      'attemptNumber': 1,
      'score': 80,
      'totalQuestions': 5,
      'correctAnswers': 4,
      'answers': [2, 0, 1, 3, 0],
      'timestamp': '2026-08-20T09:15:00.000Z',
      'timeSpentSeconds': 340,
      'locked': true,
    };

    final attempt = QuizAttempt.fromJson(json);

    expect(attempt.id, 'attempt-abc123');
    expect(attempt.score, 80);
    expect(attempt.answers, [2, 0, 1, 3, 0]);
    expect(attempt.locked, true);
    expect(attempt.toJson()['quizId'], 'builtin-q1w1-post');
  });

  test('QuizUnlockCode round-trips with optional fields present', () {
    final json = {
      'id': 'code-1',
      'quizId': 'builtin-q1w1-post',
      'studentId': '123456',
      'code': 'XYZ123',
      'generatedAt': '2026-08-20T09:00:00.000Z',
      'usedAt': '2026-08-20T09:15:00.000Z',
      'expiresAt': '2026-08-27T09:00:00.000Z',
      'isUsed': true,
      'isArchived': false,
    };

    final unlockCode = QuizUnlockCode.fromJson(json);

    expect(unlockCode.code, 'XYZ123');
    expect(unlockCode.isUsed, true);
    expect(unlockCode.isArchived, false);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/models/quiz_attempt_test.dart`
Expected: FAIL — files don't exist yet.

- [ ] **Step 3: Implement `QuizAttempt`**

```dart
// lib/core/models/quiz_attempt.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_attempt.freezed.dart';
part 'quiz_attempt.g.dart';

@freezed
class QuizAttempt with _$QuizAttempt {
  const factory QuizAttempt({
    required String id,
    required String quizId,
    required String studentId,
    required int attemptNumber,
    required num score,
    required int totalQuestions,
    required int correctAnswers,
    required List<int> answers, // selected option index per question, in order
    required String timestamp, // ISO string, kept as string to match Firestore exactly
    int? timeSpentSeconds,
    required bool locked,
  }) = _QuizAttempt;

  factory QuizAttempt.fromJson(Map<String, dynamic> json) =>
      _$QuizAttemptFromJson(json);
}
```

- [ ] **Step 4: Implement `QuizUnlockCode`**

```dart
// lib/core/models/quiz_unlock_code.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_unlock_code.freezed.dart';
part 'quiz_unlock_code.g.dart';

@freezed
class QuizUnlockCode with _$QuizUnlockCode {
  const factory QuizUnlockCode({
    required String id,
    required String quizId,
    required String studentId,
    required String code,
    required String generatedAt,
    String? usedAt,
    String? expiresAt,
    required bool isUsed,
    @Default(false) bool isArchived,
  }) = _QuizUnlockCode;

  factory QuizUnlockCode.fromJson(Map<String, dynamic> json) =>
      _$QuizUnlockCodeFromJson(json);
}
```

- [ ] **Step 5: Generate code**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/core/models/quiz_attempt_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/core/models/quiz_attempt.dart lib/core/models/quiz_attempt.freezed.dart \
        lib/core/models/quiz_attempt.g.dart lib/core/models/quiz_unlock_code.dart \
        lib/core/models/quiz_unlock_code.freezed.dart lib/core/models/quiz_unlock_code.g.dart \
        test/core/models/quiz_attempt_test.dart
git commit -m "feat: QuizAttempt and QuizUnlockCode models"
```

---

### Task 8: `TeacherQuizQuestion`, `TeacherQuiz`, `TeacherLesson`, `BuiltInQuestion` models

**Files:**
- Create: `lib/core/models/teacher_quiz_question.dart`
- Create: `lib/core/models/teacher_quiz.dart`
- Create: `lib/core/models/teacher_lesson.dart`
- Create: `lib/core/models/built_in_question.dart`
- Test: `test/core/models/teacher_quiz_test.dart`

**Interfaces:**
- Consumes: `SubjectKey`, `QuestionType`, `QuizPhase` (Task 3), `ARPayload`,
  `CurriculumContent` (Task 5).
- Produces: four freezed classes, consumed by Phase 4's teacher CRUD screens
  and by the built-in/Firestore merge logic in Phase 2.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/models/teacher_quiz_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/built_in_question.dart';
import 'package:ar_science_explorer/core/models/question_type.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/teacher_quiz.dart';
import 'package:ar_science_explorer/core/models/teacher_quiz_question.dart';

void main() {
  test('TeacherQuizQuestion defaults type to mc when absent', () {
    final question = TeacherQuizQuestion.fromJson(const {
      'question': 'What is H2O?',
      'options': ['Water', 'Oxygen', 'Hydrogen', 'Salt'],
      'correctIndex': 0,
      'hint': 'It is a liquid at room temperature.',
    });

    expect(question.type, QuestionType.mc);
  });

  test('TeacherQuiz defaults phase to post when absent (legacy quiz)', () {
    final quiz = TeacherQuiz.fromJson({
      'id': 'quiz-1',
      'title': 'Q1W1 Post-Test',
      'subject': 'chemistry',
      'questions': <Map<String, dynamic>>[],
      'createdAt': '2026-08-20T09:00:00.000Z',
    });

    expect(quiz.subject, SubjectKey.chemistry);
    expect(quiz.phase, QuizPhase.post);
  });

  test('BuiltInQuestion round-trips a tf question using the 4-slot convention', () {
    final question = BuiltInQuestion.fromJson(const {
      'id': 'q1w1-tf-1',
      'subject': 'chemistry',
      'question': 'Atoms are indivisible.',
      'options': ['True', 'False', '-', '-'],
      'correctIndex': 0,
      'hint': 'Think about what "atomos" means.',
      'type': 'tf',
    });

    expect(question.type, QuestionType.tf);
    expect(question.options, ['True', 'False', '-', '-']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/models/teacher_quiz_test.dart`
Expected: FAIL — files don't exist yet.

- [ ] **Step 3: Implement `TeacherQuizQuestion`**

```dart
// lib/core/models/teacher_quiz_question.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'question_type.dart';

part 'teacher_quiz_question.freezed.dart';
part 'teacher_quiz_question.g.dart';

QuestionType _typeFromJson(String? value) => QuestionType.fromFirestore(value);
String _typeToJson(QuestionType value) => value.firestoreValue;

@freezed
class TeacherQuizQuestion with _$TeacherQuizQuestion {
  const factory TeacherQuizQuestion({
    required String question,
    required List<String> options, // exactly 4 slots
    required int correctIndex,
    required String hint,
    @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
    @Default(QuestionType.mc)
    QuestionType type,
  }) = _TeacherQuizQuestion;

  factory TeacherQuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$TeacherQuizQuestionFromJson(json);
}
```

- [ ] **Step 4: Implement `TeacherQuiz`**

```dart
// lib/core/models/teacher_quiz.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'quiz_phase.dart';
import 'subject_key.dart';
import 'teacher_quiz_question.dart';

part 'teacher_quiz.freezed.dart';
part 'teacher_quiz.g.dart';

SubjectKey _subjectFromJson(String value) => SubjectKey.fromFirestore(value);
String _subjectToJson(SubjectKey value) => value.firestoreValue;
QuizPhase _phaseFromJson(String? value) => QuizPhase.fromFirestore(value);
String _phaseToJson(QuizPhase value) => value.firestoreValue;

@freezed
class TeacherQuiz with _$TeacherQuiz {
  const factory TeacherQuiz({
    required String id,
    required String title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required SubjectKey subject,
    String? topicId,
    required List<TeacherQuizQuestion> questions,
    required String createdAt,
    @JsonKey(fromJson: _phaseFromJson, toJson: _phaseToJson, includeIfNull: false)
    @Default(QuizPhase.post)
    QuizPhase phase,
  }) = _TeacherQuiz;

  factory TeacherQuiz.fromJson(Map<String, dynamic> json) =>
      _$TeacherQuizFromJson(json);
}
```

- [ ] **Step 5: Implement `TeacherLesson`**

```dart
// lib/core/models/teacher_lesson.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'ar_payload.dart';
import 'curriculum_content.dart';
import 'subject_key.dart';

part 'teacher_lesson.freezed.dart';
part 'teacher_lesson.g.dart';

SubjectKey _subjectFromJson(String value) => SubjectKey.fromFirestore(value);
String _subjectToJson(SubjectKey value) => value.firestoreValue;

@freezed
class TeacherLesson with _$TeacherLesson {
  const factory TeacherLesson({
    required String id,
    required String title,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required SubjectKey subject,
    String? content,
    String? createdAt,
    String? linkedQuizId,
    String? summary,
    List<String>? steps,
    String? labExperimentId,
    ARPayload? arPayload,
    bool? isPredefined,
    int? quarter,
    int? week,
    String? pdfUrl,
    List<String>? learningObjectives,
    List<String>? keyLearningSteps,
    List<String>? keyVocabulary,
    int? arModelIndex,
    String? arContext,
    bool? hasAR,
    CurriculumContent? curriculum,
  }) = _TeacherLesson;

  factory TeacherLesson.fromJson(Map<String, dynamic> json) =>
      _$TeacherLessonFromJson(json);
}
```

- [ ] **Step 6: Implement `BuiltInQuestion`**

```dart
// lib/core/models/built_in_question.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'question_type.dart';
import 'subject_key.dart';

part 'built_in_question.freezed.dart';
part 'built_in_question.g.dart';

SubjectKey _subjectFromJson(String value) => SubjectKey.fromFirestore(value);
String _subjectToJson(SubjectKey value) => value.firestoreValue;
QuestionType _typeFromJson(String? value) => QuestionType.fromFirestore(value);
String _typeToJson(QuestionType value) => value.firestoreValue;

@freezed
class BuiltInQuestion with _$BuiltInQuestion {
  const factory BuiltInQuestion({
    required String id,
    @JsonKey(fromJson: _subjectFromJson, toJson: _subjectToJson)
    required SubjectKey subject,
    String? topicId,
    String? lessonId,
    required String question,
    required List<String> options, // exactly 4 slots
    required int correctIndex,
    required String hint,
    @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson, includeIfNull: false)
    @Default(QuestionType.mc)
    QuestionType type,
  }) = _BuiltInQuestion;

  factory BuiltInQuestion.fromJson(Map<String, dynamic> json) =>
      _$BuiltInQuestionFromJson(json);
}
```

- [ ] **Step 7: Generate code**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 8: Run test to verify it passes**

Run: `flutter test test/core/models/teacher_quiz_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 9: Commit**

```bash
git add lib/core/models/teacher_quiz_question.dart lib/core/models/teacher_quiz_question.freezed.dart \
        lib/core/models/teacher_quiz_question.g.dart lib/core/models/teacher_quiz.dart \
        lib/core/models/teacher_quiz.freezed.dart lib/core/models/teacher_quiz.g.dart \
        lib/core/models/teacher_lesson.dart lib/core/models/teacher_lesson.freezed.dart \
        lib/core/models/teacher_lesson.g.dart lib/core/models/built_in_question.dart \
        lib/core/models/built_in_question.freezed.dart lib/core/models/built_in_question.g.dart \
        test/core/models/teacher_quiz_test.dart
git commit -m "feat: TeacherQuizQuestion, TeacherQuiz, TeacherLesson, BuiltInQuestion models"
```

---

### Task 9: `StudentRecord` model

**Files:**
- Create: `lib/core/models/student_record.dart`
- Test: `test/core/models/student_record_test.dart`

**Interfaces:**
- Consumes: `SubjectKey` (Task 3), `QuizAttempt` (Task 7).
- Produces: `StudentRecord` freezed class, consumed by `StudentRepository`
  (Task 12) and every later student-facing screen.

- [ ] **Step 1: Write the failing test**

Using the exact example document from PROJECT_FLOW.md Part 4.3:

```dart
// test/core/models/student_record_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';

void main() {
  test('StudentRecord round-trips the example document from PROJECT_FLOW.md 4.3', () {
    final json = {
      'id': '123456',
      'studentId': '123456',
      'name': 'Juan Dela Cruz',
      'grade': '7',
      'section': 'Rizal',
      'scores': {'chemistry': 85, 'biology': null, 'physics': null},
      'completedLessonIds': ['q1w1', 'q1w2'],
      'completedLabExperimentIds': <String>[],
      'completedQuizIds': ['builtin-q1w1-pre', 'builtin-q1w1-post'],
      'unlockedLessonIds': ['q1w1', 'q1w2', 'q1w3'],
      'unlockedQuizIds': ['builtin-q1w1-post'],
      'quizAttempts': [
        {
          'id': 'attempt-abc123',
          'quizId': 'builtin-q1w1-post',
          'studentId': '123456',
          'attemptNumber': 1,
          'score': 80,
          'totalQuestions': 5,
          'correctAnswers': 4,
          'answers': [2, 0, 1, 3, 0],
          'timestamp': '2026-08-20T09:15:00.000Z',
          'timeSpentSeconds': 340,
          'locked': true,
        },
      ],
      'isArchived': false,
    };

    final student = StudentRecord.fromJson(json);

    expect(student.studentId, '123456');
    expect(student.scores['chemistry'], 85);
    expect(student.scores['biology'], isNull);
    expect(student.completedLessonIds, ['q1w1', 'q1w2']);
    expect(student.quizAttempts, hasLength(1));
    expect(student.quizAttempts.first.score, 80);
    expect(student.isArchived, false);
  });

  test('StudentRecord defaults isArchived to false and uid to null when absent', () {
    final student = StudentRecord.fromJson(const {
      'id': '654321',
      'studentId': '654321',
      'name': 'Maria Santos',
      'grade': '7',
      'section': 'Bonifacio',
      'scores': {'chemistry': null, 'biology': null, 'physics': null},
      'completedLessonIds': <String>[],
      'completedLabExperimentIds': <String>[],
      'completedQuizIds': <String>[],
      'unlockedLessonIds': <String>[],
      'unlockedQuizIds': <String>[],
      'quizAttempts': <Map<String, dynamic>>[],
    });

    expect(student.uid, isNull);
    expect(student.isArchived, false);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/models/student_record_test.dart`
Expected: FAIL — `lib/core/models/student_record.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

`scores` is `Record<SubjectKey, number | null>` in the TS source — a
fixed-key map with nullable numeric values. Model it as `Map<String, num?>`
keyed by the raw `SubjectKey.firestoreValue` string (not `Map<SubjectKey, ...>`)
because Dart's `json_serializable` cannot key a JSON object by an enum
directly, and this keeps `fromJson`/`toJson` symmetric without a custom
converter:

```dart
// lib/core/models/student_record.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'quiz_attempt.dart';

part 'student_record.freezed.dart';
part 'student_record.g.dart';

@freezed
class StudentRecord with _$StudentRecord {
  const factory StudentRecord({
    required String id,
    String? uid,
    required String name,
    required String studentId,
    required String grade,
    required String section,
    required Map<String, num?> scores, // keyed by 'chemistry'/'biology'/'physics'
    required List<String> completedLessonIds,
    required List<String> completedLabExperimentIds,
    required List<String> completedQuizIds,
    required List<String> unlockedLessonIds,
    required List<String> unlockedQuizIds,
    required List<QuizAttempt> quizAttempts,
    @Default(false) bool isArchived,
  }) = _StudentRecord;

  factory StudentRecord.fromJson(Map<String, dynamic> json) =>
      _$StudentRecordFromJson(json);
}
```

- [ ] **Step 4: Generate code**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/models/student_record_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/core/models/student_record.dart lib/core/models/student_record.freezed.dart \
        lib/core/models/student_record.g.dart test/core/models/student_record_test.dart
git commit -m "feat: StudentRecord model"
```

---

### Task 10: `AuthService` — role inference and email construction (pure logic)

**Files:**
- Create: `lib/core/services/auth_service.dart`
- Test: `test/core/services/auth_service_test.dart`

**Interfaces:**
- Consumes: nothing (pure functions, no Firebase dependency in this task).
- Produces: `bool isStudentEmail(String email)`,
  `String studentEmailFromRawId(String rawId)`,
  `String normalizeStudentIdInput(String input)`. These are static/top-level
  so Task 11's `AuthService` class and later UI code can call them without
  instantiating anything.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/services/auth_service.dart';

void main() {
  group('isStudentEmail', () {
    test('matches the student pattern {digits}@arscience.school', () {
      expect(isStudentEmail('123456@arscience.school'), true);
      expect(isStudentEmail('7@arscience.school'), true); // any digit count
    });

    test('rejects anything else as a teacher email', () {
      expect(isStudentEmail('teacher@school.edu'), false);
      expect(isStudentEmail('123456@gmail.com'), false);
      expect(isStudentEmail('abc@arscience.school'), false);
    });
  });

  group('studentEmailFromRawId', () {
    test('builds the plain-digit email with no dash', () {
      expect(studentEmailFromRawId('123456'), '123456@arscience.school');
    });

    test('strips a dash if the caller passes a formatted id by mistake', () {
      expect(studentEmailFromRawId('12-3456'), '123456@arscience.school');
    });
  });

  group('normalizeStudentIdInput', () {
    test('passes a literal email through unchanged', () {
      expect(
        normalizeStudentIdInput('123456@arscience.school'),
        '123456@arscience.school',
      );
    });

    test('strips non-digits from a raw or dash-formatted id', () {
      expect(normalizeStudentIdInput('12-3456'), '123456');
      expect(normalizeStudentIdInput('123456'), '123456');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/auth_service_test.dart`
Expected: FAIL — `lib/core/services/auth_service.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/core/services/auth_service.dart
//
// Role is inferred purely from the email pattern used to sign in — there is
// no separate Firestore role field (PROJECT_FLOW.md Part 3.1). The student
// pattern is `/^\d+@arscience\.school$/`, ported exactly from the retired
// web app's src/lib/auth.ts.

final RegExp _studentEmailPattern = RegExp(r'^\d+@arscience\.school$');

/// True if [email] matches the student account pattern. Anything else is a
/// teacher account.
bool isStudentEmail(String email) => _studentEmailPattern.hasMatch(email);

/// Build the real Firebase Auth email for a raw student ID. Always
/// `{6 plain digits}@arscience.school` — no dash, even if a dash-formatted
/// id slips in (PROJECT_FLOW.md Part 3.2 / Design Spec Section 2, resolved
/// Q5: the dash is a UI display concern only, never part of the real email).
String studentEmailFromRawId(String rawId) {
  final digitsOnly = rawId.replaceAll(RegExp(r'\D'), '');
  return '$digitsOnly@arscience.school';
}

/// Normalize a student login field's raw input for use as a student id:
/// - If it contains '@', treat it as a literal email, unchanged.
/// - Otherwise strip everything but digits (handles both a raw 6-digit id
///   and a dash-formatted '00-0000' display string).
String normalizeStudentIdInput(String input) {
  if (input.contains('@')) return input;
  return input.replaceAll(RegExp(r'\D'), '');
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/auth_service_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/auth_service.dart test/core/services/auth_service_test.dart
git commit -m "feat: student/teacher role inference and email construction"
```

---

### Task 11: `AuthService` — Firebase Auth wrapper (login, sign-out, auth state)

**Files:**
- Modify: `lib/core/services/auth_service.dart`
- Modify: `test/core/services/auth_service_test.dart`

**Interfaces:**
- Consumes: `isStudentEmail`, `studentEmailFromRawId`,
  `normalizeStudentIdInput` (Task 10, same file); `firebase_auth`'s
  `FirebaseAuth`, `User`.
- Produces: `class AuthService` with constructor
  `AuthService({required FirebaseAuth firebaseAuth})`, methods
  `Future<User?> signInStudent({required String idOrEmail, required String password})`,
  `Future<User?> signInTeacher({required String email, required String password})`,
  `Future<void> signOut()`, `Stream<User?> authStateChanges()`. This is what
  `StudentRepository` (Task 12) and later login screens depend on — the
  constructor takes `FirebaseAuth` as a parameter specifically so tests (and
  Phase 2's login screens, via Riverpod) can inject `MockFirebaseAuth` instead
  of the real singleton.

- [ ] **Step 1: Write the failing test**

Append to the existing test file:

```dart
// Add to test/core/services/auth_service_test.dart

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

// ... (keep the existing groups above, add this new group at the end)

void _authServiceTests() {
  group('AuthService.signInStudent', () {
    test('signs in with the constructed email for a raw id', () async {
      final mockUser = MockUser(uid: 'uid-123456', email: '123456@arscience.school');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: false);
      final authService = AuthService(firebaseAuth: mockAuth);

      final user = await authService.signInStudent(
        idOrEmail: '123456',
        password: 'secret',
      );

      expect(user, isNotNull);
      expect(user!.email, '123456@arscience.school');
    });

    test('accepts a literal email input unchanged', () async {
      final mockUser = MockUser(uid: 'uid-123456', email: '123456@arscience.school');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: false);
      final authService = AuthService(firebaseAuth: mockAuth);

      final user = await authService.signInStudent(
        idOrEmail: '123456@arscience.school',
        password: 'secret',
      );

      expect(user, isNotNull);
    });
  });

  group('AuthService.signInTeacher', () {
    test('signs in with the email as given, no transformation', () async {
      final mockUser = MockUser(uid: 'uid-teacher', email: 'teacher@school.edu');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: false);
      final authService = AuthService(firebaseAuth: mockAuth);

      final user = await authService.signInTeacher(
        email: 'teacher@school.edu',
        password: 'secret',
      );

      expect(user, isNotNull);
      expect(user!.email, 'teacher@school.edu');
    });
  });

  group('AuthService.signOut and authStateChanges', () {
    test('signOut clears the current user', () async {
      final mockUser = MockUser(uid: 'uid-123456', email: '123456@arscience.school');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      final authService = AuthService(firebaseAuth: mockAuth);

      expect(mockAuth.currentUser, isNotNull);
      await authService.signOut();
      expect(mockAuth.currentUser, isNull);
    });

    test('authStateChanges emits the signed-in user', () async {
      final mockUser = MockUser(uid: 'uid-123456', email: '123456@arscience.school');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      final authService = AuthService(firebaseAuth: mockAuth);

      final user = await authService.authStateChanges().first;
      expect(user?.email, '123456@arscience.school');
    });
  });
}
```

Then change the file's `main()` to call both the existing pure-function tests
and this new group — replace:
```dart
void main() {
  group('isStudentEmail', () {
```
with:
```dart
void main() {
  _authServiceTests();

  group('isStudentEmail', () {
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/auth_service_test.dart`
Expected: FAIL — no `AuthService` class exists yet (compile error).

- [ ] **Step 3: Implement `AuthService`**

Append to `lib/core/services/auth_service.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around [FirebaseAuth] that applies this app's student-id
/// normalization and email construction. Takes [FirebaseAuth] as a
/// constructor parameter (rather than reading `FirebaseAuth.instance`
/// directly) so callers — including tests — can inject a fake.
class AuthService {
  AuthService({required FirebaseAuth firebaseAuth}) : _firebaseAuth = firebaseAuth;

  final FirebaseAuth _firebaseAuth;

  /// Student login (Android target). Accepts either a raw/dash-formatted
  /// student id or a literal email — see [normalizeStudentIdInput] and
  /// [studentEmailFromRawId] for the exact rules.
  Future<User?> signInStudent({
    required String idOrEmail,
    required String password,
  }) async {
    final normalized = normalizeStudentIdInput(idOrEmail);
    final email = normalized.contains('@')
        ? normalized
        : studentEmailFromRawId(normalized);
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Teacher login (Web target). No transformation — teacher emails are
  /// used exactly as entered.
  Future<User?> signInTeacher({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/auth_service_test.dart`
Expected: PASS (12 tests total — the original 7 pure-function tests plus 5
new `AuthService` tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/auth_service.dart test/core/services/auth_service_test.dart
git commit -m "feat: AuthService Firebase Auth wrapper for student/teacher login"
```

---

### Task 12: `StudentRepository` — Firestore CRUD for `/students/{studentId}`

**Files:**
- Create: `lib/core/services/student_repository.dart`
- Test: `test/core/services/student_repository_test.dart`

**Interfaces:**
- Consumes: `StudentRecord` (Task 9); `cloud_firestore`'s `FirebaseFirestore`.
- Produces: `class StudentRepository` with constructor
  `StudentRepository({required FirebaseFirestore firestore})`, methods
  `Future<StudentRecord?> getStudent(String studentId)`,
  `Future<void> saveStudent(StudentRecord student)`,
  `Stream<StudentRecord?> watchStudent(String studentId)`. This is what
  Phase 2's Home/Learn/Progress screens read from — the document id is the
  student's `studentId`, not the Firebase Auth `uid` (Global Constraints).

- [ ] **Step 1: Write the failing test**

```dart
// test/core/services/student_repository_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';

StudentRecord _sampleStudent() => StudentRecord.fromJson(const {
      'id': '123456',
      'studentId': '123456',
      'name': 'Juan Dela Cruz',
      'grade': '7',
      'section': 'Rizal',
      'scores': {'chemistry': 85, 'biology': null, 'physics': null},
      'completedLessonIds': ['q1w1'],
      'completedLabExperimentIds': <String>[],
      'completedQuizIds': <String>[],
      'unlockedLessonIds': ['q1w1', 'q1w2'],
      'unlockedQuizIds': <String>[],
      'quizAttempts': <Map<String, dynamic>>[],
      'isArchived': false,
    });

void main() {
  test('getStudent returns null when the document does not exist', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = StudentRepository(firestore: firestore);

    final result = await repo.getStudent('nonexistent');

    expect(result, isNull);
  });

  test('saveStudent writes to /students/{studentId}, then getStudent reads it back', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = StudentRepository(firestore: firestore);
    final student = _sampleStudent();

    await repo.saveStudent(student);
    final result = await repo.getStudent('123456');

    expect(result, isNotNull);
    expect(result!.name, 'Juan Dela Cruz');
    expect(result.completedLessonIds, ['q1w1']);

    // Confirm the document id is the plain studentId, not a generated id.
    final rawDoc = await firestore.collection('students').doc('123456').get();
    expect(rawDoc.exists, true);
  });

  test('watchStudent streams updates as the document changes', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = StudentRepository(firestore: firestore);
    final student = _sampleStudent();
    await repo.saveStudent(student);

    final stream = repo.watchStudent('123456');
    final first = await stream.first;
    expect(first?.name, 'Juan Dela Cruz');

    await firestore
        .collection('students')
        .doc('123456')
        .update({'name': 'Juan Dela Cruz Jr.'});

    final updated = await stream.firstWhere((s) => s?.name == 'Juan Dela Cruz Jr.');
    expect(updated?.name, 'Juan Dela Cruz Jr.');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/student_repository_test.dart`
Expected: FAIL — `lib/core/services/student_repository.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/core/services/student_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student_record.dart';

/// Firestore access for `/students/{studentId}` — the single source of
/// truth for a student's unlocked/completed lessons, quiz attempts, and
/// per-subject scores (PROJECT_FLOW.md Part 3.4). The document id is the
/// plain student id, not the Firebase Auth uid.
class StudentRepository {
  StudentRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection('students');

  Future<StudentRecord?> getStudent(String studentId) async {
    final snapshot = await _students.doc(studentId).get();
    final data = snapshot.data();
    if (data == null) return null;
    return StudentRecord.fromJson(data);
  }

  Future<void> saveStudent(StudentRecord student) {
    return _students.doc(student.studentId).set(student.toJson());
  }

  Stream<StudentRecord?> watchStudent(String studentId) {
    return _students.doc(studentId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return StudentRecord.fromJson(data);
    });
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/student_repository_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/student_repository.dart test/core/services/student_repository_test.dart
git commit -m "feat: StudentRepository for /students/{studentId} Firestore access"
```

---

### Task 13: Run the full test suite and confirm the phase is complete

**Files:**
- None created — verification only.

**Interfaces:**
- Consumes: everything from Tasks 1–12.
- Produces: nothing new; this is the phase's exit checkpoint.

- [ ] **Step 1: Run the entire test suite**

Run: `flutter test`
Expected: every test from Tasks 2–12 passes (widget smoke test + all `core/`
unit tests). If anything fails, fix it before proceeding — do not carry a
failing test into Phase 2.

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`
Expected: no errors. Warnings about generated `.freezed.dart`/`.g.dart` files
are expected and fine; do not hand-edit generated files to silence them.

- [ ] **Step 3: Confirm the manual-steps list is current**

Open `MANUAL_STEPS.md` and confirm the Firebase section still accurately
describes what's needed (running `flutterfire configure` against the real
project, replacing the placeholder `lib/firebase_options.dart` from Task 2).
Nothing in this phase requires editing that file, but Phase 2 will need a
real Firebase connection for anything beyond unit tests, so this is the
checkpoint to flag it if it hasn't happened yet.

- [ ] **Step 4: Commit the checkpoint**

```bash
git add -A
git commit -m "chore: Phase 1 complete — scaffold, core models, auth, student repository" --allow-empty
```
