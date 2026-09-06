import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quiz_phase.dart';
import '../models/quiz_unlock_code.dart';
import '../quiz_id.dart';
import 'quiz_attempt_service.dart';

const int _codeLength = 6;
// Excludes 0/O and 1/I -- a real bug found during live device testing: a
// teacher-issued code containing a zero was misread/mistyped as the letter
// O by a student, and the redemption failed with "isn't valid" (a correct,
// working rejection -- the codes genuinely differed -- but an entirely
// avoidable one). Codes are read off a screen or handwritten far more often
// than they're copy-pasted, so ambiguous characters are a real cost.
const String _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const int _maxGenerationAttempts = 10;

/// Implements PROJECT_FLOW.md Part 9's teacher-issuance side — the mirror
/// image of `AccessCodeService.redeem`. Writes directly to the same
/// `/unlockCodes` and `/quizUnlockCodes` collections `redeem()` reads; it
/// never calls `redeem()` itself. Every schema written here must exactly
/// match what `redeem()` expects (see `access_code_service.dart`).
class AccessCodeIssuanceService {
  AccessCodeIssuanceService({
    required FirebaseFirestore firestore,
    required QuizAttemptService quizAttemptService,
  }) : _firestore = firestore,
       _quizAttemptService = quizAttemptService;

  final FirebaseFirestore _firestore;
  final QuizAttemptService _quizAttemptService;
  final Random _random = Random.secure();

  CollectionReference<Map<String, dynamic>> get _unlockCodes =>
      _firestore.collection('unlockCodes');

  CollectionReference<Map<String, dynamic>> get _quizUnlockCodes =>
      _firestore.collection('quizUnlockCodes');

  /// Type 1 — subject/lesson-wide, untargeted. `lessonIds` null/empty means
  /// the whole subject (`redeem()` step 3); a non-empty list scopes the code
  /// to just those lessons (`redeem()` step 2).
  Future<String> issueSubjectCode({
    required List<String> subjects,
    List<String>? lessonIds,
    String? customCode,
  }) async {
    final code = await _resolveCode(customCode);
    final data = <String, dynamic>{
      'type': 'subject',
      'subjects': subjects,
      'usedByStudentIds': <String>[],
      'isUsed': false,
      // The teacher codes table reads this for its "Issued At" column. It
      // was never written before, so that column showed "—" for every
      // subject/lesson code (only auto-generated retake codes, which carry
      // their own `generatedAt`, ever displayed a real time).
      'createdAt': DateTime.now().toIso8601String(),
    };
    if (lessonIds != null && lessonIds.isNotEmpty) {
      data['lessonIds'] = lessonIds;
    }
    await _unlockCodes.doc(code).set(data);
    return code;
  }

  /// Type 2 — single lesson, targeted to one student (`redeem()` step 6).
  Future<String> issueLessonCode({
    required String lessonId,
    required String studentId,
    String? customCode,
  }) async {
    final code = await _resolveCode(customCode);
    await _unlockCodes.doc(code).set({
      'type': 'lesson',
      'targetId': lessonId,
      'targetStudentId': studentId,
      'usedByStudentIds': <String>[],
      'isUsed': false,
      // See issueSubjectCode — powers the codes table's "Issued At" column.
      'createdAt': DateTime.now().toIso8601String(),
    });
    return code;
  }

  /// Type 3 — quiz retake, targeted, one-time-use (`redeem()` step 1). Per
  /// PROJECT_FLOW.md Part 9.1's hard requirement, this throws a
  /// [StateError] (and writes nothing) if the student has no recorded
  /// attempt yet on this lesson's post-test.
  Future<String> issueQuizRetakeCode({
    required String lessonId,
    required String studentId,
  }) async {
    final quizId = builtinQuizId(lessonId, QuizPhase.post);
    final eligibility = await _quizAttemptService.checkEligibility(
      studentId,
      quizId,
    );
    if (eligibility.attemptCount < 1) {
      throw StateError(
        'Cannot issue a retake code: student $studentId has no recorded '
        'attempt yet on $quizId.',
      );
    }

    final code = await _resolveCode(null);
    final docRef = _quizUnlockCodes.doc();
    final quizUnlockCode = QuizUnlockCode(
      id: docRef.id,
      quizId: quizId,
      studentId: studentId,
      code: code,
      generatedAt: DateTime.now().toIso8601String(),
      isUsed: false,
    );
    await docRef.set(quizUnlockCode.toJson());
    return code;
  }

