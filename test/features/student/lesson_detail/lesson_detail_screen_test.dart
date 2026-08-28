import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/features/student/lesson_detail/lesson_detail_providers.dart';
import 'package:ar_science_explorer/features/student/lesson_detail/lesson_detail_screen.dart';

AccessCodeService _fakeAccessCodeService() {
  final firestore = FakeFirebaseFirestore();
  return AccessCodeService(
    firestore: firestore,
    quizAttemptService: QuizAttemptService(firestore: firestore),
  );
}

void main() {
  testWidgets('shows lesson title and a Mark as Read action before completion', (tester) async {
    final viewModel = LessonDetailViewModel(
      lessonId: 'q1w1',
      title: 'Scientific Models and the Particle Model of Matter',
      summary: 'Discover how scientists use models...',
      isRead: false,
      hasPreTest: true,
      postTestEligible: false,
      postTestReason: 'Complete the lesson first.',
      studentId: '111111',
      accessCodeService: _fakeAccessCodeService(),
      onMarkAsRead: () async {},
      onStartPreTest: () {},
      onStartPostTest: () {},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lessonDetailViewModelProvider('q1w1').overrideWith((ref) => Stream.value(viewModel)),
        ],
        child: const MaterialApp(home: LessonDetailScreen(lessonId: 'q1w1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scientific Models and the Particle Model of Matter'), findsOneWidget);
    expect(find.text('Mark as Read'), findsOneWidget);
    expect(find.text('Pre-Test'), findsOneWidget);
  });

  testWidgets('hides the Pre-Test action when the lesson has no pre-test bank (C3)', (tester) async {
    final viewModel = LessonDetailViewModel(
      lessonId: 'q1w2',
      title: 'A Lesson With No Pre-Test',
      summary: 'summary',
      isRead: false,
      hasPreTest: false,
      postTestEligible: true,
      postTestReason: null,
      studentId: '111111',
      accessCodeService: _fakeAccessCodeService(),
      onMarkAsRead: () async {},
      onStartPreTest: () {},
      onStartPostTest: () {},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lessonDetailViewModelProvider('q1w2').overrideWith((ref) => Stream.value(viewModel)),
        ],
        child: const MaterialApp(home: LessonDetailScreen(lessonId: 'q1w2')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pre-Test'), findsNothing);
    expect(find.text('Post-Test'), findsOneWidget);
  });

  testWidgets('a locked post-test offers a way to open the access-code sheet (C2)', (tester) async {
    final viewModel = LessonDetailViewModel(
      lessonId: 'q1w1',
      title: 'Scientific Models and the Particle Model of Matter',
      summary: 'summary',
      isRead: true,
      hasPreTest: true,
      postTestEligible: false,
      postTestReason: 'Test locked after your last attempt. Ask your teacher for a retake code.',
      studentId: '111111',
      accessCodeService: _fakeAccessCodeService(),
      onMarkAsRead: () async {},
      onStartPreTest: () {},
      onStartPostTest: () {},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lessonDetailViewModelProvider('q1w1').overrideWith((ref) => Stream.value(viewModel)),
        ],
        child: const MaterialApp(home: LessonDetailScreen(lessonId: 'q1w1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Have a retake code?'), findsOneWidget);

    await tester.tap(find.text('Have a retake code?'));
    await tester.pumpAndSettle();

    expect(find.text('Apply Code'), findsOneWidget);
  });
}
