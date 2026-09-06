// test/integration/access_code_round_trip_test.dart
//
// Cross-target integration coverage for PROJECT_FLOW.md Part 9 — the
// access-code system. Every test here shares ONE `FakeFirebaseFirestore`
// instance between a "teacher-side" service (`AccessCodeIssuanceService`,
// `QuizAttemptService.recordAttempt`) and a "student-side" service
// (`AccessCodeService.redeem`, `buildLearnViewModel`), so a code issued by
// the teacher is actually read back and acted on by the student path
// through the real backing store — not two independently-mocked halves.
//
// Unlock outcomes are checked against the app's own real unlock-check
// logic (`buildLearnViewModel` — see learn_providers.dart), not a
// hand-rolled re-check of `unlockedLessonIds`.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/models/quiz_unlock_code.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/quiz_id.dart';
import 'package:ar_science_explorer/core/services/access_code_issuance_service.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/lesson_repository.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/features/student/learn/learn_providers.dart';

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

/// Drives the real student-side Learn view model and returns just the
/// lesson-unlock map for [subject], keyed by lesson id — the exact
/// "unlocked or not" answer the Learn screen would show this student.
Future<Map<String, bool>> _unlockMapFor(
  String studentId,
  SubjectKey subject, {
  required LessonRepository lessonRepository,
  required StudentRepository studentRepository,
  required AccessCodeService accessCodeService,
}) async {
  final vm = await buildLearnViewModel(
    studentId: studentId,
    initialSubject: subject,
    lessonRepository: lessonRepository,
    studentRepository: studentRepository,
    accessCodeService: accessCodeService,
    preTestLessonIds: const {},
    onSelectSubject: (_) {},
  ).first;
  return {for (final card in vm.cards) card.lessonId: card.isUnlocked};
}

