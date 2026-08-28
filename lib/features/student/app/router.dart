import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/data/curriculum_data.dart';
import '../../../core/models/quiz_phase.dart';
import '../../../core/quiz_id.dart';
import '../home/home_screen.dart';
import '../learn/learn_screen.dart';
import '../lesson_detail/lesson_detail_screen.dart';
import '../progress/progress_screen.dart';
import '../quiz/quiz_player_screen.dart';
import '../quiz/quiz_session_controller.dart';
import 'student_providers.dart';
import 'student_shell.dart';

const _tabs = ['/home', '/learn', '/progress'];

GoRouter buildStudentRouter({required StudentServices services}) {
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
            builder: (context, state) {
              final lessonId = state.pathParameters['lessonId']!;
              return Consumer(
                builder: (context, ref, _) {
                  final studentId = ref.watch(currentStudentIdProvider).valueOrNull;
                  if (studentId == null) return const SizedBox.shrink();
                  return ProviderScope(
                    overrides: [
                      lessonDetailOverrideFor(
                        studentId,
                        lessonId,
                        services: services,
                        onStartPreTest: () {},
                        onStartPostTest: () {},
                      ),
                    ],
                    child: LessonDetailScreen(lessonId: lessonId),
                  );
                },
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/quiz/:lessonId/:phase',
        builder: (context, state) {
          final lessonId = state.pathParameters['lessonId']!;
          final phase = state.pathParameters['phase'] == 'pre' ? QuizPhase.pre : QuizPhase.post;
          final quizId = builtinQuizId(lessonId, phase);
          final questions = phase == QuizPhase.pre
              ? kPreTestQuestionsByLesson[lessonId]!
              : kPostTestQuestionsByLesson[lessonId]!;
          final lesson = kBuiltInLessons.firstWhere((l) => l.id == lessonId);

          return Consumer(
            builder: (context, ref, _) {
              final studentId = ref.watch(currentStudentIdProvider).valueOrNull;
              if (studentId == null) return const SizedBox.shrink();
              final provider = StateNotifierProvider<QuizSessionController, QuizSessionState>(
                (ref) => QuizSessionController(
                  studentId: studentId,
                  quizId: quizId,
                  subject: lesson.subject,
                  questions: questions,
                  quizAttemptService: services.quizAttemptService,
                ),
              );
              return QuizPlayerScreen(controllerProvider: provider);
            },
          );
        },
      ),
    ],
  );
}
