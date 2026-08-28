// test/features/student/learn/learn_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/features/student/learn/learn_providers.dart';
import 'package:ar_science_explorer/features/student/learn/learn_screen.dart';

void main() {
  testWidgets('locked lesson still shows its title and summary, with an unlock CTA', (tester) async {
    final viewModel = LearnViewModel(
      activeSubject: SubjectKey.chemistry,
      cards: [
        LessonCardData(
          lessonId: 'q1w5',
          title: 'Planning and Recording Scientific Investigations',
          week: 5,
          summary: 'summary text',
          isUnlocked: false,
          hasPreTest: true,
          isCompleted: false,
        ),
      ],
      onSelectSubject: (_) {},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [learnViewModelProvider.overrideWith((ref) => Stream.value(viewModel))],
        child: const MaterialApp(home: LearnScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Not fully hidden/grayed — the title and summary must still be readable.
    expect(find.text('Planning and Recording Scientific Investigations'), findsOneWidget);
    expect(find.text('summary text'), findsOneWidget);
    // The punitive "locked" framing is explicitly disallowed (Part 10.2) —
    // assert the actual, non-punitive copy instead.
    expect(find.textContaining('Unlock with your teacher'), findsOneWidget);
    expect(find.textContaining('not yet available'), findsOneWidget);
  });
}
