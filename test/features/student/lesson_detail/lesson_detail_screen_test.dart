import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/features/student/lesson_detail/lesson_detail_providers.dart';
import 'package:ar_science_explorer/features/student/lesson_detail/lesson_detail_screen.dart';

void main() {
  testWidgets('shows lesson title and a Mark as Read action before completion', (tester) async {
    final viewModel = LessonDetailViewModel(
      lessonId: 'q1w1',
      title: 'Scientific Models and the Particle Model of Matter',
      summary: 'Discover how scientists use models...',
      isRead: false,
      postTestEligible: false,
      postTestReason: 'Complete the lesson first.',
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
}
