import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/lesson_repository.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/features/student/app/router.dart';
import 'package:ar_science_explorer/features/student/app/student_providers.dart';

void main() {
  testWidgets(
      'C3: /quiz/:lessonId/pre degrades gracefully for a lesson with no pre-test bank, instead of crashing',
      (tester) async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    await studentRepo.saveStudent(StudentRecord(
      id: '111111', name: 'Juan', studentId: '111111', grade: '7', section: 'A',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [], completedLabExperimentIds: const [],
      completedQuizIds: const [], unlockedLessonIds: const [], unlockedQuizIds: const [],
      quizAttempts: const [],
    ));
    final quizAttemptService = QuizAttemptService(firestore: firestore);
    final services = StudentServices(
      lessonRepository: LessonRepository(firestore: firestore),
      studentRepository: studentRepo,
      quizAttemptService: quizAttemptService,
      accessCodeService: AccessCodeService(firestore: firestore, quizAttemptService: quizAttemptService),
    );
    final router = buildStudentRouter(services: services);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentStudentIdProvider.overrideWith((ref) => Stream.value('111111')),
          ...studentProviderOverridesFor('111111', services: services),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // q1w6 has no entry in kPreTestQuestionsByLesson (only q1w1..q1w5's
    // built-in pre-test banks are populated per Task 1's sparse data).
    router.go('/quiz/q1w6/pre');
    await tester.pumpAndSettle();

    expect(find.text('Test unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('C4: /lesson/:lessonId resolves a teacher-authored lesson id without throwing',
      (tester) async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    await studentRepo.saveStudent(StudentRecord(
      id: '111111', name: 'Juan', studentId: '111111', grade: '7', section: 'A',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [], completedLabExperimentIds: const [],
      completedQuizIds: const [], unlockedLessonIds: const [], unlockedQuizIds: const [],
      quizAttempts: const [],
    ));
    await firestore.collection('lessons').doc('teacher-extra-1').set({
      'id': 'teacher-extra-1',
      'title': 'Extra Credit: Volcanoes',
      'subject': 'physics',
    });
    final quizAttemptService = QuizAttemptService(firestore: firestore);
    final services = StudentServices(
      lessonRepository: LessonRepository(firestore: firestore),
      studentRepository: studentRepo,
      quizAttemptService: quizAttemptService,
      accessCodeService: AccessCodeService(firestore: firestore, quizAttemptService: quizAttemptService),
    );
    final router = buildStudentRouter(services: services);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentStudentIdProvider.overrideWith((ref) => Stream.value('111111')),
          ...studentProviderOverridesFor('111111', services: services),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/lesson/teacher-extra-1');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Extra Credit: Volcanoes'), findsOneWidget);
  });
}
