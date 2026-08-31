// test/features/teacher/quizzes/item_analysis_providers_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/quiz_id.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/features/teacher/quizzes/item_analysis_providers.dart';

StudentRecord _studentWith(String id, QuizAttempt attempt) => StudentRecord(
      id: id, name: 'Student $id', studentId: id, grade: '7', section: 'A',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [], completedLabExperimentIds: const [],
      completedQuizIds: const [], unlockedLessonIds: const [], unlockedQuizIds: const [],
      quizAttempts: [attempt],
    );

void main() {
  test('resolves the built-in question bank and every attempt on this quiz', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    final quizId = builtinQuizId('q1w1', QuizPhase.post);

    await studentRepo.saveStudent(_studentWith('111111', QuizAttempt(
      id: 'a1', quizId: quizId, studentId: '111111', attemptNumber: 1,
      score: 100, totalQuestions: 8, correctAnswers: 8,
      answers: const [0, 0, 0, 0, 0, 0, 0, 0],
      timestamp: DateTime(2026, 8, 20).toIso8601String(), locked: true,
    )));
    await studentRepo.saveStudent(_studentWith('222222', QuizAttempt(
      id: 'a2', quizId: quizId, studentId: '222222', attemptNumber: 1,
      score: 0, totalQuestions: 8, correctAnswers: 0,
      answers: const [1, 1, 1, 1, 1, 1, 1, 1],
      timestamp: DateTime(2026, 8, 20).toIso8601String(), locked: true,
    )));

    final stream = buildItemAnalysisViewModel(
      quizId: quizId,
      quizTitle: 'Q1W1 Post-Test',
      studentRepository: studentRepo,
    );
    final vm = await stream.first;

    expect(vm.attemptCount, 2);
    expect(vm.questions, hasLength(8));
    expect(vm.results, hasLength(8));
    expect(vm.results[0].difficultyIndex, closeTo(0.5, 0.0001));
  });

  test('ignores attempts on other quizzes', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    final postId = builtinQuizId('q1w1', QuizPhase.post);
    final preId = builtinQuizId('q1w1', QuizPhase.pre);

    await studentRepo.saveStudent(_studentWith('111111', QuizAttempt(
      id: 'a1', quizId: preId, studentId: '111111', attemptNumber: 1,
      score: 100, totalQuestions: 8, correctAnswers: 8,
      answers: const [0, 0, 0, 0, 0, 0, 0, 0],
      timestamp: DateTime(2026, 8, 20).toIso8601String(), locked: false,
    )));

    final stream = buildItemAnalysisViewModel(
      quizId: postId,
      quizTitle: 'Q1W1 Post-Test',
      studentRepository: studentRepo,
    );
    final vm = await stream.first;

    expect(vm.attemptCount, 0);
  });
}