void main() {
  group('Type 1 — subject/lesson-wide code, untargeted', () {
    test(
      'teacher issues a lesson-scoped subject code; any student redeeming it '
      'sees the real Learn view model flip that lesson to unlocked',
      () async {
        final firestore = FakeFirebaseFirestore();
        final studentRepo = StudentRepository(firestore: firestore);
        final lessonRepo = LessonRepository(firestore: firestore);
        final quizAttemptService = QuizAttemptService(firestore: firestore);
        final issuance = AccessCodeIssuanceService(
          firestore: firestore,
          quizAttemptService: quizAttemptService,
        );
        final accessCodeService = AccessCodeService(
          firestore: firestore,
          quizAttemptService: quizAttemptService,
        );
        await studentRepo.saveStudent(_blankStudent('111111'));

        // q1w2 is not unlocked by default (only q1w1 is) — see
        // curriculum_data.dart.
        final before = await _unlockMapFor(
          '111111',
          SubjectKey.chemistry,
          lessonRepository: lessonRepo,
          studentRepository: studentRepo,
          accessCodeService: accessCodeService,
        );
        expect(before['q1w2'], false);

        // Teacher issues the code — real issuance entry point.
        final code = await issuance.issueSubjectCode(
          subjects: ['chemistry'],
          lessonIds: ['q1w2'],
        );

        // Student redeems it — code isn't targeted, so any student can.
        final result = await accessCodeService.redeem(
          studentId: '111111',
          rawCode: code,
          targetId: 'q1w2',
          targetType: AccessCodeTarget.lesson,
        );
        expect(result.success, true);

        final after = await _unlockMapFor(
          '111111',
          SubjectKey.chemistry,
          lessonRepository: lessonRepo,
          studentRepository: studentRepo,
          accessCodeService: accessCodeService,
        );
        expect(after['q1w2'], true);
        // A different, never-redeemed lesson stays locked — the unlock is
        // scoped to what the code actually listed, not a blanket flip.
        expect(after['q1w3'], false);
      },
    );

    test('a full-subject code (no lessonIds) is redeemable by any student, '
        'untargeted', () async {
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
      await studentRepo.saveStudent(_blankStudent('AAA111'));
      await studentRepo.saveStudent(_blankStudent('BBB222'));

      final code = await issuance.issueSubjectCode(subjects: ['biology']);

      final first = await accessCodeService.redeem(
        studentId: 'AAA111',
        rawCode: code,
      );
      final second = await accessCodeService.redeem(
        studentId: 'BBB222',
        rawCode: code,
      );

      expect(first.success, true);
      expect(second.success, true);
    });
  });

  group('Type 2 — lesson-specific code, targeted to one student', () {
    test(
      'the targeted student unlocks the lesson via the real Learn view '
      "model; a different student's redemption of the same code is rejected",
      () async {
        final firestore = FakeFirebaseFirestore();
        final studentRepo = StudentRepository(firestore: firestore);
        final lessonRepo = LessonRepository(firestore: firestore);
        final quizAttemptService = QuizAttemptService(firestore: firestore);
        final issuance = AccessCodeIssuanceService(
          firestore: firestore,
          quizAttemptService: quizAttemptService,
        );
        final accessCodeService = AccessCodeService(
          firestore: firestore,
          quizAttemptService: quizAttemptService,
        );
        await studentRepo.saveStudent(_blankStudent('TARGETED1'));
        await studentRepo.saveStudent(_blankStudent('OTHER0002'));

        final code = await issuance.issueLessonCode(
          lessonId: 'q1w3',
          studentId: 'TARGETED1',
        );

        // A different student's attempt is rejected — targeting enforced.
        final otherResult = await accessCodeService.redeem(
          studentId: 'OTHER0002',
          rawCode: code,
          targetId: 'q1w3',
          targetType: AccessCodeTarget.lesson,
        );
        expect(otherResult.success, false);
        expect(
          otherResult.message,
          contains('assigned to a different student'),
        );
        final otherMap = await _unlockMapFor(
          'OTHER0002',
          SubjectKey.chemistry,
          lessonRepository: lessonRepo,
          studentRepository: studentRepo,
          accessCodeService: accessCodeService,
        );
        expect(otherMap['q1w3'], false);

        // The actual targeted student succeeds and sees the real unlock.
        final targetedResult = await accessCodeService.redeem(
          studentId: 'TARGETED1',
          rawCode: code,
          targetId: 'q1w3',
          targetType: AccessCodeTarget.lesson,
        );
        expect(targetedResult.success, true);
        final targetedMap = await _unlockMapFor(
          'TARGETED1',
          SubjectKey.chemistry,
          lessonRepository: lessonRepo,
          studentRepository: studentRepo,
          accessCodeService: accessCodeService,
        );
        expect(targetedMap['q1w3'], true);
      },
    );
  });

  group('Type 3 — quiz-retake code, requires a prior post-test attempt', () {
    test('issuing a retake code before any attempt exists is refused; after a '
        'real first post-test attempt is recorded, the code round-trips '
        'through redeem() and is one-time-use', () async {
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
      final postQuizId = builtinQuizId('q1w4', QuizPhase.post);

      // Part 9.1's hard precondition: no attempt yet -> refused.
      await expectLater(
        () =>
            issuance.issueQuizRetakeCode(lessonId: 'q1w4', studentId: '222222'),
        throwsStateError,
      );

      // The student's real first post-test attempt, via the same
      // QuizAttemptService the quiz-player screen actually calls.
      await quizAttemptService.recordAttempt(
        studentId: '222222',
        subject: SubjectKey.chemistry,
        attempt: QuizAttempt(
          id: 'attempt-first',
          quizId: postQuizId,
          studentId: '222222',
          attemptNumber: 1,
          score: 40,
          totalQuestions: 5,
          correctAnswers: 2,
          answers: const [0, 1, 0, 1, 0],
          timestamp: DateTime(2026, 8, 20).toIso8601String(),
          locked: true,
        ),
      );

      // Now the teacher can issue a retake code.
      final code = await issuance.issueQuizRetakeCode(
        lessonId: 'q1w4',
        studentId: '222222',
      );

      final firstRedeem = await accessCodeService.redeem(
        studentId: '222222',
        rawCode: code,
        targetId: 'q1w4',
        targetType: AccessCodeTarget.quiz,
      );
      expect(firstRedeem.success, true);
      expect(firstRedeem.message, 'Test unlocked for retake!');

      final eligibility = await quizAttemptService.checkEligibility(
        '222222',
        postQuizId,
      );
      expect(eligibility.canTake, true);

      // One-time-use: a second redemption of the same code fails.
      final secondRedeem = await accessCodeService.redeem(
        studentId: '222222',
        rawCode: code,
        targetId: 'q1w4',
        targetType: AccessCodeTarget.quiz,
      );
      expect(secondRedeem.success, false);
    });
  });

  group('Part 9.2 — validation order', () {
    test(
      'a code string that collides between /quizUnlockCodes and /unlockCodes '
      'is resolved via the retake-code store first (step 1), not the '
      'first-time test-unlock branch (step 4) that would otherwise match',
      () async {
        final firestore = FakeFirebaseFirestore();
        final studentRepo = StudentRepository(firestore: firestore);
        final quizAttemptService = QuizAttemptService(firestore: firestore);
        final accessCodeService = AccessCodeService(
          firestore: firestore,
          quizAttemptService: quizAttemptService,
        );
        await studentRepo.saveStudent(_blankStudent('333333'));
        final postQuizId = builtinQuizId('q1w5', QuizPhase.post);

        // Give the student a locked prior attempt, so unlockRetake actually
        // has something to flip (observable proof the retake branch ran).
        await quizAttemptService.recordAttempt(
          studentId: '333333',
          subject: SubjectKey.chemistry,
          attempt: QuizAttempt(
            id: 'attempt-1',
            quizId: postQuizId,
            studentId: '333333',
            attemptNumber: 1,
            score: 20,
            totalQuestions: 5,
            correctAnswers: 1,
            answers: const [0, 1, 0, 1, 0],
            timestamp: DateTime(2026, 8, 20).toIso8601String(),
            locked: true,
          ),
        );

        const dualCode = 'DUAL01';

        // Same literal code string written into BOTH stores directly, to
        // force the two-store collision the validation order exists to
        // resolve deterministically.
        await firestore
            .collection('quizUnlockCodes')
            .doc('retake-doc')
            .set(
              QuizUnlockCode(
                id: 'retake-doc',
                quizId: postQuizId,
                studentId: '333333',
                code: dualCode,
                generatedAt: DateTime(2026, 8, 21).toIso8601String(),
                isUsed: false,
              ).toJson(),
            );
        // A type:'lesson' unlockCodes doc under the SAME code string —
        // redeem()'s step 4 ("first-time test-unlock") would match this if
        // the retake store weren't checked first.
        await firestore.collection('unlockCodes').doc(dualCode).set({
          'type': 'lesson',
          'targetId': 'q1w5',
          'usedByStudentIds': <String>[],
          'isUsed': false,
        });

        final result = await accessCodeService.redeem(
          studentId: '333333',
          rawCode: dualCode,
          targetId: 'q1w5',
          targetType: AccessCodeTarget.quiz,
        );

        expect(result.success, true);
        // Step 4's message would be 'Test unlocked successfully!' — the
        // retake message proves step 1 matched first.
        expect(result.message, 'Test unlocked for retake!');

        final eligibility = await quizAttemptService.checkEligibility(
          '333333',
          postQuizId,
        );
        expect(
          eligibility.canTake,
          true,
          reason: 'unlockRetake must have actually run',
        );
      },
    );
  });

  group('Part 9.3 — error messaging echoes the exact code typed', () {
    test(
      'an unknown code is rejected with a message that echoes it verbatim',
      () async {
        final firestore = FakeFirebaseFirestore();
        final studentRepo = StudentRepository(firestore: firestore);
        final quizAttemptService = QuizAttemptService(firestore: firestore);
        final accessCodeService = AccessCodeService(
          firestore: firestore,
          quizAttemptService: quizAttemptService,
        );
        await studentRepo.saveStudent(_blankStudent('444444'));

        final result = await accessCodeService.redeem(
          studentId: '444444',
          rawCode: 'xyz123',
        );

        expect(result.success, false);
        // Echoed back upper-cased/trimmed, exactly as the service normalizes
        // and displays it — not a generic "invalid code" message.
        expect(
          result.message,
          'Code "XYZ123" isn\'t valid. Check with your teacher.',
        );
      },
    );

    test(
      'a code assigned to a different student still echoes the exact code typed',
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
        await studentRepo.saveStudent(_blankStudent('555555'));
        await studentRepo.saveStudent(_blankStudent('666666'));

        await issuance.issueLessonCode(
          lessonId: 'q1w6',
          studentId: '555555',
          customCode: 'ECHOME',
        );

        final result = await accessCodeService.redeem(
          studentId: '666666',
          rawCode: 'echome',
          targetId: 'q1w6',
          targetType: AccessCodeTarget.lesson,
        );

        expect(result.success, false);
        expect(result.message, contains('Code "ECHOME"'));
      },
    );
  });
}
