// lib/main.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ArScienceExplorerApp());
}

class ArScienceExplorerApp extends StatelessWidget {
  const ArScienceExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Science Explorer',
      home: Scaffold(
        body: Center(
          child: Text(
            kIsWeb ? 'Teacher shell (placeholder)' : 'Student shell (placeholder)',
          ),
        ),
      ),
    );
  }
}
