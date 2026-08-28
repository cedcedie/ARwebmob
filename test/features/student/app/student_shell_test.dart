import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/features/student/app/router.dart';

void main() {
  testWidgets('student router starts on Home and can navigate to Learn', (tester) async {
    final router = buildStudentRouter();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);

    router.go('/learn');
    await tester.pumpAndSettle();
    expect(find.text('Learn'), findsWidgets);
  });
}
