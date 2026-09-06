import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/quiz_id.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
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
  final preQuizId = builtinQuizId('q1w1', QuizPhase.pre);
  final postQuizId = builtinQuizId('q1w1', QuizPhase.post);

  group('checkEligibility', () {
    test('pre-test is always takeable, even with prior attempts', () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final service = QuizAttemptService(firestore: firestore);
      await studentRepo.saveStudent(_blankStudent('111111'));

      final eligibility = await service.checkEligibility('111111', preQuizId);

      expect(eligibility.canTake, true);
      expect(eligibility.isLocked, false);
    });

    test('post-test first attempt is free — no unlock required', () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final service = QuizAttemptService(firestore: firestore);
      await studentRepo.saveStudent(_blankStudent('111111'));

      final eligibility = await service.checkEligibility('111111', postQuizId);

      expect(eligibility.canTake, true);
      expect(eligibility.isLocked, false);
      expect(eligibility.attemptCount, 0);
    });

    test(
      'post-test is locked after one attempt, until a retake code unlocks it',
      () async {
        final firestore = FakeFirebaseFirestore();
        final studentRepo = StudentRepository(firestore: firestore);
        final service = QuizAttemptService(firestore: firestore);
        await studentRepo.saveStudent(_blankStudent('111111'));

        await service.recordAttempt(
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

        final eligibility = await service.checkEligibility(
          '111111',
          postQuizId,
        );
        expect(eligibility.canTake, false);
        expect(eligibility.isLocked, true);
        expect(eligibility.reason, isNotNull);
        expect(eligibility.attemptCount, 1);
      },
    );
  });

  group('recordAttempt', () {
    test(
      'post-test attempt updates scores, completedLessonIds, completedQuizIds',
      () async {
        final firestore = FakeFirebaseFirestore();
        final studentRepo = StudentRepository(firestore: firestore);
        final service = QuizAttemptService(firestore: firestore);
        await studentRepo.saveStudent(_blankStudent('111111'));

        await service.recordAttempt(
          studentId: '111111',
          subject: SubjectKey.chemistry,
          attempt: QuizAttempt(
            id: 'attempt-1',
            quizId: postQuizId,
            studentId: '111111',
            attemptNumber: 1,
            score: 80,
            totalQuestions: 5,
            correctAnswers: 4,
            answers: const [0, 1, 0, 1, 0],
            timestamp: DateTime(2026, 8, 20).toIso8601String(),
            locked: true,
          ),
        );

        final student = await studentRepo.getStudent('111111');
        expect(student!.scores['chemistry'], 80);
        expect(student.completedLessonIds, contains('q1w1'));
        expect(student.completedQuizIds, contains(postQuizId));
        expect(student.quizAttempts, hasLength(1));

        // Backup subcollection write also happened.
        final subDoc = await firestore
            .collection('students')
            .doc('111111')
            .collection('quizAttempts')
            .doc('attempt-1')
            .get();
        expect(subDoc.exists, true);
      },
    );

    test(
      'pre-test attempt does NOT touch scores or completedLessonIds',
      () async {
        final firestore = FakeFirebaseFirestore();
        final studentRepo = StudentRepository(firestore: firestore);
        final service = QuizAttemptService(firestore: firestore);
        await studentRepo.saveStudent(_blankStudent('111111'));

        await service.recordAttempt(
          studentId: '111111',
          subject: SubjectKey.chemistry,
          attempt: QuizAttempt(
            id: 'attempt-pre-1',
            quizId: preQuizId,
            studentId: '111111',
            attemptNumber: 1,
            score: 60,
            totalQuestions: 8,
            correctAnswers: 5,
            answers: const [0, 1, 0, 1, 0, 1, 0, 1],
            timestamp: DateTime(2026, 8, 20).toIso8601String(),
            locked: false,
          ),
        );

        final student = await studentRepo.getStudent('111111');
        expect(student!.scores['chemistry'], isNull);
        expect(student.completedLessonIds, isEmpty);
        expect(student.completedQuizIds, contains(preQuizId));
      },
    );

    test('a retake attempt after unlockRetake is takeable again', () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final service = QuizAttemptService(firestore: firestore);
      await studentRepo.saveStudent(_blankStudent('111111'));

      await service.recordAttempt(
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

      await service.unlockRetake('111111', postQuizId);

      final eligibility = await service.checkEligibility('111111', postQuizId);
      expect(eligibility.canTake, true);
      expect(eligibility.isLocked, false);
      expect(eligibility.attemptCount, 1);
    });

    test('normalizes locked regardless of what the caller passed in', () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final service = QuizAttemptService(firestore: firestore);
      await studentRepo.saveStudent(_blankStudent('111111'));

      // Caller wrongly passes locked: false for a post-test attempt — the
      // service must correct this to true, not trust the caller.
      await service.recordAttempt(
        studentId: '111111',
        subject: SubjectKey.chemistry,
        attempt: QuizAttempt(
          id: 'attempt-post-wrong-flag',
          quizId: postQuizId,
          studentId: '111111',
          attemptNumber: 1,
          score: 40,
          totalQuestions: 5,
          correctAnswers: 2,
          answers: const [0, 1, 0, 1, 0],
          timestamp: DateTime(2026, 8, 20).toIso8601String(),
          locked: false,
        ),
      );

      final student = await studentRepo.getStudent('111111');
      expect(student!.quizAttempts.single.locked, true);

      final subDoc = await firestore
          .collection('students')
          .doc('111111')
          .collection('quizAttempts')
          .doc('attempt-post-wrong-flag')
          .get();
      expect(subDoc.data()!['locked'], true);

      // Caller wrongly passes locked: true for a pre-test attempt — the
      // service must correct this to false.
      await service.recordAttempt(
        studentId: '111111',
        subject: SubjectKey.chemistry,
        attempt: QuizAttempt(
          id: 'attempt-pre-wrong-flag',
          quizId: preQuizId,
          studentId: '111111',
          attemptNumber: 1,
          score: 60,
          totalQuestions: 8,
          correctAnswers: 5,
          answers: const [0, 1, 0, 1, 0, 1, 0, 1],
          timestamp: DateTime(2026, 8, 21).toIso8601String(),
          locked: true,
        ),
      );

      final updatedStudent = await studentRepo.getStudent('111111');
      final preAttempt = updatedStudent!.quizAttempts.firstWhere(
        (a) => a.id == 'attempt-pre-wrong-flag',
      );
      expect(preAttempt.locked, false);

      final preSubDoc = await firestore
          .collection('students')
          .doc('111111')
          .collection('quizAttempts')
          .doc('attempt-pre-wrong-flag')
          .get();
      expect(preSubDoc.data()!['locked'], false);
    });
  });
}
