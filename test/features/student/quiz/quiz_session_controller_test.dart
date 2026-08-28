import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
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
  test('scores correctly and records the attempt on the last question', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    final quizAttemptService = QuizAttemptService(firestore: firestore);
    await studentRepo.saveStudent(StudentRecord(
      id: '111111', name: 'Test', studentId: '111111', grade: '7', section: 'A',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [], completedLabExperimentIds: const [],
      completedQuizIds: const [], unlockedLessonIds: const [], unlockedQuizIds: const [],
      quizAttempts: const [],
    ));

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
    expect(student.quizAttempts.first.locked, true); // post-test always locks after submit
  });

  test('a question can only be hinted once, and hints cap at 3 per attempt', () async {
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
  });

  test('submitAndExit submits the current selection as the final attempt', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    final quizAttemptService = QuizAttemptService(firestore: firestore);
    await studentRepo.saveStudent(StudentRecord(
      id: '111111', name: 'Test', studentId: '111111', grade: '7', section: 'A',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [], completedLabExperimentIds: const [],
      completedQuizIds: const [], unlockedLessonIds: const [], unlockedQuizIds: const [],
      quizAttempts: const [],
    ));

    final controller = QuizSessionController(
      studentId: '111111',
      quizId: builtinQuizId('q1w1', QuizPhase.post),
      subject: SubjectKey.chemistry,
      questions: _threeQuestions(),
      quizAttemptService: quizAttemptService,
    );

    controller.selectAnswer(0); // Q0 correct, not yet "submitted" via submitAnswer()
    await controller.submitAndExit();

    final student = await studentRepo.getStudent('111111');
    expect(student!.quizAttempts, hasLength(1));
    expect(student.quizAttempts.first.totalQuestions, 3);
    expect(student.quizAttempts.first.correctAnswers, 1);
    expect(student.quizAttempts.first.answers, [0, -1, -1]); // unanswered = -1
  });
}
