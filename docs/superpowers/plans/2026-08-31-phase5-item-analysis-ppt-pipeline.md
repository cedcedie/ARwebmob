# Phase 5: Item Analysis + PPT/PDF Storage Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Teacher Web's item analysis reporting (difficulty index,
discrimination index, distractor analysis — PROJECT_FLOW.md Part 7.5) and
move lesson content (PDF and the new PPTX support) off the old
`localStorage` approach onto real Firebase Storage, with a Cloud Function
converting an uploaded PPTX into slide images a student can actually view
(Part 8).

**Architecture:** Item analysis is pure client-side computation over data
that already exists (`quizAttempts[]`, Phase 2) — no new Firestore writes,
no backend component. The PPT/PDF pipeline is the one part of this whole
project that needs a real backend component: a Storage-triggered Firebase
Cloud Function (Cloud Run-based, running headless LibreOffice in a custom
container) converts an uploaded `.pptx` into one PNG per slide. Both content
types (a plain PDF, or PPTX-derived slide images) write to the same
`contentImageUrls: List<String>` field on `TeacherLesson`, so the student
viewer only branches on "how many URLs," not on two separate content types.

**Tech Stack:** `firebase_storage`, `file_picker` (teacher-side upload),
`fl_chart` (item analysis charts), `photo_view` (student slide gallery);
Node.js 20 + `firebase-functions` v2 + a Cloud Run container with
`libreoffice-impress` installed, deployed via `firebase deploy --only
functions`. Everything from Phases 1–4 continues unchanged.

**Spec:** `PROJECT_FLOW.md` Part 7.5, Part 8 (all subsections); design spec
`docs/superpowers/specs/2026-08-28-flutter-ar-science-explorer-design.md`
Section 6 (Phase 5) and Section 7 (Q1/Q2, both confirmed 2026-08-31). This
plan does not restate their content, only implements it.

## Global Constraints

- **Item analysis is Teacher Web only, computed on-demand, no new Firestore
  writes.** Confirmed Q1 (2026-08-31). Reuses `quizAttempts[]`'s existing
  `answers: List<int>` per attempt (Phase 2) — nothing new to collect.
- **PPTX conversion happens via a Cloud Function, not a third-party paid
  API.** Confirmed Q2 (2026-08-31). This requires the Firebase project on
  the paid "Blaze" plan (a real account-level action only the user can take
  — tracked in `MANUAL_STEPS.md`, confirm before Task 8 is dispatched).
- **No in-app editing of PPT/PDF content.** A teacher uploads a finished
  file (made externally — Canva, PowerPoint, whatever); the app converts
  and displays it, never edits its content.
- **Both PDF and PPTX write to the same field shape**:
  `TeacherLesson.contentImageUrls` (a new `List<String>?` field — 1 entry
  for a PDF's own URL treated as a single "page", N entries for PPTX-derived
  slide PNGs) plus `TeacherLesson.contentStatus` (a new `String?` field:
  `'processing'` while a Cloud Function conversion is in flight, `'ready'`
  once done, absent/null for a lesson with no uploaded content or a
  same-request PDF that never needed conversion). The existing `pdfUrl`
  field is NOT reused for this — it predates Storage and stays as dead
  legacy data on old records; new uploads always go through
  `contentImageUrls`/`contentStatus`.
- **The Cloud Function has no automated test harness in this project** (a
  separate Node.js codebase, not Flutter/Dart) — same situation as Phase
  3's Unity C# work. Its task's "testing" step is a real deployment +
  manual upload test, not `flutter test`. Confirm the Blaze-plan
  prerequisite with the user before dispatching that task.
- All new Firestore-touching Dart classes take their dependency as a
  constructor parameter (the established Phase 1–4 pattern) so tests use
  `fake_cloud_firestore`.
- Visual design is free to redesign (PROJECT_FLOW.md Part 12) as long as
  every documented requirement is met.

---

## File Structure

```
functions/                                  # NEW — separate Node.js codebase, not under lib/
  package.json                              # firebase-functions, firebase-admin deps
  src/index.js                              # onObjectFinalized Storage trigger
  Dockerfile                                # custom Cloud Run container w/ LibreOffice
  .gcloudignore

lib/
  core/
    models/
      teacher_lesson.dart                   # MODIFIED — add contentImageUrls, contentStatus
    services/
      lesson_content_upload_service.dart    # NEW — Storage upload for teacher lesson content
      item_analysis_calculator.dart         # NEW — difficulty/discrimination/distractor math
  features/
    teacher/
      lessons/
        lesson_form.dart                    # MODIFIED — file-picker upload UI
      quizzes/
        item_analysis_providers.dart        # NEW — fetches attempts, runs the calculator
        item_analysis_screen.dart           # NEW — fl_chart rendering, per-question breakdown
    student/
      ar_lab/
        read_tab.dart                       # MODIFIED — content viewer (photo_view gallery / processing state)
        content_viewer.dart                 # NEW — the actual gallery widget

test/
  core/
    services/
      item_analysis_calculator_test.dart
      lesson_content_upload_service_test.dart
  features/
    teacher/
      quizzes/
        item_analysis_providers_test.dart
        item_analysis_screen_test.dart
    student/
      ar_lab/
        content_viewer_test.dart
        read_tab_test.dart                  # extended, not replaced
```

---

### Task 1: `ItemAnalysisCalculator` — difficulty, discrimination, distractor math

**Files:**
- Create: `lib/core/services/item_analysis_calculator.dart`
- Test: `test/core/services/item_analysis_calculator_test.dart`

**Interfaces:**
- Consumes: `QuizAttempt` (Phase 2 model — `answers: List<int>`, `score`,
  `studentId`), `BuiltInQuestion` (Phase 1 model — `correctIndex`,
  `options`, `type`). Callers resolve the question bank for a given
  `quizId` themselves (built-in banks via `kPreTestQuestionsByLesson`/
  `kPostTestQuestionsByLesson`, or a teacher-linked quiz via
  `QuizRepository.questionsFromTeacherQuiz` — both already produce
  `List<BuiltInQuestion>`, so this calculator only ever needs that one
  type, never `TeacherQuizQuestion` directly).
- Produces: `class QuestionItemAnalysis` (`questionIndex`, `difficultyIndex`,
  `discriminationIndex`, `distractorRates: Map<int, double>` — option index
  → fraction of students who picked it) and
  `List<QuestionItemAnalysis> computeItemAnalysis({required List<BuiltInQuestion> questions, required List<QuizAttempt> attempts})`.
  Consumed by Task 2's provider.

**Exact formulas (PROJECT_FLOW.md Part 7.5, replicate exactly):**
- Difficulty index: `(students who answered this question correctly) / (total students who attempted this quiz)`.
- Discrimination index: sort students by their total quiz `score`
  descending, top ~27% and bottom ~27% (use `(attempts.length * 0.27).ceil()`,
  minimum 1 student per group if `attempts.length >= 2`), then
  `(top group's correct rate on this question) - (bottom group's correct rate on this question)`.
