// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/services/access_code_service.dart';
import 'core/services/lesson_repository.dart';
import 'core/services/quiz_attempt_service.dart';
import 'core/services/student_repository.dart';
import 'features/student/app/router.dart';
import 'features/student/app/student_providers.dart';
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

    return Consumer(
      builder: (context, ref, _) {
        final studentId = ref.watch(currentStudentIdProvider).valueOrNull;
        if (studentId == null) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: Text('Sign in'))),
          );
        }

        // Deferred until a student id is known so a widget test can pump
        // this app with `currentStudentIdProvider` overridden and never
        // touch the real Firebase singletons below (they require
        // `Firebase.initializeApp()` to already have run, which only
        // happens in the real `main()`).
        final quizAttemptService = QuizAttemptService(firestore: FirebaseFirestore.instance);
        final services = StudentServices(
          lessonRepository: LessonRepository(firestore: FirebaseFirestore.instance),
          studentRepository: StudentRepository(firestore: FirebaseFirestore.instance),
          quizAttemptService: quizAttemptService,
          accessCodeService: AccessCodeService(
            firestore: FirebaseFirestore.instance,
            quizAttemptService: quizAttemptService,
          ),
        );

        return ProviderScope(
          overrides: studentProviderOverridesFor(studentId, services: services),
          child: MaterialApp.router(
            title: 'AR Science Explorer',
            routerConfig: buildStudentRouter(services: services),
          ),
        );
      },
    );
  }
}
