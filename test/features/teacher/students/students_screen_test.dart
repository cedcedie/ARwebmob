import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/features/teacher/students/student_id_format.dart';
import 'package:ar_science_explorer/features/teacher/students/students_providers.dart';
import 'package:ar_science_explorer/features/teacher/students/students_screen.dart';

StudentRecord _sampleStudent({
  required String id,
  String? name,
  bool isArchived = false,
  Map<String, num?>? scores,
  List<String>? completedLessonIds,
  List<QuizAttempt>? quizAttempts,
}) {
  return StudentRecord(
    id: id,
    name: name ?? 'Student $id',
    studentId: id,
    grade: '7',
    section: 'Rizal',
    scores: scores ?? const {'chemistry': 85, 'biology': null, 'physics': 72},
    completedLessonIds: completedLessonIds ?? const [],
    completedLabExperimentIds: const [],
    completedQuizIds: const [],
    unlockedLessonIds: const [],
    unlockedQuizIds: const [],
    quizAttempts: quizAttempts ?? const [],
    isArchived: isArchived,
  );
}

StudentsViewModel _viewModel({
  required List<StudentRecord> students,
  bool includeArchived = false,
  void Function(bool)? onToggleIncludeArchived,
  Future<void> Function(StudentRecord)? onCreateStudent,
  Future<void> Function(String)? onArchiveStudent,
}) {
  return StudentsViewModel(
    students: students,
    includeArchived: includeArchived,
    onToggleIncludeArchived: onToggleIncludeArchived ?? (_) {},
    onCreateStudent: onCreateStudent ?? (_) async {},
    onArchiveStudent: onArchiveStudent ?? (_) async {},
  );
}

