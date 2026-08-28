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
    ],
  );
}
