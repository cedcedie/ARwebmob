// lib/firebase_options.dart
//
// PLACEHOLDER — replace by running `flutterfire configure` and selecting
// the existing ar-science-explorer Firebase project (see MANUAL_STEPS.md).
// Do not fill these in by hand; flutterfire configure generates the exact
// values (including platform-specific appId/apiKey) correctly.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'firebase_options.dart is a placeholder — run `flutterfire configure` '
        '(see MANUAL_STEPS.md) before running the web target.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'firebase_options.dart is a placeholder — run `flutterfire configure` '
          '(see MANUAL_STEPS.md) before running the Android target.',
        );
      default:
        throw UnsupportedError(
          '${defaultTargetPlatform.name} is not a supported platform for this app.',
        );
    }
  }
}
