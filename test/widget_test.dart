// test/widget_test.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/main.dart';

void main() {
  testWidgets('shows a placeholder shell without crashing', (tester) async {
    await tester.pumpWidget(const ArScienceExplorerApp());

    final expectedText = kIsWeb
        ? 'Teacher shell (placeholder)'
        : 'Student shell (placeholder)';
    expect(find.text(expectedText), findsOneWidget);
  });
}
