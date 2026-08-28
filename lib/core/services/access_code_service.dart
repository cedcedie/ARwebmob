import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quiz_phase.dart';
import '../models/student_record.dart';
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
  })  : _firestore = firestore,
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

    final targetStudentId = data['targetStudentId'] as String?;
    if (targetStudentId != null && targetStudentId != studentId) {
      return (success: false, message: 'Code "$code" is assigned to a different student.');
    }
    final usedBy = (data['usedByStudentIds'] as List?)?.cast<String>() ?? const [];
    if (usedBy.contains(studentId)) {
      return (
        success: false,
        message: 'Code "$code" has already been used. Ask your teacher for a new one.',
      );
    }

    final type = data['type'] as String? ?? 'subject';
    final lessonIds = (data['lessonIds'] as List?)?.cast<String>();
    final subjects = (data['subjects'] as List?)?.cast<String>();
    final codeTargetId = data['targetId'] as String?;
    final isUsed = data['isUsed'] as bool? ?? false;

    // ── 2. Subject code with an explicit lesson-id list ──
    if (type == 'subject' && lessonIds != null && lessonIds.isNotEmpty) {
      if (targetType != AccessCodeTarget.lesson || targetId == null || !lessonIds.contains(targetId)) {
        return (success: false, message: 'Code "$code" isn\'t valid for this lesson.');
      }
      await _unlockLessons(studentId, lessonIds);
      await _trackUsage(code, studentId);
      return (success: true, message: 'Lesson unlocked successfully!');
    }

    // ── 3. Full-subject code, no explicit lesson list ──
    if (type == 'subject' && subjects != null && subjects.isNotEmpty) {
      await _trackUsage(code, studentId);
      return (success: true, message: 'Subject unlocked successfully!');
    }

    // ── 4. First-time test-unlock code (type 'lesson', redeemed against a quiz) ──
    if (type == 'lesson' && targetType == AccessCodeTarget.quiz) {
      if (codeTargetId != null && codeTargetId != targetId) {
        return (success: false, message: 'Code "$code" isn\'t valid for this test.');
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
          message: 'Code "$code" has already been used. Ask your teacher for a new one.',
        );
      }
      if (codeTargetId != null && codeTargetId != targetId) {
        return (success: false, message: 'Code "$code" isn\'t valid for this test.');
      }
      if (targetId == null) {
        return (success: false, message: 'Code "$code" isn\'t valid for this test.');
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
        return (success: false, message: 'Code "$code" isn\'t valid for this lesson.');
      }
      if (targetId != null) {
        await _unlockLessons(studentId, [targetId]);
      }
      await _trackUsage(code, studentId);
      return (success: true, message: 'Lesson unlocked successfully!');
    }

    return (
      success: false,
      message: 'Code "$code" isn\'t for this ${targetType == AccessCodeTarget.quiz ? 'test' : 'lesson'}.',
    );
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findQuizUnlockCode(
    String code,
    String studentId,
    String quizId,
  ) async {
    final snapshot = await _firestore
        .collection('quizUnlockCodes')
        .where('code', isEqualTo: code)
        .get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final docStudentId = data['studentId'] as String?;
      final docQuizId = data['quizId'] as String?;
      final used = data['isUsed'] as bool? ?? false;
      final studentMatches = docStudentId == null || docStudentId == studentId;
      if (studentMatches && docQuizId == quizId && !used) return doc;
    }
    return null;
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
    final existing = (snapshot.data()?['usedByStudentIds'] as List?)?.cast<String>() ?? const [];
    if (existing.contains(studentId)) return;
    await codeDoc.update({
      'usedByStudentIds': [...existing, studentId],
    });
  }
}
