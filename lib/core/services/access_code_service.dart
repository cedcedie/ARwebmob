import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/curriculum_data.dart';
import '../models/quiz_phase.dart';
import '../models/student_record.dart';
import '../models/subject_key.dart';
import '../quiz_id.dart';
import 'quiz_attempt_service.dart';

/// What kind of thing an access code is being redeemed against. Mirrors the
/// retired app's `AccessCodeModal`'s `type: 'lesson' | 'quiz'` prop.
enum AccessCodeTarget { lesson, quiz }

/// Result of redeeming a code — always carries a student-displayable
/// message, success or failure (PROJECT_FLOW.md Part 9.3/9.4: never a
/// silent no-op, and a failure always echoes the exact code typed).
typedef AccessCodeResult = ({bool success, String message});

/// Implements PROJECT_FLOW.md Part 9 — the one access-code entry flow reused
/// everywhere a code is needed. Redemption only; code *issuance* (a teacher
/// generating a retake code) is Phase 4 (Teacher Web).
class AccessCodeService {
  AccessCodeService({
    required FirebaseFirestore firestore,
    required QuizAttemptService quizAttemptService,
  }) : _firestore = firestore,
       _quizAttemptService = quizAttemptService;

  final FirebaseFirestore _firestore;
  final QuizAttemptService _quizAttemptService;

  Future<AccessCodeResult> redeem({
    required String studentId,
    required String rawCode,
    String? targetId,
    AccessCodeTarget? targetType,
  }) async {
    final code = rawCode.trim().toUpperCase();
    final invalid = (
      success: false,
      message: 'Code "$code" isn\'t valid. Check with your teacher.',
    );
    if (code.isEmpty) return invalid;

    // ── 1. Auto-generated quiz-retake codes (/quizUnlockCodes) ──
    if (targetType == AccessCodeTarget.quiz && targetId != null) {
      final quizId = builtinQuizId(targetId, QuizPhase.post);
      final retakeMatch = await _findQuizUnlockCode(code, studentId, quizId);
      if (retakeMatch != null) {
        await retakeMatch.reference.update({
          'isUsed': true,
          'usedAt': DateTime.now().toIso8601String(),
        });
        await _quizAttemptService.unlockRetake(studentId, quizId);
        return (success: true, message: 'Test unlocked for retake!');
      }
    }

    // ── 2–6. /unlockCodes lookups ──
    final doc = await _firestore.collection('unlockCodes').doc(code).get();
    final data = doc.data();
    if (data == null) return invalid;

    // An archived code is a deliberately invalidated one — "reset progress
    // for all" archives every outstanding code (see
    // `AccessCodeIssuanceService.archiveAllCodes`), so a stale code handed
    // out before the reset must stop working. Without this check the
    // teacher UI's "archived" status was purely cosmetic and archived codes
    // still redeemed successfully.
    final isArchived = data['isArchived'] as bool? ?? false;
    if (isArchived) {
      return (
        success: false,
        message:
            'Code "$code" is no longer active. Ask your teacher for a new one.',
      );
    }

    final targetStudentId = data['targetStudentId'] as String?;
    if (targetStudentId != null && targetStudentId != studentId) {
      return (
        success: false,
        message: 'Code "$code" is assigned to a different student.',
      );
    }
    final usedBy =
        (data['usedByStudentIds'] as List?)?.cast<String>() ?? const [];
    if (usedBy.contains(studentId)) {
      return (
        success: false,
        message:
            'Code "$code" has already been used. Ask your teacher for a new one.',
      );
    }

    final type = data['type'] as String? ?? 'subject';
    final lessonIds = (data['lessonIds'] as List?)?.cast<String>();
    final subjects = (data['subjects'] as List?)?.cast<String>();
    final codeTargetId = data['targetId'] as String?;
    final isUsed = data['isUsed'] as bool? ?? false;

    // ── 2. Subject code with an explicit lesson-id list ──
    if (type == 'subject' && lessonIds != null && lessonIds.isNotEmpty) {
      if (targetType != AccessCodeTarget.lesson ||
          targetId == null ||
          !lessonIds.contains(targetId)) {
        return (
          success: false,
          message: 'Code "$code" isn\'t valid for this lesson.',
        );
      }
      await _unlockLessons(studentId, lessonIds);
      await _trackUsage(code, studentId);
      return (success: true, message: 'Lesson unlocked successfully!');
    }

    // ── 3. Full-subject code, no explicit lesson list ──
    if (type == 'subject' && subjects != null && subjects.isNotEmpty) {
      // This branch used to report success without unlocking anything: it
      // called _trackUsage and returned, never touching unlockedLessonIds.
      // The student saw "Subject unlocked successfully!", went to Learn,
      // and found every lesson still padlocked — and because the code was
      // now marked used, retyping it was rejected as already redeemed.
      final lessonIds = _lessonIdsForSubjects(subjects);
      if (lessonIds.isEmpty) {
        return (
          success: false,
          message:
              'Code "$code" isn\'t linked to any lessons yet. '
              'Ask your teacher to check it.',
        );
      }
      await _unlockLessons(studentId, lessonIds);
      await _trackUsage(code, studentId);
      return (success: true, message: 'Subject unlocked successfully!');
    }

    // ── 4. First-time test-unlock code (type 'lesson', redeemed against a quiz) ──
    if (type == 'lesson' && targetType == AccessCodeTarget.quiz) {
      if (codeTargetId != null && codeTargetId != targetId) {
        return (
          success: false,
          message: 'Code "$code" isn\'t valid for this test.',
        );
      }
      // No further gating action needed: QuizAttemptService already treats
      // a post-test's first attempt as free (Task 3). This code type is
      // kept for schema/UX compatibility with codes teachers may already
      // have issued as this type.
      await _trackUsage(code, studentId);
      return (success: true, message: 'Test unlocked successfully!');
    }

    // ── 5. Manually-created quiz-retake code (type 'quiz' in /unlockCodes) ──
    if (type == 'quiz' && targetType == AccessCodeTarget.quiz) {
      if (isUsed) {
        return (
          success: false,
          message:
              'Code "$code" has already been used. Ask your teacher for a new one.',
        );
      }
      if (codeTargetId != null && codeTargetId != targetId) {
        return (
          success: false,
          message: 'Code "$code" isn\'t valid for this test.',
        );
      }
      if (targetId == null) {
        return (
          success: false,
          message: 'Code "$code" isn\'t valid for this test.',
        );
      }
      final quizId = builtinQuizId(targetId, QuizPhase.post);
      await _quizAttemptService.unlockRetake(studentId, quizId);
      await doc.reference.update({'isUsed': true});
      await _trackUsage(code, studentId);
      return (success: true, message: 'Test unlocked for retake!');
    }

    // ── 6. Single specific-lesson code ──
    if (type == 'lesson' && targetType == AccessCodeTarget.lesson) {
      if (codeTargetId != null && codeTargetId != targetId) {
        return (
          success: false,
          message: 'Code "$code" isn\'t valid for this lesson.',
        );
      }
      if (targetId != null) {
        await _unlockLessons(studentId, [targetId]);
      }
      await _trackUsage(code, studentId);
      return (success: true, message: 'Lesson unlocked successfully!');
    }

    return (
      success: false,
      message:
          'Code "$code" isn\'t for this ${targetType == AccessCodeTarget.quiz ? 'test' : 'lesson'}.',
    );
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findQuizUnlockCode(
    String code,
    String studentId,
    String quizId,
  ) async {
    // Filtering on `studentId` as well as `code` is a security requirement,
    // not an optimization. Firestore evaluates a rule per matched document,
    // so `quizUnlockCodes`' read rule can only be narrowed to "rows
    // belonging to this student" if the query itself is already narrowed
    // that way — an unfiltered query would simply be denied. Before this,
    // the rule had to allow any signed-in user to list the collection,
    // which let a student read every retake code in the school and mark
    // other students' codes as used.
    final snapshot = await _firestore
        .collection('quizUnlockCodes')
        .where('studentId', isEqualTo: studentId)
        .where('code', isEqualTo: code)
        .get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final docQuizId = data['quizId'] as String?;
      final used = data['isUsed'] as bool? ?? false;
      // Same reasoning as the /unlockCodes archived check in redeem():
      // an archived retake code has been deliberately invalidated.
      final archived = data['isArchived'] as bool? ?? false;
      if (docQuizId == quizId && !used && !archived) return doc;
    }
    return null;
  }

