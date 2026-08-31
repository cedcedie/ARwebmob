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

