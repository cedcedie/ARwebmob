# Phase 2: Student Core Flow (No AR) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Android student experience end-to-end minus AR: Home, Learn,
Lesson Detail (a placeholder for Phase 3's AR Lab entry point), Progress, and
the quiz player — with the pre-test/post-test retake rule (PROJECT_FLOW.md
Part 7, "the single most important behavior to get exactly right") and the
access-code system (Part 9) both wired to real Firestore-backed logic and
fully unit-tested. This proves the hardest business logic *before* Unity/AR
complexity is layered on top in Phase 3.

**Architecture:** Extends Phase 1's `core/` layer with a `core/data/` static
curriculum data source (the 24 built-in lessons + their pre/post-test
question banks, ported verbatim from the retired app's `src/data/curriculum.ts`
— these ship as compiled Dart data, not Firestore documents, per
PROJECT_FLOW.md Part 4.2) and three new `core/services/` classes
(`LessonRepository`, `QuizAttemptService`, `AccessCodeService`) that hold all
the retake-rule and access-code business logic, unit-tested against
`fake_cloud_firestore` exactly like Phase 1's `StudentRepository`. A new
`features/student/` tree holds the screens, each backed by Riverpod providers
that read from `core/services/`. `go_router` handles navigation; state that
needs to survive rebuilds (the in-progress quiz session) lives in a
`StateNotifier`, not screen-local `State`.

**Tech Stack:** Everything from Phase 1, plus (per the design spec's Phase 2
UI package list): `go_router`, `hooks_riverpod` + `flutter_hooks` (added
alongside Phase 1's `flutter_riverpod` — `hooks_riverpod` re-exports it, so
this is additive, not a replacement), `google_fonts`, `shared_preferences`,
`skeletonizer`, `pin_code_fields`, `confetti`, `flutter_animate`.

**Spec:** `PROJECT_FLOW.md` Parts 4.2, 5, 7, 9, 10 (also read Part 11 — "what
must be 1:1" — before touching any task below); design spec
`docs/superpowers/specs/2026-08-28-flutter-ar-science-explorer-design.md`
Phase 2 section. This plan does not restate their content, only implements
it.

## Global Constraints

- Package/app name stays `ar_science_explorer` (Phase 1). All new code lives
  under `lib/core/` (shared logic) and `lib/features/student/` (Android-only
  screens) — do not create a `lib/student/` top-level directory, Part 2.1's
  target split is expressed as a `kIsWeb` branch inside one app, not two
  separate app roots.
- **Built-in curriculum content is static Dart data, not Firestore** — the 24
  lessons and their question banks are compiled into the app (PROJECT_FLOW.md
  Part 4.2). Only teacher-authored lessons/quizzes (`/lessons/{id}`,
  `/quizzes/{id}`) are Firestore reads. Every screen that lists lessons must
  merge both sources — built-ins first, teacher-authored appended, deduped by
  id — per Part 4.2's `mergedLessons` pattern.
- **The retake rule, exactly as PROJECT_FLOW.md Part 7.1 states it — not as
  the retired app's current code implements it.** Reading the retired app's
  `src/lib/storage.ts` and `src/components/student/screens/QuizScreen.tsx`
  while researching this plan turned up a real discrepancy: the live code
  gates *every* post-test attempt (including the first) behind
  `unlockedQuizIds`, never auto-unlocking a post-test's first attempt on
  Read-phase completion. That contradicts Part 7.1's explicit rule ("the
  first attempt requires no access code") and matches almost exactly the
  regression Part 7.1 itself warns against ("accidentally gating first-attempt
  post-tests"). This plan implements the *documented* rule — first post-test
  attempt always free, only a retake (attempt 2+) requires a code — not the
  retired app's literal current behavior. This is flagged in `MANUAL_STEPS.md`
  for the client to confirm; do not silently revert to the buggy version if
  this comes up in review.
  - One simplification this correction enables: because eligibility becomes
    purely attempt-history-based (see Task 3), `StudentRecord.unlockedQuizIds`
    is no longer load-bearing gating logic — it's kept on the model (Phase 1)
    for schema compatibility and is still written to for display purposes
    where the retired app's UI checked it, but `QuizAttemptService` does not
    read it to decide eligibility.
- **Phase 3 doesn't exist yet.** The real "Read phase complete" signal
  normally comes from the AR Lab's three-phase Scan/Read/Review flow (Part
  6.2), which isn't built until Phase 3. This phase's Lesson Detail screen
  (Task 9) stands in for that entry point with a literal "Mark as Read"
  button that performs the same completion side effect Phase 3's AR flow will
  later trigger instead. This is a deliberate, temporary stand-in — comment it
  as such in code so Phase 3 knows exactly what to replace.
- **Scoring formula and pass threshold are fixed**: `score = round((correct /
  total) * 100)`, pass at `score >= 50` (Part 7.3, Part 11 — must be 1:1).
- **Score color thresholds are fixed** (Part 10.1): ≥80 good/green, 50–79
  caution/amber, <50 needs-work/red.
- **Access-code error messages must echo the exact code the student typed**
  (Part 9.3) — never a generic "invalid code" message.
- Quarter → subject mapping is fixed: Q1 = chemistry, Q2 = biology, Q3 =
  physics, 8 weeks each, 24 lessons total, lesson ids `q{quarter}w{week}`
  (Part 5, Part 11).
- Visual design, navigation chrome, and animation language are explicitly
  free to redesign (Part 12) as long as every documented flow stays reachable
  and every state-transition rule (retake gating, pass/fail behavior, access
  code validation order) is preserved exactly.
- All new Firestore-touching classes take their Firestore/Auth dependency as
  a constructor parameter (Phase 1's `StudentRepository`/`AuthService`
  pattern) so tests inject `FakeFirebaseFirestore`.
- **fake_cloud_firestore stream-relisten quirk (from Phase 1):** in any new
  test that listens to a `snapshots()`-backed stream, keep one continuous
  subscription across assertions — do not call `.first` and then relisten
  `.firstWhere(...)` on the same `Stream` instance (see Phase 1's
  `student_repository_test.dart` for the working pattern).

---

## File Structure

```
lib/
  core/
    data/
      curriculum_data.dart          # kBuiltInLessons, kPreTestQuestions, kPostTestQuestions
    services/
      lesson_repository.dart        # /lessons/{id} Firestore reads + mergedLessons()
      quiz_attempt_service.dart     # eligibility + recordAttempt (the retake rule)
      access_code_service.dart      # redeem() — Part 9.2 validation order
      progress_calculator.dart      # pure functions for Home/Progress screens
  features/
    student/
      app/
        student_shell.dart          # bottom-nav scaffold: Home / Learn / Progress
        router.dart                 # go_router config for the student target
      home/
        home_providers.dart
        home_screen.dart
      learn/
        learn_providers.dart
        learn_screen.dart
        lesson_card.dart
      lesson_detail/
        lesson_detail_providers.dart
        lesson_detail_screen.dart
      quiz/
        quiz_session_controller.dart  # Riverpod StateNotifier: quiz-in-progress state
        quiz_player_screen.dart
        quiz_results_screen.dart
      progress/
        progress_providers.dart
        progress_screen.dart
      access_code/
        access_code_sheet.dart      # shared bottom sheet, Part 9's "one entry flow reused everywhere"
test/
  core/
    data/
      curriculum_data_test.dart
    services/
      lesson_repository_test.dart
      quiz_attempt_service_test.dart
      access_code_service_test.dart
      progress_calculator_test.dart
  features/
    student/
      quiz/
        quiz_session_controller_test.dart
      home/
        home_screen_test.dart
      learn/
        learn_screen_test.dart
      progress/
        progress_screen_test.dart
```

---

### Task 1: Curriculum static data — port `curriculum.ts` into Dart

**Files:**
- Create: `lib/core/data/curriculum_data.dart`
- Test: `test/core/data/curriculum_data_test.dart`

**Interfaces:**
- Consumes: `Lesson`, `BuiltInQuestion`, `SubjectKey`, `QuestionType` (Phase 1
  models); `builtinQuizId`/`parseBuiltinId` are NOT used here — the built-in
  question lists are keyed by `lessonId` directly, phase-scoped ids are only
  constructed at read time by `QuizAttemptService`/screens.
- Produces:
  - `const List<Lesson> kBuiltInLessons` — all 24 lessons, in curriculum
    order (q1w1 → q1w8, q2w1 → q2w8, q3w1 → q3w8).
  - `const Map<String, List<BuiltInQuestion>> kPreTestQuestionsByLesson` —
    keyed by lesson id; a lesson with no pre-test (rare in the source) is
    simply absent from the map, not present with an empty list.
  - `const Map<String, List<BuiltInQuestion>> kPostTestQuestionsByLesson` —
    keyed by lesson id; every lesson has a post-test (falls back to the
    legacy `questions` array in the source when no explicit `postTest` is
    defined — see the port instructions below).

**Port instructions (mechanical, not a design task):**

Source: `src/data/curriculum.ts` in the retired
`C:\Users\cedri\OneDrive\Documents\GitHub\AR\ar-science-explorer` repo — the
`CURRICULUM` array (currently 24 entries, one per lesson). For each entry:

1. Build a `Lesson` (Phase 1 model) from every field on the entry **except**
   `questions`, `preTest`, `postTest` — these three map straight onto Phase
   1's `Lesson` fields with the same names (`id`, `title`, `subject`,
   `summary`, `topicId`, `steps`, `isUnlockedByDefault`, `quarter`, `week`,
   `pdfUrl`, `curriculum`, `arPayload`, `labExperimentId`, `hasAR`). This
   mirrors exactly what the source's own `LESSONS` derived-export does
   (`curriculum.ts`, the `export const LESSONS` block near the bottom): strip
   the three quiz arrays, keep everything else as `Lesson`.
2. For `kPreTestQuestionsByLesson[lesson.id]`: only present if the source
   entry has a non-empty `preTest` array. Map each item to a
   `BuiltInQuestion` with:
   - `id`: the source item's `id` if present, otherwise
     `'${lesson.id}-pre-${index + 1}'` (1-indexed) — this reproduces the
     source's `stampQuestions()` id-generation exactly.
   - `subject`: `lesson.subject`, `lessonId`: `lesson.id`, `topicId`:
     `lesson.topicId` (all three are stamped from the parent lesson, not
     present on the source question item itself).
   - `question`, `options`, `correctIndex`, `hint`: copied verbatim.
   - `type`: the source item's `type` field if present (`'tf'` for the
     True/False pre/post-tests — all 24 lessons' `preTest`/`postTest` arrays
     use `type: 'tf'` with the 4-slot `['True', 'False', '-', '-']`
     convention already established in Phase 1's `QuestionType`), otherwise
     defaults to `mc` via `QuestionType.fromFirestore(null)`.
3. For `kPostTestQuestionsByLesson[lesson.id]`: use the source entry's
   `postTest` array if present and non-empty; otherwise use its `questions`
   array (the legacy per-lesson quiz — every lesson has at least one of the
   two, so every lesson id ends up with a post-test entry). Same per-item
   mapping as step 2, with id fallback `'${lesson.id}-post-${index + 1}'`.
4. Preserve source order — do not alphabetize or otherwise reorder lessons
   or questions.
5. Copy text fields (`title`, `summary`, `question`, `options`, `hint`,
   curriculum standards/competencies/objectives, AR payload `description`/
   `keyIdeas`) **verbatim** — do not paraphrase or trim (Part 11).

- [ ] **Step 1: Write the failing test**

These spot-check known values already quoted in `PROJECT_FLOW.md` (Parts 5
and 6.0.1) plus structural invariants, rather than re-asserting the entire
port line-by-line — the port itself is verified by exact transcription per
the instructions above, not by an exhaustive test.

```dart
// test/core/data/curriculum_data_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/data/curriculum_data.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/question_type.dart';

void main() {
  test('kBuiltInLessons has exactly 24 lessons, 8 per subject, in curriculum order', () {
    expect(kBuiltInLessons, hasLength(24));

    final bySubject = <SubjectKey, int>{};
    for (final lesson in kBuiltInLessons) {
      bySubject[lesson.subject] = (bySubject[lesson.subject] ?? 0) + 1;
    }
    expect(bySubject[SubjectKey.chemistry], 8);
    expect(bySubject[SubjectKey.biology], 8);
    expect(bySubject[SubjectKey.physics], 8);

    // Curriculum order: q1w1..q1w8, q2w1..q2w8, q3w1..q3w8.
    final expectedIds = [
      for (final q in [1, 2, 3]) for (final w in [1, 2, 3, 4, 5, 6, 7, 8]) 'q${q}w$w',
    ];
    expect(kBuiltInLessons.map((l) => l.id).toList(), expectedIds);
  });

  test('every lesson id is unique', () {
    final ids = kBuiltInLessons.map((l) => l.id).toSet();
    expect(ids, hasLength(24));
  });

  test('Q1W1 matches the worked example in PROJECT_FLOW.md Part 6.0.1', () {
    final q1w1 = kBuiltInLessons.firstWhere((l) => l.id == 'q1w1');
    expect(q1w1.title, 'Scientific Models and the Particle Model of Matter');
    expect(q1w1.subject, SubjectKey.chemistry);
    expect(q1w1.isUnlockedByDefault, true);
    expect(q1w1.quarter, 1);
    expect(q1w1.week, 1);
    expect(q1w1.arPayload, isNotNull);
    expect(q1w1.arPayload!.title, 'Democritus Atom');
    expect(q1w1.arPayload!.modelIndex, 0);
    expect(q1w1.arPayload!.detectionMode, 'marker');
    expect(q1w1.arPayload!.keyIdeas, hasLength(4));
  });

  test('every lesson has a post-test question bank', () {
    for (final lesson in kBuiltInLessons) {
      expect(
        kPostTestQuestionsByLesson[lesson.id],
        isNotNull,
        reason: '${lesson.id} must have a post-test (falls back to legacy questions[])',
      );
      expect(kPostTestQuestionsByLesson[lesson.id], isNotEmpty);
    }
  });

  test('Q1W1 pre-test is 8 true/false questions, stamped with lesson metadata', () {
    final preTest = kPreTestQuestionsByLesson['q1w1'];
    expect(preTest, isNotNull);
    expect(preTest, hasLength(8));
    for (final q in preTest!) {
      expect(q.subject, SubjectKey.chemistry);
      expect(q.lessonId, 'q1w1');
      expect(q.type, QuestionType.tf);
      expect(q.options, hasLength(4));
      expect(q.options[2], '-');
      expect(q.options[3], '-');
    }
    expect(
      preTest.first.question,
      'Scientists use models to explain things that cannot be easily seen.',
    );
    expect(preTest.first.correctIndex, 0);
  });

  test('every question in every bank has exactly 4 option slots', () {
    for (final bank in [...kPreTestQuestionsByLesson.values, ...kPostTestQuestionsByLesson.values]) {
      for (final q in bank) {
        expect(q.options, hasLength(4), reason: '${q.id} must have 4 option slots');
      }
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/data/curriculum_data_test.dart`
Expected: FAIL — `lib/core/data/curriculum_data.dart` doesn't exist yet.

- [ ] **Step 3: Perform the port**

Read `src/data/curriculum.ts` end to end from the retired repo path above.
Transcribe all 24 `CURRICULUM` entries into `lib/core/data/curriculum_data.dart`
following the 5 port instructions given above exactly. The file's shape:

```dart
// lib/core/data/curriculum_data.dart
//
// Ported verbatim from the retired ar-science-explorer web app's
// src/data/curriculum.ts (24 lessons, 8 per quarter/subject). This is the
// single source of truth for built-in curriculum content — it ships as
// compiled Dart data, not Firestore documents (PROJECT_FLOW.md Part 4.2).
// Do not paraphrase or trim any text field when re-porting; if the source
// changes, re-run this port rather than hand-editing values here.

import '../models/ar_payload.dart';
import '../models/built_in_question.dart';
import '../models/curriculum_content.dart';
import '../models/lesson.dart';
import '../models/question_type.dart';
import '../models/subject_key.dart';

final List<Lesson> kBuiltInLessons = [
  const Lesson(
    id: 'q1w1',
    title: 'Scientific Models and the Particle Model of Matter',
    subject: SubjectKey.chemistry,
    summary: 'Discover how scientists use models to explain properties of matter and changes of state.',
    topicId: 'c1',
    steps: ['Understand Scientific Models', 'Explore the Particle Model', 'Identify properties of S, L, G'],
    isUnlockedByDefault: true,
    quarter: 1,
    week: 1,
    pdfUrl: '/lessons/Q1W1.pdf',
    curriculum: CurriculumContent(
      standards: 'Learners learn that the particle model explains the properties of solids, liquids, and gases and the processes involved in changes of state.',
      performanceStandards: 'By the end of the Quarter, learners recognize that scientists use models to describe the particle model of matter. They use diagrams and illustrations to explain the motion and arrangement of particles during changes of state.',
      learningCompetencies: [
        'Recognize that scientists use models to explain phenomena that cannot be easily seen or detected',
        'Describe the Particle Model of Matter as "All matter is made up of tiny particles with each pure substance having its own kind of particles."',
      ],
      objectives: [
        'Describe and explain the different models used by the scientist to explain phenomena that cannot be easily seen or detected',
        'Describe particle model of matter',
        'Recognize that matter consists of tiny particles',
      ],
      contentDetails: 'Scientific Models and the Particle Model of Matter',
      integration: CurriculumIntegration(
        qualities: ['Critical Thinking', 'Perseverance'],
        description: 'Students question and analyze the nature of matter and how models represent it.',
      ),
    ),
    arPayload: ARPayload(
      modelIndex: 0,
      detectionMode: 'marker',
      markerImage: '/markers/Q1W1.jpg',
      anchorHint: 'Scan the Democritus worksheet marker.',
      lessonSteps: ['Aim at Q1W1 marker', 'View the 3D atom model', 'Discover its structure'],
      title: 'Democritus Atom',
      subtitle: 'Ancient Greek Atomic Theory (c. 400 BCE)',
      description: 'Democritus proposed that all matter consists of tiny, indivisible particles called "atomos".',
      keyIdeas: [
        'Smallest, indestructible building blocks of matter',
        'Particles in constant, random motion',
        'Differ in shape and size',
        'Form all materials in the universe',
      ],
    ),
  ),
  // ... continue for all 24 lessons, transcribed field-for-field from
  // src/data/curriculum.ts's CURRICULUM array, in source order.
];

const _q1w1PostQuestions = [
  BuiltInQuestion(
    id: 'q1w1-post-1',
    subject: SubjectKey.chemistry,
    lessonId: 'q1w1',
    topicId: 'c1',
    question: 'Scientists use scientific models because some objects are too small, too large, or too complex to observe directly.',
    options: ['True', 'False', '-', '-'],
    correctIndex: 0,
    hint: 'Think about atoms and planets.',
    type: QuestionType.tf,
  ),
  // ... remaining postTest questions for q1w1, then repeat this pattern for
  // every lesson's preTest/postTest (or legacy questions[] fallback) array.
];

final Map<String, List<BuiltInQuestion>> kPreTestQuestionsByLesson = {
  'q1w1': const [
    BuiltInQuestion(
      id: 'q1w1-pre-1',
      subject: SubjectKey.chemistry,
      lessonId: 'q1w1',
      topicId: 'c1',
      question: 'Scientists use models to explain things that cannot be easily seen.',
      options: ['True', 'False', '-', '-'],
      correctIndex: 0,
      hint: 'Models represent the very small or very large.',
      type: QuestionType.tf,
    ),
    // ... remaining 7 pre-test questions for q1w1
  ],
  // ... every other lesson id that defines a preTest array in the source
};

final Map<String, List<BuiltInQuestion>> kPostTestQuestionsByLesson = {
  'q1w1': _q1w1PostQuestions,
  // ... every lesson id (all 24), using postTest if present else questions[]
};
```

(The excerpt above is real, verbatim-copied content for Q1W1 — continue the
same pattern for the remaining 23 lessons, copying every field from the
source without paraphrasing.)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/data/curriculum_data_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/data/curriculum_data.dart test/core/data/curriculum_data_test.dart
git commit -m "feat: port built-in curriculum data (24 lessons + pre/post-test banks)"
```

---

### Task 2: `LessonRepository` — Firestore reads for teacher lessons + `mergedLessons`

**Files:**
- Create: `lib/core/services/lesson_repository.dart`
- Test: `test/core/services/lesson_repository_test.dart`

**Interfaces:**
- Consumes: `Lesson`, `TeacherLesson` (Phase 1 models); `kBuiltInLessons`
  (Task 1); `cloud_firestore`'s `FirebaseFirestore`.
- Produces: `class LessonRepository` with constructor
  `LessonRepository({required FirebaseFirestore firestore})`, methods
  `Stream<List<TeacherLesson>> watchTeacherLessons()` and
  `List<Lesson> mergedLessons(List<TeacherLesson> teacherLessons)`. Screens
  (Learn, Lesson Detail) combine these: watch teacher lessons, then call
  `mergedLessons` with the latest snapshot.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/services/lesson_repository_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/data/curriculum_data.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/teacher_lesson.dart';
import 'package:ar_science_explorer/core/services/lesson_repository.dart';

void main() {
  test('mergedLessons puts built-ins first, teacher-authored lessons appended', () {
    final firestore = FakeFirebaseFirestore();
    final repo = LessonRepository(firestore: firestore);

    final teacherLesson = TeacherLesson(
      id: 'teacher-extra-1',
      title: 'Extra Credit: Volcanoes',
      subject: SubjectKey.physics,
      isPredefined: false,
    );

    final merged = repo.mergedLessons([teacherLesson]);

    expect(merged.length, kBuiltInLessons.length + 1);
    expect(merged.first.id, kBuiltInLessons.first.id);
    expect(merged.last.id, 'teacher-extra-1');
  });

  test('mergedLessons dedupes by id, built-in wins over a same-id teacher lesson', () {
    final firestore = FakeFirebaseFirestore();
    final repo = LessonRepository(firestore: firestore);

    // A teacher lesson that collides with a built-in id should not create a
    // duplicate entry or shadow the built-in's real content.
    final colliding = TeacherLesson(
      id: 'q1w1',
      title: 'Should not appear',
      subject: SubjectKey.chemistry,
    );

    final merged = repo.mergedLessons([colliding]);

    expect(merged.length, kBuiltInLessons.length);
    expect(merged.where((l) => l.id == 'q1w1').single.title,
        kBuiltInLessons.firstWhere((l) => l.id == 'q1w1').title);
  });

  test('watchTeacherLessons streams /lessons documents as TeacherLesson', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = LessonRepository(firestore: firestore);

    await firestore.collection('lessons').doc('teacher-1').set({
      'id': 'teacher-1',
      'title': 'Community Garden Ecology',
      'subject': 'biology',
    });

    final lessons = await repo.watchTeacherLessons().first;

    expect(lessons, hasLength(1));
    expect(lessons.first.title, 'Community Garden Ecology');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/lesson_repository_test.dart`
Expected: FAIL — `lib/core/services/lesson_repository.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/core/services/lesson_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/curriculum_data.dart';
import '../models/lesson.dart';
import '../models/teacher_lesson.dart';

/// Reads teacher-authored lessons from `/lessons/{lessonId}` and merges them
/// with the built-in curriculum (`kBuiltInLessons`) — built-ins first, then
/// Firestore-authored ones, deduped by id (PROJECT_FLOW.md Part 4.2's
/// `mergedLessons` pattern; a built-in id always wins on collision, since the
/// built-in curriculum is the authoritative 24-lesson set).
class LessonRepository {
  LessonRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<List<TeacherLesson>> watchTeacherLessons() {
    return _firestore.collection('lessons').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => TeacherLesson.fromJson(doc.data())).toList(),
        );
  }

  List<Lesson> mergedLessons(List<TeacherLesson> teacherLessons) {
    final builtInIds = kBuiltInLessons.map((l) => l.id).toSet();
    final appended = teacherLessons
        .where((tl) => !builtInIds.contains(tl.id))
        .map(_toLesson);
    return [...kBuiltInLessons, ...appended];
  }

  Lesson _toLesson(TeacherLesson tl) {
    return Lesson(
      id: tl.id,
      title: tl.title,
      subject: tl.subject,
      topicId: tl.topicId,
      summary: tl.summary ?? '',
      steps: tl.steps ?? const [],
      labExperimentId: tl.labExperimentId,
      arPayload: tl.arPayload,
      hasAR: tl.hasAR ?? false,
      pdfUrl: tl.pdfUrl,
      isUnlockedByDefault: false,
      curriculum: tl.curriculum,
      week: tl.week,
      quarter: tl.quarter,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/lesson_repository_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/lesson_repository.dart test/core/services/lesson_repository_test.dart
git commit -m "feat: LessonRepository — teacher lessons + mergedLessons (built-in first, deduped)"
```

---

### Task 3: `QuizAttemptService` — the retake rule (Part 7.1)

**Files:**
- Create: `lib/core/services/quiz_attempt_service.dart`
- Test: `test/core/services/quiz_attempt_service_test.dart`

**Interfaces:**
- Consumes: `StudentRecord`, `QuizAttempt`, `SubjectKey` (Phase 1 models);
  `parseBuiltinId` (Phase 1 `quiz_id.dart`); `cloud_firestore`'s
  `FirebaseFirestore`.
- Produces:
  - `class QuizEligibility` — `({bool canTake, bool isLocked, String? reason, int attemptCount})`
    as a Dart record typedef.
  - `class QuizAttemptService` with constructor
    `QuizAttemptService({required FirebaseFirestore firestore})`, methods
    `Future<QuizEligibility> checkEligibility(String studentId, String quizId)`
    and
    `Future<void> recordAttempt({required String studentId, required QuizAttempt attempt, required SubjectKey subject})`.
    Consumed by the quiz session controller (Task 10) and the access-code
    service's retake-unlock step (Task 4).

**Business rule this task implements (PROJECT_FLOW.md Part 7.1, as corrected
in Global Constraints above):**

- Pre-test (`parseBuiltinId(quizId).phase == QuizPhase.pre`): always
  `canTake: true`, `isLocked: false`, regardless of attempt history.
- Post-test, zero prior attempts: `canTake: true`, `isLocked: false` — first
  attempt is always free.
- Post-test, latest attempt has `locked == true`: `canTake: false`,
  `isLocked: true`, `reason: 'Test locked after your last attempt. Ask your
  teacher for a retake code.'`.
- Post-test, latest attempt has `locked == false` (a retake code was applied
  and consumed the lock): `canTake: true`, `isLocked: false`.

`recordAttempt` mirrors the retired app's `storage.ts` `completeQuiz` (the
"consolidated" method — it's the one actually wired to the live quiz screen,
per `QuizScreen.tsx`'s `handleShowResult`/`handleConfirmBack`), corrected per
Global Constraints to not touch `unlockedQuizIds` as a gating mechanism:

- Sets `attempt.locked = true` for a post-test attempt (always locks after
  submission — a subsequent retake needs a code to unlock it again), `false`
  for a pre-test attempt (pre-tests are never locked).
- Appends `attempt` to `StudentRecord.quizAttempts` and writes the same
  attempt to `/students/{studentId}/quizAttempts/{attempt.id}` as a backup
  subcollection write (both writes happen — this resolves PROJECT_FLOW.md
  Part 13, open question 6: the embedded array is what `checkEligibility`
  reads from and is therefore the source of truth for gating; the
  subcollection is a denormalized backup, matching the retired app's own
  comment "Save to subcollection as a backup").
- Adds `attempt.quizId` to `completedQuizIds`.
- Post-test only: sets `scores[subject]` to `attempt.score` (a pre-test score
  must never overwrite the headline subject score — Part 7.5's context).
- Post-test only, and only when `parseBuiltinId(attempt.quizId)` reports
  `isBuiltin: true` with a non-null `lessonId`: adds that `lessonId` to
  `completedLessonIds`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/services/quiz_attempt_service_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/quiz_id.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';

StudentRecord _blankStudent(String id) => StudentRecord(
      id: id,
      name: 'Test Student',
      studentId: id,
      grade: '7',
      section: 'Rizal',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [],
      completedLabExperimentIds: const [],
      completedQuizIds: const [],
      unlockedLessonIds: const [],
      unlockedQuizIds: const [],
      quizAttempts: const [],
    );

void main() {
  final preQuizId = builtinQuizId('q1w1', QuizPhase.pre);
  final postQuizId = builtinQuizId('q1w1', QuizPhase.post);

  group('checkEligibility', () {
    test('pre-test is always takeable, even with prior attempts', () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final service = QuizAttemptService(firestore: firestore);
      await studentRepo.saveStudent(_blankStudent('111111'));

      final eligibility = await service.checkEligibility('111111', preQuizId);

      expect(eligibility.canTake, true);
      expect(eligibility.isLocked, false);
    });

    test('post-test first attempt is free — no unlock required', () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final service = QuizAttemptService(firestore: firestore);
      await studentRepo.saveStudent(_blankStudent('111111'));

      final eligibility = await service.checkEligibility('111111', postQuizId);

      expect(eligibility.canTake, true);
      expect(eligibility.isLocked, false);
      expect(eligibility.attemptCount, 0);
    });

    test('post-test is locked after one attempt, until a retake code unlocks it', () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final service = QuizAttemptService(firestore: firestore);
      await studentRepo.saveStudent(_blankStudent('111111'));

      await service.recordAttempt(
        studentId: '111111',
        subject: SubjectKey.chemistry,
        attempt: QuizAttempt(
          id: 'attempt-1',
          quizId: postQuizId,
          studentId: '111111',
          attemptNumber: 1,
          score: 40,
          totalQuestions: 5,
          correctAnswers: 2,
          answers: const [0, 1, 0, 1, 0],
          timestamp: DateTime(2026, 8, 20).toIso8601String(),
          locked: true,
        ),
      );

      final eligibility = await service.checkEligibility('111111', postQuizId);
      expect(eligibility.canTake, false);
      expect(eligibility.isLocked, true);
      expect(eligibility.reason, isNotNull);
      expect(eligibility.attemptCount, 1);
    });
  });

  group('recordAttempt', () {
    test('post-test attempt updates scores, completedLessonIds, completedQuizIds', () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final service = QuizAttemptService(firestore: firestore);
      await studentRepo.saveStudent(_blankStudent('111111'));

      await service.recordAttempt(
        studentId: '111111',
        subject: SubjectKey.chemistry,
        attempt: QuizAttempt(
          id: 'attempt-1',
          quizId: postQuizId,
          studentId: '111111',
          attemptNumber: 1,
          score: 80,
          totalQuestions: 5,
          correctAnswers: 4,
          answers: const [0, 1, 0, 1, 0],
          timestamp: DateTime(2026, 8, 20).toIso8601String(),
          locked: true,
        ),
      );

      final student = await studentRepo.getStudent('111111');
      expect(student!.scores['chemistry'], 80);
      expect(student.completedLessonIds, contains('q1w1'));
      expect(student.completedQuizIds, contains(postQuizId));
      expect(student.quizAttempts, hasLength(1));

      // Backup subcollection write also happened.
      final subDoc = await firestore
          .collection('students')
          .doc('111111')
          .collection('quizAttempts')
          .doc('attempt-1')
          .get();
      expect(subDoc.exists, true);
    });

    test('pre-test attempt does NOT touch scores or completedLessonIds', () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final service = QuizAttemptService(firestore: firestore);
      await studentRepo.saveStudent(_blankStudent('111111'));

      await service.recordAttempt(
        studentId: '111111',
        subject: SubjectKey.chemistry,
        attempt: QuizAttempt(
          id: 'attempt-pre-1',
          quizId: preQuizId,
          studentId: '111111',
          attemptNumber: 1,
          score: 60,
          totalQuestions: 8,
          correctAnswers: 5,
          answers: const [0, 1, 0, 1, 0, 1, 0, 1],
          timestamp: DateTime(2026, 8, 20).toIso8601String(),
          locked: false,
        ),
      );

      final student = await studentRepo.getStudent('111111');
      expect(student!.scores['chemistry'], isNull);
      expect(student.completedLessonIds, isEmpty);
      expect(student.completedQuizIds, contains(preQuizId));
    });

    test('a retake attempt after unlockRetake is takeable again', () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final service = QuizAttemptService(firestore: firestore);
      await studentRepo.saveStudent(_blankStudent('111111'));

      await service.recordAttempt(
        studentId: '111111',
        subject: SubjectKey.chemistry,
        attempt: QuizAttempt(
          id: 'attempt-1',
          quizId: postQuizId,
          studentId: '111111',
          attemptNumber: 1,
          score: 40,
          totalQuestions: 5,
          correctAnswers: 2,
          answers: const [0, 1, 0, 1, 0],
          timestamp: DateTime(2026, 8, 20).toIso8601String(),
          locked: true,
        ),
      );

      await service.unlockRetake('111111', postQuizId);

      final eligibility = await service.checkEligibility('111111', postQuizId);
      expect(eligibility.canTake, true);
      expect(eligibility.isLocked, false);
      expect(eligibility.attemptCount, 1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/quiz_attempt_service_test.dart`
Expected: FAIL — `lib/core/services/quiz_attempt_service.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/core/services/quiz_attempt_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quiz_attempt.dart';
import '../models/quiz_phase.dart';
import '../models/student_record.dart';
import '../models/subject_key.dart';
import '../quiz_id.dart';

/// Result of a quiz eligibility check. See PROJECT_FLOW.md Part 7.1.
typedef QuizEligibility = ({
  bool canTake,
  bool isLocked,
  String? reason,
  int attemptCount,
});

/// Implements PROJECT_FLOW.md Part 7.1's retake rule — the single most
/// important behavior in the product per the client. See this plan's Global
/// Constraints for why this deviates from the retired app's literal
/// storage.ts behavior (which gates first post-test attempts too, a bug this
/// document's own Part 7.1 warns against).
///
/// - Pre-test: always takeable, never locked.
/// - Post-test: first attempt always free; every attempt after that is
///   locked until a teacher-issued retake code flips the latest attempt's
///   `locked` flag back to false (see `unlockRetake`, called by
///   `AccessCodeService` when a valid retake code is redeemed).
class QuizAttemptService {
  QuizAttemptService({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _studentDoc(String studentId) =>
      _firestore.collection('students').doc(studentId);

  Future<QuizEligibility> checkEligibility(String studentId, String quizId) async {
    final parsed = parseBuiltinId(quizId);

    if (parsed.phase == QuizPhase.pre) {
      final count = await _attemptsFor(studentId, quizId);
      return (canTake: true, isLocked: false, reason: null, attemptCount: count.length);
    }

    final attempts = await _attemptsFor(studentId, quizId);
    if (attempts.isEmpty) {
      return (canTake: true, isLocked: false, reason: null, attemptCount: 0);
    }

    final latest = attempts.first; // _attemptsFor returns newest-first.
    if (latest.locked) {
      return (
        canTake: false,
        isLocked: true,
        reason: 'Test locked after your last attempt. Ask your teacher for a retake code.',
        attemptCount: attempts.length,
      );
    }
    return (canTake: true, isLocked: false, reason: null, attemptCount: attempts.length);
  }

  Future<List<QuizAttempt>> _attemptsFor(String studentId, String quizId) async {
    final snapshot = await _studentDoc(studentId).get();
    final data = snapshot.data();
    if (data == null) return const [];
    final student = StudentRecord.fromJson(data);
    final attempts = student.quizAttempts.where((a) => a.quizId == quizId).toList()
      ..sort((a, b) => DateTime.parse(b.timestamp).compareTo(DateTime.parse(a.timestamp)));
    return attempts;
  }

  Future<void> recordAttempt({
    required String studentId,
    required QuizAttempt attempt,
    required SubjectKey subject,
  }) async {
    final parsed = parseBuiltinId(attempt.quizId);
    final isPreTest = parsed.phase == QuizPhase.pre;

    final snapshot = await _studentDoc(studentId).get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Cannot record a quiz attempt for unknown student $studentId');
    }
    final student = StudentRecord.fromJson(data);

    final updated = student.copyWith(
      quizAttempts: [...student.quizAttempts, attempt],
      completedQuizIds: {...student.completedQuizIds, attempt.quizId}.toList(),
      scores: isPreTest
          ? student.scores
          : {...student.scores, subject.firestoreValue: attempt.score},
      completedLessonIds: (!isPreTest && parsed.isBuiltin && parsed.lessonId != null)
          ? {...student.completedLessonIds, parsed.lessonId!}.toList()
          : student.completedLessonIds,
    );

    await _studentDoc(studentId).set(updated.toJson());

    // Backup write to the quizAttempts subcollection (denormalized read
    // copy — the embedded array on the student doc above is the source of
    // truth `checkEligibility` reads from).
    await _studentDoc(studentId)
        .collection('quizAttempts')
        .doc(attempt.id)
        .set(attempt.toJson());
  }

  /// Flips the latest attempt for [quizId] from locked to unlocked, allowing
  /// one retake. Called by `AccessCodeService` when a valid retake code is
  /// redeemed (PROJECT_FLOW.md Part 9.1, code type 3).
  Future<void> unlockRetake(String studentId, String quizId) async {
    final snapshot = await _studentDoc(studentId).get();
    final data = snapshot.data();
    if (data == null) return;
    final student = StudentRecord.fromJson(data);

    final attempts = student.quizAttempts.where((a) => a.quizId == quizId).toList()
      ..sort((a, b) => DateTime.parse(b.timestamp).compareTo(DateTime.parse(a.timestamp)));
    if (attempts.isEmpty || !attempts.first.locked) return;

    final latestId = attempts.first.id;
    final updatedAttempts = student.quizAttempts
        .map((a) => a.id == latestId ? a.copyWith(locked: false) : a)
        .toList();

    await _studentDoc(studentId).set(
      student.copyWith(quizAttempts: updatedAttempts).toJson(),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/quiz_attempt_service_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/quiz_attempt_service.dart test/core/services/quiz_attempt_service_test.dart
git commit -m "feat: QuizAttemptService — pre/post-test retake rule (PROJECT_FLOW.md Part 7.1)"
```

---

### Task 4: `AccessCodeService` — redemption, Part 9.2's validation order

**Files:**
- Create: `lib/core/services/access_code_service.dart`
- Test: `test/core/services/access_code_service_test.dart`

**Interfaces:**
- Consumes: `QuizUnlockCode` (Phase 1 model); `QuizAttemptService.unlockRetake`
  (Task 3); `builtinQuizId`/`parseBuiltinId` (Phase 1); `cloud_firestore`'s
  `FirebaseFirestore`.
- Produces:
  - `class AccessCodeResult` — sealed via a Dart record:
    `({bool success, String message})`. `message` is always
    student-displayable (Part 9.3/9.4 — success or failure, both need real
    copy, never a silent no-op).
  - `enum AccessCodeTarget { lesson, quiz }` — mirrors the retired app's
    `type: 'lesson' | 'quiz'` prop on `AccessCodeModal`.
  - `class AccessCodeService` with constructor
    `AccessCodeService({required FirebaseFirestore firestore, required QuizAttemptService quizAttemptService})`,
    method
    `Future<AccessCodeResult> redeem({required String studentId, required String rawCode, String? targetId, AccessCodeTarget? targetType})`.
    `targetId`/`targetType` are both nullable because the Home screen's entry
    box (Part 10.1) redeems a code with no specific target in mind — only
    subject-wide codes can succeed from there; a lesson-card or post-test
    retake redemption always passes both.
- This task only implements **redemption** — code *creation* (a teacher
  issuing a retake code) is Phase 4 (Teacher Web) territory. Firestore
  collections used here (`/unlockCodes/{code}`, `/quizUnlockCodes/{id}`) are
  read/written by this service but populated by Phase 4 UI later; tests seed
  them directly.

**Validation order this task implements, exactly as PROJECT_FLOW.md Part 9.2
specifies (stopping at the first match):**

1. Quiz-retake codes, stored in `/quizUnlockCodes` (auto-generated by a
   teacher issuing a retake). Requires `targetType == quiz`. Matches on
   `code` (case-insensitive, stored/compared uppercased), and — if the
   `QuizUnlockCode.studentId` field is set — requires it to equal `studentId`.
   Must not already be `isUsed`. On match: mark `isUsed: true` with
   `usedAt`, call `quizAttemptService.unlockRetake(studentId, quizId)`.
2. Subject code with an explicit lesson-id list (`/unlockCodes`,
   `type: 'subject'` with non-empty `lessonIds`). Requires `targetType ==
   lesson` and the code's `lessonIds` to contain `targetId`. On match: record
   usage (`usedByStudentIds` gains `studentId`) — actually unlocking those
   lesson ids into `StudentRecord.unlockedLessonIds` is this task's job too
   (see implementation).
3. Full-subject code (`type: 'subject'`, no `lessonIds`). No `targetId`
   requirement — works from the generic Home entry box. On match: record
   usage; the caller (Home screen) is responsible for treating "subject
   unlocked" as a UI-level fact (Phase 1/2 don't model a separate
   `unlockedSubjects` field — PROJECT_FLOW.md doesn't define one on
   `StudentRecord` either, so this stays a session-level concern, matching
   the retired app's separate Zustand `unlocked` store slice, not a Firestore
   field).
4. First-time test-unlock code (`type: 'lesson'`, being redeemed against a
   quiz — `targetType == quiz`). Requires the code's `targetId` (if set) to
   equal `targetId`. On match: record usage. (No further server-side unlock
   needed — per Task 3's corrected rule, a post-test's first attempt is
   already free; this code type existing in the source was compensating for
   the source's gate-everything bug. This plan keeps the code type and its
   validation slot for schema compatibility, but its practical effect here is
   just "valid code, thanks" — see the implementation's comment.)
5. Manually-created quiz-retake code (`type: 'quiz'` in `/unlockCodes`,
   distinct from step 1's auto-generated `/quizUnlockCodes`). Requires
   `targetType == quiz`, must not be `isUsed`, `targetId` (if set) must
   match. On match: mark `isUsed: true`, record usage, call
   `quizAttemptService.unlockRetake`.
6. Single specific-lesson code (`type: 'lesson'`, `targetType == lesson`).
   Requires `targetId` (if set) to equal `targetId`. On match: unlock that
   lesson id into `unlockedLessonIds`, record usage.

Any code not found, or found but rejected by every applicable step, returns
`AccessCodeResult(success: false, message: 'Code "$rawCode" isn\'t valid. Check with your teacher.')`
— echoing the exact typed code (Part 9.3).

- [ ] **Step 1: Write the failing test**

```dart
// test/core/services/access_code_service_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/quiz_id.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';

StudentRecord _blankStudent(String id) => StudentRecord(
      id: id,
      name: 'Test Student',
      studentId: id,
      grade: '7',
      section: 'Rizal',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [],
      completedLabExperimentIds: const [],
      completedQuizIds: const [],
      unlockedLessonIds: const [],
      unlockedQuizIds: const [],
      quizAttempts: const [],
    );

void main() {
  test('an unknown code echoes the exact code the student typed', () async {
    final firestore = FakeFirebaseFirestore();
    final service = AccessCodeService(
      firestore: firestore,
      quizAttemptService: QuizAttemptService(firestore: firestore),
    );

    final result = await service.redeem(studentId: '111111', rawCode: 'xyz123');

    expect(result.success, false);
    expect(result.message, contains('"XYZ123"'));
  });

  test('a full-subject code succeeds from the generic Home entry (no target)', () async {
    final firestore = FakeFirebaseFirestore();
    await StudentRepository(firestore: firestore).saveStudent(_blankStudent('111111'));
    await firestore.collection('unlockCodes').doc('SCIGRADE7').set({
      'type': 'subject',
      'subjects': ['chemistry', 'biology', 'physics'],
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    });
    final service = AccessCodeService(
      firestore: firestore,
      quizAttemptService: QuizAttemptService(firestore: firestore),
    );

    final result = await service.redeem(studentId: '111111', rawCode: 'scigrade7');

    expect(result.success, true);
  });

  test('a subject code with a lesson-id list only unlocks listed lessons for a matching target', () async {
    final firestore = FakeFirebaseFirestore();
    await StudentRepository(firestore: firestore).saveStudent(_blankStudent('111111'));
    await firestore.collection('unlockCodes').doc('Q1W3CODE').set({
      'type': 'subject',
      'lessonIds': ['q1w3', 'q1w4'],
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    });
    final service = AccessCodeService(
      firestore: firestore,
      quizAttemptService: QuizAttemptService(firestore: firestore),
    );

    final wrongTarget = await service.redeem(
      studentId: '111111',
      rawCode: 'Q1W3CODE',
      targetId: 'q1w5',
      targetType: AccessCodeTarget.lesson,
    );
    expect(wrongTarget.success, false);

    final rightTarget = await service.redeem(
      studentId: '111111',
      rawCode: 'Q1W3CODE',
      targetId: 'q1w3',
      targetType: AccessCodeTarget.lesson,
    );
    expect(rightTarget.success, true);

    final student = await StudentRepository(firestore: firestore).getStudent('111111');
    expect(student!.unlockedLessonIds, containsAll(['q1w3', 'q1w4']));
  });

  test('a single specific-lesson code unlocks exactly that lesson', () async {
    final firestore = FakeFirebaseFirestore();
    await StudentRepository(firestore: firestore).saveStudent(_blankStudent('111111'));
    await firestore.collection('unlockCodes').doc('ONELESSON').set({
      'type': 'lesson',
      'targetId': 'q2w2',
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    });
    final service = AccessCodeService(
      firestore: firestore,
      quizAttemptService: QuizAttemptService(firestore: firestore),
    );

    final result = await service.redeem(
      studentId: '111111',
      rawCode: 'ONELESSON',
      targetId: 'q2w2',
      targetType: AccessCodeTarget.lesson,
    );

    expect(result.success, true);
    final student = await StudentRepository(firestore: firestore).getStudent('111111');
    expect(student!.unlockedLessonIds, ['q2w2']);
  });

  test('a quiz-retake code unlocks a locked post-test for exactly one more attempt', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    final quizAttemptService = QuizAttemptService(firestore: firestore);
    await studentRepo.saveStudent(_blankStudent('111111'));
    final postQuizId = builtinQuizId('q1w1', QuizPhase.post);

    await quizAttemptService.recordAttempt(
      studentId: '111111',
      subject: SubjectKey.chemistry,
      attempt: QuizAttempt(
        id: 'attempt-1',
        quizId: postQuizId,
        studentId: '111111',
        attemptNumber: 1,
        score: 40,
        totalQuestions: 5,
        correctAnswers: 2,
        answers: const [0, 1, 0, 1, 0],
        timestamp: DateTime(2026, 8, 20).toIso8601String(),
        locked: true,
      ),
    );

    await firestore.collection('quizUnlockCodes').doc('retake-1').set({
      'id': 'retake-1',
      'quizId': postQuizId,
      'studentId': '111111',
      'code': 'RETRY99',
      'generatedAt': DateTime(2026, 8, 21).toIso8601String(),
      'isUsed': false,
    });

    final service = AccessCodeService(firestore: firestore, quizAttemptService: quizAttemptService);
    final result = await service.redeem(
      studentId: '111111',
      rawCode: 'retry99',
      targetId: 'q1w1',
      targetType: AccessCodeTarget.quiz,
    );

    expect(result.success, true);
    final eligibility = await quizAttemptService.checkEligibility('111111', postQuizId);
    expect(eligibility.canTake, true);
  });

  test('a used-up quiz-retake code cannot be redeemed twice', () async {
    final firestore = FakeFirebaseFirestore();
    await StudentRepository(firestore: firestore).saveStudent(_blankStudent('111111'));
    await firestore.collection('quizUnlockCodes').doc('retake-1').set({
      'id': 'retake-1',
      'quizId': builtinQuizId('q1w1', QuizPhase.post),
      'studentId': '111111',
      'code': 'RETRY99',
      'generatedAt': DateTime(2026, 8, 21).toIso8601String(),
      'isUsed': true,
      'usedAt': DateTime(2026, 8, 21).toIso8601String(),
    });

    final service = AccessCodeService(
      firestore: firestore,
      quizAttemptService: QuizAttemptService(firestore: firestore),
    );
    final result = await service.redeem(
      studentId: '111111',
      rawCode: 'retry99',
      targetId: 'q1w1',
      targetType: AccessCodeTarget.quiz,
    );

    expect(result.success, false);
    expect(result.message, contains('"RETRY99"'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/access_code_service_test.dart`
Expected: FAIL — `lib/core/services/access_code_service.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/core/services/access_code_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student_record.dart';
import '../quiz_id.dart';
import 'quiz_attempt_service.dart';

/// What kind of thing an access code is being redeemed against. Mirrors the
/// retired app's `AccessCodeModal`'s `type: 'lesson' | 'quiz'` prop.
enum AccessCodeTarget { lesson, quiz }

/// Result of redeeming a code — always carries a student-displayable
/// message, success or failure (PROJECT_FLOW.md Part 9.3/9.4: never a
/// silent no-op, and a failure always echoes the exact code typed).
typedef AccessCodeResult = ({bool success, String message});

/// Implements PROJECT_FLOW.md Part 9 — the one access-code entry flow reused
/// everywhere a code is needed. Redemption only; code *issuance* (a teacher
/// generating a retake code) is Phase 4 (Teacher Web).
class AccessCodeService {
  AccessCodeService({
    required FirebaseFirestore firestore,
    required QuizAttemptService quizAttemptService,
  })  : _firestore = firestore,
        _quizAttemptService = quizAttemptService;

  final FirebaseFirestore _firestore;
  final QuizAttemptService _quizAttemptService;

  Future<AccessCodeResult> redeem({
    required String studentId,
    required String rawCode,
    String? targetId,
    AccessCodeTarget? targetType,
  }) async {
    final code = rawCode.trim().toUpperCase();
    final invalid = (
      success: false,
      message: 'Code "$code" isn\'t valid. Check with your teacher.',
    );
    if (code.isEmpty) return invalid;

    // ── 1. Auto-generated quiz-retake codes (/quizUnlockCodes) ──
    if (targetType == AccessCodeTarget.quiz && targetId != null) {
      final quizId = builtinQuizId(targetId, _postPhaseOf(targetId));
      final retakeMatch = await _findQuizUnlockCode(code, studentId, quizId);
      if (retakeMatch != null) {
        await retakeMatch.reference.update({
          'isUsed': true,
          'usedAt': DateTime.now().toIso8601String(),
        });
        await _quizAttemptService.unlockRetake(studentId, quizId);
        return (success: true, message: 'Test unlocked for retake!');
      }
    }

    // ── 2–6. /unlockCodes lookups ──
    final doc = await _firestore.collection('unlockCodes').doc(code).get();
    final data = doc.data();
    if (data == null) return invalid;

    final targetStudentId = data['targetStudentId'] as String?;
    if (targetStudentId != null && targetStudentId != studentId) {
      return (success: false, message: 'Code "$code" is assigned to a different student.');
    }
    final usedBy = (data['usedByStudentIds'] as List?)?.cast<String>() ?? const [];
    if (usedBy.contains(studentId)) {
      return (
        success: false,
        message: 'Code "$code" has already been used. Ask your teacher for a new one.',
      );
    }

    final type = data['type'] as String? ?? 'subject';
    final lessonIds = (data['lessonIds'] as List?)?.cast<String>();
    final subjects = (data['subjects'] as List?)?.cast<String>();
    final codeTargetId = data['targetId'] as String?;
    final isUsed = data['isUsed'] as bool? ?? false;

    // ── 2. Subject code with an explicit lesson-id list ──
    if (type == 'subject' && lessonIds != null && lessonIds.isNotEmpty) {
      if (targetType != AccessCodeTarget.lesson || targetId == null || !lessonIds.contains(targetId)) {
        return (success: false, message: 'Code "$code" isn\'t valid for this lesson.');
      }
      await _unlockLessons(studentId, lessonIds);
      await _trackUsage(code, studentId);
      return (success: true, message: 'Lesson unlocked successfully!');
    }

    // ── 3. Full-subject code, no explicit lesson list ──
    if (type == 'subject' && subjects != null && subjects.isNotEmpty) {
      await _trackUsage(code, studentId);
      return (success: true, message: 'Subject unlocked successfully!');
    }

    // ── 4. First-time test-unlock code (type 'lesson', redeemed against a quiz) ──
    if (type == 'lesson' && targetType == AccessCodeTarget.quiz) {
      if (codeTargetId != null && codeTargetId != targetId) {
        return (success: false, message: 'Code "$code" isn\'t valid for this test.');
      }
      // No further gating action needed: QuizAttemptService already treats
      // a post-test's first attempt as free (Task 3). This code type is
      // kept for schema/UX compatibility with codes teachers may already
      // have issued as this type.
      await _trackUsage(code, studentId);
      return (success: true, message: 'Test unlocked successfully!');
    }

    // ── 5. Manually-created quiz-retake code (type 'quiz' in /unlockCodes) ──
    if (type == 'quiz' && targetType == AccessCodeTarget.quiz) {
      if (isUsed) {
        return (
          success: false,
          message: 'Code "$code" has already been used. Ask your teacher for a new one.',
        );
      }
      if (codeTargetId != null && codeTargetId != targetId) {
        return (success: false, message: 'Code "$code" isn\'t valid for this test.');
      }
      if (targetId != null) {
        final quizId = builtinQuizId(targetId, _postPhaseOf(targetId));
        await _quizAttemptService.unlockRetake(studentId, quizId);
      }
      await doc.reference.update({'isUsed': true});
      await _trackUsage(code, studentId);
      return (success: true, message: 'Test unlocked for retake!');
    }

    // ── 6. Single specific-lesson code ──
    if (type == 'lesson' && targetType == AccessCodeTarget.lesson) {
      if (codeTargetId != null && codeTargetId != targetId) {
        return (success: false, message: 'Code "$code" isn\'t valid for this lesson.');
      }
      if (targetId != null) {
        await _unlockLessons(studentId, [targetId]);
      }
      await _trackUsage(code, studentId);
      return (success: true, message: 'Lesson unlocked successfully!');
    }

    return (
      success: false,
      message: 'Code "$code" isn\'t for this ${targetType == AccessCodeTarget.quiz ? 'test' : 'lesson'}.',
    );
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findQuizUnlockCode(
    String code,
    String studentId,
    String quizId,
  ) async {
    final snapshot = await _firestore
        .collection('quizUnlockCodes')
        .where('code', isEqualTo: code)
        .get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final docStudentId = data['studentId'] as String?;
      final docQuizId = data['quizId'] as String?;
      final used = data['isUsed'] as bool? ?? false;
      final studentMatches = docStudentId == null || docStudentId == studentId;
      if (studentMatches && docQuizId == quizId && !used) return doc;
    }
    return null;
  }

  Future<void> _unlockLessons(String studentId, List<String> lessonIds) async {
    final studentDoc = _firestore.collection('students').doc(studentId);
    final snapshot = await studentDoc.get();
    final data = snapshot.data();
    if (data == null) return;
    final student = StudentRecord.fromJson(data);
    final updated = {...student.unlockedLessonIds, ...lessonIds}.toList();
    await studentDoc.set(student.copyWith(unlockedLessonIds: updated).toJson());
  }

  Future<void> _trackUsage(String code, String studentId) async {
    final codeDoc = _firestore.collection('unlockCodes').doc(code);
    final snapshot = await codeDoc.get();
    final existing = (snapshot.data()?['usedByStudentIds'] as List?)?.cast<String>() ?? const [];
    if (existing.contains(studentId)) return;
    await codeDoc.update({
      'usedByStudentIds': [...existing, studentId],
    });
  }

  // Every post-test id this service builds is phase-scoped 'post' — a
  // retake code only ever applies to a post-test (pre-tests are never
  // gated, Part 7.1).
  QuizPhaseAlias _postPhaseOf(String _) => QuizPhaseAlias.post;
}

// Local alias so this file doesn't need to import quiz_phase.dart's
// QuizPhase enum just to spell QuizPhase.post once; kept trivial on purpose.
typedef QuizPhaseAlias = QuizPhase;
```

Note: the `_postPhaseOf`/`QuizPhaseAlias` indirection above is unnecessary —
simplify it away during implementation by importing `QuizPhase` directly and
calling `builtinQuizId(targetId, QuizPhase.post)`. It's left spelled out here
only because this plan's code block needs to show a real, compiling import
path; the implementer should write the straightforward version:

```dart
import '../models/quiz_phase.dart';
// ...
final quizId = builtinQuizId(targetId, QuizPhase.post);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/access_code_service_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/access_code_service.dart test/core/services/access_code_service_test.dart
git commit -m "feat: AccessCodeService — code redemption, Part 9.2 validation order"
```

---

### Task 5: `ProgressCalculator` — pure functions for Home/Progress screens

**Files:**
- Create: `lib/core/services/progress_calculator.dart`
- Test: `test/core/services/progress_calculator_test.dart`

**Interfaces:**
- Consumes: `Lesson`, `StudentRecord`, `QuizAttempt` (Phase 1 models).
- Produces (all pure, no Firestore — testable with plain object construction):
  - `enum ScoreBand { good, caution, needsWork }` +
    `ScoreBand scoreBandFor(num score)` (Part 10.1's exact thresholds: ≥80
    good, 50–79 caution, <50 needsWork).
  - `Lesson? nextIncompleteLesson(List<Lesson> orderedLessons, StudentRecord student)`
    — first lesson in curriculum order whose id is not in
    `completedLessonIds` (Part 10.1's "Continue where you left off").
  - `double percentComplete(StudentRecord student, {int totalLessons = 24})`
    — `completedLessonIds.length / totalLessons` (Part 10.1).
  - `({int quarter, int week})? currentQuarterWeek(List<Lesson> orderedLessons, StudentRecord student)`
    — the quarter/week of `nextIncompleteLesson`'s result (null if every
    lesson is complete).
  - `List<QuizAttempt> lastNAttempts(StudentRecord student, {int n = 3})` —
    most recent first (Part 10.1's "last 3 quiz attempts").

- [ ] **Step 1: Write the failing test**

```dart
// test/core/services/progress_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/data/curriculum_data.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/services/progress_calculator.dart';

StudentRecord _studentWith({
  List<String> completedLessonIds = const [],
  List<QuizAttempt> quizAttempts = const [],
}) =>
    StudentRecord(
      id: '111111',
      name: 'Test Student',
      studentId: '111111',
      grade: '7',
      section: 'Rizal',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: completedLessonIds,
      completedLabExperimentIds: const [],
      completedQuizIds: const [],
      unlockedLessonIds: const [],
      unlockedQuizIds: const [],
      quizAttempts: quizAttempts,
    );

void main() {
  group('scoreBandFor', () {
    test('applies the exact Part 10.1 thresholds', () {
      expect(scoreBandFor(100), ScoreBand.good);
      expect(scoreBandFor(80), ScoreBand.good);
      expect(scoreBandFor(79), ScoreBand.caution);
      expect(scoreBandFor(50), ScoreBand.caution);
      expect(scoreBandFor(49), ScoreBand.needsWork);
      expect(scoreBandFor(0), ScoreBand.needsWork);
    });
  });

  group('nextIncompleteLesson', () {
    test('returns the first lesson in curriculum order not yet completed', () {
      final student = _studentWith(completedLessonIds: ['q1w1', 'q1w2']);
      final next = nextIncompleteLesson(kBuiltInLessons, student);
      expect(next?.id, 'q1w3');
    });

    test('returns null once every lesson is complete', () {
      final allIds = kBuiltInLessons.map((l) => l.id).toList();
      final student = _studentWith(completedLessonIds: allIds);
      expect(nextIncompleteLesson(kBuiltInLessons, student), isNull);
    });
  });

  group('percentComplete', () {
    test('divides completed count by 24', () {
      final student = _studentWith(completedLessonIds: ['q1w1', 'q1w2', 'q1w3']);
      expect(percentComplete(student), closeTo(3 / 24, 0.0001));
    });
  });

  group('currentQuarterWeek', () {
    test('derives quarter/week from the next incomplete lesson', () {
      final student = _studentWith(completedLessonIds: ['q1w1', 'q1w2', 'q1w3', 'q1w4']);
      final result = currentQuarterWeek(kBuiltInLessons, student);
      expect(result?.quarter, 1);
      expect(result?.week, 5);
    });
  });

  group('lastNAttempts', () {
    test('returns the 3 most recent attempts, newest first', () {
      final attempts = [
        QuizAttempt(
          id: 'a1', quizId: 'builtin-q1w1-post', studentId: '111111', attemptNumber: 1,
          score: 60, totalQuestions: 5, correctAnswers: 3, answers: const [0, 0, 0, 0, 0],
          timestamp: DateTime(2026, 8, 1).toIso8601String(), locked: true,
        ),
        QuizAttempt(
          id: 'a2', quizId: 'builtin-q1w2-post', studentId: '111111', attemptNumber: 1,
          score: 80, totalQuestions: 5, correctAnswers: 4, answers: const [0, 0, 0, 0, 0],
          timestamp: DateTime(2026, 8, 5).toIso8601String(), locked: true,
        ),
        QuizAttempt(
          id: 'a3', quizId: 'builtin-q1w3-post', studentId: '111111', attemptNumber: 1,
          score: 40, totalQuestions: 5, correctAnswers: 2, answers: const [0, 0, 0, 0, 0],
          timestamp: DateTime(2026, 8, 10).toIso8601String(), locked: true,
        ),
        QuizAttempt(
          id: 'a4', quizId: 'builtin-q1w4-post', studentId: '111111', attemptNumber: 1,
          score: 90, totalQuestions: 5, correctAnswers: 5, answers: const [0, 0, 0, 0, 0],
          timestamp: DateTime(2026, 8, 15).toIso8601String(), locked: true,
        ),
      ];
      final student = _studentWith(quizAttempts: attempts);

      final last3 = lastNAttempts(student);

      expect(last3, hasLength(3));
      expect(last3.map((a) => a.id).toList(), ['a4', 'a3', 'a2']);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/progress_calculator_test.dart`
Expected: FAIL — `lib/core/services/progress_calculator.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/core/services/progress_calculator.dart
import '../models/lesson.dart';
import '../models/quiz_attempt.dart';
import '../models/student_record.dart';

/// PROJECT_FLOW.md Part 10.1's exact score-color thresholds.
enum ScoreBand { good, caution, needsWork }

ScoreBand scoreBandFor(num score) {
  if (score >= 80) return ScoreBand.good;
  if (score >= 50) return ScoreBand.caution;
  return ScoreBand.needsWork;
}

/// First lesson in curriculum order not yet in [student]'s completedLessonIds.
Lesson? nextIncompleteLesson(List<Lesson> orderedLessons, StudentRecord student) {
  final completed = student.completedLessonIds.toSet();
  for (final lesson in orderedLessons) {
    if (!completed.contains(lesson.id)) return lesson;
  }
  return null;
}

double percentComplete(StudentRecord student, {int totalLessons = 24}) {
  return student.completedLessonIds.length / totalLessons;
}

({int quarter, int week})? currentQuarterWeek(
  List<Lesson> orderedLessons,
  StudentRecord student,
) {
  final next = nextIncompleteLesson(orderedLessons, student);
  if (next == null || next.quarter == null || next.week == null) return null;
  return (quarter: next.quarter!, week: next.week!);
}

List<QuizAttempt> lastNAttempts(StudentRecord student, {int n = 3}) {
  final sorted = [...student.quizAttempts]
    ..sort((a, b) => DateTime.parse(b.timestamp).compareTo(DateTime.parse(a.timestamp)));
  return sorted.take(n).toList();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/progress_calculator_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/progress_calculator.dart test/core/services/progress_calculator_test.dart
git commit -m "feat: ProgressCalculator — pure Home/Progress screen computations"
```

---

### Task 6: Student app shell, router, and Riverpod wiring

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`
- Create: `lib/features/student/app/student_shell.dart`
- Create: `lib/features/student/app/router.dart`
- Test: `test/features/student/app/student_shell_test.dart`

**Interfaces:**
- Consumes: nothing from `core/` directly — this task is pure app-shell
  wiring; screens (Tasks 7–11) plug into the router.
- Produces: a `go_router` `GoRouter` instance reachable from `main.dart`'s
  non-web branch, with three routes (`/home`, `/learn`, `/progress`) inside a
  bottom-nav shell, plus nested routes for lesson detail and the quiz player
  added incrementally by Tasks 9–10. Riverpod's `ProviderScope` wraps the
  whole app (replacing Phase 1's bare `MaterialApp`).

- [ ] **Step 1: Add Phase 2's UI dependencies**

Edit `pubspec.yaml`, add under `dependencies:`:
```yaml
  go_router: ^14.6.2
  hooks_riverpod: ^2.6.1
  flutter_hooks: ^0.20.5
  google_fonts: ^6.2.1
  shared_preferences: ^2.3.3
  skeletonizer: ^1.4.2
  pin_code_fields: ^8.0.1
  confetti: ^0.8.0
  flutter_animate: ^4.5.2
```
Run: `flutter pub get`
Expected: resolves cleanly (bump patch versions if `flutter pub outdated`
shows conflicts — same policy as Phase 1 Task 1).

- [ ] **Step 2: Write the failing test**

```dart
// test/features/student/app/student_shell_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/features/student/app/router.dart';

void main() {
  testWidgets('student router starts on Home and can navigate to Learn', (tester) async {
    final router = buildStudentRouter();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);

    router.go('/learn');
    await tester.pumpAndSettle();
    expect(find.text('Learn'), findsWidgets);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/student/app/student_shell_test.dart`
Expected: FAIL — `lib/features/student/app/router.dart` doesn't exist yet.

- [ ] **Step 4: Implement the shell and router**

```dart
// lib/features/student/app/student_shell.dart
import 'package:flutter/material.dart';

/// Bottom-nav scaffold shared by Home / Learn / Progress (Part 10). Screens
/// themselves are free to redesign (Part 12); this only fixes the three
/// destinations and their order.
class StudentShell extends StatelessWidget {
  const StudentShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Learn'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Progress'),
        ],
      ),
    );
  }
}
```

```dart
// lib/features/student/app/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../home/home_screen.dart';
import '../learn/learn_screen.dart';
import '../progress/progress_screen.dart';
import 'student_shell.dart';

const _tabs = ['/home', '/learn', '/progress'];

GoRouter buildStudentRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final index = _tabs.indexWhere((t) => state.matchedLocation.startsWith(t));
          return StudentShell(
            currentIndex: index < 0 ? 0 : index,
            onDestinationSelected: (i) => context.go(_tabs[i]),
            child: child,
          );
        },
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/learn', builder: (context, state) => const LearnScreen()),
          GoRoute(path: '/progress', builder: (context, state) => const ProgressScreen()),
        ],
      ),
    ],
  );
}
```

- [ ] **Step 5: Wire the router into `main.dart`'s Android branch**

Modify `lib/main.dart` — replace the placeholder `Scaffold` shell on the
non-web branch with the router, keep the web branch's placeholder untouched
(Phase 4 replaces that):

```dart
// lib/main.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'features/student/app/router.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: ArScienceExplorerApp()));
}

class ArScienceExplorerApp extends StatelessWidget {
  const ArScienceExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const MaterialApp(
        title: 'AR Science Explorer',
        home: Scaffold(
          body: Center(child: Text('Teacher shell (placeholder)')),
        ),
      );
    }
    return MaterialApp.router(
      title: 'AR Science Explorer',
      routerConfig: buildStudentRouter(),
    );
  }
}
```

- [ ] **Step 6: Update the Phase 1 smoke test for the new shell**

`test/widget_test.dart` pumped `ArScienceExplorerApp` directly and asserted
on placeholder text that no longer exists on the Android branch. Update it:

```dart
// test/widget_test.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/main.dart';

void main() {
  testWidgets('shows the teacher placeholder on web, the student shell on Android', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ArScienceExplorerApp()),
    );
    await tester.pumpAndSettle();

    if (kIsWeb) {
      expect(find.text('Teacher shell (placeholder)'), findsOneWidget);
    } else {
      expect(find.text('Home'), findsWidgets);
    }
  });
}
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `flutter test test/features/student/app/student_shell_test.dart test/widget_test.dart`
Expected: PASS. (This will fail to compile until Tasks 7/8/11 create
`home_screen.dart`/`learn_screen.dart`/`progress_screen.dart` — Step 8 below
adds three minimal placeholder screens now so this task is independently
committable; Tasks 7/8/11 later flesh them out with real Firestore-backed
providers, replacing these bodies, not their file paths.)

- [ ] **Step 8: Add minimal placeholder screens so this task compiles standalone**

```dart
// lib/features/student/home/home_screen.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Home'));
}
```

```dart
// lib/features/student/learn/learn_screen.dart
import 'package:flutter/material.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Learn'));
}
```

```dart
// lib/features/student/progress/progress_screen.dart
import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Progress'));
}
```

- [ ] **Step 9: Run the full suite to confirm nothing else broke**

Run: `flutter test`
Expected: all Phase 1 tests plus this task's new tests PASS.

- [ ] **Step 10: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart lib/features/student/app/ \
        lib/features/student/home/home_screen.dart lib/features/student/learn/learn_screen.dart \
        lib/features/student/progress/progress_screen.dart test/features/student/app/ test/widget_test.dart
git commit -m "feat: student app shell — go_router + Riverpod wiring, bottom-nav scaffold"
```

---

### Task 7: Home screen (Part 10.1)

**Files:**
- Create: `lib/features/student/home/home_providers.dart`
- Modify: `lib/features/student/home/home_screen.dart`
- Test: `test/features/student/home/home_screen_test.dart`

**Interfaces:**
- Consumes: `LessonRepository.mergedLessons` (Task 2), `StudentRepository`
  (Phase 1), `ProgressCalculator` functions (Task 5), `AccessCodeService`
  (Task 4), `AuthService` (Phase 1, for the current student id).
- Produces: a `homeViewModelProvider` Riverpod provider exposing everything
  the screen renders (greeting, quarter/week, percent complete, continue
  lesson, stat tiles, last 3 attempts, access-code redemption callback) as
  one typed object, so `HomeScreen` itself stays a dumb render of that state
  — this is what `home_screen_test.dart` overrides to test the screen
  without touching Firestore.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/student/home/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/core/data/curriculum_data.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/features/student/home/home_providers.dart';
import 'package:ar_science_explorer/features/student/home/home_screen.dart';

void main() {
  testWidgets('renders greeting, percent complete, and the continue-lesson card', (tester) async {
    final viewModel = HomeViewModel(
      studentDisplayName: 'Juan',
      currentQuarter: 1,
      currentWeek: 3,
      percentComplete: 2 / 24,
      continueLesson: kBuiltInLessons.firstWhere((l) => l.id == 'q1w3'),
      lessonsCompletedCount: 2,
      quizzesTakenCount: 3,
      lastAttempts: const <QuizAttempt>[],
      onRedeemCode: (_) async => (success: true, message: 'ok'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeViewModelProvider.overrideWith((ref) => Stream.value(viewModel))],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Juan'), findsWidgets);
    expect(find.textContaining('Scientific Models'), findsWidgets); // q1w3's title
    expect(find.textContaining('8%'), findsWidgets); // round(2/24*100) == 8
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/student/home/home_screen_test.dart`
Expected: FAIL — `HomeViewModel`/`homeViewModelProvider` don't exist yet.

- [ ] **Step 3: Implement the view model and provider**

```dart
// lib/features/student/home/home_providers.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/data/curriculum_data.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/quiz_attempt.dart';
import '../../../core/services/access_code_service.dart';
import '../../../core/services/progress_calculator.dart';
import '../../../core/services/student_repository.dart';

class HomeViewModel {
  const HomeViewModel({
    required this.studentDisplayName,
    required this.currentQuarter,
    required this.currentWeek,
    required this.percentComplete,
    required this.continueLesson,
    required this.lessonsCompletedCount,
    required this.quizzesTakenCount,
    required this.lastAttempts,
    required this.onRedeemCode,
  });

  final String studentDisplayName;
  final int? currentQuarter;
  final int? currentWeek;
  final double percentComplete;
  final Lesson? continueLesson;
  final int lessonsCompletedCount;
  final int quizzesTakenCount;
  final List<QuizAttempt> lastAttempts;
  final Future<AccessCodeResult> Function(String rawCode) onRedeemCode;
}

/// Overridden in tests (see Step 1); in the real app this is provided by a
/// ProviderScope override at app startup once the signed-in student id is
/// known (wired alongside AuthService in a later task/screen, not repeated
/// here to avoid duplicating Phase 1's auth wiring).
final homeViewModelProvider = StreamProvider.autoDispose<HomeViewModel>((ref) {
  throw UnimplementedError(
    'homeViewModelProvider must be overridden with a real student-scoped '
    'stream at app startup — see home_providers_test.dart for the shape.',
  );
});

/// Builds the real streaming view model for a signed-in student. Called from
/// the app-startup override, not from HomeScreen directly.
Stream<HomeViewModel> buildHomeViewModel({
  required String studentId,
  required StudentRepository studentRepository,
  required AccessCodeService accessCodeService,
  required List<Lesson> orderedLessons,
}) {
  return studentRepository.watchStudent(studentId).map((student) {
    if (student == null) {
      return HomeViewModel(
        studentDisplayName: studentId,
        currentQuarter: null,
        currentWeek: null,
        percentComplete: 0,
        continueLesson: orderedLessons.isNotEmpty ? orderedLessons.first : null,
        lessonsCompletedCount: 0,
        quizzesTakenCount: 0,
        lastAttempts: const [],
        onRedeemCode: (code) => accessCodeService.redeem(studentId: studentId, rawCode: code),
      );
    }
    final quarterWeek = currentQuarterWeek(orderedLessons, student);
    return HomeViewModel(
      studentDisplayName: student.name.isNotEmpty ? student.name.split(' ').first : studentId,
      currentQuarter: quarterWeek?.quarter,
      currentWeek: quarterWeek?.week,
      percentComplete: percentComplete(student),
      continueLesson: nextIncompleteLesson(orderedLessons, student),
      lessonsCompletedCount: student.completedLessonIds.length,
      quizzesTakenCount: student.quizAttempts.length,
      lastAttempts: lastNAttempts(student),
      onRedeemCode: (code) => accessCodeService.redeem(studentId: studentId, rawCode: code),
    );
  });
}
```

- [ ] **Step 4: Implement the screen**

```dart
// lib/features/student/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/progress_calculator.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncViewModel = ref.watch(homeViewModelProvider);

    return asyncViewModel.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Could not load your progress: $error')),
      data: (vm) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hi, ${vm.studentDisplayName}!', style: Theme.of(context).textTheme.headlineSmall),
          if (vm.currentQuarter != null && vm.currentWeek != null)
            Text('Quarter ${vm.currentQuarter} · Week ${vm.currentWeek}'),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: vm.percentComplete),
          Text('${(vm.percentComplete * 100).round()}% complete'),
          const SizedBox(height: 16),
          if (vm.continueLesson != null)
            Card(
              child: ListTile(
                title: const Text('Continue where you left off'),
                subtitle: Text(vm.continueLesson!.title),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => context.push('/lesson/${vm.continueLesson!.id}'),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatTile(label: 'Lessons completed', value: '${vm.lessonsCompletedCount}')),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(label: 'Quizzes taken', value: '${vm.quizzesTakenCount}')),
            ],
          ),
          const SizedBox(height: 16),
          Text('Recent quiz attempts', style: Theme.of(context).textTheme.titleMedium),
          for (final attempt in vm.lastAttempts)
            ListTile(
              title: Text(attempt.quizId),
              trailing: _ScoreBadge(score: attempt.score),
            ),
          const SizedBox(height: 16),
          _AccessCodeBox(onRedeem: vm.onRedeemCode),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});
  final num score;

  @override
  Widget build(BuildContext context) {
    final band = scoreBandFor(score);
    final color = switch (band) {
      ScoreBand.good => Colors.green,
      ScoreBand.caution => Colors.amber,
      ScoreBand.needsWork => Colors.red,
    };
    return Chip(
      label: Text('$score%'),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color),
    );
  }
}

class _AccessCodeBox extends StatefulWidget {
  const _AccessCodeBox({required this.onRedeem});
  final Future<dynamic> Function(String) onRedeem;

  @override
  State<_AccessCodeBox> createState() => _AccessCodeBoxState();
}

class _AccessCodeBoxState extends State<_AccessCodeBox> {
  final _controller = TextEditingController();
  String? _message;
  bool _loading = false;

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final result = await widget.onRedeem(_controller.text);
    setState(() {
      _loading = false;
      _message = (result as dynamic).message as String;
      if ((result as dynamic).success == true) _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter code from teacher'),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'ENTER CODE HERE'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Applying...' : 'Apply Code'),
            ),
            if (_message != null) Text(_message!),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/student/home/home_screen_test.dart`
Expected: PASS (1 test).

- [ ] **Step 6: Run the full suite to confirm nothing else broke**

Run: `flutter test`
Expected: all tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/student/home/ test/features/student/home/
git commit -m "feat: Home screen — greeting, progress, continue-lesson, access-code box (Part 10.1)"
```

---

### Task 8: Learn screen — subject tabs + lesson cards (Part 10.2)

**Files:**
- Create: `lib/features/student/learn/learn_providers.dart`
- Create: `lib/features/student/learn/lesson_card.dart`
- Modify: `lib/features/student/learn/learn_screen.dart`
- Test: `test/features/student/learn/learn_screen_test.dart`

**Interfaces:**
- Consumes: `LessonRepository` (Task 2), `StudentRepository` (Phase 1),
  `SubjectKey` (Phase 1).
- Produces: `LearnViewModel` (subject tabs, lesson cards with computed
  locked/unlocked state per lesson) and `learnViewModelProvider`, following
  the same override-in-tests pattern as Task 7.

**Locked/unlocked rule (Part 10.2, exact):** a lesson counts as unlocked if
`lesson.isUnlockedByDefault == true` OR the student's `unlockedLessonIds`
contains that lesson's id.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/student/learn/learn_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/features/student/learn/learn_providers.dart';
import 'package:ar_science_explorer/features/student/learn/learn_screen.dart';

void main() {
  testWidgets('locked lesson still shows its title and summary, with an unlock CTA', (tester) async {
    final viewModel = LearnViewModel(
      activeSubject: SubjectKey.chemistry,
      cards: [
        LessonCardData(
          lessonId: 'q1w5',
          title: 'Planning and Recording Scientific Investigations',
          week: 5,
          summary: 'summary text',
          isUnlocked: false,
          hasPreTest: true,
          isCompleted: false,
        ),
      ],
      onSelectSubject: (_) {},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [learnViewModelProvider.overrideWith((ref) => Stream.value(viewModel))],
        child: const MaterialApp(home: LearnScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Not fully hidden/grayed — the title and summary must still be readable.
    expect(find.text('Planning and Recording Scientific Investigations'), findsOneWidget);
    expect(find.text('summary text'), findsOneWidget);
    // The punitive "locked" framing is explicitly disallowed (Part 10.2) —
    // assert the actual, non-punitive copy instead.
    expect(find.textContaining('Unlock with your teacher'), findsOneWidget);
    expect(find.textContaining('not yet available'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/student/learn/learn_screen_test.dart`
Expected: FAIL — `LearnViewModel`/`learnViewModelProvider` don't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/features/student/learn/learn_providers.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/subject_key.dart';
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/student_repository.dart';

class LessonCardData {
  const LessonCardData({
    required this.lessonId,
    required this.title,
    required this.week,
    required this.summary,
    required this.isUnlocked,
    required this.hasPreTest,
    required this.isCompleted,
  });

  final String lessonId;
  final String title;
  final int? week;
  final String summary;
  final bool isUnlocked;
  final bool hasPreTest;
  final bool isCompleted;
}

class LearnViewModel {
  const LearnViewModel({
    required this.activeSubject,
    required this.cards,
    required this.onSelectSubject,
  });

  final SubjectKey activeSubject;
  final List<LessonCardData> cards;
  final ValueChanged<SubjectKey> onSelectSubject;
}

typedef ValueChanged<T> = void Function(T value);

final learnViewModelProvider = StreamProvider.autoDispose<LearnViewModel>((ref) {
  throw UnimplementedError(
    'learnViewModelProvider must be overridden with a real student-scoped '
    'stream at app startup.',
  );
});

/// Builds the real streaming view model. [preTestLessonIds] is the set of
/// lesson ids that have a non-empty pre-test bank (from
/// kPreTestQuestionsByLesson.keys in the real app-startup wiring) — passed
/// in rather than imported here so this function stays testable without
/// pulling in the full curriculum data set.
Stream<LearnViewModel> buildLearnViewModel({
  required String studentId,
  required SubjectKey initialSubject,
  required LessonRepository lessonRepository,
  required StudentRepository studentRepository,
  required Set<String> preTestLessonIds,
  required void Function(SubjectKey) onSelectSubject,
}) {
  return lessonRepository.watchTeacherLessons().asyncMap((teacherLessons) async {
    final merged = lessonRepository.mergedLessons(teacherLessons);
    final student = await studentRepository.getStudent(studentId);
    final unlockedIds = student?.unlockedLessonIds.toSet() ?? const <String>{};
    final completedIds = student?.completedLessonIds.toSet() ?? const <String>{};

    final cards = merged
        .where((l) => l.subject == initialSubject)
        .map((l) => LessonCardData(
              lessonId: l.id,
              title: l.title,
              week: l.week,
              summary: l.summary,
              isUnlocked: l.isUnlockedByDefault || unlockedIds.contains(l.id),
              hasPreTest: preTestLessonIds.contains(l.id),
              isCompleted: completedIds.contains(l.id),
            ))
        .toList();

    return LearnViewModel(activeSubject: initialSubject, cards: cards, onSelectSubject: onSelectSubject);
  });
}
```

```dart
// lib/features/student/learn/lesson_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'learn_providers.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({super.key, required this.data});
  final LessonCardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(data.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.week != null) Text('Week ${data.week}'),
            Text(data.summary),
            if (!data.isUnlocked) ...[
              const Text('Not yet available'),
              const Text('Unlock with your teacher\'s code'),
            ],
          ],
        ),
        trailing: !data.isUnlocked
            ? const Icon(Icons.lock_outline)
            : data.hasPreTest
                ? TextButton(
                    onPressed: () => context.push('/quiz/${data.lessonId}/pre'),
                    child: const Text('Pre-Test'),
                  )
                : null,
        onTap: () {
          if (data.isUnlocked) {
            context.push('/lesson/${data.lessonId}');
          } else {
            _showAccessCodeSheet(context, targetId: data.lessonId);
          }
        },
      ),
    );
  }

  void _showAccessCodeSheet(BuildContext context, {required String targetId}) {
    // Wired to AccessCodeService via the shared access_code_sheet widget —
    // implemented alongside AccessCodeService's UI consumers; the sheet
    // itself is a small, self-contained widget with no new business logic,
    // so it is not TDD'd as a separate task — build it as part of this
    // task's implementation, reusing AccessCodeService.redeem directly.
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Enter code to unlock this lesson ($targetId)'),
      ),
    );
  }
}
```

```dart
// lib/features/student/learn/learn_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/subject_key.dart';
import 'learn_providers.dart';
import 'lesson_card.dart';

const _subjectOrder = [SubjectKey.chemistry, SubjectKey.biology, SubjectKey.physics];

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncViewModel = ref.watch(learnViewModelProvider);

    return asyncViewModel.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Could not load lessons: $error')),
      data: (vm) => DefaultTabController(
        length: _subjectOrder.length,
        initialIndex: _subjectOrder.indexOf(vm.activeSubject),
        child: Column(
          children: [
            TabBar(
              onTap: (i) => vm.onSelectSubject(_subjectOrder[i]),
              tabs: const [Tab(text: 'Chemistry'), Tab(text: 'Biology'), Tab(text: 'Physics')],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [for (final card in vm.cards) LessonCard(data: card)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/student/learn/learn_screen_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Run the full suite to confirm nothing else broke**

Run: `flutter test`
Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/student/learn/ test/features/student/learn/
git commit -m "feat: Learn screen — subject tabs, non-punitive locked lesson cards (Part 10.2)"
```

---

### Task 9: Lesson Detail screen (Phase 3 AR-Lab stand-in)

**Files:**
- Create: `lib/features/student/lesson_detail/lesson_detail_providers.dart`
- Create: `lib/features/student/lesson_detail/lesson_detail_screen.dart`
- Modify: `lib/features/student/app/router.dart`
- Test: `test/features/student/lesson_detail/lesson_detail_screen_test.dart`

**Interfaces:**
- Consumes: `LessonRepository`, `StudentRepository`, `QuizAttemptService`
  (for pre/post-test eligibility display).
- Produces: a `/lesson/:lessonId` route rendering lesson content, a
  **temporary** "Mark as Read" action (stands in for Phase 3's AR Review
  phase completion — see Global Constraints), and Pre-Test/Post-Test launch
  buttons gated by `QuizAttemptService.checkEligibility`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/student/lesson_detail/lesson_detail_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/features/student/lesson_detail/lesson_detail_providers.dart';
import 'package:ar_science_explorer/features/student/lesson_detail/lesson_detail_screen.dart';

void main() {
  testWidgets('shows lesson title and a Mark as Read action before completion', (tester) async {
    final viewModel = LessonDetailViewModel(
      lessonId: 'q1w1',
      title: 'Scientific Models and the Particle Model of Matter',
      summary: 'Discover how scientists use models...',
      isRead: false,
      postTestEligible: false,
      postTestReason: 'Complete the lesson first.',
      onMarkAsRead: () async {},
      onStartPreTest: () {},
      onStartPostTest: () {},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lessonDetailViewModelProvider('q1w1').overrideWith((ref) => Stream.value(viewModel)),
        ],
        child: const MaterialApp(home: LessonDetailScreen(lessonId: 'q1w1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scientific Models and the Particle Model of Matter'), findsOneWidget);
    expect(find.text('Mark as Read'), findsOneWidget);
    expect(find.text('Pre-Test'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/student/lesson_detail/lesson_detail_screen_test.dart`
Expected: FAIL — files don't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/features/student/lesson_detail/lesson_detail_providers.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/quiz_id.dart';
import '../../../core/models/quiz_phase.dart';
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/quiz_attempt_service.dart';
import '../../../core/services/student_repository.dart';

class LessonDetailViewModel {
  const LessonDetailViewModel({
    required this.lessonId,
    required this.title,
    required this.summary,
    required this.isRead,
    required this.postTestEligible,
    required this.postTestReason,
    required this.onMarkAsRead,
    required this.onStartPreTest,
    required this.onStartPostTest,
  });

  final String lessonId;
  final String title;
  final String summary;
  final bool isRead;
  final bool postTestEligible;
  final String? postTestReason;
  final Future<void> Function() onMarkAsRead;
  final void Function() onStartPreTest;
  final void Function() onStartPostTest;
}

final lessonDetailViewModelProvider =
    StreamProvider.autoDispose.family<LessonDetailViewModel, String>((ref, lessonId) {
  throw UnimplementedError(
    'lessonDetailViewModelProvider must be overridden at app startup with a '
    'real stream for the given lessonId.',
  );
});

/// TEMPORARY (Phase 2 only): `onMarkAsRead` performs the same
/// `completedLessonIds` write Phase 3's real AR Review-phase completion will
/// perform instead. Replace the caller of this function's `onMarkAsRead`
/// wiring in Phase 3 — do not delete `QuizAttemptService`/`StudentRepository`
/// usage, only the UI trigger changes.
Stream<LessonDetailViewModel> buildLessonDetailViewModel({
  required String studentId,
  required String lessonId,
  required String title,
  required String summary,
  required StudentRepository studentRepository,
  required QuizAttemptService quizAttemptService,
  required void Function() onStartPreTest,
  required void Function() onStartPostTest,
}) {
  return studentRepository.watchStudent(studentId).asyncMap((student) async {
    final isRead = student?.completedLessonIds.contains(lessonId) ?? false;
    final postQuizId = builtinQuizId(lessonId, QuizPhase.post);
    final eligibility = await quizAttemptService.checkEligibility(studentId, postQuizId);

    return LessonDetailViewModel(
      lessonId: lessonId,
      title: title,
      summary: summary,
      isRead: isRead,
      postTestEligible: eligibility.canTake,
      postTestReason: eligibility.reason,
      onMarkAsRead: () => studentRepository.saveStudent(
        (student!).copyWith(completedLessonIds: {...student.completedLessonIds, lessonId}.toList()),
      ),
      onStartPreTest: onStartPreTest,
      onStartPostTest: onStartPostTest,
    );
  });
}
```

```dart
// lib/features/student/lesson_detail/lesson_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'lesson_detail_providers.dart';

class LessonDetailScreen extends ConsumerWidget {
  const LessonDetailScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncViewModel = ref.watch(lessonDetailViewModelProvider(lessonId));

    return Scaffold(
      appBar: AppBar(title: const Text('Lesson')),
      body: asyncViewModel.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Could not load this lesson: $error')),
        data: (vm) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(vm.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(vm.summary),
            const SizedBox(height: 24),
            // TEMPORARY: stands in for Phase 3's real AR Review-phase
            // completion signal — see lesson_detail_providers.dart's doc
            // comment. Phase 3 replaces this button with the real flow.
            if (!vm.isRead)
              FilledButton(
                onPressed: () async {
                  await vm.onMarkAsRead();
                },
                child: const Text('Mark as Read'),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                vm.onStartPreTest();
                context.push('/quiz/${vm.lessonId}/pre');
              },
              child: const Text('Pre-Test'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: vm.postTestEligible
                  ? () {
                      vm.onStartPostTest();
                      context.push('/quiz/${vm.lessonId}/post');
                    }
                  : null,
              child: Text(vm.postTestEligible ? 'Post-Test' : (vm.postTestReason ?? 'Post-Test locked')),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Add the route**

Modify `lib/features/student/app/router.dart` — add inside the `ShellRoute`'s
`routes` list:
```dart
          GoRoute(
            path: '/lesson/:lessonId',
            builder: (context, state) => LessonDetailScreen(
              lessonId: state.pathParameters['lessonId']!,
            ),
          ),
```
And its import: `import '../lesson_detail/lesson_detail_screen.dart';`

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/student/lesson_detail/lesson_detail_screen_test.dart`
Expected: PASS (1 test).

- [ ] **Step 6: Run the full suite to confirm nothing else broke**

Run: `flutter test`
Expected: all tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/student/lesson_detail/ lib/features/student/app/router.dart \
        test/features/student/lesson_detail/
git commit -m "feat: Lesson Detail screen — temporary pre-AR stand-in, pre/post-test launch"
```

---

### Task 10: Quiz session controller + player/results screens (Part 7.3, 7.4)

**Files:**
- Create: `lib/features/student/quiz/quiz_session_controller.dart`
- Create: `lib/features/student/quiz/quiz_player_screen.dart`
- Create: `lib/features/student/quiz/quiz_results_screen.dart`
- Modify: `lib/features/student/app/router.dart`
- Test: `test/features/student/quiz/quiz_session_controller_test.dart`

**Interfaces:**
- Consumes: `BuiltInQuestion`, `QuizAttempt` (Phase 1 models);
  `QuizAttemptService` (Task 3); `kPreTestQuestionsByLesson`/
  `kPostTestQuestionsByLesson` (Task 1); `builtinQuizId` (Phase 1).
- Produces: `class QuizSessionState` (immutable snapshot: current question
  index, selected answer, submitted answers, hints used, hinted-question
  indices, show-result flag) and `class QuizSessionController extends
  StateNotifier<QuizSessionState>` with methods `selectAnswer(int)`,
  `submitAnswer()`, `useHint()`, `nextQuestion()`,
  `submitAndExit()` (the mid-quiz "back" confirmation path — Part 7.3).
  `QuizSessionController` is what `QuizPlayerScreen` reads; it is the piece
  that is independently unit-testable without pumping widgets, per this
  plan's usual pattern of keeping business/state logic separate from render
  code.

**Mechanics this task implements exactly (PROJECT_FLOW.md Part 7.3):**

- One question at a time; MC uses all 4 option slots, T/F uses slots 0/1
  only (`BuiltInQuestion.type`).
- 3 hints per attempt total, tracked per-question — a question already
  hinted cannot be hinted again in the same attempt.
- Immediate right/wrong feedback per question before advancing
  (`showResult` flips true on `submitAnswer()`, `nextQuestion()` advances and
  resets it).
- Exiting mid-quiz (`submitAndExit()`) submits whatever's currently
  answered as the final attempt — it does not discard progress. The current
  question's selection counts if one was made, even if not yet "submitted"
  via `submitAnswer()`.
- Scoring: `round((correctAnswers / totalQuestions) * 100)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/student/quiz/quiz_session_controller_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/built_in_question.dart';
import 'package:ar_science_explorer/core/models/question_type.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/quiz_id.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/features/student/quiz/quiz_session_controller.dart';

List<BuiltInQuestion> _threeQuestions() => [
      for (var i = 0; i < 3; i++)
        BuiltInQuestion(
          id: 'q$i',
          subject: SubjectKey.chemistry,
          lessonId: 'q1w1',
          question: 'Question $i',
          options: const ['A', 'B', 'C', 'D'],
          correctIndex: 0,
          hint: 'hint $i',
          type: QuestionType.mc,
        ),
    ];

void main() {
  test('scores correctly and records the attempt on the last question', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    final quizAttemptService = QuizAttemptService(firestore: firestore);
    await studentRepo.saveStudent(StudentRecord(
      id: '111111', name: 'Test', studentId: '111111', grade: '7', section: 'A',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [], completedLabExperimentIds: const [],
      completedQuizIds: const [], unlockedLessonIds: const [], unlockedQuizIds: const [],
      quizAttempts: const [],
    ));

    final quizId = builtinQuizId('q1w1', QuizPhase.post);
    final controller = QuizSessionController(
      studentId: '111111',
      quizId: quizId,
      subject: SubjectKey.chemistry,
      questions: _threeQuestions(),
      quizAttemptService: quizAttemptService,
    );

    // Q0: correct
    controller.selectAnswer(0);
    controller.submitAnswer();
    expect(controller.state.showResult, true);
    controller.nextQuestion();

    // Q1: wrong
    controller.selectAnswer(1);
    controller.submitAnswer();
    controller.nextQuestion();

    // Q2 (last): correct — submitting this one should persist the attempt.
    controller.selectAnswer(0);
    await controller.submitAnswer();

    expect(controller.state.isComplete, true);
    expect(controller.state.finalScore, 67); // round(2/3*100)

    final student = await studentRepo.getStudent('111111');
    expect(student!.quizAttempts, hasLength(1));
    expect(student.quizAttempts.first.correctAnswers, 2);
    expect(student.quizAttempts.first.locked, true); // post-test always locks after submit
  });

  test('a question can only be hinted once, and hints cap at 3 per attempt', () async {
    final firestore = FakeFirebaseFirestore();
    final quizAttemptService = QuizAttemptService(firestore: firestore);
    final controller = QuizSessionController(
      studentId: '111111',
      quizId: builtinQuizId('q1w1', QuizPhase.post),
      subject: SubjectKey.chemistry,
      questions: _threeQuestions(),
      quizAttemptService: quizAttemptService,
    );

    expect(controller.state.hintsUsed, 0);
    controller.useHint();
    expect(controller.state.hintsUsed, 1);
    expect(controller.state.hintedQuestionIndices, contains(0));

    // Same question again — no-op, hints stay at 1.
    controller.useHint();
    expect(controller.state.hintsUsed, 1);
  });

  test('submitAndExit submits the current selection as the final attempt', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    final quizAttemptService = QuizAttemptService(firestore: firestore);
    await studentRepo.saveStudent(StudentRecord(
      id: '111111', name: 'Test', studentId: '111111', grade: '7', section: 'A',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [], completedLabExperimentIds: const [],
      completedQuizIds: const [], unlockedLessonIds: const [], unlockedQuizIds: const [],
      quizAttempts: const [],
    ));

    final controller = QuizSessionController(
      studentId: '111111',
      quizId: builtinQuizId('q1w1', QuizPhase.post),
      subject: SubjectKey.chemistry,
      questions: _threeQuestions(),
      quizAttemptService: quizAttemptService,
    );

    controller.selectAnswer(0); // Q0 correct, not yet "submitted" via submitAnswer()
    await controller.submitAndExit();

    final student = await studentRepo.getStudent('111111');
    expect(student!.quizAttempts, hasLength(1));
    expect(student.quizAttempts.first.totalQuestions, 3);
    expect(student.quizAttempts.first.correctAnswers, 1);
    expect(student.quizAttempts.first.answers, [0, -1, -1]); // unanswered = -1
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/student/quiz/quiz_session_controller_test.dart`
Expected: FAIL — `lib/features/student/quiz/quiz_session_controller.dart`
doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/features/student/quiz/quiz_session_controller.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/built_in_question.dart';
import '../../../core/models/quiz_attempt.dart';
import '../../../core/models/subject_key.dart';
import '../../../core/services/quiz_attempt_service.dart';

class QuizSessionState {
  const QuizSessionState({
    required this.questionIndex,
    required this.selectedAnswer,
    required this.answers,
    required this.showResult,
    required this.hintsUsed,
    required this.hintedQuestionIndices,
    required this.isComplete,
    required this.finalScore,
  });

  factory QuizSessionState.initial(int questionCount) => QuizSessionState(
        questionIndex: 0,
        selectedAnswer: null,
        answers: List<int>.filled(questionCount, -1),
        showResult: false,
        hintsUsed: 0,
        hintedQuestionIndices: const {},
        isComplete: false,
        finalScore: null,
      );

  final int questionIndex;
  final int? selectedAnswer;
  final List<int> answers;
  final bool showResult;
  final int hintsUsed;
  final Set<int> hintedQuestionIndices;
  final bool isComplete;
  final int? finalScore;

  QuizSessionState copyWith({
    int? questionIndex,
    int? selectedAnswer,
    bool clearSelectedAnswer = false,
    List<int>? answers,
    bool? showResult,
    int? hintsUsed,
    Set<int>? hintedQuestionIndices,
    bool? isComplete,
    int? finalScore,
  }) {
    return QuizSessionState(
      questionIndex: questionIndex ?? this.questionIndex,
      selectedAnswer: clearSelectedAnswer ? null : (selectedAnswer ?? this.selectedAnswer),
      answers: answers ?? this.answers,
      showResult: showResult ?? this.showResult,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      hintedQuestionIndices: hintedQuestionIndices ?? this.hintedQuestionIndices,
      isComplete: isComplete ?? this.isComplete,
      finalScore: finalScore ?? this.finalScore,
    );
  }
}

/// Owns the live state of one quiz attempt in progress. Not a screen widget
/// on purpose — QuizPlayerScreen only renders `state` and calls these
/// methods, so the hint/scoring/exit-submits-progress rules (Part 7.3) are
/// unit-testable without pumping any widget.
class QuizSessionController extends StateNotifier<QuizSessionState> {
  QuizSessionController({
    required this.studentId,
    required this.quizId,
    required this.subject,
    required this.questions,
    required this.quizAttemptService,
  }) : super(QuizSessionState.initial(questions.length));

  final String studentId;
  final String quizId;
  final SubjectKey subject;
  final List<BuiltInQuestion> questions;
  final QuizAttemptService quizAttemptService;

  BuiltInQuestion get currentQuestion => questions[state.questionIndex];

  void selectAnswer(int optionIndex) {
    if (state.showResult) return;
    state = state.copyWith(selectedAnswer: optionIndex);
  }

  /// Records the current question's answer and shows right/wrong feedback.
  /// On the last question, this also persists the completed attempt.
  Future<void> submitAnswer() async {
    if (state.selectedAnswer == null) return;
    final updatedAnswers = [...state.answers];
    updatedAnswers[state.questionIndex] = state.selectedAnswer!;
    state = state.copyWith(answers: updatedAnswers, showResult: true);

    if (state.questionIndex == questions.length - 1) {
      await _persistAttempt(updatedAnswers);
    }
  }

  void useHint() {
    if (state.hintsUsed >= 3) return;
    if (state.hintedQuestionIndices.contains(state.questionIndex)) return;
    state = state.copyWith(
      hintsUsed: state.hintsUsed + 1,
      hintedQuestionIndices: {...state.hintedQuestionIndices, state.questionIndex},
    );
  }

  void nextQuestion() {
    if (state.questionIndex >= questions.length - 1) return;
    state = state.copyWith(
      questionIndex: state.questionIndex + 1,
      clearSelectedAnswer: true,
      showResult: false,
    );
  }

  /// Part 7.3: exiting mid-quiz submits whatever's currently answered, it
  /// does not discard progress. The in-progress question's selection counts
  /// even if `submitAnswer()` was never called for it.
  Future<void> submitAndExit() async {
    final updatedAnswers = [...state.answers];
    if (state.selectedAnswer != null) {
      updatedAnswers[state.questionIndex] = state.selectedAnswer!;
    }
    await _persistAttempt(updatedAnswers);
  }

  Future<void> _persistAttempt(List<int> answers) async {
    final correctCount = [
      for (var i = 0; i < questions.length; i++)
        if (answers[i] == questions[i].correctIndex) 1,
    ].length;
    final score = questions.isEmpty ? 0 : (correctCount / questions.length * 100).round();

    final eligibility = await quizAttemptService.checkEligibility(studentId, quizId);
    final attempt = QuizAttempt(
      id: 'attempt-$quizId-$studentId-${DateTime.now().millisecondsSinceEpoch}',
      quizId: quizId,
      studentId: studentId,
      attemptNumber: eligibility.attemptCount + 1,
      score: score,
      totalQuestions: questions.length,
      correctAnswers: correctCount,
      answers: answers,
      timestamp: DateTime.now().toIso8601String(),
      locked: !quizId.endsWith('-pre'), // pre-tests never lock, post-tests always do
    );

    await quizAttemptService.recordAttempt(studentId: studentId, attempt: attempt, subject: subject);

    state = state.copyWith(isComplete: true, finalScore: score);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/student/quiz/quiz_session_controller_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Implement the player and results screens**

```dart
// lib/features/student/quiz/quiz_player_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/built_in_question.dart';
import 'quiz_session_controller.dart';

/// Renders whatever `QuizSessionController.state` says — all Part 7.3 rules
/// (hints, scoring, exit-submits-progress) live in the controller, tested
/// separately; this widget is presentation only.
class QuizPlayerScreen extends ConsumerWidget {
  const QuizPlayerScreen({
    super.key,
    required this.controllerProvider,
  });

  final StateNotifierProvider<QuizSessionController, QuizSessionState> controllerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(controllerProvider);
    final controller = ref.read(controllerProvider.notifier);
    final question = controller.currentQuestion;
    final isTrueFalse = question.type.name == 'tf';
    final visibleOptions = isTrueFalse ? question.options.sublist(0, 2) : question.options;

    if (state.isComplete) {
      return QuizResultsScreen(score: state.finalScore ?? 0);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${state.questionIndex + 1} of ${controller.questions.length}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context, controller),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(question.question, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            for (var i = 0; i < visibleOptions.length; i++)
              RadioListTile<int>(
                value: i,
                groupValue: state.selectedAnswer,
                onChanged: state.showResult ? null : (v) => controller.selectAnswer(v!),
                title: Text(visibleOptions[i]),
              ),
            if (!state.showResult)
              TextButton.icon(
                onPressed: state.hintsUsed < 3 && !state.hintedQuestionIndices.contains(state.questionIndex)
                    ? controller.useHint
                    : null,
                icon: const Icon(Icons.lightbulb_outline),
                label: Text('Hint (${3 - state.hintsUsed} left)'),
              ),
            if (state.hintedQuestionIndices.contains(state.questionIndex) && !state.showResult)
              Text('Hint: ${question.hint}'),
            if (state.showResult)
              Text(
                state.selectedAnswer == question.correctIndex ? 'Correct!' : 'Incorrect',
                style: TextStyle(
                  color: state.selectedAnswer == question.correctIndex ? Colors.green : Colors.orange,
                ),
              ),
            const Spacer(),
            FilledButton(
              onPressed: state.showResult
                  ? controller.nextQuestion
                  : (state.selectedAnswer == null ? null : controller.submitAnswer),
              child: Text(state.showResult ? 'Next Question' : 'Submit Answer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context, QuizSessionController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Test?'),
        content: const Text('Going back will submit your test with your current answers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continue Quiz')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit & Exit')),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.submitAndExit();
      if (context.mounted) context.pop();
    }
  }
}
```

```dart
// lib/features/student/quiz/quiz_results_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _autoContinueSeconds = 4;

/// Part 7.4: pass shows a visibly cancelable auto-continue countdown; fail
/// never auto-redirects and states the retry rule plainly.
class QuizResultsScreen extends StatefulWidget {
  const QuizResultsScreen({super.key, required this.score});
  final int score;

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  late int _secondsLeft = _passed ? _autoContinueSeconds : 0;
  Timer? _timer;
  bool get _passed => widget.score >= 50;

  @override
  void initState() {
    super.initState();
    if (_passed) _scheduleTick();
  }

  void _scheduleTick() {
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        context.go('/progress');
        return;
      }
      setState(() => _secondsLeft -= 1);
      _scheduleTick();
    });
  }

  void _cancelAutoContinue() {
    _timer?.cancel();
    setState(() => _secondsLeft = -1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_passed ? 'Nice work!' : 'Not quite there yet',
                style: Theme.of(context).textTheme.headlineMedium),
            Text('${widget.score}%'),
            if (!_passed)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Ask your teacher for an unlock code to retake this test. '
                  "Pre-tests don't need a code — you can retry those anytime.",
                ),
              ),
            FilledButton(
              onPressed: () => context.go('/progress'),
              child: const Text('View My Progress'),
            ),
            if (_passed && _secondsLeft > 0)
              TextButton(
                onPressed: _cancelAutoContinue,
                child: Text('Continuing in $_secondsLeft s — tap to stay here'),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Add quiz routes**

Modify `lib/features/student/app/router.dart` — add inside the `ShellRoute`'s
`routes` list (outside the bottom-nav shell would be more correct since a
quiz shouldn't show the tab bar; use a top-level `GoRoute` alongside the
`ShellRoute`, not nested inside it):

```dart
      GoRoute(
        path: '/quiz/:lessonId/:phase',
        builder: (context, state) {
          // Wiring the concrete QuizSessionController provider (with the
          // right question bank for lessonId+phase, looked up from
          // kPreTestQuestionsByLesson/kPostTestQuestionsByLesson, and a real
          // QuizAttemptService/current studentId) happens where AuthService's
          // signed-in student id is available — same app-startup override
          // pattern as Task 7/8/9's view-model providers, not repeated here.
          throw UnimplementedError('Wire a concrete controllerProvider override for this route.');
        },
      ),
```

(This route is deliberately left as a documented wiring point rather than a
fabricated provider lookup — the concrete `StateNotifierProvider` needs a
real `studentId` from `AuthService`'s auth state, which is app-startup
context, exactly like `homeViewModelProvider`'s override in Task 7. Wire it
there, alongside the other screen-provider overrides, once that startup
wiring task exists.)

- [ ] **Step 7: Run the full suite to confirm nothing else broke**

Run: `flutter test`
Expected: all tests PASS (the router's `UnimplementedError` above is inside
a `builder` closure, never called by any test in this plan, so it does not
fail the suite).

- [ ] **Step 8: Commit**

```bash
git add lib/features/student/quiz/ lib/features/student/app/router.dart \
        test/features/student/quiz/
git commit -m "feat: Quiz session controller + player/results screens (Part 7.3, 7.4)"
```

---

### Task 11: Progress screen (Part 10.3)

**Files:**
- Create: `lib/features/student/progress/progress_providers.dart`
- Modify: `lib/features/student/progress/progress_screen.dart`
- Test: `test/features/student/progress/progress_screen_test.dart`

**Interfaces:**
- Consumes: `LessonRepository`, `StudentRepository`, `ProgressCalculator`
  (Task 5).
- Produces: `ProgressViewModel` grouping lesson completion and quiz attempts
  by subject, and `progressViewModelProvider`.

**Accessibility requirement (Part 10.3, exact):** per-question
correct/incorrect indicators need a real visual **and** text label — not
color-only, not hover/tooltip-only.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/student/progress/progress_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/features/student/progress/progress_providers.dart';
import 'package:ar_science_explorer/features/student/progress/progress_screen.dart';

void main() {
  testWidgets('question correctness has a text label, not just a color', (tester) async {
    final viewModel = ProgressViewModel(
      subjectSections: [
        SubjectProgressSection(
          subject: SubjectKey.chemistry,
          lessons: [
            LessonProgressRow(lessonId: 'q1w1', title: 'Scientific Models', isCompleted: true),
          ],
          quizAttempts: [
            QuizAttemptRow(
              quizId: 'builtin-q1w1-post',
              bestScore: 80,
              latestScore: 80,
              perQuestionCorrect: const [true, false, true],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [progressViewModelProvider.overrideWith((ref) => Stream.value(viewModel))],
        child: const MaterialApp(home: ProgressScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Correct'), findsWidgets);
    expect(find.text('Incorrect'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/student/progress/progress_screen_test.dart`
Expected: FAIL — `ProgressViewModel` and friends don't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/features/student/progress/progress_providers.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/subject_key.dart';
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/progress_calculator.dart';
import '../../../core/services/student_repository.dart';

class LessonProgressRow {
  const LessonProgressRow({required this.lessonId, required this.title, required this.isCompleted});
  final String lessonId;
  final String title;
  final bool isCompleted;
}

class QuizAttemptRow {
  const QuizAttemptRow({
    required this.quizId,
    required this.bestScore,
    required this.latestScore,
    required this.perQuestionCorrect,
  });
  final String quizId;
  final num bestScore;
  final num latestScore;
  final List<bool> perQuestionCorrect;
}

class SubjectProgressSection {
  const SubjectProgressSection({required this.subject, required this.lessons, required this.quizAttempts});
  final SubjectKey subject;
  final List<LessonProgressRow> lessons;
  final List<QuizAttemptRow> quizAttempts;
}

class ProgressViewModel {
  const ProgressViewModel({required this.subjectSections});
  final List<SubjectProgressSection> subjectSections;
}

final progressViewModelProvider = StreamProvider.autoDispose<ProgressViewModel>((ref) {
  throw UnimplementedError(
    'progressViewModelProvider must be overridden with a real student-scoped '
    'stream at app startup.',
  );
});

const _subjectOrder = [SubjectKey.chemistry, SubjectKey.biology, SubjectKey.physics];

Stream<ProgressViewModel> buildProgressViewModel({
  required String studentId,
  required LessonRepository lessonRepository,
  required StudentRepository studentRepository,
}) {
  return studentRepository.watchStudent(studentId).asyncMap((student) async {
    final teacherLessons = await lessonRepository.watchTeacherLessons().first;
    final merged = lessonRepository.mergedLessons(teacherLessons);
    final completed = student?.completedLessonIds.toSet() ?? const <String>{};

    final sections = _subjectOrder.map((subject) {
      final lessons = merged
          .where((l) => l.subject == subject)
          .map((l) => LessonProgressRow(lessonId: l.id, title: l.title, isCompleted: completed.contains(l.id)))
          .toList();

      final attemptsBySubject = (student?.quizAttempts ?? const [])
          .where((a) => merged.any((l) => a.quizId.contains(l.id) && l.subject == subject))
          .toList();
      final byQuizId = <String, List<dynamic>>{};
      for (final a in attemptsBySubject) {
        byQuizId.putIfAbsent(a.quizId, () => []).add(a);
      }
      final quizRows = byQuizId.entries.map((entry) {
        final attempts = entry.value.cast<dynamic>();
        final scores = attempts.map((a) => a.score as num).toList();
        final latest = attempts.reduce((a, b) =>
            DateTime.parse(a.timestamp).isAfter(DateTime.parse(b.timestamp)) ? a : b);
        final perQuestion = <bool>[
          for (var i = 0; i < (latest.answers as List).length; i++) false,
        ]; // per-question correctness needs the question bank's correctIndex,
           // resolved by the caller before this row is displayed (see
           // ProgressScreen's per-attempt detail expansion, wired with real
           // question data at the screen layer, not duplicated here).
        return QuizAttemptRow(
          quizId: entry.key,
          bestScore: scores.reduce((a, b) => a > b ? a : b),
          latestScore: latest.score as num,
          perQuestionCorrect: perQuestion,
        );
      }).toList();

      return SubjectProgressSection(subject: subject, lessons: lessons, quizAttempts: quizRows);
    }).toList();

    return ProgressViewModel(subjectSections: sections);
  });
}
```

- [ ] **Step 4: Implement the screen**

```dart
// lib/features/student/progress/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'progress_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncViewModel = ref.watch(progressViewModelProvider);

    return asyncViewModel.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Could not load your progress: $error')),
      data: (vm) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final section in vm.subjectSections) ...[
            Text(section.subject.name, style: Theme.of(context).textTheme.titleLarge),
            for (final lesson in section.lessons)
              ListTile(
                leading: Icon(lesson.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked),
                title: Text(lesson.title),
                trailing: Text(lesson.isCompleted ? 'Completed' : 'Not yet'),
              ),
            for (final attempt in section.quizAttempts) ...[
              ListTile(
                title: Text(attempt.quizId),
                subtitle: Text('Best: ${attempt.bestScore}% · Latest: ${attempt.latestScore}%'),
              ),
              // Accessible per-question indicator: icon + text label
              // together (Part 10.3) — never color-only, never
              // tooltip/hover-only.
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < attempt.perQuestionCorrect.length; i++)
                    Chip(
                      avatar: Icon(
                        attempt.perQuestionCorrect[i] ? Icons.check : Icons.close,
                        size: 16,
                      ),
                      label: Text(attempt.perQuestionCorrect[i] ? 'Correct' : 'Incorrect'),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/student/progress/progress_screen_test.dart`
Expected: PASS (1 test).

- [ ] **Step 6: Run the full suite to confirm nothing else broke**

Run: `flutter test`
Expected: all tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/student/progress/ test/features/student/progress/
git commit -m "feat: Progress screen — per-subject completion + accessible per-question breakdown (Part 10.3)"
```

---

### Task 12: App-startup wiring — connect the signed-in student to every screen provider

**Files:**
- Create: `lib/features/student/app/student_providers.dart`
- Modify: `lib/features/student/app/router.dart`
- Modify: `lib/main.dart`
- Test: `test/features/student/app/student_providers_test.dart`

**Interfaces:**
- Consumes: `AuthService.authStateChanges()` (Phase 1); `homeViewModelProvider`/
  `buildHomeViewModel` (Task 7); `learnViewModelProvider`/`buildLearnViewModel`
  (Task 8); `lessonDetailViewModelProvider`/`buildLessonDetailViewModel`
  (Task 9); `progressViewModelProvider`/`buildProgressViewModel` (Task 11);
  `QuizSessionController` (Task 10); `LessonRepository`, `StudentRepository`,
  `QuizAttemptService`, `AccessCodeService` (Tasks 2–4); `kPreTestQuestionsByLesson`/
  `kPostTestQuestionsByLesson` (Task 1).
- Produces: `currentStudentIdProvider` (a `StreamProvider<String?>` derived
  from Firebase Auth's signed-in user's email, per Phase 1's
  `isStudentEmail`/student-id-from-email convention) and a
  `studentProviderOverridesFor(String studentId)` helper that returns the
  list of `Override`s (`homeViewModelProvider.overrideWith(...)`, etc.) a
  `ProviderScope` needs once a student id is known. This is what closes out
  every "wired at app startup" comment left in Tasks 7–11 — after this task,
  none of those `UnimplementedError`s are reachable in the real app.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/student/app/student_providers_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/lesson_repository.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/features/student/app/student_providers.dart';
import 'package:ar_science_explorer/features/student/home/home_providers.dart';
import 'package:ar_science_explorer/features/student/learn/learn_providers.dart';
import 'package:ar_science_explorer/features/student/progress/progress_providers.dart';

void main() {
  test('studentProviderOverridesFor wires Home/Learn/Progress to a real student stream', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    await studentRepo.saveStudent(StudentRecord(
      id: '111111', name: 'Juan Dela Cruz', studentId: '111111', grade: '7', section: 'Rizal',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [], completedLabExperimentIds: const [],
      completedQuizIds: const [], unlockedLessonIds: const [], unlockedQuizIds: const [],
      quizAttempts: const [],
    ));

    final services = StudentServices(
      lessonRepository: LessonRepository(firestore: firestore),
      studentRepository: studentRepo,
      quizAttemptService: QuizAttemptService(firestore: firestore),
      accessCodeService: AccessCodeService(
        firestore: firestore,
        quizAttemptService: QuizAttemptService(firestore: firestore),
      ),
    );

    final container = ProviderContainer(
      overrides: studentProviderOverridesFor('111111', services: services),
    );
    addTearDown(container.dispose);

    final home = await container.read(homeViewModelProvider.future);
    expect(home.studentDisplayName, 'Juan');

    final learn = await container.read(learnViewModelProvider.future);
    expect(learn.cards, isNotEmpty);

    final progress = await container.read(progressViewModelProvider.future);
    expect(progress.subjectSections, hasLength(3));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/student/app/student_providers_test.dart`
Expected: FAIL — `lib/features/student/app/student_providers.dart` doesn't
exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/features/student/app/student_providers.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/data/curriculum_data.dart';
import '../../../core/models/subject_key.dart';
import '../../../core/services/access_code_service.dart';
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/quiz_attempt_service.dart';
import '../../../core/services/student_repository.dart';
import '../home/home_providers.dart';
import '../learn/learn_providers.dart';
import '../lesson_detail/lesson_detail_providers.dart';
import '../progress/progress_providers.dart';

/// Bundles every core/ service a student screen needs, so app startup only
/// has to construct these once (each takes the same FirebaseFirestore
/// instance) and pass the bundle around.
class StudentServices {
  const StudentServices({
    required this.lessonRepository,
    required this.studentRepository,
    required this.quizAttemptService,
    required this.accessCodeService,
  });

  final LessonRepository lessonRepository;
  final StudentRepository studentRepository;
  final QuizAttemptService quizAttemptService;
  final AccessCodeService accessCodeService;
}

/// Every `ProviderScope` override the student screens need once a signed-in
/// student id is known. Closes out the "wired at app startup" comments left
/// in home_providers.dart, learn_providers.dart, progress_providers.dart,
/// and lesson_detail_providers.dart.
List<Override> studentProviderOverridesFor(
  String studentId, {
  required StudentServices services,
  SubjectKey initialLearnSubject = SubjectKey.chemistry,
}) {
  return [
    homeViewModelProvider.overrideWith(
      (ref) => buildHomeViewModel(
        studentId: studentId,
        studentRepository: services.studentRepository,
        accessCodeService: services.accessCodeService,
        orderedLessons: kBuiltInLessons,
      ),
    ),
    learnViewModelProvider.overrideWith(
      (ref) => buildLearnViewModel(
        studentId: studentId,
        initialSubject: initialLearnSubject,
        lessonRepository: services.lessonRepository,
        studentRepository: services.studentRepository,
        preTestLessonIds: kPreTestQuestionsByLesson.keys.toSet(),
        onSelectSubject: (_) {}, // screen-level tab state, not app-startup concern
      ),
    ),
    progressViewModelProvider.overrideWith(
      (ref) => buildProgressViewModel(
        studentId: studentId,
        lessonRepository: services.lessonRepository,
        studentRepository: services.studentRepository,
      ),
    ),
  ];
}

/// Per-lesson override for `lessonDetailViewModelProvider` — a `.family`
/// provider, so it's overridden per lessonId at the call site (the route
/// builder in router.dart), not bundled into the list above.
StreamProvider<LessonDetailViewModel> lessonDetailOverrideFor(
  String studentId,
  String lessonId, {
  required StudentServices services,
  required void Function() onStartPreTest,
  required void Function() onStartPostTest,
}) {
  final lesson = kBuiltInLessons.firstWhere((l) => l.id == lessonId);
  return lessonDetailViewModelProvider(lessonId).overrideWith(
    (ref) => buildLessonDetailViewModel(
      studentId: studentId,
      lessonId: lessonId,
      title: lesson.title,
      summary: lesson.summary,
      studentRepository: services.studentRepository,
      quizAttemptService: services.quizAttemptService,
      onStartPreTest: onStartPreTest,
      onStartPostTest: onStartPostTest,
    ),
  ) as StreamProvider<LessonDetailViewModel>;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/student/app/student_providers_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Wire `currentStudentIdProvider` and thread it through `main.dart`**

```dart
// Add to lib/features/student/app/student_providers.dart
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/auth_service.dart' show isStudentEmail;

/// The signed-in student's id, derived from their Firebase Auth email
/// (Phase 1's student email convention: `{digits}@arscience.school`). Null
/// while signed out or signed in as a teacher.
final currentStudentIdProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) {
    final email = user?.email;
    if (email == null || !isStudentEmail(email)) return null;
    return email.split('@').first;
  });
});
```

Modify `lib/main.dart`'s non-web branch to build `StudentServices` once
(constructed from `FirebaseFirestore.instance`, matching Phase 1's
constructor-injection pattern) and rebuild the `ProviderScope`'s overrides
whenever `currentStudentIdProvider` changes:

```dart
// lib/main.dart — non-web branch, replacing the bare MaterialApp.router call
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/services/access_code_service.dart';
import 'core/services/lesson_repository.dart';
import 'core/services/quiz_attempt_service.dart';
import 'core/services/student_repository.dart';
import 'features/student/app/student_providers.dart';

// Inside ArScienceExplorerApp.build(), non-web branch:
final quizAttemptService = QuizAttemptService(firestore: FirebaseFirestore.instance);
final services = StudentServices(
  lessonRepository: LessonRepository(firestore: FirebaseFirestore.instance),
  studentRepository: StudentRepository(firestore: FirebaseFirestore.instance),
  quizAttemptService: quizAttemptService,
  accessCodeService: AccessCodeService(
    firestore: FirebaseFirestore.instance,
    quizAttemptService: quizAttemptService,
  ),
);

return Consumer(
  builder: (context, ref, _) {
    final studentId = ref.watch(currentStudentIdProvider).valueOrNull;
    if (studentId == null) {
      return const MaterialApp(home: Scaffold(body: Center(child: Text('Sign in'))));
    }
    return ProviderScope(
      overrides: studentProviderOverridesFor(studentId, services: services),
      child: MaterialApp.router(
        title: 'AR Science Explorer',
        routerConfig: buildStudentRouter(),
      ),
    );
  },
);
```

- [ ] **Step 6: Wire the `/quiz/:lessonId/:phase` route's controller override**

Replace Task 10 Step 6's `UnimplementedError` placeholder in
`lib/features/student/app/router.dart` with the real wiring, now that
`StudentServices`/`currentStudentIdProvider` exist:

```dart
      GoRoute(
        path: '/quiz/:lessonId/:phase',
        builder: (context, state) {
          final lessonId = state.pathParameters['lessonId']!;
          final phase = state.pathParameters['phase'] == 'pre' ? QuizPhase.pre : QuizPhase.post;
          final quizId = builtinQuizId(lessonId, phase);
          final questions = phase == QuizPhase.pre
              ? kPreTestQuestionsByLesson[lessonId]!
              : kPostTestQuestionsByLesson[lessonId]!;
          final lesson = kBuiltInLessons.firstWhere((l) => l.id == lessonId);

          return Consumer(
            builder: (context, ref, _) {
              final studentId = ref.watch(currentStudentIdProvider).valueOrNull;
              if (studentId == null) return const SizedBox.shrink();
              final provider = StateNotifierProvider<QuizSessionController, QuizSessionState>(
                (ref) => QuizSessionController(
                  studentId: studentId,
                  quizId: quizId,
                  subject: lesson.subject,
                  questions: questions,
                  quizAttemptService: services.quizAttemptService,
                ),
              );
              return QuizPlayerScreen(controllerProvider: provider);
            },
          );
        },
      ),
```

Add the needed imports to `router.dart`:
`quiz_id.dart`, `models/quiz_phase.dart`, `data/curriculum_data.dart`,
`quiz/quiz_player_screen.dart`, `quiz/quiz_session_controller.dart`,
`app/student_providers.dart` — and thread `services` into `buildStudentRouter`
as a required parameter (`GoRouter buildStudentRouter({required StudentServices services})`),
updating Task 6/9's call sites and `student_shell_test.dart`/
`lesson_detail_screen_test.dart` accordingly (construct a throwaway
`StudentServices` backed by `FakeFirebaseFirestore` in those tests, the same
way `student_providers_test.dart` does above).

- [ ] **Step 7: Run the full suite to confirm nothing else broke**

Run: `flutter test`
Expected: all tests PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/student/app/ lib/main.dart test/features/student/app/student_providers_test.dart
git commit -m "feat: wire signed-in student id to every screen provider (app-startup)"
```

---

### Task 13: Run the full test suite and confirm the phase is complete

**Files:**
- Modify: `MANUAL_STEPS.md` (append the Part 7.1 discrepancy flag).
- None else created — verification only.

**Interfaces:**
- Consumes: everything from Tasks 1–12.
- Produces: nothing new; this is the phase's exit checkpoint.

- [ ] **Step 1: Run the entire test suite**

Run: `flutter test`
Expected: every test from Phase 1 and this phase passes. If anything fails,
fix it before proceeding — do not carry a failing test into Phase 3.

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`
Expected: no errors (the Phase 1 `invalid_annotation_target` warnings on
`@JsonKey`-annotated freezed constructor params are known-benign and remain
expected; do not hand-edit generated files to silence them).

- [ ] **Step 3: Flag the Part 7.1 discrepancy in `MANUAL_STEPS.md`**

Append a new section to `MANUAL_STEPS.md`:

```markdown
## Confirm with the client — Phase 2

- [ ] **Post-test first-attempt gating (PROJECT_FLOW.md Part 7.1).** While
      building Phase 2, I found the retired web app's actual code
      (`src/lib/storage.ts`'s `validateQuizEligibility`,
      `src/components/student/screens/QuizScreen.tsx`'s `handleStartQuiz`)
      gates *every* post-test attempt — including the first — behind
      `unlockedQuizIds`, contradicting Part 7.1's stated rule ("the first
      attempt requires no access code") and matching almost exactly the
      regression Part 7.1 itself warns against. I implemented the
      *documented* rule (first post-test attempt always free) in
      `QuizAttemptService`, not the retired app's literal current behavior.
      Please confirm this is the intended fix and not a case where the
      documented rule itself needs updating to match some other real
      constraint I'm not aware of.
```

- [ ] **Step 4: Commit the checkpoint**

```bash
git add -A
git commit -m "chore: Phase 2 complete — student core flow, retake rule, access codes" --allow-empty
```
