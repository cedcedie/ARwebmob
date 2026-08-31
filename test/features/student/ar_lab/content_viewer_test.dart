import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/features/student/ar_lab/content_viewer.dart';

void main() {
  testWidgets('shows nothing when no content has been uploaded', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ContentViewer(imageUrls: null, status: null))),
    );
    expect(find.byType(ContentViewer), findsOneWidget);
    expect(find.textContaining('Processing'), findsNothing);
  });

  testWidgets('shows a processing message while status is processing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentViewer(imageUrls: ['https://example.com/a.pptx'], status: 'processing'),
        ),
      ),
    );
    expect(find.textContaining('Processing'), findsOneWidget);
  });

  testWidgets('shows a swipeable gallery once ready', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentViewer(
            imageUrls: ['https://example.com/slide1.png', 'https://example.com/slide2.png'],
            status: 'ready',
          ),
        ),
      ),
    );
    expect(find.textContaining('Processing'), findsNothing);
    expect(find.textContaining('1 / 2'), findsOneWidget); // slide counter
  });
}
