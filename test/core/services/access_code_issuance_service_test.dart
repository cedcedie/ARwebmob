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
  test(
    'issueSubjectCode (whole-subject, no lessonIds) round-trips through redeem() for an untargeted student',
    () async {
      final firestore = FakeFirebaseFirestore();
      await StudentRepository(
        firestore: firestore,
      ).saveStudent(_blankStudent('111111'));
      final issuance = AccessCodeIssuanceService(
        firestore: firestore,
        quizAttemptService: QuizAttemptService(firestore: firestore),
      );
      final accessCodeService = AccessCodeService(
        firestore: firestore,
        quizAttemptService: QuizAttemptService(firestore: firestore),
      );

      final code = await issuance.issueSubjectCode(subjects: ['chemistry']);

      final result = await accessCodeService.redeem(
        studentId: '111111',
        rawCode: code,
      );

      expect(result.success, true);
      expect(result.message, 'Subject unlocked successfully!');
    },
  );

  test(
    'issueSubjectCode with lessonIds: redeem() succeeds for a listed lesson, fails for one not in the list',
    () async {
      final firestore = FakeFirebaseFirestore();
      await StudentRepository(
        firestore: firestore,
      ).saveStudent(_blankStudent('111111'));
      final issuance = AccessCodeIssuanceService(
        firestore: firestore,
        quizAttemptService: QuizAttemptService(firestore: firestore),
      );
      final accessCodeService = AccessCodeService(
        firestore: firestore,
        quizAttemptService: QuizAttemptService(firestore: firestore),
      );

      final code = await issuance.issueSubjectCode(
        subjects: ['chemistry'],
        lessonIds: ['q1w1', 'q1w2'],
      );

      final wrongLesson = await accessCodeService.redeem(
        studentId: '111111',
        rawCode: code,
        targetId: 'q1w9',
        targetType: AccessCodeTarget.lesson,
      );
      expect(wrongLesson.success, false);
      expect(wrongLesson.message, contains("isn't valid for this lesson"));

      final rightLesson = await accessCodeService.redeem(
        studentId: '111111',
        rawCode: code,
        targetId: 'q1w1',
        targetType: AccessCodeTarget.lesson,
      );
      expect(rightLesson.success, true);
    },
  );

  test(
    'issueLessonCode: redeem() succeeds for the targeted student, fails "different student" for another',
    () async {
      final firestore = FakeFirebaseFirestore();
      await StudentRepository(
        firestore: firestore,
      ).saveStudent(_blankStudent('111111'));
      await StudentRepository(
        firestore: firestore,
      ).saveStudent(_blankStudent('222222'));
      final issuance = AccessCodeIssuanceService(
        firestore: firestore,
        quizAttemptService: QuizAttemptService(firestore: firestore),
      );
      final accessCodeService = AccessCodeService(
        firestore: firestore,
        quizAttemptService: QuizAttemptService(firestore: firestore),
      );

      final code = await issuance.issueLessonCode(
        lessonId: 'q2w2',
        studentId: '111111',
      );

      final otherStudent = await accessCodeService.redeem(
        studentId: '222222',
        rawCode: code,
        targetId: 'q2w2',
        targetType: AccessCodeTarget.lesson,
      );
      expect(otherStudent.success, false);
      expect(otherStudent.message, contains('assigned to a different student'));

      final targetedStudent = await accessCodeService.redeem(
        studentId: '111111',
        rawCode: code,
        targetId: 'q2w2',
        targetType: AccessCodeTarget.lesson,
      );
      expect(targetedStudent.success, true);

      final student = await StudentRepository(
        firestore: firestore,
      ).getStudent('111111');
      expect(student!.unlockedLessonIds, contains('q2w2'));
    },
  );

  test(
    'issueQuizRetakeCode throws and writes nothing when the student has zero attempts on the post-test',
    () async {
      final firestore = FakeFirebaseFirestore();
      await StudentRepository(
        firestore: firestore,
      ).saveStudent(_blankStudent('111111'));
      final issuance = AccessCodeIssuanceService(
        firestore: firestore,
        quizAttemptService: QuizAttemptService(firestore: firestore),
      );

      await expectLater(
        () =>
            issuance.issueQuizRetakeCode(lessonId: 'q1w1', studentId: '111111'),
        throwsStateError,
      );

      final quizUnlockCodes = await firestore
          .collection('quizUnlockCodes')
          .get();
      expect(quizUnlockCodes.docs, isEmpty);
    },
  );

  test(
    'issueQuizRetakeCode succeeds after >=1 attempt, round-trips through redeem() once, and is rejected on a second redeem',
    () async {
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

      final issuance = AccessCodeIssuanceService(
        firestore: firestore,
        quizAttemptService: quizAttemptService,
      );
      final accessCodeService = AccessCodeService(
        firestore: firestore,
        quizAttemptService: quizAttemptService,
      );

      final code = await issuance.issueQuizRetakeCode(
        lessonId: 'q1w1',
        studentId: '111111',
      );

      final firstRedeem = await accessCodeService.redeem(
        studentId: '111111',
        rawCode: code,
        targetId: 'q1w1',
        targetType: AccessCodeTarget.quiz,
      );
      expect(firstRedeem.success, true);
      expect(firstRedeem.message, 'Test unlocked for retake!');

      final eligibility = await quizAttemptService.checkEligibility(
        '111111',
        postQuizId,
      );
      expect(eligibility.canTake, true);

      final secondRedeem = await accessCodeService.redeem(
        studentId: '111111',
        rawCode: code,
        targetId: 'q1w1',
        targetType: AccessCodeTarget.quiz,
      );
      expect(secondRedeem.success, false);
    },
  );

  test(
    'a duplicate teacher-supplied custom code is rejected with no overwrite of the existing doc',
    () async {
      final firestore = FakeFirebaseFirestore();
      await StudentRepository(
        firestore: firestore,
      ).saveStudent(_blankStudent('111111'));
      final issuance = AccessCodeIssuanceService(
        firestore: firestore,
        quizAttemptService: QuizAttemptService(firestore: firestore),
      );

      await issuance.issueSubjectCode(
        subjects: ['chemistry'],
        customCode: 'MYCODE1',
      );

      await expectLater(
        () => issuance.issueSubjectCode(
          subjects: ['biology'],
          customCode: 'mycode1',
        ),
        throwsStateError,
      );

      final doc = await firestore
          .collection('unlockCodes')
          .doc('MYCODE1')
          .get();
      expect(doc.data()!['subjects'], ['chemistry']);
    },
  );

  test(
    'watchIssuedUnlockCodes streams the docs written by issueSubjectCode and issueLessonCode',
    () async {
      final firestore = FakeFirebaseFirestore();
      await StudentRepository(
        firestore: firestore,
      ).saveStudent(_blankStudent('111111'));
      final issuance = AccessCodeIssuanceService(
        firestore: firestore,
        quizAttemptService: QuizAttemptService(firestore: firestore),
      );

      await issuance.issueSubjectCode(
        subjects: ['chemistry'],
        customCode: 'STREAM01',
      );
      await issuance.issueLessonCode(
        lessonId: 'q1w1',
        studentId: '111111',
        customCode: 'STREAM02',
      );

      final codes = await issuance.watchIssuedUnlockCodes().first;

      expect(codes.length, 2);
      expect(codes.map((c) => c['id']), containsAll(['STREAM01', 'STREAM02']));
    },
  );

  test(
    'watchIssuedRetakeCodes streams QuizUnlockCode models written by issueQuizRetakeCode',
    () async {
      final firestore = FakeFirebaseFirestore();
      final quizAttemptService = QuizAttemptService(firestore: firestore);
      await StudentRepository(
        firestore: firestore,
      ).saveStudent(_blankStudent('111111'));
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
      final issuance = AccessCodeIssuanceService(
        firestore: firestore,
        quizAttemptService: quizAttemptService,
      );

      await issuance.issueQuizRetakeCode(lessonId: 'q1w1', studentId: '111111');

      final retakeCodes = await issuance.watchIssuedRetakeCodes().first;

      expect(retakeCodes.length, 1);
      expect(retakeCodes.first.studentId, '111111');
      expect(retakeCodes.first.quizId, postQuizId);
      expect(retakeCodes.first.isUsed, false);
    },
  );

  group('deleting an issued code', () {
    test(
      'removes a subject/lesson code so it can no longer be redeemed',
      () async {
        final firestore = FakeFirebaseFirestore();
        final quizAttemptService = QuizAttemptService(firestore: firestore);
        final issuance = AccessCodeIssuanceService(
          firestore: firestore,
          quizAttemptService: quizAttemptService,
        );
        final studentRepository = StudentRepository(firestore: firestore);
        await studentRepository.saveStudent(_blankStudent('111111'));

        final code = await issuance.issueSubjectCode(
          subjects: const ['chemistry'],
          customCode: 'TYPO01',
        );

        await issuance.deleteUnlockCode(code);

        expect(await issuance.watchIssuedUnlockCodes().first, isEmpty);

        // Deletion is a real invalidation, not just a table tidy-up.
        final redeemer = AccessCodeService(
          firestore: firestore,
          quizAttemptService: quizAttemptService,
        );
        final result = await redeemer.redeem(
          studentId: '111111',
          rawCode: code,
          targetId: 'q1w1',
          targetType: AccessCodeTarget.lesson,
        );
        expect(result.success, isFalse);
      },
    );

    test(
      'deleting is case-insensitive about the code the teacher typed',
      () async {
        final firestore = FakeFirebaseFirestore();
        final issuance = AccessCodeIssuanceService(
          firestore: firestore,
          quizAttemptService: QuizAttemptService(firestore: firestore),
        );
        await issuance.issueSubjectCode(
          subjects: const ['chemistry'],
          customCode: 'ABC123',
        );

        await issuance.deleteUnlockCode('abc123');

        expect(await issuance.watchIssuedUnlockCodes().first, isEmpty);
      },
    );

    test('removes a retake code by its document id', () async {
      // Retake code documents use auto-generated ids with the code as a
      // mere field, so they must be deleted by id, not by code string.
      final firestore = FakeFirebaseFirestore();
      final quizAttemptService = QuizAttemptService(firestore: firestore);
      final studentRepository = StudentRepository(firestore: firestore);
      final postQuizId = builtinQuizId('q1w1', QuizPhase.post);
      await studentRepository.saveStudent(_blankStudent('111111'));
      await quizAttemptService.recordAttempt(
        studentId: '111111',
        subject: SubjectKey.chemistry,
        attempt: QuizAttempt(
          id: 'attempt-1',
          quizId: postQuizId,
          studentId: '111111',
          attemptNumber: 1,
          score: 60,
          totalQuestions: 5,
          correctAnswers: 3,
          answers: const [0, 1, 0, 1, 0],
          timestamp: DateTime(2026, 8, 20).toIso8601String(),
          locked: true,
        ),
      );
      final issuance = AccessCodeIssuanceService(
        firestore: firestore,
        quizAttemptService: quizAttemptService,
      );
      await issuance.issueQuizRetakeCode(lessonId: 'q1w1', studentId: '111111');
      final issued = await issuance.watchIssuedRetakeCodes().first;

      await issuance.deleteRetakeCode(issued.single.id);

      expect(await issuance.watchIssuedRetakeCodes().first, isEmpty);
    });
  });
}
