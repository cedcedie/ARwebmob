import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ar_science_explorer/core/data/curriculum_data.dart';
import 'package:ar_science_explorer/core/models/lesson.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/teacher_lesson.dart';
import 'package:ar_science_explorer/core/models/teacher_quiz.dart';
import 'package:ar_science_explorer/core/services/lesson_repository.dart';
import 'package:ar_science_explorer/features/teacher/app/teacher_providers.dart';
import 'package:ar_science_explorer/features/teacher/lessons/lessons_providers.dart';
import 'package:ar_science_explorer/features/teacher/lessons/lessons_screen.dart';

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
}

Future<void> _pumpLessonsScreen(
  WidgetTester tester, {
  required FakeFirebaseFirestore firestore,
}) async {
  final services = teacherServicesFromFirestore(firestore);
  await tester.pumpWidget(
    ProviderScope(
      overrides: teacherProviderOverridesFor(services: services),
      child: ShadApp(
        home: Scaffold(body: const LessonsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('built-in lessons are non-editable and show a Built-in badge', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await _pumpLessonsScreen(tester, firestore: firestore);

    expect(find.text(kBuiltInLessons.first.title), findsOneWidget);
    expect(find.text('Built-in'), findsWidgets);
    expect(find.byTooltip('Edit'), findsNothing);
    expect(find.byTooltip('Archive'), findsNothing);
  });

  testWidgets('teacher-authored lessons are editable', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repo = LessonRepository(firestore: firestore);
    await repo.createLesson(
      const TeacherLesson(
        id: 'teacher-custom-1',
        title: 'Teacher Volcano Lab',
        subject: SubjectKey.physics,
        summary: 'Extra lab',
        quarter: 1,
        week: 5,
      ),
    );

    await _pumpLessonsScreen(tester, firestore: firestore);

    expect(find.text('Teacher Volcano Lab'), findsOneWidget);
    await _scrollTo(tester, find.byTooltip('Edit'));
    expect(find.byTooltip('Edit'), findsOneWidget);
    expect(find.byTooltip('Archive'), findsOneWidget);
  });

  testWidgets('Add Lesson opens the form dialog', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await _pumpLessonsScreen(tester, firestore: firestore);

    await tester.tap(find.text('Add Lesson'));
    await tester.pumpAndSettle();

    expect(find.text('Add lesson'), findsOneWidget);
    expect(find.byKey(const Key('lesson-title')), findsOneWidget);
  });

  testWidgets('submitting a valid form calls createLesson', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await _pumpLessonsScreen(tester, firestore: firestore);

    await tester.tap(find.text('Add Lesson'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('lesson-title')));
    await tester.enterText(find.byKey(const Key('lesson-title')), 'New Teacher Lesson');
    await tester.tap(find.byKey(const Key('lesson-summary')));
    await tester.enterText(find.byKey(const Key('lesson-summary')), 'A custom summary');
    await tester.tap(find.byKey(const Key('lesson-quarter')));
    await tester.enterText(find.byKey(const Key('lesson-quarter')), '1');
    await tester.tap(find.byKey(const Key('lesson-week')));
    await tester.enterText(find.byKey(const Key('lesson-week')), '5');

    await tester.scrollUntilVisible(
      find.byKey(const Key('lesson-submit')),
      50,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('lesson-submit')));
    await tester.pumpAndSettle();

    final docs = await firestore.collection('lessons').get();
    expect(docs.docs, hasLength(1));
    expect(docs.docs.single.data()['title'], 'New Teacher Lesson');
    expect(find.text('New Teacher Lesson'), findsOneWidget);
    // Success feedback after a successful create (Fix 4).
    expect(find.text('Lesson created'), findsOneWidget);
  });

  testWidgets('Add Lesson dialog does not dismiss on an outside tap', (
    tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    await _pumpLessonsScreen(tester, firestore: firestore);

    await tester.tap(find.text('Add Lesson'));
    await tester.pumpAndSettle();
    expect(find.text('Add lesson'), findsOneWidget);

    // Tap far outside the dialog card, on the barrier itself.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    // An accidental outside click must not lose an in-progress edit.
    expect(find.text('Add lesson'), findsOneWidget);
  });

  testWidgets('AR model index shows a preview placeholder in tests', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await _pumpLessonsScreen(tester, firestore: firestore);

    await tester.tap(find.text('Add Lesson'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('lesson-quarter')), '1');
    await tester.enterText(find.byKey(const Key('lesson-week')), '1');
    await tester.pumpAndSettle();

    expect(find.textContaining('Model preview: assets/models/democritus_atom.glb'), findsOneWidget);
  });

  testWidgets('editing a teacher lesson pre-fills the form and calls updateLesson', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repo = LessonRepository(firestore: firestore);
    await repo.createLesson(
      const TeacherLesson(
        id: 'teacher-edit-1',
        title: 'Editable Lesson',
        subject: SubjectKey.biology,
        summary: 'Original summary',
      ),
    );

    await _pumpLessonsScreen(tester, firestore: firestore);

    await _scrollTo(tester, find.byTooltip('Edit'));
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit lesson'), findsOneWidget);
    expect(find.byKey(const Key('lesson-title')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('lesson-title')), 'Updated Lesson Title');
    await tester.scrollUntilVisible(
      find.byKey(const Key('lesson-submit')),
      50,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('lesson-submit')));
    await tester.pumpAndSettle();

    final doc = await firestore.collection('lessons').doc('teacher-edit-1').get();
    expect(doc.data()!['title'], 'Updated Lesson Title');
    expect(find.text('Updated Lesson Title'), findsOneWidget);
  });

  testWidgets('tapping the Title column header sorts rows alphabetically', (
    tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    final repo = LessonRepository(firestore: firestore);
    await repo.createLesson(
      const TeacherLesson(
        id: 'teacher-zeta',
        title: 'Zeta Lesson',
        subject: SubjectKey.physics,
      ),
    );
    await repo.createLesson(
      const TeacherLesson(
        id: 'teacher-alpha',
        title: 'Alpha Lesson',
        subject: SubjectKey.physics,
      ),
    );

    await _pumpLessonsScreen(tester, firestore: firestore);

    // Both rows exist before any sort is applied.
    expect(find.text('Zeta Lesson'), findsOneWidget);
    expect(find.text('Alpha Lesson'), findsOneWidget);

    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();

    final alphaTop = tester.getTopLeft(find.text('Alpha Lesson')).dy;
    final zetaTop = tester.getTopLeft(find.text('Zeta Lesson')).dy;
    expect(
      alphaTop,
      lessThan(zetaTop),
      reason: 'ascending sort should place Alpha above Zeta',
    );

    // Tapping again reverses to descending.
    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();

    final alphaTop2 = tester.getTopLeft(find.text('Alpha Lesson')).dy;
    final zetaTop2 = tester.getTopLeft(find.text('Zeta Lesson')).dy;
    expect(
      zetaTop2,
      lessThan(alphaTop2),
      reason: 'descending sort should place Zeta above Alpha',
    );
  });

  testWidgets(
    'Quarter/Week sort always places a lesson missing quarter/week at the '
    'end, in both directions (item 5)',
    (tester) async {
      final firestore = FakeFirebaseFirestore();
      final repo = LessonRepository(firestore: firestore);
      await repo.createLesson(
        const TeacherLesson(
          id: 'teacher-early',
          title: 'Early Lesson',
          subject: SubjectKey.physics,
          quarter: 1,
          week: 1,
        ),
      );
      await repo.createLesson(
        const TeacherLesson(
          id: 'teacher-late',
          title: 'Late Lesson',
          subject: SubjectKey.physics,
          quarter: 4,
          week: 3,
        ),
      );
      await repo.createLesson(
        const TeacherLesson(
          id: 'teacher-unset',
          title: 'Unset Lesson',
          subject: SubjectKey.physics,
          // No quarter/week set.
        ),
      );

      await _pumpLessonsScreen(tester, firestore: firestore);

      await tester.tap(find.text('Quarter/Week'));
      await tester.pumpAndSettle();

      final earlyTop = tester.getTopLeft(find.text('Early Lesson')).dy;
      final lateTop = tester.getTopLeft(find.text('Late Lesson')).dy;
      final unsetTop = tester.getTopLeft(find.text('Unset Lesson')).dy;
      expect(
        earlyTop,
        lessThan(lateTop),
        reason: 'ascending sort should place Q1W1 above Q4W3',
      );
      expect(
        lateTop,
        lessThan(unsetTop),
        reason:
            'ascending sort must still place the unset lesson after every '
            'scheduled lesson, not before Quarter 1',
      );

      // Tapping again reverses to descending.
      await tester.tap(find.text('Quarter/Week'));
      await tester.pumpAndSettle();

      final earlyTop2 = tester.getTopLeft(find.text('Early Lesson')).dy;
      final lateTop2 = tester.getTopLeft(find.text('Late Lesson')).dy;
      final unsetTop2 = tester.getTopLeft(find.text('Unset Lesson')).dy;
      expect(
        lateTop2,
        lessThan(earlyTop2),
        reason: 'descending sort should place Q4W3 above Q1W1',
      );
      expect(
        earlyTop2,
        lessThan(unsetTop2),
        reason:
            'the unset lesson must stay last even on a descending sort, not '
            'jump to the front',
      );
    },
  );

  testWidgets('archiving a teacher lesson removes it from the default view', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repo = LessonRepository(firestore: firestore);
    await repo.createLesson(
      const TeacherLesson(
        id: 'teacher-archive-1',
        title: 'Archive Me',
        subject: SubjectKey.chemistry,
      ),
    );

    await _pumpLessonsScreen(tester, firestore: firestore);
    expect(find.text('Archive Me'), findsOneWidget);

    await _scrollTo(tester, find.byTooltip('Archive'));
    await tester.tap(find.byTooltip('Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Archive Me'), findsNothing);

    final doc = await firestore.collection('lessons').doc('teacher-archive-1').get();
    expect(doc.data()!['isArchived'], true);
    // Item 2: success feedback after a successful archive.
    expect(find.text('Lesson archived'), findsOneWidget);
  });

  testWidgets(
    'a throwing onArchiveLesson shows an error toast instead of silently '
    'doing nothing (item 2)',
    (tester) async {
      final lesson = Lesson(
        id: 'teacher-archive-fail',
        title: 'Archive Me Too',
        subject: SubjectKey.chemistry,
        summary: 'Summary',
        steps: const [],
        quarter: 1,
        week: 1,
      );
      final teacherLesson = TeacherLesson(
        id: lesson.id,
        title: lesson.title,
        subject: lesson.subject,
        summary: lesson.summary,
        quarter: lesson.quarter,
        week: lesson.week,
      );
      final viewModel = LessonsViewModel(
        rows: [
          DisplayLesson(
            lesson: lesson,
            isBuiltIn: false,
            teacherLesson: teacherLesson,
          ),
        ],
        quizOptions: const <TeacherQuiz>[],
        onCreateLesson: (_) async {},
        onUpdateLesson: (_) async {},
        onArchiveLesson: (_) async {
          throw Exception('boom');
        },
        fetchLessonById: (_) async => null,
      );

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lessonsViewModelProvider.overrideWith(
              (ref) => Stream.value(viewModel),
            ),
          ],
          child: ShadApp(home: Scaffold(body: const LessonsScreen())),
        ),
      );
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.byTooltip('Archive'));
      await tester.tap(find.byTooltip('Archive'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(find.text('Archive Me Too'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining("Couldn't archive this lesson"), findsOneWidget);
    },
  );
}
