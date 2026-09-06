import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quiz_attempt.dart';
import '../models/quiz_phase.dart';
import '../models/student_record.dart';
import '../models/subject_key.dart';
import '../quiz_id.dart';

/// Result of a quiz eligibility check. See PROJECT_FLOW.md Part 7.1.
typedef QuizEligibility = ({
  bool canTake,
  bool isLocked,
  String? reason,
  int attemptCount,
});

/// Implements PROJECT_FLOW.md Part 7.1's retake rule — the single most
/// important behavior in the product per the client. See this plan's Global
/// Constraints for why this deviates from the retired app's literal
/// storage.ts behavior (which gates first post-test attempts too, a bug this
/// document's own Part 7.1 warns against).
///
/// - Pre-test: always takeable, never locked.
/// - Post-test: first attempt always free; every attempt after that is
///   locked until a teacher-issued retake code flips the latest attempt's
///   `locked` flag back to false (see `unlockRetake`, called by
///   `AccessCodeService` when a valid retake code is redeemed).
class QuizAttemptService {
  QuizAttemptService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _studentDoc(String studentId) =>
      _firestore.collection('students').doc(studentId);

  Future<QuizEligibility> checkEligibility(
    String studentId,
    String quizId,
  ) async {
    final parsed = parseBuiltinId(quizId);

    if (parsed.phase == QuizPhase.pre) {
      final count = await _attemptsFor(studentId, quizId);
      return (
        canTake: true,
        isLocked: false,
        reason: null,
        attemptCount: count.length,
      );
    }

    final attempts = await _attemptsFor(studentId, quizId);
    if (attempts.isEmpty) {
      return (canTake: true, isLocked: false, reason: null, attemptCount: 0);
    }

    final latest = attempts.first; // _attemptsFor returns newest-first.
    if (latest.locked) {
      return (
        canTake: false,
        isLocked: true,
        reason:
            'Test locked after your last attempt. Ask your teacher for a retake code.',
        attemptCount: attempts.length,
      );
    }
    return (
      canTake: true,
      isLocked: false,
      reason: null,
      attemptCount: attempts.length,
    );
  }

  Future<List<QuizAttempt>> _attemptsFor(
    String studentId,
    String quizId,
  ) async {
    final snapshot = await _studentDoc(studentId).get();
    final data = snapshot.data();
    if (data == null) return const [];
    final student = StudentRecord.fromJson(data);
    final attempts =
        student.quizAttempts.where((a) => a.quizId == quizId).toList()..sort(
          (a, b) => DateTime.parse(
            b.timestamp,
          ).compareTo(DateTime.parse(a.timestamp)),
        );
    return attempts;
  }

  Future<void> recordAttempt({
    required String studentId,
    required QuizAttempt attempt,
    required SubjectKey subject,
  }) async {
    final parsed = parseBuiltinId(attempt.quizId);
    final isPreTest = parsed.phase == QuizPhase.pre;

    final snapshot = await _studentDoc(studentId).get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError(
        'Cannot record a quiz attempt for unknown student $studentId',
      );
    }
    final student = StudentRecord.fromJson(data);

    // Normalize the lock flag ourselves rather than trusting the caller:
    // post-test attempts always lock on submission, pre-test attempts never
    // lock, regardless of what the caller set on the QuizAttempt.
    final normalizedAttempt = attempt.copyWith(locked: !isPreTest);

    final updated = student.copyWith(
      quizAttempts: [...student.quizAttempts, normalizedAttempt],
      completedQuizIds: {...student.completedQuizIds, attempt.quizId}.toList(),
      scores: isPreTest
          ? student.scores
          : {...student.scores, subject.firestoreValue: attempt.score},
      completedLessonIds:
          (!isPreTest && parsed.isBuiltin && parsed.lessonId != null)
          ? {...student.completedLessonIds, parsed.lessonId!}.toList()
          : student.completedLessonIds,
    );

    await _studentDoc(studentId).set(updated.toJson());

    // Backup write to the quizAttempts subcollection (denormalized read
    // copy — the embedded array on the student doc above is the source of
    // truth `checkEligibility` reads from).
    await _studentDoc(studentId)
        .collection('quizAttempts')
        .doc(normalizedAttempt.id)
        .set(normalizedAttempt.toJson());
  }

  /// Flips the latest attempt for [quizId] from locked to unlocked, allowing
  /// one retake. Called by `AccessCodeService` when a valid retake code is
  /// redeemed (PROJECT_FLOW.md Part 9.1, code type 3).
  Future<void> unlockRetake(String studentId, String quizId) async {
    final snapshot = await _studentDoc(studentId).get();
    final data = snapshot.data();
    if (data == null) return;
    final student = StudentRecord.fromJson(data);

    final attempts =
        student.quizAttempts.where((a) => a.quizId == quizId).toList()..sort(
          (a, b) => DateTime.parse(
            b.timestamp,
          ).compareTo(DateTime.parse(a.timestamp)),
        );
    if (attempts.isEmpty || !attempts.first.locked) return;

    final latestId = attempts.first.id;
    final updatedAttempts = student.quizAttempts
        .map((a) => a.id == latestId ? a.copyWith(locked: false) : a)
        .toList();

    await _studentDoc(
      studentId,
    ).set(student.copyWith(quizAttempts: updatedAttempts).toJson());
  }
}
