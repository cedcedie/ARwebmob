// test/widget_test.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/features/student/app/student_providers.dart';
import 'package:ar_science_explorer/features/teacher/auth/teacher_auth_providers.dart';
import 'package:ar_science_explorer/main.dart';

void main() {
  testWidgets('shows the teacher login on web, the sign-in gate on Android', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // No user is signed in for this smoke test. Overriding these
        // providers (rather than relying on the real FirebaseAuth.instance
        // default) keeps this test from requiring a live Firebase app —
        // the real main() always calls Firebase.initializeApp() before
        // runApp(), which this plain widget test intentionally doesn't do.
        overrides: [
          currentStudentIdProvider.overrideWith((ref) => Stream.value(null)),
          currentTeacherEmailProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const ArScienceExplorerApp(),
      ),
    );
    await tester.pumpAndSettle();

    if (kIsWeb) {
      expect(find.text('Teacher sign in'), findsOneWidget);
    } else {
      // No student is signed in, so the app's signed-out gate is what
      // renders — see ArScienceExplorerApp's non-web branch in lib/main.dart.
      expect(find.text('Sign in'), findsOneWidget);
    }
  });
}