- Distractor rates: for each wrong option index, `(students who chose it) / (total students who attempted)`. Multiple-choice only — for a `QuestionType.tf` question, still compute it (the formula doesn't care about question type), but Task 3's UI only surfaces it for MC questions per Part 7.5's "optional, multiple-choice only" framing (a UI-layer choice, not a calculator-layer one — the calculator stays generic).

- [ ] **Step 1: Write the failing test**

```dart
// test/core/services/item_analysis_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/built_in_question.dart';
import 'package:ar_science_explorer/core/models/question_type.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/services/item_analysis_calculator.dart';

List<BuiltInQuestion> _twoQuestions() => [
      BuiltInQuestion(
        id: 'q0', subject: SubjectKey.chemistry, lessonId: 'q1w1',
        question: 'Q0', options: const ['A', 'B', 'C', 'D'],
        correctIndex: 0, hint: 'hint', type: QuestionType.mc,
      ),
      BuiltInQuestion(
        id: 'q1', subject: SubjectKey.chemistry, lessonId: 'q1w1',
        question: 'Q1', options: const ['A', 'B', 'C', 'D'],
        correctIndex: 1, hint: 'hint', type: QuestionType.mc,
      ),
    ];

QuizAttempt _attempt(String studentId, int score, List<int> answers) => QuizAttempt(
      id: 'attempt-$studentId', quizId: 'builtin-q1w1-post', studentId: studentId,
      attemptNumber: 1, score: score, totalQuestions: 2, correctAnswers: 0,
      answers: answers, timestamp: DateTime(2026, 8, 20).toIso8601String(), locked: true,
    );

void main() {
  test('difficulty index is the fraction of students correct on each question', () {
    final attempts = [
      _attempt('1', 100, [0, 1]), // both correct
      _attempt('2', 50, [0, 2]),  // q0 correct, q1 wrong
      _attempt('3', 50, [3, 1]),  // q0 wrong, q1 correct
      _attempt('4', 0, [3, 2]),   // both wrong
    ];

    final result = computeItemAnalysis(questions: _twoQuestions(), attempts: attempts);

    expect(result[0].difficultyIndex, closeTo(2 / 4, 0.0001)); // q0: students 1,2 correct
    expect(result[1].difficultyIndex, closeTo(2 / 4, 0.0001)); // q1: students 1,3 correct
  });

  test('discrimination index compares top-scoring vs bottom-scoring groups', () {
    // 10 students, scores 100 down to 10 in steps of 10 — top ~27% = 3, bottom ~27% = 3.
    final attempts = List.generate(10, (i) {
      final score = 100 - i * 10;
      // Question 0: only the top 3 scorers (i = 0,1,2) answer it correctly.
      final q0Correct = i < 3;
      return _attempt('$i', score, [q0Correct ? 0 : 1, 0]);
    });

    final result = computeItemAnalysis(questions: _twoQuestions(), attempts: attempts);

    // Top group (highest 3 scores) got q0 100% correct; bottom group (lowest 3) got it 0%.
    expect(result[0].discriminationIndex, closeTo(1.0, 0.0001));
  });

  test('distractor rates report the fraction choosing each wrong option', () {
    final attempts = [
      _attempt('1', 0, [1, 0]), // chose option 1 for q0
      _attempt('2', 0, [1, 0]), // chose option 1 for q0
      _attempt('3', 0, [2, 0]), // chose option 2 for q0
      _attempt('4', 100, [0, 0]), // correct on q0
    ];

    final result = computeItemAnalysis(questions: _twoQuestions(), attempts: attempts);

    expect(result[0].distractorRates[1], closeTo(2 / 4, 0.0001));
    expect(result[0].distractorRates[2], closeTo(1 / 4, 0.0001));
    expect(result[0].distractorRates.containsKey(0), false); // correct option isn't a distractor
  });

  test('returns an empty list for zero attempts, not a crash', () {
    final result = computeItemAnalysis(questions: _twoQuestions(), attempts: const []);
    expect(result, hasLength(2));
    expect(result[0].difficultyIndex, 0.0);
    expect(result[0].discriminationIndex, 0.0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/item_analysis_calculator_test.dart`
Expected: FAIL — file doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/core/services/item_analysis_calculator.dart
import '../models/built_in_question.dart';
import '../models/quiz_attempt.dart';

/// Per-question item analysis result — PROJECT_FLOW.md Part 7.5.
class QuestionItemAnalysis {
  const QuestionItemAnalysis({
    required this.questionIndex,
    required this.difficultyIndex,
    required this.discriminationIndex,
    required this.distractorRates,
  });

  final int questionIndex;
  final double difficultyIndex;
  final double discriminationIndex;

  /// Wrong-option index -> fraction of all students who chose it. The
  /// correct option is never a key here.
  final Map<int, double> distractorRates;
}

/// Computes per-question item analysis across every attempt on one quiz.
/// [questions] and each attempt's `answers[i]` must be index-aligned —
/// callers are responsible for resolving the right question bank for the
/// quiz (built-in or teacher-authored) before calling this.
List<QuestionItemAnalysis> computeItemAnalysis({
  required List<BuiltInQuestion> questions,
  required List<QuizAttempt> attempts,
}) {
  final total = attempts.length;
  if (total == 0) {
    return [
      for (var i = 0; i < questions.length; i++)
        QuestionItemAnalysis(
          questionIndex: i,
          difficultyIndex: 0.0,
          discriminationIndex: 0.0,
          distractorRates: const {},
        ),
    ];
  }

  final sortedByScore = [...attempts]..sort((a, b) => b.score.compareTo(a.score));
  final groupSize = (total * 0.27).ceil().clamp(1, total);
  final topGroup = sortedByScore.take(groupSize).toList();
  final bottomGroup = sortedByScore.reversed.take(groupSize).toList();

  return [
    for (var i = 0; i < questions.length; i++)
      _analyzeQuestion(i, questions[i], attempts, topGroup, bottomGroup, total),
  ];
}

QuestionItemAnalysis _analyzeQuestion(
  int questionIndex,
  BuiltInQuestion question,
  List<QuizAttempt> attempts,
  List<QuizAttempt> topGroup,
  List<QuizAttempt> bottomGroup,
  int total,
) {
  bool answeredCorrectly(QuizAttempt a) =>
      questionIndex < a.answers.length && a.answers[questionIndex] == question.correctIndex;

  final correctCount = attempts.where(answeredCorrectly).length;
  final difficultyIndex = correctCount / total;

  final topCorrectRate = topGroup.isEmpty
      ? 0.0
      : topGroup.where(answeredCorrectly).length / topGroup.length;
  final bottomCorrectRate = bottomGroup.isEmpty
      ? 0.0
      : bottomGroup.where(answeredCorrectly).length / bottomGroup.length;
  final discriminationIndex = topCorrectRate - bottomCorrectRate;

  final distractorCounts = <int, int>{};
  for (final attempt in attempts) {
    if (questionIndex >= attempt.answers.length) continue;
    final chosen = attempt.answers[questionIndex];
    if (chosen == question.correctIndex) continue;
    if (chosen < 0 || chosen >= question.options.length) continue; // unanswered (-1) or invalid
    distractorCounts[chosen] = (distractorCounts[chosen] ?? 0) + 1;
  }
  final distractorRates = {
    for (final entry in distractorCounts.entries) entry.key: entry.value / total,
  };

  return QuestionItemAnalysis(
    questionIndex: questionIndex,
    difficultyIndex: difficultyIndex,
    discriminationIndex: discriminationIndex,
    distractorRates: distractorRates,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/item_analysis_calculator_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/item_analysis_calculator.dart test/core/services/item_analysis_calculator_test.dart
git commit -m "feat: ItemAnalysisCalculator — difficulty/discrimination/distractor math (Part 7.5)"
```

---

### Task 2: Item analysis provider — resolve attempts + question bank, run the calculator

**Files:**
- Create: `lib/features/teacher/quizzes/item_analysis_providers.dart`
- Test: `test/features/teacher/quizzes/item_analysis_providers_test.dart`

**Interfaces:**
- Consumes: `computeItemAnalysis` (Task 1); `StudentRepository.watchAllStudents`
  (Phase 4 — already exists, used by the roster); `kPreTestQuestionsByLesson`/
  `kPostTestQuestionsByLesson` (Phase 2 Task 1); `QuizRepository.questionsFromTeacherQuiz`
  (the teacher-quiz-reachability fix from this session — read
  `lib/core/services/quiz_repository.dart` to confirm its exact current
  signature before wiring against it, it was added after this plan's initial
  drafting).
- Produces: `class ItemAnalysisViewModel` (`quizTitle`, `questions: List<BuiltInQuestion>`,
  `results: List<QuestionItemAnalysis>`, `attemptCount: int`) and
  `itemAnalysisViewModelProvider` (`.family<ItemAnalysisViewModel, String>`,
  keyed on `quizId`), following the same override-at-app-startup pattern
  every other screen provider in this codebase uses.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/teacher/quizzes/item_analysis_providers_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/quiz_id.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/features/teacher/quizzes/item_analysis_providers.dart';

StudentRecord _studentWith(String id, QuizAttempt attempt) => StudentRecord(
      id: id, name: 'Student $id', studentId: id, grade: '7', section: 'A',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [], completedLabExperimentIds: const [],
      completedQuizIds: const [], unlockedLessonIds: const [], unlockedQuizIds: const [],
      quizAttempts: [attempt],
    );

void main() {
  test('resolves the built-in question bank and every attempt on this quiz', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    final quizId = builtinQuizId('q1w1', QuizPhase.post);

    await studentRepo.saveStudent(_studentWith('111111', QuizAttempt(
      id: 'a1', quizId: quizId, studentId: '111111', attemptNumber: 1,
      score: 100, totalQuestions: 8, correctAnswers: 8,
      answers: const [0, 0, 0, 0, 0, 0, 0, 0],
      timestamp: DateTime(2026, 8, 20).toIso8601String(), locked: true,
    )));
    await studentRepo.saveStudent(_studentWith('222222', QuizAttempt(
      id: 'a2', quizId: quizId, studentId: '222222', attemptNumber: 1,
      score: 0, totalQuestions: 8, correctAnswers: 0,
      answers: const [1, 1, 1, 1, 1, 1, 1, 1],
      timestamp: DateTime(2026, 8, 20).toIso8601String(), locked: true,
    )));

    final stream = buildItemAnalysisViewModel(
      quizId: quizId,
      quizTitle: 'Q1W1 Post-Test',
      studentRepository: studentRepo,
    );
    final vm = await stream.first;

    expect(vm.attemptCount, 2);
    expect(vm.questions, hasLength(8));
    expect(vm.results, hasLength(8));
    expect(vm.results[0].difficultyIndex, closeTo(0.5, 0.0001));
  });

  test('ignores attempts on other quizzes', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    final postId = builtinQuizId('q1w1', QuizPhase.post);
    final preId = builtinQuizId('q1w1', QuizPhase.pre);

    await studentRepo.saveStudent(_studentWith('111111', QuizAttempt(
      id: 'a1', quizId: preId, studentId: '111111', attemptNumber: 1,
      score: 100, totalQuestions: 8, correctAnswers: 8,
      answers: const [0, 0, 0, 0, 0, 0, 0, 0],
      timestamp: DateTime(2026, 8, 20).toIso8601String(), locked: false,
    )));

    final stream = buildItemAnalysisViewModel(
      quizId: postId,
      quizTitle: 'Q1W1 Post-Test',
      studentRepository: studentRepo,
    );
    final vm = await stream.first;

    expect(vm.attemptCount, 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/teacher/quizzes/item_analysis_providers_test.dart`
Expected: FAIL — file doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
// lib/features/teacher/quizzes/item_analysis_providers.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/data/curriculum_data.dart';
import '../../../core/models/built_in_question.dart';
import '../../../core/quiz_id.dart';
import '../../../core/services/item_analysis_calculator.dart';
import '../../../core/services/student_repository.dart';

class ItemAnalysisViewModel {
  const ItemAnalysisViewModel({
    required this.quizTitle,
    required this.questions,
    required this.results,
    required this.attemptCount,
  });

  final String quizTitle;
  final List<BuiltInQuestion> questions;
  final List<QuestionItemAnalysis> results;
  final int attemptCount;
}

final itemAnalysisViewModelProvider =
    StreamProvider.autoDispose.family<ItemAnalysisViewModel, String>((ref, quizId) {
  throw UnimplementedError(
    'itemAnalysisViewModelProvider must be overridden at app startup with a '
    'real stream for the given quizId.',
  );
});

Stream<ItemAnalysisViewModel> buildItemAnalysisViewModel({
  required String quizId,
  required String quizTitle,
  required StudentRepository studentRepository,
}) {
  final parsed = parseBuiltinId(quizId);
  final questions = parsed.isBuiltin && parsed.lessonId != null
      ? (parsed.phase.name == 'pre'
          ? kPreTestQuestionsByLesson[parsed.lessonId!] ?? const <BuiltInQuestion>[]
          : kPostTestQuestionsByLesson[parsed.lessonId!] ?? const <BuiltInQuestion>[])
      : const <BuiltInQuestion>[]; // teacher-linked quiz question resolution — see Task 2 note below

  return studentRepository.watchAllStudents(includeArchived: true).map((students) {
    final attempts = [
      for (final student in students)
        for (final attempt in student.quizAttempts)
          if (attempt.quizId == quizId) attempt,
    ];

    return ItemAnalysisViewModel(
      quizTitle: quizTitle,
      questions: questions,
      results: computeItemAnalysis(questions: questions, attempts: attempts),
      attemptCount: attempts.length,
    );
  });
}
```

**Note on teacher-linked quizzes:** this task's test only exercises the
built-in-lesson path (matching what a first implementation needs to prove
the core wiring). If `parsed.isBuiltin` is false (a teacher-authored,
non-`builtin-`-prefixed quiz id), `questions` currently resolves to an
empty list — this is a known, deliberate scope trim for this task, not a
silent gap: item analysis on a teacher-created quiz needs `QuizRepository`
injected and a lookup by raw quiz id, which the next task (screen wiring)
should add once you've re-confirmed `QuizRepository`'s exact current
`getQuiz`/similar method against the real file (it may have changed since
this plan was drafted, per the Global Constraints note above). Do not
implement this speculatively in Task 2 — do it for real in Task 3 once
you're looking at the real, current `QuizRepository` API.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/teacher/quizzes/item_analysis_providers_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/teacher/quizzes/item_analysis_providers.dart \
        test/features/teacher/quizzes/item_analysis_providers_test.dart
git commit -m "feat: item analysis provider — resolve attempts + built-in question bank"
```

---

### Task 3: Item analysis screen (`fl_chart`) + teacher-quiz question resolution

**Files:**
- Modify: `pubspec.yaml` (add `fl_chart`)
- Modify: `lib/features/teacher/quizzes/item_analysis_providers.dart`
- Create: `lib/features/teacher/quizzes/item_analysis_screen.dart`
- Test: `test/features/teacher/quizzes/item_analysis_screen_test.dart`

**Interfaces:**
- Consumes: `ItemAnalysisViewModel`, `itemAnalysisViewModelProvider` (Task 2).
- Produces: `class ItemAnalysisScreen extends ConsumerWidget` taking
  `quizId: String`, `quizTitle: String`, rendering a bar chart of
  difficulty index per question, discrimination index per question, and a
  distractor-rate breakdown for multiple-choice questions only (Part 7.5's
  "optional, MC only" framing applied here at the UI layer).

- [ ] **Step 1: Add `fl_chart`**

Edit `pubspec.yaml`, add under `dependencies:`: `fl_chart: ^0.69.0`
Run: `flutter pub get`

- [ ] **Step 2: Resolve teacher-linked quizzes for real**

`QuizRepository` (confirmed current signature, `lib/core/services/quiz_repository.dart`)
has `Future<TeacherQuiz?> fetchQuizById(String quizId)` and
`List<BuiltInQuestion> questionsFromTeacherQuiz(TeacherQuiz quiz, {required String lessonId})`.
Extend `buildItemAnalysisViewModel` (Task 2) to accept a
`QuizRepository quizRepository` parameter (required, not optional — every
real caller has one available). Restructure it to `async*`/return a
`Stream` built from an `async` function (since resolving a non-built-in
quiz's questions now needs an `await` before the stream can be built):

```dart
// Replace Task 2's buildItemAnalysisViewModel with this version:
Stream<ItemAnalysisViewModel> buildItemAnalysisViewModel({
  required String quizId,
  required String quizTitle,
  required StudentRepository studentRepository,
  required QuizRepository quizRepository,
}) async* {
  final parsed = parseBuiltinId(quizId);
  List<BuiltInQuestion> questions;
  if (parsed.isBuiltin && parsed.lessonId != null) {
    questions = parsed.phase == QuizPhase.pre
        ? kPreTestQuestionsByLesson[parsed.lessonId!] ?? const <BuiltInQuestion>[]
        : kPostTestQuestionsByLesson[parsed.lessonId!] ?? const <BuiltInQuestion>[];
  } else {
    final teacherQuiz = await quizRepository.fetchQuizById(quizId);
    questions = teacherQuiz == null
        ? const <BuiltInQuestion>[]
        : quizRepository.questionsFromTeacherQuiz(teacherQuiz, lessonId: quizId);
  }

  yield* studentRepository.watchAllStudents(includeArchived: true).map((students) {
    final attempts = [
      for (final student in students)
        for (final attempt in student.quizAttempts)
          if (attempt.quizId == quizId) attempt,
    ];

    return ItemAnalysisViewModel(
      quizTitle: quizTitle,
      questions: questions,
      results: computeItemAnalysis(questions: questions, attempts: attempts),
      attemptCount: attempts.length,
    );
  });
}
```

Add the needed import (`../../../core/services/quiz_repository.dart`,
`../../../core/models/quiz_phase.dart`, `../../../core/models/teacher_quiz.dart`
if not already present). Add a test proving a teacher-created quiz's item
analysis resolves real questions from `quizRepository.fetchQuizById`, not
an empty list — seed a `TeacherQuiz` doc via `fake_cloud_firestore` and a
matching student attempt, same pattern as Task 2's tests.

**This changes `buildItemAnalysisViewModel`'s signature** (adds the now-
required `quizRepository` parameter) — update the two existing call sites
in Task 2's `test/features/teacher/quizzes/item_analysis_providers_test.dart`
to pass `quizRepository: QuizRepository(firestore: firestore)` alongside
their existing arguments, so those tests keep compiling and passing.

- [ ] **Step 3: Write the failing screen test**

```dart
// test/features/teacher/quizzes/item_analysis_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/core/models/built_in_question.dart';
import 'package:ar_science_explorer/core/models/question_type.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/services/item_analysis_calculator.dart';
import 'package:ar_science_explorer/features/teacher/quizzes/item_analysis_providers.dart';
import 'package:ar_science_explorer/features/teacher/quizzes/item_analysis_screen.dart';

void main() {
  testWidgets('shows attempt count and a row per question', (tester) async {
    final vm = ItemAnalysisViewModel(
      quizTitle: 'Q1W1 Post-Test',
      questions: [
        BuiltInQuestion(
          id: 'q0', subject: SubjectKey.chemistry, lessonId: 'q1w1',
          question: 'What is H2O?', options: const ['Water', 'Oxygen', 'Hydrogen', 'Salt'],
          correctIndex: 0, hint: 'hint', type: QuestionType.mc,
        ),
      ],
      results: const [
        QuestionItemAnalysis(
          questionIndex: 0, difficultyIndex: 0.75, discriminationIndex: 0.3,
          distractorRates: {1: 0.15, 2: 0.1},
        ),
      ],
      attemptCount: 20,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemAnalysisViewModelProvider('quiz-1').overrideWith((ref) => Stream.value(vm))],
        child: const MaterialApp(home: ItemAnalysisScreen(quizId: 'quiz-1', quizTitle: 'Q1W1 Post-Test')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('20'), findsWidgets); // attempt count shown somewhere
    expect(find.textContaining('What is H2O?'), findsOneWidget);
    expect(find.textContaining('75%'), findsWidgets); // difficulty index rendered as a percent
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/features/teacher/quizzes/item_analysis_screen_test.dart`
Expected: FAIL — `lib/features/teacher/quizzes/item_analysis_screen.dart` doesn't exist yet.

- [ ] **Step 5: Implement**

```dart
// lib/features/teacher/quizzes/item_analysis_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/built_in_question.dart';
import '../../../core/models/question_type.dart';
import '../../../core/services/item_analysis_calculator.dart';
import 'item_analysis_providers.dart';

class ItemAnalysisScreen extends ConsumerWidget {
  const ItemAnalysisScreen({super.key, required this.quizId, required this.quizTitle});

  final String quizId;
  final String quizTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncViewModel = ref.watch(itemAnalysisViewModelProvider(quizId));

    return Scaffold(
      appBar: AppBar(title: Text('Item Analysis — $quizTitle')),
      body: asyncViewModel.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Could not load item analysis: $error')),
        data: (vm) {
          if (vm.attemptCount == 0) {
            return const Center(child: Text('No attempts yet on this quiz.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${vm.attemptCount} attempts analyzed'),
              const SizedBox(height: 16),
              for (var i = 0; i < vm.questions.length; i++)
                _QuestionAnalysisCard(question: vm.questions[i], result: vm.results[i]),
            ],
          );
        },
      ),
    );
  }
}

class _QuestionAnalysisCard extends StatelessWidget {
  const _QuestionAnalysisCard({required this.question, required this.result});

  final BuiltInQuestion question;
  final QuestionItemAnalysis result;

  @override
  Widget build(BuildContext context) {
    final difficultyPct = (result.difficultyIndex * 100).round();
    final discriminationLabel = result.discriminationIndex >= 0
        ? '+${(result.discriminationIndex * 100).round()}%'
        : '${(result.discriminationIndex * 100).round()}%';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Q${result.questionIndex + 1}: ${question.question}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Difficulty: $difficultyPct% correct'),
            Text('Discrimination: $discriminationLabel'),
            SizedBox(
              height: 80,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarRodData(toY: result.difficultyIndex * 100, color: Colors.blue),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarRodData(
                        toY: (result.discriminationIndex.clamp(-1.0, 1.0) * 100).abs(),
                        color: result.discriminationIndex >= 0 ? Colors.green : Colors.red,
                      ),
                    ]),
                  ],
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
            if (question.type == QuestionType.mc && result.distractorRates.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Distractors:', style: Theme.of(context).textTheme.labelMedium),
              for (final entry in result.distractorRates.entries)
                Text('  ${question.options[entry.key]}: ${(entry.value * 100).round()}%'),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/teacher/quizzes/item_analysis_screen_test.dart`
Expected: PASS (1 test).

- [ ] **Step 7: Wire a link into the existing quizzes screen**

Read `lib/features/teacher/quizzes/quizzes_screen.dart` first (the real
current file) and add a way to navigate from a quiz row to
`ItemAnalysisScreen(quizId: quiz.id, quizTitle: quiz.title)` — follow
whatever navigation pattern (route push, dialog, etc.) that screen already
uses for its other row actions, don't invent a new one.

- [ ] **Step 8: Run the full suite to confirm nothing else broke**

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 9: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/teacher/quizzes/ \
        test/features/teacher/quizzes/item_analysis_screen_test.dart \
        test/core/services/item_analysis_calculator_test.dart
git commit -m "feat: item analysis screen — fl_chart rendering, teacher-quiz support (Part 7.5)"
```

---

### Task 4: `TeacherLesson` gains `contentImageUrls` + `contentStatus`

**Files:**
- Modify: `lib/core/models/teacher_lesson.dart`
- Test: `test/core/models/teacher_lesson_content_test.dart`

**Interfaces:**
- Produces: two new optional fields on `TeacherLesson` —
  `List<String>? contentImageUrls` and `String? contentStatus`
  (`'processing'` | `'ready'`, or null). Consumed by every later task in
  this plan.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/models/teacher_lesson_content_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/teacher_lesson.dart';

void main() {
  test('contentImageUrls and contentStatus round-trip', () {
    final json = {
      'id': 'teacher-1',
      'title': 'Volcanoes',
      'subject': 'chemistry',
      'contentImageUrls': ['https://example.com/slide1.png', 'https://example.com/slide2.png'],
      'contentStatus': 'ready',
    };

    final lesson = TeacherLesson.fromJson(json);

    expect(lesson.contentImageUrls, hasLength(2));
    expect(lesson.contentStatus, 'ready');
    expect(lesson.toJson()['contentStatus'], 'ready');
  });

  test('both fields default to null when absent', () {
    final lesson = TeacherLesson.fromJson(const {
      'id': 'teacher-2', 'title': 'No content yet', 'subject': 'biology',
    });

    expect(lesson.contentImageUrls, isNull);
    expect(lesson.contentStatus, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/models/teacher_lesson_content_test.dart`
Expected: FAIL — the two fields don't exist on `TeacherLesson` yet.

- [ ] **Step 3: Add the fields**

Read `lib/core/models/teacher_lesson.dart`'s real current content first
(it's grown since Phase 1 — this plan's earlier File Structure section
does not enumerate every existing field). Add inside the `const factory
TeacherLesson({...})` constructor, alongside the existing `pdfUrl` field:

```dart
    List<String>? contentImageUrls,
    String? contentStatus, // 'processing' | 'ready' | null
```

- [ ] **Step 4: Regenerate freezed/json_serializable code**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/models/teacher_lesson_content_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Run the full suite to confirm nothing else broke**

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/core/models/teacher_lesson.dart lib/core/models/teacher_lesson.freezed.dart \
        lib/core/models/teacher_lesson.g.dart test/core/models/teacher_lesson_content_test.dart
git commit -m "feat: TeacherLesson gains contentImageUrls + contentStatus (Part 8)"
```

---

### Task 5: `LessonContentUploadService` — Firebase Storage upload

**Files:**
- Modify: `pubspec.yaml` (add `firebase_storage`, `file_picker`)
- Create: `lib/core/services/lesson_content_upload_service.dart`
- Test: `test/core/services/lesson_content_upload_service_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks. Defines its own narrow
  `StorageUploader` interface (below) rather than depending on
  `firebase_storage`'s full `FirebaseStorage`/`Reference` API surface
  directly — this codebase's established pattern
  (`fake_cloud_firestore` for Firestore) has no equivalent fake for
  `firebase_storage`, and `FirebaseStorage`/`Reference` are large concrete
  SDK classes with many members, not designed to be faked wholesale. A
  narrow, single-purpose interface this class owns is easy to fake for
  real in tests and easy to adapt the real SDK to in production.
- Produces: `abstract class StorageUploader` (one method:
  `Future<String> upload(String path, Uint8List bytes)`),
  `class FirebaseStorageUploader implements StorageUploader` (the real,
  production adapter wrapping `FirebaseStorage.instance`), and
  `class LessonContentUploadService` with constructor
  `LessonContentUploadService({required StorageUploader uploader})`, method
  `Future<String> uploadLessonContent({required String lessonId, required String fileName, required Uint8List bytes})`
  — uploads to `lessons/{lessonId}/{fileName}` and returns the download
  URL. Consumed by Task 6's lesson form, which constructs
  `LessonContentUploadService(uploader: FirebaseStorageUploader())` for
  real use.

- [ ] **Step 1: Add dependencies**

Edit `pubspec.yaml`, add under `dependencies:`:
```yaml
  firebase_storage: ^12.3.0
  file_picker: ^8.1.0
```
Run: `flutter pub get`

- [ ] **Step 2: Write the failing test**

```dart
// test/core/services/lesson_content_upload_service_test.dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/services/lesson_content_upload_service.dart';

class _FakeStorageUploader implements StorageUploader {
  String? lastPath;
  Uint8List? lastBytes;

  @override
  Future<String> upload(String path, Uint8List bytes) async {
    lastPath = path;
    lastBytes = bytes;
    return 'https://fake-storage.example/$path';
  }
}

void main() {
  test('uploads to lessons/{lessonId}/{fileName} and returns the download URL', () async {
    final fakeUploader = _FakeStorageUploader();
    final service = LessonContentUploadService(uploader: fakeUploader);

    final url = await service.uploadLessonContent(
      lessonId: 'teacher-1',
      fileName: 'slides.pptx',
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    expect(fakeUploader.lastPath, 'lessons/teacher-1/slides.pptx');
    expect(fakeUploader.lastBytes, [1, 2, 3]);
    expect(url, 'https://fake-storage.example/lessons/teacher-1/slides.pptx');
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/core/services/lesson_content_upload_service_test.dart`
Expected: FAIL — file doesn't exist yet.

- [ ] **Step 4: Implement**

```dart
// lib/core/services/lesson_content_upload_service.dart
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Narrow upload interface `LessonContentUploadService` depends on — makes
/// the service trivially fakeable in tests without mocking the full
/// `FirebaseStorage`/`Reference` SDK surface.
abstract class StorageUploader {
  Future<String> upload(String path, Uint8List bytes);
}

/// Real, production `StorageUploader` backed by `firebase_storage`.
class FirebaseStorageUploader implements StorageUploader {
  FirebaseStorageUploader({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> upload(String path, Uint8List bytes) async {
    final ref = _storage.ref(path);
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }
}

/// Uploads a teacher's lesson content file (PDF or PPTX) to Firebase
/// Storage under lessons/{lessonId}/{fileName}. The PPTX-to-slide-images
/// conversion itself is NOT this class's job — that's the Cloud Function
/// (Task 8), triggered automatically once this upload lands in Storage.
class LessonContentUploadService {
  LessonContentUploadService({required StorageUploader uploader}) : _uploader = uploader;

  final StorageUploader _uploader;

  Future<String> uploadLessonContent({
    required String lessonId,
    required String fileName,
    required Uint8List bytes,
  }) {
    return _uploader.upload('lessons/$lessonId/$fileName', bytes);
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/services/lesson_content_upload_service_test.dart`
Expected: PASS (1 test).

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/services/lesson_content_upload_service.dart \
        test/core/services/lesson_content_upload_service_test.dart
git commit -m "feat: LessonContentUploadService — Firebase Storage upload for lesson content"
```

---

### Task 6: Teacher lesson form — PPTX/PDF upload UI

**Files:**
- Modify: `lib/features/teacher/lessons/lesson_form.dart`
- Test: `test/features/teacher/lessons/lesson_form_content_upload_test.dart`

**Interfaces:**
- Consumes: `LessonContentUploadService` (Task 5), `file_picker`'s
  `FilePicker`.
- Produces: a file-picker button in the lesson form that uploads the
  selected `.pptx`/`.pdf`, sets `contentImageUrls: [uploadedUrl]` and
  `contentStatus: 'processing'` on submit (the Cloud Function, Task 8,
  later expands a PPTX's single uploaded-file URL into the real
  multi-slide-image array and flips `contentStatus` to `'ready'`; for a
  plain PDF, this task's own logic should set `contentStatus: 'ready'`
  immediately, since no conversion is needed).

- [ ] **Step 1: Write the failing test**

```dart
// test/features/teacher/lessons/lesson_form_content_upload_test.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/teacher_lesson.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/features/teacher/lessons/lesson_form.dart';

void main() {
  testWidgets('uploading a .pptx sets contentStatus to processing on submit', (tester) async {
    TeacherLesson? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonForm(
            quizOptions: const [],
            onSubmit: (lesson) async => submitted = lesson,
            // Test-only injection point — see Step 3's implementation note:
            // the real upload call is abstracted behind a function the
            // widget accepts, so this test can simulate "a file was picked
            // and uploaded" without touching real file-picker/Storage APIs.
            uploadContentOverride: (fileName, bytes) async => (
              url: 'https://fake-storage.example/slides.pptx',
              isConversionNeeded: true,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('lesson-title')), 'Volcanoes');
    await tester.tap(find.byKey(const Key('lesson-upload-content')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lesson-submit')));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.contentStatus, 'processing');
    expect(submitted!.contentImageUrls, ['https://fake-storage.example/slides.pptx']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/teacher/lessons/lesson_form_content_upload_test.dart`
Expected: FAIL — `LessonForm` doesn't have an `uploadContentOverride`
parameter or upload button yet.

- [ ] **Step 3: Implement**

Read `lib/features/teacher/lessons/lesson_form.dart`'s real current content
in full first (Task 3 of this plan already showed a snapshot above, but
re-verify before editing — other tasks in this plan may have touched it).
Add:

```dart
// Add to LessonForm's constructor:
  const LessonForm({
    super.key,
    this.initial,
    required this.quizOptions,
    required this.onSubmit,
    this.submitLabel = 'Save',
    this.uploadContentOverride, // test-only injection point
  });

  // ... existing fields ...
  final Future<({String url, bool isConversionNeeded})> Function(String fileName, Uint8List bytes)?
      uploadContentOverride;
```

```dart
// Add to LessonFormState:
  String? _uploadedContentUrl;
  bool _uploadedContentNeedsConversion = false;

  Future<void> _pickAndUploadContent() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pptx', 'pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;

    final isConversionNeeded = file!.extension?.toLowerCase() == 'pptx';
    final ({String url, bool isConversionNeeded}) uploadResult;
    if (widget.uploadContentOverride != null) {
      uploadResult = await widget.uploadContentOverride!(file.name, file.bytes!);
    } else {
      final lessonId = widget.initial?.id ?? 'teacher-${DateTime.now().millisecondsSinceEpoch}';
      final service = LessonContentUploadService(uploader: FirebaseStorageUploader());
      final url = await service.uploadLessonContent(
        lessonId: lessonId, fileName: file.name, bytes: file.bytes!,
      );
      uploadResult = (url: url, isConversionNeeded: isConversionNeeded);
    }

    setState(() {
      _uploadedContentUrl = uploadResult.url;
      _uploadedContentNeedsConversion = uploadResult.isConversionNeeded;
    });
  }
```

Add the button to the form's `build()` (near the existing content-related
fields):

```dart
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('lesson-upload-content'),
              onPressed: _pickAndUploadContent,
              icon: const Icon(Icons.upload_file),
              label: Text(_uploadedContentUrl == null ? 'Upload PPTX or PDF' : 'Content uploaded'),
            ),
```

Update `_handleSubmit()`'s `TeacherLesson(...)` construction to include:
```dart
      contentImageUrls: _uploadedContentUrl != null
          ? [_uploadedContentUrl!]
          : widget.initial?.contentImageUrls,
      contentStatus: _uploadedContentUrl == null
          ? widget.initial?.contentStatus
          : (_uploadedContentNeedsConversion ? 'processing' : 'ready'),
```

Add the needed imports: `dart:typed_data`, `package:file_picker/file_picker.dart`,
`../../../core/services/lesson_content_upload_service.dart` (this last one
brings in both `LessonContentUploadService` and `FirebaseStorageUploader`).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/teacher/lessons/lesson_form_content_upload_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Run the full suite to confirm nothing else broke**

Run: `flutter test`
Expected: all tests pass (this modifies an existing, tested file —
`lessons_screen_test.dart`/other `LessonForm` consumers must still pass
unchanged, since `uploadContentOverride` is optional and every other field
is untouched).

- [ ] **Step 6: Commit**

```bash
git add lib/features/teacher/lessons/lesson_form.dart \
        test/features/teacher/lessons/lesson_form_content_upload_test.dart
git commit -m "feat: teacher lesson form — PPTX/PDF upload UI"
```

---

### Task 7: Student content viewer — slide gallery / processing state

**Files:**
- Modify: `pubspec.yaml` (add `photo_view`)
- Create: `lib/features/student/ar_lab/content_viewer.dart`
- Modify: `lib/features/student/ar_lab/read_tab.dart`
- Test: `test/features/student/ar_lab/content_viewer_test.dart`
- Test: `test/features/student/ar_lab/read_tab_test.dart` (extend, don't replace)

**Interfaces:**
- Consumes: `TeacherLesson.contentImageUrls`/`contentStatus` (Task 4) —
  but `ArLabViewModel` (Phase 3) currently exposes `title`/`summary` from a
  merged `Lesson`, not the raw `TeacherLesson`. Read
  `lib/features/student/ar_lab/ar_lab_providers.dart`'s real current
  content first — you'll likely need to add `contentImageUrls`/`contentStatus`
  fields to `ArLabViewModel` itself (sourced from the merged lesson if it's
  teacher-authored; a built-in curriculum lesson never has these, so they
  stay null for those) rather than threading the raw `TeacherLesson`
  through. Do this as part of this task, it's a small, necessary extension
  of Task 6 of Phase 3's original `ArLabViewModel`, not a new provider.
- Produces: `class ContentViewer extends StatelessWidget` taking
  `imageUrls: List<String>?` and `status: String?`, rendering: nothing (no
  content uploaded) when `imageUrls` is null; a "Processing your teacher's
  uploaded content..." message when `status == 'processing'`; a swipeable
  `photo_view` gallery when `status == 'ready'` (or `status == null` with a
  non-empty `imageUrls` — the legacy/single-PDF-URL case that never needed
  conversion).

- [ ] **Step 1: Add `photo_view`**

Edit `pubspec.yaml`, add under `dependencies:`: `photo_view: ^0.15.0`
Run: `flutter pub get`

- [ ] **Step 2: Write the failing test**

```dart
// test/features/student/ar_lab/content_viewer_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/features/student/ar_lab/content_viewer.dart';

void main() {
  testWidgets('shows nothing when no content has been uploaded', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ContentViewer(imageUrls: null, status: null))),
    );
    expect(find.byType(ContentViewer), findsOneWidget);
    expect(find.textContaining('Processing'), findsNothing);
  });

  testWidgets('shows a processing message while status is processing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentViewer(imageUrls: ['https://example.com/a.pptx'], status: 'processing'),
        ),
      ),
    );
    expect(find.textContaining('Processing'), findsOneWidget);
  });

  testWidgets('shows a swipeable gallery once ready', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentViewer(
            imageUrls: ['https://example.com/slide1.png', 'https://example.com/slide2.png'],
            status: 'ready',
          ),
        ),
      ),
    );
    expect(find.textContaining('Processing'), findsNothing);
    expect(find.textContaining('1 / 2'), findsOneWidget); // slide counter
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/student/ar_lab/content_viewer_test.dart`
Expected: FAIL — file doesn't exist yet.

- [ ] **Step 4: Implement**

```dart
// lib/features/student/ar_lab/content_viewer.dart
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ContentViewer extends StatefulWidget {
  const ContentViewer({super.key, required this.imageUrls, required this.status});

  final List<String>? imageUrls;
  final String? status;

  @override
  State<ContentViewer> createState() => _ContentViewerState();
}

