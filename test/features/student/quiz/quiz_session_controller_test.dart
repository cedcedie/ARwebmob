import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/core/models/built_in_question.dart';
import 'package:ar_science_explorer/core/models/question_type.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/quiz_id.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/features/student/quiz/quiz_session_controller.dart';

List<BuiltInQuestion> _threeQuestions() => [
  for (var i = 0; i < 3; i++)
    BuiltInQuestion(
      id: 'q$i',
      subject: SubjectKey.chemistry,
      lessonId: 'q1w1',
      question: 'Question $i',
      options: const ['A', 'B', 'C', 'D'],
      correctIndex: 0,
      hint: 'hint $i',
      type: QuestionType.mc,
    ),
];

void main() {
  test(
    'scores correctly and records the attempt on the last question',
    () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final quizAttemptService = QuizAttemptService(firestore: firestore);
      await studentRepo.saveStudent(
        StudentRecord(
          id: '111111',
          name: 'Test',
          studentId: '111111',
          grade: '7',
          section: 'A',
          scores: const {'chemistry': null, 'biology': null, 'physics': null},
          completedLessonIds: const [],
          completedLabExperimentIds: const [],
          completedQuizIds: const [],
          unlockedLessonIds: const [],
          unlockedQuizIds: const [],
          quizAttempts: const [],
        ),
      );

      final quizId = builtinQuizId('q1w1', QuizPhase.post);
      final controller = QuizSessionController(
        studentId: '111111',
        quizId: quizId,
        subject: SubjectKey.chemistry,
        questions: _threeQuestions(),
        quizAttemptService: quizAttemptService,
      );

      // Q0: correct
      controller.selectAnswer(0);
      controller.submitAnswer();
      expect(controller.state.showResult, true);
      controller.nextQuestion();

      // Q1: wrong
      controller.selectAnswer(1);
      controller.submitAnswer();
      controller.nextQuestion();

      // Q2 (last): correct — submitting this one should persist the attempt.
      controller.selectAnswer(0);
      await controller.submitAnswer();

      expect(controller.state.isComplete, true);
      expect(controller.state.finalScore, 67); // round(2/3*100)

      final student = await studentRepo.getStudent('111111');
      expect(student!.quizAttempts, hasLength(1));
      expect(student.quizAttempts.first.correctAnswers, 2);
      expect(
        student.quizAttempts.first.locked,
        true,
      ); // post-test always locks after submit
    },
  );

  test(
    'a question can only be hinted once, and hints cap at 3 per attempt',
    () async {
      final firestore = FakeFirebaseFirestore();
      final quizAttemptService = QuizAttemptService(firestore: firestore);
      final controller = QuizSessionController(
        studentId: '111111',
        quizId: builtinQuizId('q1w1', QuizPhase.post),
        subject: SubjectKey.chemistry,
        questions: _threeQuestions(),
        quizAttemptService: quizAttemptService,
      );

      expect(controller.state.hintsUsed, 0);
      controller.useHint();
      expect(controller.state.hintsUsed, 1);
      expect(controller.state.hintedQuestionIndices, contains(0));

      // Same question again — no-op, hints stay at 1.
      controller.useHint();
      expect(controller.state.hintsUsed, 1);
    },
  );

  test(
    'submitAndExit submits the current selection as the final attempt',
    () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final quizAttemptService = QuizAttemptService(firestore: firestore);
      await studentRepo.saveStudent(
        StudentRecord(
          id: '111111',
          name: 'Test',
          studentId: '111111',
          grade: '7',
          section: 'A',
          scores: const {'chemistry': null, 'biology': null, 'physics': null},
          completedLessonIds: const [],
          completedLabExperimentIds: const [],
          completedQuizIds: const [],
          unlockedLessonIds: const [],
          unlockedQuizIds: const [],
          quizAttempts: const [],
        ),
      );

      final controller = QuizSessionController(
        studentId: '111111',
        quizId: builtinQuizId('q1w1', QuizPhase.post),
        subject: SubjectKey.chemistry,
        questions: _threeQuestions(),
        quizAttemptService: quizAttemptService,
      );

      controller.selectAnswer(
        0,
      ); // Q0 correct, not yet "submitted" via submitAnswer()
      await controller.submitAndExit();

      final student = await studentRepo.getStudent('111111');
      expect(student!.quizAttempts, hasLength(1));
      expect(student.quizAttempts.first.totalQuestions, 3);
      expect(student.quizAttempts.first.correctAnswers, 1);
      expect(student.quizAttempts.first.answers, [
        0,
        -1,
        -1,
      ]); // unanswered = -1
    },
  );

  test(
    'regression: invalidating a completed session before re-entry gives a fresh '
    'session, not the stale completed one (the retake dead-end bug)',
    () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final quizAttemptService = QuizAttemptService(firestore: firestore);
      await studentRepo.saveStudent(
        StudentRecord(
          id: '111111',
          name: 'Test',
          studentId: '111111',
          grade: '7',
          section: 'A',
          scores: const {'chemistry': null, 'biology': null, 'physics': null},
          completedLessonIds: const [],
          completedLabExperimentIds: const [],
          completedQuizIds: const [],
          unlockedLessonIds: const [],
          unlockedQuizIds: const [],
          quizAttempts: const [],
        ),
      );

      final quizId = builtinQuizId('q1w1', QuizPhase.post);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      QuizSessionKey key() => QuizSessionKey(
        studentId: '111111',
        quizId: quizId,
        subject: SubjectKey.chemistry,
        questions: _threeQuestions(),
        quizAttemptService: quizAttemptService,
      );

      // Complete a full attempt (mirrors QuizPlayerScreen's flow), watched
      // through the real `.family` provider — same as router.dart does.
      final provider1 = quizSessionControllerProvider(key());
      final sub = container.listen(provider1, (_, _) {});
      final controller1 = container.read(provider1.notifier);

      controller1.selectAnswer(0);
      await controller1.submitAnswer();
      controller1.nextQuestion();
      controller1.selectAnswer(0);
      await controller1.submitAnswer();
      controller1.nextQuestion();
      controller1.selectAnswer(0);
      await controller1.submitAnswer();

      expect(controller1.state.isComplete, true);
      expect(controller1.state.finalScore, 100);

      // Deliberately do NOT close `sub` first — this proves the reset comes
      // from the explicit `ref.invalidate(...)` call router.dart's
      // onStartPostTest performs (quiz_session_controller.dart's provider
      // doc comment), not merely from `.autoDispose`'s listener-count-hits-
      // zero timing, which a widget-unmount edge case could delay or skip.
      container.invalidate(
        quizSessionControllerProvider(
          QuizSessionKey.identity(
            studentId: '111111',
            quizId: quizId,
            quizAttemptService: quizAttemptService,
          ),
        ),
      );

      // Re-enter with a fresh key built the same way router.dart builds one
      // on the next navigation to /quiz/q1w1/post — same studentId+quizId,
      // so it's `==` to the original, but the cached completed session must
      // NOT come back.
      final provider2 = quizSessionControllerProvider(key());
      final controller2 = container.read(provider2.notifier);
      final state2 = container.read(provider2);

      expect(identical(controller2, controller1), false);
      expect(state2.isComplete, false);
      expect(state2.questionIndex, 0);
      expect(state2.finalScore, isNull);
      expect(state2.answers, [-1, -1, -1]);

      sub.close();
    },
  );

  test(
    'no regression on the original I2 fix: an in-progress (not yet complete) '
    'session survives being re-read through an equal key, unaffected by other '
    'sessions being invalidated',
    () async {
      final firestore = FakeFirebaseFirestore();
      final quizAttemptService = QuizAttemptService(firestore: firestore);
      final quizId = builtinQuizId('q1w1', QuizPhase.post);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      QuizSessionKey key() => QuizSessionKey(
        studentId: '111111',
        quizId: quizId,
        subject: SubjectKey.chemistry,
        questions: _threeQuestions(),
        quizAttemptService: quizAttemptService,
      );

      final provider1 = quizSessionControllerProvider(key());
      final sub = container.listen(provider1, (_, _) {});
      final controller1 = container.read(provider1.notifier);

      // Mid-quiz, not complete: answer the first question but stay on it.
      controller1.selectAnswer(2);
      await controller1.submitAnswer();
      expect(controller1.state.isComplete, false);
      expect(controller1.state.answers, [2, -1, -1]);

      // An unrelated ancestor rebuild (e.g. a hint tap on this same screen,
      // or router.dart's Consumer rebuilding for an unrelated reason) simply
      // re-reads the provider through a new-but-equal `QuizSessionKey`
      // instance — this must return the SAME live controller with progress
      // intact, not a fresh one.
      final provider2 = quizSessionControllerProvider(key());
      final state2 = container.read(provider2);

      expect(identical(container.read(provider2.notifier), controller1), true);
      expect(state2.isComplete, false);
      expect(state2.answers, [2, -1, -1]);
      expect(state2.showResult, true);

      sub.close();
    },
  );
}
