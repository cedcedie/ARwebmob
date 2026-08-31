// test/integration/quiz_retake_rule_test.dart
//
// Cross-target integration coverage for PROJECT_FLOW.md Part 7.1 — "the
// single most important behavior to get exactly right" per the client:
//
//   - Pre-test: always retakeable, no access code required, ever.
//   - Post-test: first attempt free; every retake after that requires a
//     teacher-issued quiz-retake access code (Part 9.1, code type 3).
//
// Both rules are driven end-to-end through the real
// `QuizAttemptService` (student quiz-taking) and `AccessCodeIssuanceService`
// + `AccessCodeService` (teacher issuance -> student redemption), sharing
// one `FakeFirebaseFirestore`, so this is a genuine teacher-issues /
// student-redeems round trip, not two independently-mocked halves. The
// two rules are asserted in ways that would fail if they were ever
// accidentally swapped or merged (e.g. gating a pre-test, or freeing a
// post-test retake).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/quiz_id.dart';
import 'package:ar_science_explorer/core/services/access_code_issuance_service.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';

StudentRecord _blankStudent(String id) => StudentRecord(
      id: id,
      name: 'Student $id',
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

QuizAttempt _attempt({
  required String id,
  required String quizId,
  required String studentId,
  required int attemptNumber,
  required int score,
  required bool locked,
}) =>
    QuizAttempt(
      id: id,
      quizId: quizId,
      studentId: studentId,
      attemptNumber: attemptNumber,
      score: score,
      totalQuestions: 5,
      correctAnswers: (score / 20).round(),
      answers: const [0, 1, 0, 1, 0],
      timestamp: DateTime(2026, 8, 20, attemptNumber).toIso8601String(),
      locked: locked,
    );

void main() {
  test(
    'pre-test: retakeable with no access code, ever — 3 consecutive '
    'attempts with zero gating and no code involved at any point',
    () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final quizAttemptService = QuizAttemptService(firestore: firestore);
      await studentRepo.saveStudent(_blankStudent('111111'));
      final preQuizId = builtinQuizId('q1w1', QuizPhase.pre);

      for (var attemptNumber = 1; attemptNumber <= 3; attemptNumber++) {
        final eligibility = await quizAttemptService.checkEligibility('111111', preQuizId);
        expect(
          eligibility.canTake,
          true,
          reason: 'pre-test attempt #$attemptNumber must be freely takeable',
        );
        expect(eligibility.isLocked, false);

        await quizAttemptService.recordAttempt(
          studentId: '111111',
          subject: SubjectKey.chemistry,
          attempt: _attempt(
            id: 'pre-attempt-$attemptNumber',
            quizId: preQuizId,
            studentId: '111111',
            attemptNumber: attemptNumber,
            score: 40,
            locked: false, // caller intent is irrelevant; service normalizes
          ),
        );
      }

      // After 3 attempts, still no gate — a pre-test never locks.
      final finalEligibility = await quizAttemptService.checkEligibility('111111', preQuizId);
      expect(finalEligibility.canTake, true);
      expect(finalEligibility.isLocked, false);
      expect(finalEligibility.attemptCount, 3);

      final student = await studentRepo.getStudent('111111');
      // Pre-test attempts never lock, no matter how many pile up.
      expect(student!.quizAttempts.every((a) => !a.locked), true);
      // And Part 7.1's "no code required, ever" rule is never touched by an
      // /unlockCodes or /quizUnlockCodes write for this student.
      final unlockCodes = await firestore.collection('unlockCodes').get();
      final quizUnlockCodes = await firestore.collection('quizUnlockCodes').get();
      expect(unlockCodes.docs, isEmpty);
      expect(quizUnlockCodes.docs, isEmpty);
    },
  );

  test(
    'post-test: first attempt is free; a retake without a code is rejected; '
    'a retake with a real teacher-issued code succeeds',
    () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final quizAttemptService = QuizAttemptService(firestore: firestore);
      final issuance = AccessCodeIssuanceService(
        firestore: firestore,
        quizAttemptService: quizAttemptService,
      );
      final accessCodeService = AccessCodeService(
        firestore: firestore,
        quizAttemptService: quizAttemptService,
      );
      await studentRepo.saveStudent(_blankStudent('222222'));
      final postQuizId = builtinQuizId('q1w1', QuizPhase.post);

      // First attempt: free, no code needed.
      final firstEligibility = await quizAttemptService.checkEligibility('222222', postQuizId);
      expect(firstEligibility.canTake, true);
      expect(firstEligibility.attemptCount, 0);

      await quizAttemptService.recordAttempt(
        studentId: '222222',
        subject: SubjectKey.chemistry,
        attempt: _attempt(
          id: 'post-attempt-1',
          quizId: postQuizId,
          studentId: '222222',
          attemptNumber: 1,
          score: 40,
          locked: true,
        ),
      );

      // Retake attempt #2: locked without a code.
      final lockedEligibility = await quizAttemptService.checkEligibility('222222', postQuizId);
      expect(lockedEligibility.canTake, false);
      expect(lockedEligibility.isLocked, true);
      expect(lockedEligibility.reason, isNotNull);

      // A retake attempted anyway is simulated at the caller layer by the
      // same guard the real quiz-player screen relies on: it must consult
      // checkEligibility before allowing entry to the quiz. Confirm the
      // service itself gives no path around this — redeeming a bogus code
      // does nothing.
      final bogusRedeem = await accessCodeService.redeem(
        studentId: '222222',
        rawCode: 'NOTREAL',
        targetId: 'q1w1',
        targetType: AccessCodeTarget.quiz,
      );
      expect(bogusRedeem.success, false);
      final stillLocked = await quizAttemptService.checkEligibility('222222', postQuizId);
      expect(stillLocked.canTake, false);

      // Teacher issues a real retake code now that a first attempt exists
      // (Part 9.1's precondition), and the student redeems it.
      final code = await issuance.issueQuizRetakeCode(lessonId: 'q1w1', studentId: '222222');
      final redeemResult = await accessCodeService.redeem(
        studentId: '222222',
        rawCode: code,
        targetId: 'q1w1',
        targetType: AccessCodeTarget.quiz,
      );
      expect(redeemResult.success, true);

      final unlockedEligibility = await quizAttemptService.checkEligibility('222222', postQuizId);
      expect(unlockedEligibility.canTake, true);
      expect(unlockedEligibility.isLocked, false);

      // The retake itself locks again on submission, same as attempt 1.
      await quizAttemptService.recordAttempt(
        studentId: '222222',
        subject: SubjectKey.chemistry,
        attempt: _attempt(
          id: 'post-attempt-2',
          quizId: postQuizId,
          studentId: '222222',
          attemptNumber: 2,
          score: 80,
          locked: true,
        ),
      );
      final afterRetake = await quizAttemptService.checkEligibility('222222', postQuizId);
      expect(afterRetake.canTake, false, reason: 'the retake itself locks again on submission');
      expect(afterRetake.attemptCount, 2);
    },
  );

  test(
    'the two rules are not conflated: a pre-test and a post-test for the '
    'same lesson gate independently even when interleaved',
    () async {
      final firestore = FakeFirebaseFirestore();
      final studentRepo = StudentRepository(firestore: firestore);
      final quizAttemptService = QuizAttemptService(firestore: firestore);
      await studentRepo.saveStudent(_blankStudent('333333'));
      final preQuizId = builtinQuizId('q1w7', QuizPhase.pre);
      final postQuizId = builtinQuizId('q1w7', QuizPhase.post);

      // Two pre-test attempts, freely.
      await quizAttemptService.recordAttempt(
        studentId: '333333',
        subject: SubjectKey.chemistry,
        attempt: _attempt(
          id: 'pre-1',
          quizId: preQuizId,
          studentId: '333333',
          attemptNumber: 1,
          score: 60,
          locked: false,
        ),
      );
      await quizAttemptService.recordAttempt(
        studentId: '333333',
        subject: SubjectKey.chemistry,
        attempt: _attempt(
          id: 'pre-2',
          quizId: preQuizId,
          studentId: '333333',
          attemptNumber: 2,
          score: 80,
          locked: false,
        ),
      );
      // Pre-test stays open no matter what.
      final preEligibility = await quizAttemptService.checkEligibility('333333', preQuizId);
      expect(preEligibility.canTake, true, reason: 'pre-test retakes never gate');

      // Post-test's first attempt is still free, unaffected by the pre-test
      // history above — if the two rules were ever accidentally merged
      // (e.g. post-test inheriting "no attempts yet -> free" scoped across
      // phases, or pre-test inheriting the post-test's lock), one of these
      // two assertions would fail.
      final postEligibilityBeforeAttempt =
          await quizAttemptService.checkEligibility('333333', postQuizId);
      expect(postEligibilityBeforeAttempt.canTake, true);
      expect(postEligibilityBeforeAttempt.attemptCount, 0);

      await quizAttemptService.recordAttempt(
        studentId: '333333',
        subject: SubjectKey.chemistry,
        attempt: _attempt(
          id: 'post-1',
          quizId: postQuizId,
          studentId: '333333',
          attemptNumber: 1,
          score: 40,
          locked: true,
        ),
      );

      // Post-test now locks after its own first attempt...
      final postEligibilityAfterAttempt =
          await quizAttemptService.checkEligibility('333333', postQuizId);
      expect(postEligibilityAfterAttempt.canTake, false);

      // ...while the pre-test remains completely unaffected and open.
      final preEligibilityAfterPostAttempt =
          await quizAttemptService.checkEligibility('333333', preQuizId);
      expect(preEligibilityAfterPostAttempt.canTake, true);
      expect(preEligibilityAfterPostAttempt.isLocked, false);
    },
  );
}
