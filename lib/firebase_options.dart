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
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          '${defaultTargetPlatform.name} is not a supported platform for this app.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBZXwWJexTEFG_iI5WsCBvaM2YiXqo66yc',
    appId: '1:770827848561:web:c741605ca6e0bac38dc4d0',
    messagingSenderId: '770827848561',
    projectId: 'ar-science-explorer',
    authDomain: 'ar-science-explorer.firebaseapp.com',
    databaseURL: 'https://ar-science-explorer-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'ar-science-explorer.firebasestorage.app',
    measurementId: 'G-SYVPL146CZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCI9VctEzFH0BMg3VROWbC_r8UffZAAycg',
    appId: '1:770827848561:android:1f1094ff51b312f28dc4d0',
    messagingSenderId: '770827848561',
    projectId: 'ar-science-explorer',
    databaseURL: 'https://ar-science-explorer-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'ar-science-explorer.firebasestorage.app',
  );
}
