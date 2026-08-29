import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/data/curriculum_data.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/quiz_phase.dart';
import '../../../core/quiz_id.dart';
import '../ar_lab/ar_lab_screen.dart';
import '../home/home_screen.dart';
import '../learn/learn_screen.dart';
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
                  // Invalidating the quiz session right before the student
                  // navigates in guarantees a fresh attempt deterministically
                  // — not just as a side effect of `.autoDispose` timing —
                  // whether this is a genuine first attempt (no-op: nothing
                  // cached yet) or a retake after an `AccessCodeService`
                  // unlock (discards the stale, already-`isComplete: true`
                  // controller from the locked attempt). See
                  // quiz_session_controller.dart's provider doc comment.
                  void invalidateQuizSession(QuizPhase phase) {
                    ref.invalidate(quizSessionControllerProvider(
                      QuizSessionKey.identity(
                        studentId: studentId,
                        quizId: builtinQuizId(lessonId, phase),
                        quizAttemptService: services.quizAttemptService,
                      ),
                    ));
                  }

                  return ProviderScope(
                    overrides: [
                      arLabOverrideFor(
                        studentId,
                        lessonId,
                        services: services,
                        onStartPreTest: () => invalidateQuizSession(QuizPhase.pre),
                        onStartPostTest: () => invalidateQuizSession(QuizPhase.post),
                      ),
                    ],
                    child: ArLabScreen(lessonId: lessonId),
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
              ? kPreTestQuestionsByLesson[lessonId]
              : kPostTestQuestionsByLesson[lessonId];

          // Defense in depth: most lessons have no pre-test bank (Task 1's
          // data is intentionally sparse), and a teacher-authored lesson id
          // has neither. Screens are expected to hide the action that would
          // reach here when a bank is missing (LessonCard's `hasPreTest`,
          // ArLabScreen's `vm.hasPreTest`) — this is the fallback for a
          // stale link or a manually-typed URL, not the primary guard.
          if (questions == null || questions.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Test unavailable')),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('This test is not available for this lesson.'),
                ),
              ),
            );
          }

          return Consumer(
            builder: (context, ref, _) {
              final studentId = ref.watch(currentStudentIdProvider).valueOrNull;
              if (studentId == null) return const SizedBox.shrink();

              final mergedAsync = ref.watch(mergedLessonsProvider);
              return mergedAsync.when(
                loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
                error: (error, stack) =>
                    Scaffold(body: Center(child: Text('Could not load this test: $error'))),
                data: (merged) {
                  Lesson? lesson;
                  for (final candidate in merged) {
                    if (candidate.id == lessonId) {
                      lesson = candidate;
                      break;
                    }
                  }
                  if (lesson == null) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Test unavailable')),
                      body: const Center(child: Text('This lesson could not be found.')),
                    );
                  }

                  // A single, top-level `.family` provider keyed on
                  // (studentId, quizId) — not a fresh `StateNotifierProvider`
                  // built inline on every rebuild, which used to silently
                  // discard in-progress quiz answers on any rebuild of this
                  // route (e.g. a hint tap, an answer selection).
                  final controllerProvider = quizSessionControllerProvider(
                    QuizSessionKey(
                      studentId: studentId,
                      quizId: quizId,
                      subject: lesson.subject,
                      questions: questions,
                      quizAttemptService: services.quizAttemptService,
                    ),
                  );
                  return QuizPlayerScreen(controllerProvider: controllerProvider);
                },
              );
            },
          );
        },
      ),
    ],
  );
}
