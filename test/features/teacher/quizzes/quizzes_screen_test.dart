import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ar_science_explorer/core/data/curriculum_data.dart';
import 'package:ar_science_explorer/core/models/question_type.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/teacher_quiz.dart';
import 'package:ar_science_explorer/core/models/teacher_quiz_question.dart';
import 'package:ar_science_explorer/core/services/quiz_repository.dart';
import 'package:ar_science_explorer/features/teacher/app/teacher_providers.dart';
import 'package:ar_science_explorer/features/teacher/quizzes/quizzes_providers.dart';
import 'package:ar_science_explorer/features/teacher/quizzes/quizzes_screen.dart';

TeacherQuiz _sampleQuiz({
  String id = 'quiz-custom-1',
  String title = 'Custom Quiz',
}) {
  return TeacherQuiz(
    id: id,
    title: title,
    subject: SubjectKey.chemistry,
    topicId: 'c1',
    phase: QuizPhase.post,
    createdAt: '2026-08-29T00:00:00.000Z',
    questions: const [
      TeacherQuizQuestion(
        question: 'What is H2O?',
        options: ['Water', 'Salt', 'Air', 'Fire'],
        correctIndex: 0,
        hint: 'Think liquid.',
        type: QuestionType.mc,
      ),
    ],
  );
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
}

