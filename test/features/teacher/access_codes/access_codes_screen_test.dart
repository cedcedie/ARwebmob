import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/core/data/curriculum_data.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/quiz_id.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/features/teacher/access_codes/access_codes_providers.dart';
import 'package:ar_science_explorer/features/teacher/access_codes/access_codes_screen.dart';
import 'package:ar_science_explorer/features/teacher/app/teacher_providers.dart';

StudentRecord _blankStudent(String id, {String name = 'Test Student'}) => StudentRecord(
      id: id,
      name: name,
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

Future<void> _pumpAccessCodesScreen(
  WidgetTester tester, {
  required AccessCodesViewModel viewModel,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accessCodesViewModelProvider.overrideWith((ref) => Stream.value(viewModel)),
      ],
      child: const MaterialApp(home: AccessCodesScreen()),
    ),
  );
  await tester.pump();
}

Future<void> _tapIssueButton(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('subject form issues a code and displays it prominently', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final services = teacherServicesFromFirestore(firestore);
    String? issuedCode;

    await _pumpAccessCodesScreen(
      tester,
      viewModel: AccessCodesViewModel(
        students: const [],
        lessons: kBuiltInLessons,
        issuedCodes: const [],
        onIssueSubjectCode: ({
          required subjects,
          lessonIds,
          customCode,
        }) async {
          issuedCode = await services.accessCodeIssuanceService.issueSubjectCode(
            subjects: subjects,
            lessonIds: lessonIds,
            customCode: customCode,
          );
          return issuedCode!;
        },
        onIssueLessonCode: ({
          required lessonId,
          required studentId,
          customCode,
        }) =>
            services.accessCodeIssuanceService.issueLessonCode(
              lessonId: lessonId,
              studentId: studentId,
              customCode: customCode,
            ),
        onIssueQuizRetakeCode: ({
          required lessonId,
          required studentId,
        }) =>
            services.accessCodeIssuanceService.issueQuizRetakeCode(
              lessonId: lessonId,
              studentId: studentId,
            ),
        checkRetakeEligible: ({
          required studentId,
          required lessonId,
        }) async =>
            true,
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Custom code (optional)'), 'CHEM01');
    await _tapIssueButton(tester, 'Issue subject code');

    expect(find.text('CHEM01'), findsWidgets);
    expect(find.textContaining('Code issued'), findsOneWidget);
    expect(issuedCode, 'CHEM01');

    final doc = await firestore.collection('unlockCodes').doc('CHEM01').get();
    expect(doc.exists, true);
  });

  testWidgets('lesson targeted form issues a code for the selected student and lesson', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final services = teacherServicesFromFirestore(firestore);

    await _pumpAccessCodesScreen(
      tester,
      viewModel: AccessCodesViewModel(
        students: [_blankStudent('222222', name: 'Maria')],
        lessons: kBuiltInLessons,
        issuedCodes: const [],
        onIssueSubjectCode: ({
          required subjects,
          lessonIds,
          customCode,
        }) =>
            services.accessCodeIssuanceService.issueSubjectCode(
              subjects: subjects,
              lessonIds: lessonIds,
              customCode: customCode,
            ),
        onIssueLessonCode: ({
          required lessonId,
          required studentId,
          customCode,
        }) =>
            services.accessCodeIssuanceService.issueLessonCode(
              lessonId: lessonId,
              studentId: studentId,
              customCode: customCode,
            ),
        onIssueQuizRetakeCode: ({
          required lessonId,
          required studentId,
        }) =>
            services.accessCodeIssuanceService.issueQuizRetakeCode(
              lessonId: lessonId,
              studentId: studentId,
            ),
        checkRetakeEligible: ({
          required studentId,
          required lessonId,
        }) async =>
            true,
      ),
    );

    await tester.tap(find.text('Lesson targeted'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Student'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maria (222222)').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Lesson'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('q1w1').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Custom code (optional)'), 'LESS01');
    await _tapIssueButton(tester, 'Issue lesson code');

    expect(find.text('LESS01'), findsWidgets);

    final doc = await firestore.collection('unlockCodes').doc('LESS01').get();
    expect(doc.data()!['type'], 'lesson');
    expect(doc.data()!['targetStudentId'], '222222');
    expect(doc.data()!['targetId'], 'q1w1');
  });

  testWidgets('retake form disables submit when student has no post-test attempt', (tester) async {
    await _pumpAccessCodesScreen(
      tester,
      viewModel: AccessCodesViewModel(
        students: [_blankStudent('333333', name: 'No Attempt')],
        lessons: kBuiltInLessons,
        issuedCodes: const [],
        onIssueSubjectCode: ({
          required subjects,
          lessonIds,
          customCode,
        }) async =>
            'unused',
        onIssueLessonCode: ({
          required lessonId,
          required studentId,
          customCode,
        }) async =>
            'unused',
        onIssueQuizRetakeCode: ({
          required lessonId,
          required studentId,
        }) async =>
            'unused',
        checkRetakeEligible: ({
          required studentId,
          required lessonId,
        }) async =>
            false,
      ),
    );

    await tester.tap(find.text('Quiz retake'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Student'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No Attempt (333333)').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Lesson'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('q1w1').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('no recorded post-test attempt'), findsOneWidget);
    final submitButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Issue retake code'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(submitButton.onPressed, isNull);
  });

  testWidgets('retake form issues a code after a post-test attempt exists', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final services = teacherServicesFromFirestore(firestore);
    final studentRepo = StudentRepository(firestore: firestore);
    final quizAttemptService = QuizAttemptService(firestore: firestore);
    await studentRepo.saveStudent(_blankStudent('444444', name: 'Has Attempt'));

    final quizId = builtinQuizId('q1w1', QuizPhase.post);
    await quizAttemptService.recordAttempt(
      studentId: '444444',
      subject: SubjectKey.chemistry,
      attempt: QuizAttempt(
        id: 'attempt-1',
        quizId: quizId,
        studentId: '444444',
        attemptNumber: 1,
        score: 80,
        totalQuestions: 10,
        correctAnswers: 8,
        answers: const [0, 1, 2, 3, 0, 1, 2, 3, 0, 1],
        timestamp: DateTime(2026, 1, 1).toIso8601String(),
        locked: true,
      ),
    );

    await _pumpAccessCodesScreen(
      tester,
      viewModel: AccessCodesViewModel(
        students: [_blankStudent('444444', name: 'Has Attempt')],
        lessons: kBuiltInLessons,
        issuedCodes: const [],
        onIssueSubjectCode: ({
          required subjects,
          lessonIds,
          customCode,
        }) async =>
            'unused',
        onIssueLessonCode: ({
          required lessonId,
          required studentId,
          customCode,
        }) async =>
            'unused',
        onIssueQuizRetakeCode: ({
          required lessonId,
          required studentId,
        }) =>
            services.accessCodeIssuanceService.issueQuizRetakeCode(
              lessonId: lessonId,
              studentId: studentId,
            ),
        checkRetakeEligible: ({
          required studentId,
          required lessonId,
        }) async {
          final eligibility = await quizAttemptService.checkEligibility(
            studentId,
            builtinQuizId(lessonId, QuizPhase.post),
          );
          return eligibility.attemptCount >= 1;
        },
      ),
    );

    await tester.tap(find.text('Quiz retake'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Student'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Has Attempt (444444)').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Lesson'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('q1w1').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));

    await _tapIssueButton(tester, 'Issue retake code');

    expect(find.textContaining('Code issued'), findsOneWidget);

    final docs = await firestore.collection('quizUnlockCodes').get();
    expect(docs.docs, isNotEmpty);
    expect(docs.docs.first.data()['studentId'], '444444');
  });

  testWidgets('duplicate custom code shows StateError message, not a generic error', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final services = teacherServicesFromFirestore(firestore);
    await firestore.collection('unlockCodes').doc('TAKEN1').set({
      'type': 'subject',
      'subjects': ['chemistry'],
      'usedByStudentIds': <String>[],
      'isUsed': false,
    });

    await _pumpAccessCodesScreen(
      tester,
      viewModel: AccessCodesViewModel(
        students: const [],
        lessons: kBuiltInLessons,
        issuedCodes: const [],
        onIssueSubjectCode: ({
          required subjects,
          lessonIds,
          customCode,
        }) =>
            services.accessCodeIssuanceService.issueSubjectCode(
              subjects: subjects,
              lessonIds: lessonIds,
              customCode: customCode,
            ),
        onIssueLessonCode: ({
          required lessonId,
          required studentId,
          customCode,
        }) async =>
            'unused',
        onIssueQuizRetakeCode: ({
          required lessonId,
          required studentId,
        }) async =>
            'unused',
        checkRetakeEligible: ({
          required studentId,
          required lessonId,
        }) async =>
            false,
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Custom code (optional)'), 'TAKEN1');
    await _tapIssueButton(tester, 'Issue subject code');

    expect(find.textContaining('already exists'), findsOneWidget);
    expect(find.textContaining('Code issued'), findsNothing);
  });

  testWidgets('issued codes table merges unlock and retake sources', (tester) async {
    await _pumpAccessCodesScreen(
      tester,
      viewModel: AccessCodesViewModel(
        students: const [],
        lessons: kBuiltInLessons,
        issuedCodes: const [
          IssuedCodeRow(
            code: 'SUBJ01',
            type: IssuedCodeType.subject,
            target: 'any',
            status: 'unused',
            issuedAt: '2026-01-01T00:00:00.000',
          ),
          IssuedCodeRow(
            code: 'RETAKE1',
            type: IssuedCodeType.retake,
            target: '111111',
            status: 'unused',
            issuedAt: '2026-01-02T00:00:00.000',
          ),
        ],
        onIssueSubjectCode: ({
          required subjects,
          lessonIds,
          customCode,
        }) async =>
            'unused',
        onIssueLessonCode: ({
          required lessonId,
          required studentId,
          customCode,
        }) async =>
            'unused',
        onIssueQuizRetakeCode: ({
          required lessonId,
          required studentId,
        }) async =>
            'unused',
        checkRetakeEligible: ({
          required studentId,
          required lessonId,
        }) async =>
            false,
      ),
    );

    expect(find.text('SUBJ01'), findsOneWidget);
    expect(find.text('RETAKE1'), findsOneWidget);
    expect(find.text('111111'), findsOneWidget);
    expect(find.text('Retake'), findsOneWidget);
  });
}
