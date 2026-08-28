import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../home/home_screen.dart';
import '../learn/learn_screen.dart';
import '../lesson_detail/lesson_detail_screen.dart';
import '../progress/progress_screen.dart';
import 'student_shell.dart';

const _tabs = ['/home', '/learn', '/progress'];

GoRouter buildStudentRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final index = _tabs.indexWhere((t) => state.matchedLocation.startsWith(t));
          return StudentShell(
            currentIndex: index < 0 ? 0 : index,
            onDestinationSelected: (i) => context.go(_tabs[i]),
            child: child,
          );
        },
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/learn', builder: (context, state) => const LearnScreen()),
          GoRoute(path: '/progress', builder: (context, state) => const ProgressScreen()),
          GoRoute(
            path: '/lesson/:lessonId',
            builder: (context, state) => LessonDetailScreen(
              lessonId: state.pathParameters['lessonId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/quiz/:lessonId/:phase',
        builder: (context, state) {
          // Wiring the concrete QuizSessionController provider (with the
          // right question bank for lessonId+phase, looked up from
          // kPreTestQuestionsByLesson/kPostTestQuestionsByLesson, and a real
          // QuizAttemptService/current studentId) happens where AuthService's
          // signed-in student id is available — same app-startup override
          // pattern as Task 7/8/9's view-model providers, not repeated here.
          throw UnimplementedError('Wire a concrete controllerProvider override for this route.');
        },
      ),
    ],
  );
}