Future<void> _pumpQuizzesScreen(
  WidgetTester tester, {
  required FakeFirebaseFirestore firestore,
}) async {
  final services = teacherServicesFromFirestore(firestore);
  await tester.pumpWidget(
    ProviderScope(
      overrides: teacherProviderOverridesFor(services: services),
      child: ShadApp(
        home: Scaffold(body: const QuizzesScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('table lists built-in banks as read-only rows', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await _pumpQuizzesScreen(tester, firestore: firestore);

    final firstLesson = kBuiltInLessons.first;
    expect(find.textContaining('${firstLesson.title} Pre-Test'), findsOneWidget);
    expect(find.text('Built-in'), findsWidgets);
    expect(find.byTooltip('Edit'), findsNothing);
    expect(find.byTooltip('Delete'), findsNothing);
  });

  testWidgets('teacher quizzes are editable', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repo = QuizRepository(firestore: firestore);
    await repo.createQuiz(_sampleQuiz());

    await _pumpQuizzesScreen(tester, firestore: firestore);

    expect(find.text('Custom Quiz'), findsOneWidget);
    await _scrollTo(tester, find.byTooltip('Edit'));
    expect(find.byTooltip('Edit'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);
  });

  testWidgets('adding a question row appends another editor block', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await _pumpQuizzesScreen(tester, firestore: firestore);

    await tester.tap(find.text('Add Quiz'));
    await tester.pumpAndSettle();

    expect(find.text('Question 1'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('quiz-add-question')),
      50,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('quiz-add-question')));
    await tester.pumpAndSettle();

    expect(find.text('Question 1'), findsOneWidget);
    expect(find.text('Question 2'), findsOneWidget);
  });

  testWidgets('removing a question row removes its editor block', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await _pumpQuizzesScreen(tester, firestore: firestore);

    await tester.tap(find.text('Add Quiz'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('quiz-add-question')),
      50,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('quiz-add-question')));
    await tester.pumpAndSettle();
    expect(find.text('Question 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quiz-q1-remove')));
    await tester.pumpAndSettle();

    expect(find.text('Question 2'), findsNothing);
    expect(find.text('Question 1'), findsOneWidget);
  });

  testWidgets('incomplete submit is blocked with a validation message', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await _pumpQuizzesScreen(tester, firestore: firestore);

    await tester.tap(find.text('Add Quiz'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quiz-title')));
    await tester.enterText(find.byKey(const Key('quiz-title')), 'Incomplete Quiz');
    await tester.tap(find.byKey(const Key('quiz-question-0-text')));
    await tester.enterText(find.byKey(const Key('quiz-question-0-text')), 'What is science?');
    await tester.tap(find.byKey(const Key('quiz-q0-option-0')));
    await tester.enterText(find.byKey(const Key('quiz-q0-option-0')), 'A');

    await tester.scrollUntilVisible(
      find.byKey(const Key('quiz-submit')),
      50,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('quiz-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('option 2 is required'), findsOneWidget);
    final docs = await firestore.collection('quizzes').get();
    expect(docs.docs, isEmpty);
  });

  testWidgets('complete submit calls createQuiz with entered shape', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await _pumpQuizzesScreen(tester, firestore: firestore);

    await tester.tap(find.text('Add Quiz'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quiz-title')));
    await tester.enterText(find.byKey(const Key('quiz-title')), 'Complete Quiz');
    await tester.tap(find.byKey(const Key('quiz-topic-id')));
    await tester.enterText(find.byKey(const Key('quiz-topic-id')), 'c2');
    await tester.tap(find.byKey(const Key('quiz-question-0-text')));
    await tester.enterText(find.byKey(const Key('quiz-question-0-text')), 'Pick one');
    await tester.tap(find.byKey(const Key('quiz-q0-option-0')));
    await tester.enterText(find.byKey(const Key('quiz-q0-option-0')), 'Alpha');
    await tester.tap(find.byKey(const Key('quiz-q0-option-1')));
    await tester.enterText(find.byKey(const Key('quiz-q0-option-1')), 'Beta');
    await tester.tap(find.byKey(const Key('quiz-q0-option-2')));
    await tester.enterText(find.byKey(const Key('quiz-q0-option-2')), 'Gamma');
    await tester.tap(find.byKey(const Key('quiz-q0-option-3')));
    await tester.enterText(find.byKey(const Key('quiz-q0-option-3')), 'Delta');
    await tester.tap(find.byKey(const Key('quiz-question-0-hint')));
    await tester.enterText(find.byKey(const Key('quiz-question-0-hint')), 'First letter');

    await tester.scrollUntilVisible(
      find.byKey(const Key('quiz-q0-correct-2')),
      50,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('quiz-q0-correct-2')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('quiz-submit')),
      50,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('quiz-submit')));
    await tester.pumpAndSettle();

    final docs = await firestore.collection('quizzes').get();
    expect(docs.docs, hasLength(1));
    final data = docs.docs.single.data();
    expect(data['title'], 'Complete Quiz');
    expect(data['topicId'], 'c2');
    expect(data['phase'], 'post');
    final questions = data['questions'] as List<dynamic>;
    expect(questions, hasLength(1));
    expect(questions.first['question'], 'Pick one');
    expect(questions.first['options'], ['Alpha', 'Beta', 'Gamma', 'Delta']);
    expect(questions.first['correctIndex'], 2);
    expect(questions.first['hint'], 'First letter');
    // Success feedback after a successful create (Fix 4).
    expect(find.text('Quiz created'), findsOneWidget);
  });

  testWidgets('Add Quiz dialog does not dismiss on an outside tap', (
    tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    await _pumpQuizzesScreen(tester, firestore: firestore);

    await tester.tap(find.text('Add Quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Add quiz'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('Add quiz'), findsOneWidget);
  });

  testWidgets('editing a teacher quiz calls updateQuiz', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repo = QuizRepository(firestore: firestore);
    await repo.createQuiz(_sampleQuiz());

    await _pumpQuizzesScreen(tester, firestore: firestore);

    await _scrollTo(tester, find.text('Custom Quiz'));
    await _scrollTo(tester, find.byTooltip('Edit'));
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quiz-title')));
    await tester.enterText(find.byKey(const Key('quiz-title')), 'Renamed Quiz');
    await tester.scrollUntilVisible(
      find.byKey(const Key('quiz-submit')),
      50,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('quiz-submit')));
    await tester.pumpAndSettle();

    final doc = await firestore.collection('quizzes').doc('quiz-custom-1').get();
    expect(doc.data()!['title'], 'Renamed Quiz');
    expect(find.text('Renamed Quiz'), findsOneWidget);
  });

  testWidgets('deleting a teacher quiz removes it and shows success feedback (item 3)', (
    tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    final repo = QuizRepository(firestore: firestore);
    await repo.createQuiz(_sampleQuiz());

    await _pumpQuizzesScreen(tester, firestore: firestore);
    expect(find.text('Custom Quiz'), findsOneWidget);

    await _scrollTo(tester, find.byTooltip('Delete'));
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Custom Quiz'), findsNothing);
    final doc = await firestore.collection('quizzes').doc('quiz-custom-1').get();
    expect(doc.exists, false);
    expect(find.text('Quiz deleted'), findsOneWidget);
  });

  testWidgets(
    'a throwing onDeleteQuiz shows an error toast instead of silently '
    'doing nothing (item 3)',
    (tester) async {
      final quiz = _sampleQuiz();
      final viewModel = QuizzesViewModel(
        rows: [DisplayQuiz(quiz: quiz, isBuiltIn: false)],
        onCreateQuiz: (_) async {},
        onUpdateQuiz: (_) async {},
        onDeleteQuiz: (_) async {
          throw Exception('boom');
        },
      );

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quizzesViewModelProvider.overrideWith(
              (ref) => Stream.value(viewModel),
            ),
          ],
          child: ShadApp(home: Scaffold(body: const QuizzesScreen())),
        ),
      );
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.byTooltip('Delete'));
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Quiz'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining("Couldn't delete this quiz"), findsOneWidget);
    },
  );

  testWidgets('an empty quiz list shows a tailored empty state (item 5)', (
    tester,
  ) async {
    final viewModel = QuizzesViewModel(
      rows: const [],
      onCreateQuiz: (_) async {},
      onUpdateQuiz: (_) async {},
      onDeleteQuiz: (_) async {},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizzesViewModelProvider.overrideWith(
            (ref) => Stream.value(viewModel),
          ),
        ],
        child: ShadApp(home: Scaffold(body: const QuizzesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No quizzes yet — add your first quiz to get started.'),
      findsOneWidget,
    );
  });
}
