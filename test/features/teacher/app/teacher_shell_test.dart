import 'package:ar_science_explorer/core/theme/app_theme.dart';
import 'package:ar_science_explorer/features/teacher/app/teacher_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildShell({required ValueChanged<int> onDestinationSelected}) {
    return MaterialApp(
      theme: appMaterialTheme,
      home: TeacherShell(
        selectedIndex: 0,
        onDestinationSelected: onDestinationSelected,
        child: const SizedBox.shrink(),
      ),
    );
  }

  testWidgets('nav rail has exactly the 4 real destinations, no Item '
      'Analysis entry', (tester) async {
    await tester.pumpWidget(buildShell(onDestinationSelected: (_) {}));

    // Item Analysis is inherently quiz-scoped (no standalone list route),
    // so it must not have its own rail destination — see teacher_shell.dart.
    expect(find.text('Item Analysis'), findsNothing);

    expect(find.text('Lessons'), findsOneWidget);
    expect(find.text('Quizzes'), findsOneWidget);
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Access Codes'), findsOneWidget);
  });

  testWidgets('tapping a rail destination reports its index', (tester) async {
    final selections = <int>[];
    await tester.pumpWidget(
      buildShell(onDestinationSelected: selections.add),
    );

    await tester.tap(find.text('Students'));
    await tester.pumpAndSettle();

    expect(selections, [2]);
  });
}