  /// Invalidates every outstanding code in both collections by setting
  /// `isArchived: true`, and reports how many docs it touched.
  ///
  /// Called by "reset progress for all" (client feedback, UAT): wiping every
  /// student's progress while leaving previously handed-out codes live left
  /// teachers with a pile of stale codes they couldn't tell apart from
  /// current ones. Archived codes are rejected at redemption by
  /// `AccessCodeService.redeem` and shown as "archived" in the codes table,
  /// so this is a genuine invalidation, not just a label. Archiving rather
  /// than deleting keeps the audit trail of what was issued.
  ///
  /// Batched (Firestore caps a batch at 500 ops) to scale past one
  /// classroom's worth of codes.
  Future<int> archiveAllCodes() async {
    var archived = 0;
    const batchLimit = 500;

    for (final collection in [_unlockCodes, _quizUnlockCodes]) {
      final snapshot = await collection.get();
      final live = snapshot.docs
          .where((doc) => (doc.data()['isArchived'] as bool? ?? false) == false)
          .toList();
      for (var i = 0; i < live.length; i += batchLimit) {
        final batch = _firestore.batch();
        for (final doc in live.skip(i).take(batchLimit)) {
          batch.update(doc.reference, {'isArchived': true});
        }
        await batch.commit();
      }
      archived += live.length;
    }

    return archived;
  }

  /// Permanently removes a subject/lesson code from `/unlockCodes`.
  ///
  /// Distinct from archiving on purpose. Archiving invalidates a code but
  /// keeps it in the table as a record of what was handed out; deleting is
  /// for codes that should never have existed — a typo, a test code, a
  /// batch issued to the wrong section — which otherwise accumulate in the
  /// table forever with no way to clear them.
  Future<void> deleteUnlockCode(String code) {
    return _unlockCodes.doc(code.trim().toUpperCase()).delete();
  }

  /// Permanently removes a retake code from `/quizUnlockCodes`.
  ///
  /// Keyed by document id, not by the code string: retake code documents
  /// use auto-generated ids and the code itself is only a field, so two
  /// codes could in principle collide on the string but never on the id.
  Future<void> deleteRetakeCode(String docId) {
    return _quizUnlockCodes.doc(docId).delete();
  }

  /// Streams `/unlockCodes` docs (subject + lesson codes) for the teacher's
  /// codes table, each map annotated with its doc id under `'id'`.
  Stream<List<Map<String, dynamic>>> watchIssuedUnlockCodes() {
    return _unlockCodes.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
          .toList(),
    );
  }

  /// Streams `/quizUnlockCodes` docs (retake codes) as typed models.
  Stream<List<QuizUnlockCode>> watchIssuedRetakeCodes() {
    return _quizUnlockCodes.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => QuizUnlockCode.fromJson(doc.data()))
          .toList(),
    );
  }

  /// Resolves the code to write to `/unlockCodes/{code}`. A teacher-supplied
  /// [customCode] that already exists is rejected outright (rather than
  /// silently auto-suffixed) so the teacher never ends up handing out a code
  /// different from the one they typed. An omitted [customCode] auto-generates
  /// a random 6-character code, retried on collision up to
  /// [_maxGenerationAttempts] times.
  Future<String> _resolveCode(String? customCode) async {
    if (customCode != null && customCode.trim().isNotEmpty) {
      final code = customCode.trim().toUpperCase();
      final existing = await _unlockCodes.doc(code).get();
      if (existing.exists) {
        throw StateError(
          'Code "$code" already exists. Choose a different code.',
        );
      }
      return code;
    }

    for (var attempt = 0; attempt < _maxGenerationAttempts; attempt++) {
      final candidate = _generateCode();
      final existing = await _unlockCodes.doc(candidate).get();
      if (!existing.exists) return candidate;
    }
    throw StateError(
      'Could not generate a unique access code after $_maxGenerationAttempts attempts.',
    );
  }

  String _generateCode() {
    return List.generate(
      _codeLength,
      (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
    ).join();
  }
}