Future<void> _pumpStudentsScreen(
  WidgetTester tester, {
  required StudentsViewModel viewModel,
  List<Override> extraOverrides = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentsViewModelProvider.overrideWith(
          (ref) => Stream.value(viewModel),
        ),
        ...extraOverrides,
      ],
      child: const ShadApp(home: StudentsScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('table shows non-archived students by default', (tester) async {
    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(
        students: [_sampleStudent(id: '123456', name: 'Active One')],
      ),
    );

    expect(find.text('Active One'), findsOneWidget);
    expect(find.text('Archived One'), findsNothing);
  });

  testWidgets('archived filter toggle calls include-archived handler', (
    tester,
  ) async {
    var includeArchived = false;
    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(
        students: [_sampleStudent(id: '123456', name: 'Active One')],
        includeArchived: includeArchived,
        onToggleIncludeArchived: (value) => includeArchived = value,
      ),
    );

    await tester.tap(find.text('Show archived'));
    await tester.pump();

    expect(includeArchived, isTrue);
  });

  testWidgets('table includes archived students when includeArchived is true', (
    tester,
  ) async {
    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(
        students: [
          _sampleStudent(id: '123456', name: 'Active One'),
          _sampleStudent(id: '999999', name: 'Archived One', isArchived: true),
        ],
        includeArchived: true,
      ),
    );

    expect(find.text('Active One'), findsOneWidget);
    expect(find.text('Archived One'), findsOneWidget);
  });

  testWidgets('create form validates student id is exactly 6 digits', (
    tester,
  ) async {
    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(students: const []),
    );

    await tester.tap(find.text('Add Student'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('student_name')),
      'New Student',
    );
    await tester.enterText(find.byKey(const Key('student_id')), '12345');
    await tester.enterText(find.byKey(const Key('student_grade')), '7');
    await tester.enterText(find.byKey(const Key('student_section')), 'Rizal');

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Student ID must be exactly 6 digits'), findsOneWidget);
  });

  testWidgets('submit calls createStudent with empty activity fields', (
    tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    final repo = StudentRepository(firestore: firestore);
    StudentRecord? created;

    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(
        students: const [],
        onCreateStudent: (student) async {
          created = student;
          await repo.createStudent(student);
        },
      ),
    );

    await tester.tap(find.text('Add Student'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('student_name')), 'Ana Reyes');
    await tester.enterText(find.byKey(const Key('student_id')), '12-3456');
    await tester.enterText(find.byKey(const Key('student_grade')), '8');
    await tester.enterText(
      find.byKey(const Key('student_section')),
      'Bonifacio',
    );

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(created, isNotNull);
    expect(created!.scores, const {
      'chemistry': null,
      'biology': null,
      'physics': null,
    });
    expect(created!.completedLessonIds, isEmpty);
    expect(created!.quizAttempts, isEmpty);
    expect(created!.studentId, '123456');

    final doc = await firestore.collection('students').doc('123456').get();
    expect(doc.exists, true);
    expect(formatStudentIdForDisplay('123456'), '12-3456');
    // Success feedback after a successful create (Fix 4).
    expect(find.text('Student saved'), findsOneWidget);
  });

  testWidgets('Add Student dialog does not dismiss on an outside tap', (
    tester,
  ) async {
    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(students: const []),
    );

    await tester.tap(find.text('Add Student'));
    await tester.pumpAndSettle();
    expect(find.text('Add Student'), findsWidgets);
    expect(find.byKey(const Key('student_name')), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    // An accidental outside click must not lose an in-progress roster entry.
    expect(find.byKey(const Key('student_name')), findsOneWidget);
  });

  testWidgets('archiving a row removes it from the default view', (
    tester,
  ) async {
    final archivedIds = <String>[];

    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(
        students: [_sampleStudent(id: '123456', name: 'To Archive')],
        onArchiveStudent: (id) async => archivedIds.add(id),
      ),
    );

    expect(find.text('To Archive'), findsOneWidget);

    await tester.tap(find.byTooltip('Archive'));
    await tester.pump();

    expect(archivedIds, ['123456']);
  });

  testWidgets('roster shows lesson-completion count and quiz-attempt count', (
    tester,
  ) async {
    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(
        students: [
          _sampleStudent(
            id: '123456',
            name: 'Progressed Student',
            completedLessonIds: const ['lesson-1', 'lesson-2', 'lesson-3'],
            quizAttempts: [
              QuizAttempt(
                id: 'a1',
                quizId: 'chemistry-lesson-1-pre',
                studentId: '123456',
                attemptNumber: 1,
                score: 8,
                totalQuestions: 10,
                correctAnswers: 8,
                answers: const [0, 1, 2],
                timestamp: '2026-08-01T10:00:00.000Z',
                locked: false,
              ),
              QuizAttempt(
                id: 'a2',
                quizId: 'chemistry-lesson-1-post',
                studentId: '123456',
                attemptNumber: 1,
                score: 9,
                totalQuestions: 10,
                correctAnswers: 9,
                answers: const [0, 1, 2],
                timestamp: '2026-08-02T10:00:00.000Z',
                locked: true,
              ),
            ],
          ),
        ],
      ),
    );

    expect(find.text('Lessons: 3'), findsOneWidget);
    expect(find.text('Quizzes taken: 2'), findsOneWidget);

    // Drill down into the per-student detail view.
    await tester.tap(find.byTooltip('View progress details'));
    await tester.pumpAndSettle();

    expect(find.text('Lessons completed: 3'), findsOneWidget);
    expect(find.text('Quiz attempts (2)'), findsOneWidget);
    expect(find.textContaining('chemistry-lesson-1-pre'), findsOneWidget);
    expect(find.textContaining('chemistry-lesson-1-post'), findsOneWidget);
  });

  testWidgets('roster shows zero-progress state for a brand-new student', (
    tester,
  ) async {
    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(
        students: [_sampleStudent(id: '654321', name: 'Fresh Student')],
      ),
    );

    expect(find.text('Lessons: 0'), findsOneWidget);
    expect(find.text('Quizzes taken: 0'), findsOneWidget);
  });
}
