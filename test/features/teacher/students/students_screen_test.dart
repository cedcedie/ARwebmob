import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/features/teacher/students/student_id_format.dart';
import 'package:ar_science_explorer/features/teacher/students/student_csv_import.dart';
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
  Future<void> Function(StudentRecord, String)? onCreateStudent,
  Future<List<StudentImportOutcome>> Function(List<StudentImportRow>)?
  onImportStudents,
  Future<void> Function(String, String)? onResetStudentPassword,
  Future<void> Function(String)? onArchiveStudent,
  Future<void> Function()? onResetAllProgress,
}) {
  return StudentsViewModel(
    students: students,
    includeArchived: includeArchived,
    onToggleIncludeArchived: onToggleIncludeArchived ?? (_) {},
    onCreateStudent: onCreateStudent ?? (_, _) async {},
    onImportStudents: onImportStudents ?? (_) async => const [],
    onResetStudentPassword: onResetStudentPassword ?? (_, _) async {},
    onArchiveStudent: onArchiveStudent ?? (_) async {},
    onResetAllProgress: onResetAllProgress ?? () async {},
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
  // Two pumps: the first frame renders the loading skeleton (whose shimmer
  // is a *repeating* animation, so a stray extra frame would leave its
  // timer pending at teardown); the second lets the stream's value land and
  // replaces the skeleton with the real table.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
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
    String? createdPassword;

    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(
        students: const [],
        onCreateStudent: (student, password) async {
          created = student;
          createdPassword = password;
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
    // The teacher sets the student's login password here (UAT request).
    await tester.enterText(
      find.byKey(const Key('student_password')),
      'science123',
    );
    await tester.enterText(
      find.byKey(const Key('student_password_confirm')),
      'science123',
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
    expect(createdPassword, 'science123');

    final doc = await firestore.collection('students').doc('123456').get();
    expect(doc.exists, true);
    expect(formatStudentIdForDisplay('123456'), '12-3456');
    // Success feedback after a successful create (Fix 4).
    expect(find.text('Student saved'), findsOneWidget);
  });

  testWidgets(
    'a throwing onCreateStudent keeps the dialog open with an error message '
    '(item 3: silent-failure dialog trap)',
    (tester) async {
      await _pumpStudentsScreen(
        tester,
        viewModel: _viewModel(
          students: const [],
          onCreateStudent: (_, _) async {
            throw Exception('boom');
          },
        ),
      );

      await tester.tap(find.text('Add Student'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('student_name')),
        'Ana Reyes',
      );
      await tester.enterText(find.byKey(const Key('student_id')), '123456');
      await tester.enterText(find.byKey(const Key('student_grade')), '8');
      await tester.enterText(
        find.byKey(const Key('student_section')),
        'Bonifacio',
      );
      await tester.enterText(
        find.byKey(const Key('student_password')),
        'science123',
      );
      await tester.enterText(
        find.byKey(const Key('student_password_confirm')),
        'science123',
      );

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Dialog stays open (barrierDismissible: false + failed submit), the
      // entered values are preserved, and a human-readable error is shown
      // instead of the dialog silently doing nothing.
      expect(find.byKey(const Key('student_name')), findsOneWidget);
      expect(find.text('Ana Reyes'), findsOneWidget);
      expect(find.text('Student saved'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining("Couldn't save this student"), findsOneWidget);
    },
  );

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

  testWidgets('tapping the Name column header sorts rows alphabetically', (
    tester,
  ) async {
    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(
        students: [
          _sampleStudent(id: '000003', name: 'Zoe'),
          _sampleStudent(id: '000001', name: 'Amy'),
          _sampleStudent(id: '000002', name: 'Mona'),
        ],
      ),
    );

    await tester.tap(find.text('Name'));
    await tester.pump();

    final amyTop = tester.getTopLeft(find.text('Amy')).dy;
    final monaTop = tester.getTopLeft(find.text('Mona')).dy;
    final zoeTop = tester.getTopLeft(find.text('Zoe')).dy;
    expect(amyTop, lessThan(monaTop));
    expect(monaTop, lessThan(zoeTop));
  });

  testWidgets(
    'selecting rows shows an Archive selected action that archives all '
    'selected students at once',
    (tester) async {
      final archived = <String>[];
      await _pumpStudentsScreen(
        tester,
        viewModel: _viewModel(
          students: [
            _sampleStudent(id: '000001', name: 'Alice'),
            _sampleStudent(id: '000002', name: 'Bob'),
          ],
          onArchiveStudent: (id) async => archived.add(id),
        ),
      );

      expect(find.textContaining('Archive selected'), findsNothing);

      // Row checkboxes: index 0 is the header "select all" checkbox.
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pump();
      await tester.tap(find.byType(Checkbox).at(2));
      await tester.pump();

      expect(find.text('Archive selected (2)'), findsOneWidget);

      await tester.tap(find.text('Archive selected (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Archive 2 student(s)?'), findsOneWidget);
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(archived, unorderedEquals(['000001', '000002']));
      expect(find.textContaining('Archive selected'), findsNothing);
      // Item 4: success feedback after a bulk archive.
      expect(find.text('2 students archived'), findsOneWidget);
    },
  );

  testWidgets(
    'bulk archive with a partial failure shows an error toast and keeps the '
    'failed student selected for retry (item 4)',
    (tester) async {
      final archived = <String>[];
      await _pumpStudentsScreen(
        tester,
        viewModel: _viewModel(
          students: [
            _sampleStudent(id: '000001', name: 'Alice'),
            _sampleStudent(id: '000002', name: 'Bob'),
          ],
          onArchiveStudent: (id) async {
            if (id == '000002') throw Exception('boom');
            archived.add(id);
          },
        ),
      );

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pump();
      await tester.tap(find.byType(Checkbox).at(2));
      await tester.pump();

      await tester.tap(find.text('Archive selected (2)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(archived, ['000001']);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining("couldn't be archived"), findsOneWidget);
      // The failed student stays selected — "Archive selected" still shows
      // for just that one — so the teacher can retry it directly.
      expect(find.text('Archive selected (1)'), findsOneWidget);
    },
  );

  testWidgets(
    'archiving a row confirms first, then calls the archive handler with '
    'success feedback (item 4)',
    (tester) async {
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
      await tester.pumpAndSettle();

      // Confirmation dialog now guards a single-row archive, matching the
      // bulk-archive path — the archive must not happen until confirmed.
      expect(find.text('Archive student?'), findsOneWidget);
      expect(archivedIds, isEmpty);

      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(archivedIds, ['123456']);
      expect(find.text('Student archived'), findsOneWidget);
    },
  );

  testWidgets('archiving a row shows Cancel keeps the student unarchived', (
    tester,
  ) async {
    final archivedIds = <String>[];

    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(
        students: [_sampleStudent(id: '123456', name: 'Keep Me')],
        onArchiveStudent: (id) async => archivedIds.add(id),
      ),
    );

    await tester.tap(find.byTooltip('Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(archivedIds, isEmpty);
    expect(find.text('Keep Me'), findsOneWidget);
  });

  testWidgets('a throwing single-row archive shows an error toast instead of '
      'silently doing nothing (item 4)', (tester) async {
    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(
        students: [_sampleStudent(id: '123456', name: 'Fails To Archive')],
        onArchiveStudent: (_) async {
          throw Exception('boom');
        },
      ),
    );

    await tester.tap(find.byTooltip('Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Fails To Archive'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    expect(
      find.textContaining("Couldn't archive this student"),
      findsOneWidget,
    );
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

  testWidgets('an empty roster shows a tailored empty state (item 5)', (
    tester,
  ) async {
    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(students: const []),
    );

    expect(
      find.text('No students yet — add your first student to get started.'),
      findsOneWidget,
    );
  });
}
