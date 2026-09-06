import 'package:ar_science_explorer/core/theme/app_theme.dart';
import 'package:ar_science_explorer/features/teacher/app/teacher_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Widget buildShell({required ValueChanged<int> onDestinationSelected}) {
    // TeacherShell is a ConsumerWidget (theme toggle + signed-in teacher
    // email), so it needs a ProviderScope above it.
    return ProviderScope(
      child: MaterialApp(
        theme: appMaterialTheme,
        home: TeacherShell(
          selectedIndex: 0,
          onDestinationSelected: onDestinationSelected,
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }

  testWidgets('nav rail has exactly the 6 real destinations, no Item '
      'Analysis entry', (tester) async {
    await tester.pumpWidget(buildShell(onDestinationSelected: (_) {}));

    // Item Analysis is inherently quiz-scoped (no standalone list route),
    // so it must not have its own rail destination — see teacher_shell.dart.
    expect(find.text('Item Analysis'), findsNothing);

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Lessons'), findsOneWidget);
    expect(find.text('Quizzes'), findsOneWidget);
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Access Codes'), findsOneWidget);
    expect(find.text('Teacher Access'), findsOneWidget);
  });

  testWidgets('tapping a rail destination reports its index', (tester) async {
    final selections = <int>[];
    await tester.pumpWidget(buildShell(onDestinationSelected: selections.add));

    await tester.tap(find.text('Students'));
    await tester.pumpAndSettle();

    // Students is the 4th rail entry (Dashboard, Lessons, Quizzes, Students).
    expect(selections, [3]);
  });
}
