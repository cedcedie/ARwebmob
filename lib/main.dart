// lib/main.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'features/student/app/router.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: ArScienceExplorerApp()));
}

class ArScienceExplorerApp extends StatelessWidget {
  const ArScienceExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const MaterialApp(
        title: 'AR Science Explorer',
        home: Scaffold(
          body: Center(child: Text('Teacher shell (placeholder)')),
        ),
      );
    }
    return MaterialApp.router(
      title: 'AR Science Explorer',
      routerConfig: buildStudentRouter(),
    );
  }
}