class _ContentViewerState extends State<ContentViewer> {
  final _controller = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;
    if (urls == null || urls.isEmpty) return const SizedBox.shrink();

    if (widget.status == 'processing') {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Expanded(child: Text('Processing your teacher\'s uploaded content...')),
          ],
        ),
      );
    }

    return SizedBox(
      height: 400,
      child: Column(
        children: [
          Expanded(
            child: PhotoViewGallery.builder(
              pageController: _controller,
              itemCount: urls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              builder: (context, index) => PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(urls[index]),
              ),
            ),
          ),
          Text('${_currentIndex + 1} / ${urls.length}'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/student/ar_lab/content_viewer_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6: Wire into `ArLabViewModel` and `ReadTab`**

Read `lib/features/student/ar_lab/ar_lab_providers.dart` and `read_tab.dart`
in full first. Add `contentImageUrls`/`contentStatus` fields to
`ArLabViewModel`, sourced in `buildArLabViewModel` from the resolved
merged lesson when it's teacher-authored (a `TeacherLesson`-backed
`Lesson` won't currently expose these — you may need to also add them to
`Lesson` itself and to `LessonRepository._toLesson`'s mapping, following
the exact same pattern `hasAR`/`arPayload` already use there). Add
`ContentViewer(imageUrls: vm.contentImageUrls, status: vm.contentStatus)`
into `read_tab.dart`'s existing `ListView`, after the summary text and
before the "Mark as Read" button. Extend `read_tab_test.dart` (Phase 3's
existing test file — read it first) with a case proving content renders
when present, and confirm the existing no-content case still passes
unchanged.

- [ ] **Step 7: Run the full suite to confirm nothing else broke**

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/models/lesson.dart \
        lib/core/models/lesson.freezed.dart lib/core/models/lesson.g.dart \
        lib/core/services/lesson_repository.dart \
        lib/features/student/ar_lab/content_viewer.dart \
        lib/features/student/ar_lab/ar_lab_providers.dart \
        lib/features/student/ar_lab/read_tab.dart \
        test/features/student/ar_lab/content_viewer_test.dart \
        test/features/student/ar_lab/read_tab_test.dart
git commit -m "feat: student content viewer — slide gallery + processing state (Part 8)"
```

---

### Task 8: Cloud Function — PPTX → slide images (Cloud Run + LibreOffice)

**Files (new, separate Node.js codebase):**
- Create: `functions/package.json`
- Create: `functions/src/index.js`
- Create: `functions/Dockerfile`
- Create: `functions/.gcloudignore`

**Interfaces:**
- Produces: a Storage-triggered Cloud Function
  (`onObjectFinalized`) that, when a `.pptx` lands under `lessons/{lessonId}/`,
  converts it to one PNG per slide via headless LibreOffice, uploads each
  PNG back to `lessons/{lessonId}/slides/{n}.png`, and updates the
  matching Firestore doc's `contentImageUrls`/`contentStatus` fields.

**⚠️ Prerequisite — confirm with the user before starting this task:** the
Firebase project must be on the "Blaze" (pay-as-you-go) plan. Cloud
Run-based functions (required for a custom container with LibreOffice)
are not available on the free "Spark" plan. This is a real account-level
action tracked in `MANUAL_STEPS.md` — do not proceed with deployment
(Step 4 below) until the user confirms this is done; the code itself
(Steps 1-3) can be written regardless.

**No automated test harness** — this is a separate Node.js codebase with
no `flutter test` coverage. Verification is: deploy it for real, upload a
real `.pptx` through the teacher lesson form (Task 6), and confirm slide
images actually appear.

- [ ] **Step 1: Scaffold the function**

```json
// functions/package.json
{
  "name": "functions",
  "engines": { "node": "20" },
  "main": "src/index.js",
  "dependencies": {
    "firebase-admin": "^12.6.0",
    "firebase-functions": "^6.0.1"
  },
  "private": true
}
```

```dockerfile
# functions/Dockerfile
FROM node:20-slim

RUN apt-get update && apt-get install -y \
    libreoffice-impress \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY package.json ./
RUN npm install --omit=dev
COPY . .

CMD ["node", "src/index.js"]
```

```
functions/.gcloudignore
node_modules/
*.log
```

- [ ] **Step 2: Implement the conversion logic**

```javascript
// functions/src/index.js
const { onObjectFinalized } = require('firebase-functions/v2/storage');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { execFile } = require('node:child_process');
const { promisify } = require('node:util');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');

initializeApp();
const execFileAsync = promisify(execFile);

// Matches uploads under lessons/{lessonId}/{fileName}.pptx — Task 5/6's
// LessonContentUploadService writes exactly this path shape.
const PPTX_PATH_PATTERN = /^lessons\/([^/]+)\/([^/]+\.pptx)$/i;

exports.convertLessonPptx = onObjectFinalized(
  { region: 'us-central1', memory: '2GiB', timeoutSeconds: 300, cpu: 2 },
  async (event) => {
    const filePath = event.data.name;
    const match = filePath.match(PPTX_PATH_PATTERN);
    if (!match) return; // not a lesson PPTX upload — ignore (PDF uploads, other files)

    const [, lessonId] = match;
    const bucket = getStorage().bucket(event.data.bucket);
    const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'pptx-'));
    const localPptxPath = path.join(tmpDir, 'input.pptx');

    try {
      await bucket.file(filePath).download({ destination: localPptxPath });

      // Headless LibreOffice: convert PPTX -> PDF -> per-page PNGs. Going
      // through an intermediate PDF is LibreOffice's most reliable path for
      // slide-accurate image export (a direct pptx->png batch conversion is
      // less consistent across LibreOffice versions).
      await execFileAsync('soffice', [
        '--headless', '--convert-to', 'pdf', '--outdir', tmpDir, localPptxPath,
      ]);
      const localPdfPath = path.join(tmpDir, 'input.pdf');

      await execFileAsync('pdftoppm', ['-png', '-r', '150', localPdfPath, path.join(tmpDir, 'slide')]);

      const files = (await fs.readdir(tmpDir))
        .filter((f) => f.startsWith('slide') && f.endsWith('.png'))
        .sort();

      const uploadedUrls = [];
      for (let i = 0; i < files.length; i++) {
        const destPath = `lessons/${lessonId}/slides/${i}.png`;
        await bucket.upload(path.join(tmpDir, files[i]), {
          destination: destPath,
          metadata: { contentType: 'image/png' },
        });
        const [url] = await bucket.file(destPath).getSignedUrl({
          action: 'read',
          expires: '01-01-2100', // effectively permanent for this app's purposes
        });
        uploadedUrls.push(url);
      }

      await getFirestore().collection('lessons').doc(lessonId).update({
        contentImageUrls: uploadedUrls,
        contentStatus: 'ready',
      });
    } catch (error) {
      console.error(`[convertLessonPptx] Failed for ${filePath}:`, error);
      await getFirestore().collection('lessons').doc(lessonId).update({
        contentStatus: 'ready', // fail open — don't leave the lesson stuck "processing" forever;
                                 // contentImageUrls stays as the original single pptx URL, which
                                 // isn't viewable as an image, but the lesson isn't silently stuck.
      }).catch(() => {}); // best-effort — don't let a Firestore write failure mask the original error
      throw error; // still surfaces in Cloud Functions logs/monitoring
    } finally {
      await fs.rm(tmpDir, { recursive: true, force: true });
    }
  },
);
```

- [ ] **Step 3: Verify the code compiles/lints locally (no deploy yet)**

Run (from `functions/`): `npm install`
Expected: resolves cleanly, no syntax errors (`node --check src/index.js`
if you want a quick syntax-only sanity check without a full deploy).

- [ ] **Step 4: Confirm Blaze plan, then deploy**

Ask the user to confirm the Firebase project is on the Blaze plan (Firebase
Console → Project Settings → Usage and billing). Once confirmed, run (from
the repo root): `firebase deploy --only functions`
Expected: the function deploys successfully; Firebase CLI reports the Cloud
Run service URL/trigger is live.

- [ ] **Step 5: Manual end-to-end verification**

Ask the user to: open the teacher lesson form, upload a real `.pptx` for a
test lesson, wait roughly 30-60 seconds, then check that lesson's Firestore
doc (`/lessons/{id}`) shows `contentStatus: 'ready'` and
`contentImageUrls` populated with real slide image URLs — then open that
lesson on the student side and confirm the slide gallery (Task 7) actually
renders the real slides.

- [ ] **Step 6: Update `MANUAL_STEPS.md`**

Record the Blaze-plan confirmation and the deployment as done, and add a
note: "any time `functions/src/index.js` changes, re-run `firebase deploy
--only functions` — this doesn't happen automatically."

- [ ] **Step 7: Commit**

```bash
git add functions/ MANUAL_STEPS.md
git commit -m "feat: Cloud Function — PPTX to slide-image conversion (Part 8)"
```

---

### Task 9: Run the full test suite and confirm the phase is complete

**Files:**
- None created — verification only.

**Interfaces:**
- Consumes: everything from Tasks 1–8.
- Produces: nothing new; this is the phase's exit checkpoint.

- [ ] **Step 1: Run the entire Flutter test suite**

Run: `flutter test`
Expected: every test from Tasks 1–7 passes (Task 8's Cloud Function has no
Flutter test coverage by design — its verification was Task 8's own manual
steps).

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`
Expected: no new errors beyond the established, known-benign baseline
(the Phase 1 `@JsonKey` warnings and whatever count the last Phase 1-4
checkpoint recorded).

- [ ] **Step 3: Confirm MANUAL_STEPS.md is current**

Confirm the Blaze-plan and Cloud Function deployment items from Task 8 are
marked done, and that nothing else from this phase needs a manual step you
haven't flagged.

- [ ] **Step 4: Commit the checkpoint**

```bash
git add -A
git commit -m "chore: Phase 5 complete — item analysis + PPT/PDF Storage pipeline" --allow-empty
```
