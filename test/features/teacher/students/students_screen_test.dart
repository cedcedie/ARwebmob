import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
}) {
  return StudentRecord(
    id: id,
    name: name ?? 'Student $id',
    studentId: id,
    grade: '7',
    section: 'Rizal',
    scores: scores ??
        const {'chemistry': 85, 'biology': null, 'physics': 72},
    completedLessonIds: const [],
    completedLabExperimentIds: const [],
    completedQuizIds: const [],
    unlockedLessonIds: const [],
    unlockedQuizIds: const [],
    quizAttempts: const [],
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
        studentsViewModelProvider.overrideWith((ref) => Stream.value(viewModel)),
        ...extraOverrides,
      ],
      child: const MaterialApp(home: StudentsScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('table shows non-archived students by default', (tester) async {
    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(students: [
        _sampleStudent(id: '123456', name: 'Active One'),
      ]),
    );

    expect(find.text('Active One'), findsOneWidget);
    expect(find.text('Archived One'), findsNothing);
  });

  testWidgets('archived filter toggle calls include-archived handler', (tester) async {
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

  testWidgets('table includes archived students when includeArchived is true', (tester) async {
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

  testWidgets('create form validates student id is exactly 6 digits', (tester) async {
    await _pumpStudentsScreen(
      tester,
      viewModel: _viewModel(students: const []),
    );

    await tester.tap(find.text('Add Student'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('student_name')), 'New Student');
    await tester.enterText(find.byKey(const Key('student_id')), '12345');
    await tester.enterText(find.byKey(const Key('student_grade')), '7');
    await tester.enterText(find.byKey(const Key('student_section')), 'Rizal');

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Student ID must be exactly 6 digits'), findsOneWidget);
  });

  testWidgets('submit calls createStudent with empty activity fields', (tester) async {
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
    await tester.enterText(find.byKey(const Key('student_section')), 'Bonifacio');

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(created, isNotNull);
    expect(created!.scores, const {'chemistry': null, 'biology': null, 'physics': null});
    expect(created!.completedLessonIds, isEmpty);
    expect(created!.quizAttempts, isEmpty);
    expect(created!.studentId, '123456');

    final doc = await firestore.collection('students').doc('123456').get();
    expect(doc.exists, true);
    expect(formatStudentIdForDisplay('123456'), '12-3456');
  });

  testWidgets('archiving a row removes it from the default view', (tester) async {
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
}
