import 'package:go_router/go_router.dart';

import '../access_codes/access_codes_screen.dart';
import '../lessons/lessons_screen.dart';
import '../quizzes/quizzes_screen.dart';
import '../students/students_screen.dart';
import 'teacher_providers.dart';
import 'teacher_shell.dart';

const _routes = [
  '/teacher/lessons',
  '/teacher/quizzes',
  '/teacher/students',
  '/teacher/access-codes',
];

GoRouter buildTeacherRouter({required TeacherServices services}) {
  return GoRouter(
    initialLocation: '/teacher/lessons',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final index = _routes.indexWhere((route) => state.matchedLocation.startsWith(route));
          return TeacherShell(
            selectedIndex: index < 0 ? 0 : index,
            onDestinationSelected: (i) {
              if (i == TeacherShell.itemAnalysisIndex) return;
              context.go(_routes[i]);
            },
            child: child,
          );
        },
        routes: [
          GoRoute(path: '/teacher/lessons', builder: (context, state) => const LessonsScreen()),
          GoRoute(path: '/teacher/quizzes', builder: (context, state) => const QuizzesScreen()),
          GoRoute(path: '/teacher/students', builder: (context, state) => const StudentsScreen()),
          GoRoute(
            path: '/teacher/access-codes',
            builder: (context, state) => const AccessCodesScreen(),
          ),
        ],
      ),
    ],
  );
}
