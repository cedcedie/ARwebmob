// test/widget_test.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/main.dart';

void main() {
  testWidgets('shows the teacher placeholder on web, the student shell on Android', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ArScienceExplorerApp()),
    );
    await tester.pumpAndSettle();

    if (kIsWeb) {
      expect(find.text('Teacher shell (placeholder)'), findsOneWidget);
    } else {
      expect(find.text('Home'), findsWidgets);
    }
  });
}
