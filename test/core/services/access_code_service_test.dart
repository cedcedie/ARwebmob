import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/quiz_id.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';

StudentRecord _blankStudent(String id) => StudentRecord(
      id: id,
      name: 'Test Student',
      studentId: id,
      grade: '7',
      section: 'Rizal',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [],
      completedLabExperimentIds: const [],
      completedQuizIds: const [],
      unlockedLessonIds: const [],
      unlockedQuizIds: const [],
      quizAttempts: const [],
    );

void main() {
  test('an unknown code echoes the exact code the student typed', () async {
    final firestore = FakeFirebaseFirestore();
    final service = AccessCodeService(
      firestore: firestore,
      quizAttemptService: QuizAttemptService(firestore: firestore),
    );

    final result = await service.redeem(studentId: '111111', rawCode: 'xyz123');

    expect(result.success, false);
    expect(result.message, contains('"XYZ123"'));
  });

  test('a full-subject code succeeds from the generic Home entry (no target)', () async {
    final firestore = FakeFirebaseFirestore();
    await StudentRepository(firestore: firestore).saveStudent(_blankStudent('111111'));
    await firestore.collection('unlockCodes').doc('SCIGRADE7').set({
      'type': 'subject',
      'subjects': ['chemistry', 'biology', 'physics'],
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    });
    final service = AccessCodeService(
      firestore: firestore,
      quizAttemptService: QuizAttemptService(firestore: firestore),
    );

    final result = await service.redeem(studentId: '111111', rawCode: 'scigrade7');

    expect(result.success, true);
  });

  test('a subject code with a lesson-id list only unlocks listed lessons for a matching target', () async {
    final firestore = FakeFirebaseFirestore();
    await StudentRepository(firestore: firestore).saveStudent(_blankStudent('111111'));
    await firestore.collection('unlockCodes').doc('Q1W3CODE').set({
      'type': 'subject',
      'lessonIds': ['q1w3', 'q1w4'],
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    });
    final service = AccessCodeService(
      firestore: firestore,
      quizAttemptService: QuizAttemptService(firestore: firestore),
    );

    final wrongTarget = await service.redeem(
      studentId: '111111',
      rawCode: 'Q1W3CODE',
      targetId: 'q1w5',
      targetType: AccessCodeTarget.lesson,
    );
    expect(wrongTarget.success, false);

    final rightTarget = await service.redeem(
      studentId: '111111',
      rawCode: 'Q1W3CODE',
      targetId: 'q1w3',
      targetType: AccessCodeTarget.lesson,
    );
    expect(rightTarget.success, true);

    final student = await StudentRepository(firestore: firestore).getStudent('111111');
    expect(student!.unlockedLessonIds, containsAll(['q1w3', 'q1w4']));
  });

  test('a single specific-lesson code unlocks exactly that lesson', () async {
    final firestore = FakeFirebaseFirestore();
    await StudentRepository(firestore: firestore).saveStudent(_blankStudent('111111'));
    await firestore.collection('unlockCodes').doc('ONELESSON').set({
      'type': 'lesson',
      'targetId': 'q2w2',
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    });
    final service = AccessCodeService(
      firestore: firestore,
      quizAttemptService: QuizAttemptService(firestore: firestore),
    );

    final result = await service.redeem(
      studentId: '111111',
      rawCode: 'ONELESSON',
      targetId: 'q2w2',
      targetType: AccessCodeTarget.lesson,
    );

    expect(result.success, true);
    final student = await StudentRepository(firestore: firestore).getStudent('111111');
    expect(student!.unlockedLessonIds, ['q2w2']);
  });

  test('a quiz-retake code unlocks a locked post-test for exactly one more attempt', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    final quizAttemptService = QuizAttemptService(firestore: firestore);
    await studentRepo.saveStudent(_blankStudent('111111'));
    final postQuizId = builtinQuizId('q1w1', QuizPhase.post);

    await quizAttemptService.recordAttempt(
      studentId: '111111',
      subject: SubjectKey.chemistry,
      attempt: QuizAttempt(
        id: 'attempt-1',
        quizId: postQuizId,
        studentId: '111111',
        attemptNumber: 1,
        score: 40,
        totalQuestions: 5,
        correctAnswers: 2,
        answers: const [0, 1, 0, 1, 0],
        timestamp: DateTime(2026, 8, 20).toIso8601String(),
        locked: true,
      ),
    );

    await firestore.collection('quizUnlockCodes').doc('retake-1').set({
      'id': 'retake-1',
      'quizId': postQuizId,
      'studentId': '111111',
      'code': 'RETRY99',
      'generatedAt': DateTime(2026, 8, 21).toIso8601String(),
      'isUsed': false,
    });

    final service = AccessCodeService(firestore: firestore, quizAttemptService: quizAttemptService);
    final result = await service.redeem(
      studentId: '111111',
      rawCode: 'retry99',
      targetId: 'q1w1',
      targetType: AccessCodeTarget.quiz,
    );

    expect(result.success, true);
    final eligibility = await quizAttemptService.checkEligibility('111111', postQuizId);
    expect(eligibility.canTake, true);
  });

  test('a used-up quiz-retake code cannot be redeemed twice', () async {
    final firestore = FakeFirebaseFirestore();
    await StudentRepository(firestore: firestore).saveStudent(_blankStudent('111111'));
    await firestore.collection('quizUnlockCodes').doc('retake-1').set({
      'id': 'retake-1',
      'quizId': builtinQuizId('q1w1', QuizPhase.post),
      'studentId': '111111',
      'code': 'RETRY99',
      'generatedAt': DateTime(2026, 8, 21).toIso8601String(),
      'isUsed': true,
      'usedAt': DateTime(2026, 8, 21).toIso8601String(),
    });

    final service = AccessCodeService(
      firestore: firestore,
      quizAttemptService: QuizAttemptService(firestore: firestore),
    );
    final result = await service.redeem(
      studentId: '111111',
      rawCode: 'retry99',
      targetId: 'q1w1',
      targetType: AccessCodeTarget.quiz,
    );

    expect(result.success, false);
    expect(result.message, contains('"RETRY99"'));
  });
}
