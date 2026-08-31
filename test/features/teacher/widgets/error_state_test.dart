import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ar_science_explorer/features/teacher/widgets/error_state.dart';

void main() {
  group('humanizeLoadError', () {
    test('maps FirebaseException permission-denied to a plain sentence', () {
      final message = humanizeLoadError(
        FirebaseException(plugin: 'firestore', code: 'permission-denied'),
        subjectLabel: 'lessons',
      );
      expect(message, contains("don't have permission"));
      expect(message, isNot(contains('FirebaseException')));
    });

    test('maps FirebaseException unavailable to a connection sentence', () {
      final message = humanizeLoadError(
        FirebaseException(plugin: 'firestore', code: 'unavailable'),
        subjectLabel: 'quizzes',
      );
      expect(message, contains('connection'));
    });

    test('maps a generic network-ish error to a connection sentence', () {
      final message = humanizeLoadError(
        Exception('SocketException: Connection refused'),
        subjectLabel: 'students',
      );
      expect(message, contains('connection'));
      expect(message, isNot(contains('SocketException')));
    });

    test('falls back to a generic sentence naming the subject for an '
        'unrecognized error', () {
      final message = humanizeLoadError(
        StateError('something odd happened'),
        subjectLabel: 'students',
      );
      expect(message, contains('students'));
      expect(message, isNot(contains('StateError')));
      expect(message, isNot(contains('something odd happened')));
    });
  });

  group('ErrorState widget', () {
    testWidgets('shows the message and an icon, no retry button when '
        'onRetry is null', (tester) async {
      await tester.pumpWidget(
        const ShadApp(
          home: ErrorState(message: "Couldn't load lessons right now."),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load lessons right now."), findsOneWidget);
      expect(find.byIcon(LucideIcons.circleAlert), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('shows a Retry button that invokes onRetry when tapped', (
      tester,
    ) async {
      var retried = false;
      await tester.pumpWidget(
        ShadApp(
          home: ErrorState(
            message: 'Something failed.',
            onRetry: () => retried = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retried, isTrue);
    });
  });
}
