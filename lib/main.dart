// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/services/access_code_service.dart';
import 'core/services/lesson_repository.dart';
import 'core/services/quiz_attempt_service.dart';
import 'core/services/student_repository.dart';
import 'features/student/app/router.dart';
import 'features/student/app/student_providers.dart';
import 'features/teacher/app/router.dart';
import 'features/teacher/app/teacher_providers.dart';
import 'features/teacher/auth/teacher_auth_providers.dart';
import 'features/teacher/auth/teacher_login_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: ArScienceExplorerApp()));
}

class ArScienceExplorerApp extends StatefulWidget {
  const ArScienceExplorerApp({super.key});

  @override
  State<ArScienceExplorerApp> createState() => _ArScienceExplorerAppState();
}

class _ArScienceExplorerAppState extends State<ArScienceExplorerApp> {
  // Student branch — constructed once, the first time a signed-in student id
  // is known — not on every rebuild of the surrounding Consumer.
  String? _servicesStudentId;
  StudentServices? _studentServices;
  GoRouter? _studentRouter;

  // Teacher branch — same caching rationale as the student branch above.
  String? _servicesTeacherEmail;
  TeacherServices? _teacherServices;
  GoRouter? _teacherRouter;

  StudentServices _studentServicesFor(String studentId) {
    if (_studentServices != null && _servicesStudentId == studentId) {
      return _studentServices!;
    }
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
    _servicesStudentId = studentId;
    _studentServices = services;
    _studentRouter = buildStudentRouter(services: services);
    return services;
  }

  TeacherServices _teacherServicesFor(String teacherEmail) {
    if (_teacherServices != null && _servicesTeacherEmail == teacherEmail) {
      return _teacherServices!;
    }
    final services = teacherServicesFromFirestore(FirebaseFirestore.instance);
    _servicesTeacherEmail = teacherEmail;
    _teacherServices = services;
    _teacherRouter = buildTeacherRouter(services: services);
    return services;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Consumer(
        builder: (context, ref, _) {
          final teacherEmail = ref.watch(currentTeacherEmailProvider).valueOrNull;
          if (teacherEmail == null) {
            return const ProviderScope(child: TeacherLoginScreen());
          }

          final services = _teacherServicesFor(teacherEmail);

          return ProviderScope(
            overrides: teacherProviderOverridesFor(services: services),
            child: MaterialApp.router(
              title: 'AR Science Explorer',
              routerConfig: _teacherRouter!,
            ),
          );
        },
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

        final services = _studentServicesFor(studentId);

        return ProviderScope(
          overrides: studentProviderOverridesFor(studentId, services: services),
          child: MaterialApp.router(
            title: 'AR Science Explorer',
            routerConfig: _studentRouter!,
          ),
        );
      },
    );
  }
}
