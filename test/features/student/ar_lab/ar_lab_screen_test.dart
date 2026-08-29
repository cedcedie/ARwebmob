import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/features/student/ar_lab/ar_lab_providers.dart';
import 'package:ar_science_explorer/features/student/ar_lab/ar_lab_screen.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  testWidgets('renders three tabs: Scan, Read, Review', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final quizAttemptService = QuizAttemptService(firestore: firestore);
    final vm = ArLabViewModel(
      lessonId: 'q1w1',
      title: 'Scientific Models and the Particle Model of Matter',
      summary: 'summary',
      hasAR: true,
      markerIndex: 0,
      isRead: false,
      hasPreTest: true,
      postTestEligible: false,
      postTestReason: 'Complete the lesson first.',
      studentId: '111111',
      accessCodeService: AccessCodeService(firestore: firestore, quizAttemptService: quizAttemptService),
      onMarkAsRead: () async {},
      onStartPreTest: () {},
      onStartPostTest: () {},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          arLabViewModelProvider('q1w1').overrideWith((ref) => Stream.value(vm)),
        ],
        child: const MaterialApp(home: ArLabScreen(lessonId: 'q1w1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });
}