  /// Every built-in lesson id belonging to any of [subjects] (the Firestore
  /// string values written by `AccessCodeIssuanceService.issueSubjectCode`).
  /// An unrecognized subject string is skipped rather than throwing, so one
  /// bad entry can't fail a code that also names valid subjects.
  List<String> _lessonIdsForSubjects(List<String> subjects) {
    final wanted = <SubjectKey>{};
    for (final raw in subjects) {
      try {
        wanted.add(SubjectKey.fromFirestore(raw));
      } on ArgumentError {
        continue;
      }
    }
    if (wanted.isEmpty) return const [];
    return [
      for (final lesson in kBuiltInLessons)
        if (wanted.contains(lesson.subject)) lesson.id,
    ];
  }

  Future<void> _unlockLessons(String studentId, List<String> lessonIds) async {
    final studentDoc = _firestore.collection('students').doc(studentId);
    final snapshot = await studentDoc.get();
    final data = snapshot.data();
    if (data == null) return;
    final student = StudentRecord.fromJson(data);
    final updated = {...student.unlockedLessonIds, ...lessonIds}.toList();
    await studentDoc.set(student.copyWith(unlockedLessonIds: updated).toJson());
  }

  Future<void> _trackUsage(String code, String studentId) async {
    final codeDoc = _firestore.collection('unlockCodes').doc(code);
    final snapshot = await codeDoc.get();
    final existing =
        (snapshot.data()?['usedByStudentIds'] as List?)?.cast<String>() ??
        const [];
    if (existing.contains(studentId)) return;
    await codeDoc.update({
      'usedByStudentIds': [...existing, studentId],
    });
  }
}
