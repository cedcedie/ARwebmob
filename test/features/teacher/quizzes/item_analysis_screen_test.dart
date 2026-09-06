// test/features/teacher/quizzes/item_analysis_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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
          id: 'q0',
          subject: SubjectKey.chemistry,
          lessonId: 'q1w1',
          question: 'What is H2O?',
          options: const ['Water', 'Oxygen', 'Hydrogen', 'Salt'],
          correctIndex: 0,
          hint: 'hint',
          type: QuestionType.mc,
        ),
      ],
      results: const [
        QuestionItemAnalysis(
          questionIndex: 0,
          difficultyIndex: 0.75,
          discriminationIndex: 0.3,
          distractorRates: {1: 0.15, 2: 0.1},
        ),
      ],
      attemptCount: 20,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemAnalysisViewModelProvider(
            'quiz-1',
          ).overrideWith((ref) => Stream.value(vm)),
        ],
        // ShadApp, not MaterialApp: the screen reads ShadTheme.of(context).
        child: const ShadApp(
          home: ItemAnalysisScreen(
            quizId: 'quiz-1',
            quizTitle: 'Q1W1 Post-Test',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('20'),
      findsWidgets,
    ); // attempt count shown somewhere
    expect(find.textContaining('What is H2O?'), findsOneWidget);
    expect(
      find.textContaining('75%'),
      findsWidgets,
    ); // difficulty index rendered as a percent

    // UAT feedback: teachers want the headcount, not just the percentage.
    expect(
      find.textContaining('15 of 20 students answered correctly'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows a humanized message (not the raw error) and retries on tap',
    (tester) async {
      var attempt = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemAnalysisViewModelProvider('quiz-1').overrideWith((ref) {
              attempt++;
              return Stream.error(Exception('boom'));
            }),
          ],
          child: const ShadApp(
            home: ItemAnalysisScreen(
              quizId: 'quiz-1',
              quizTitle: 'Q1W1 Post-Test',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Exception'), findsNothing);
      expect(
        find.textContaining("Couldn't load item analysis"),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(attempt, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(attempt, 2);
    },
  );
}
