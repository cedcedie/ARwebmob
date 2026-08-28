import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ar_science_explorer/features/student/quiz/quiz_results_screen.dart';

Widget _wrap(Widget child) {
  final router = GoRouter(
    initialLocation: '/results',
    routes: [
      GoRoute(path: '/results', builder: (context, state) => child),
      GoRoute(path: '/progress', builder: (context, state) => const Placeholder()),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('a failed pre-test tells the student they can retry anytime, no code needed',
      (tester) async {
    await tester.pumpWidget(_wrap(const QuizResultsScreen(score: 30, isPreTest: true)));
    await tester.pump();

    expect(find.textContaining('retry it anytime, no code needed'), findsOneWidget);
    expect(find.textContaining('Ask your teacher for a retake code'), findsNothing);
  });

  testWidgets('a failed post-test tells the student to ask their teacher for a retake code',
      (tester) async {
    await tester.pumpWidget(_wrap(const QuizResultsScreen(score: 30, isPreTest: false)));
    await tester.pump();

    expect(find.textContaining('Ask your teacher for a retake code'), findsOneWidget);
    expect(find.textContaining('retry it anytime, no code needed'), findsNothing);
  });

  testWidgets('a passed quiz shows no retry copy at all, regardless of phase', (tester) async {
    await tester.pumpWidget(_wrap(const QuizResultsScreen(score: 90, isPreTest: false)));
    await tester.pump();

    expect(find.textContaining('retry it anytime, no code needed'), findsNothing);
    expect(find.textContaining('Ask your teacher for a retake code'), findsNothing);

    // Cancel the pass-state auto-continue countdown so no Timer is left
    // pending when the test tears down.
    await tester.tap(find.textContaining('tap to stay here'));
    await tester.pump();
  });
}
