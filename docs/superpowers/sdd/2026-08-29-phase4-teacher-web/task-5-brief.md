# Task 5 brief — `AccessCodeIssuanceService` (the three code types)

(Copied verbatim from `docs/superpowers/plans/2026-08-29-phase4-teacher-web.md`, Task 5.)

This is the highest-risk task in the phase: it must produce documents
matching exactly what `AccessCodeService.redeem` (Phase 2,
`lib/core/services/access_code_service.dart`) already reads, or issued
codes will silently fail to redeem. Every test in this task should
round-trip through the real `redeem()` method, not just assert on the
written Firestore doc shape in isolation.

**Files:**
- Create: `lib/core/services/access_code_issuance_service.dart`
- Test: `test/core/services/access_code_issuance_service_test.dart`

**Interfaces:**
- Produces: `AccessCodeIssuanceService`, consumed by Task 12 (access codes
  screen).
- Consumes: `AccessCodeService` (Phase 2, for round-trip tests only — the
  issuance service itself writes directly to Firestore, it does not call
  `redeem`), `QuizAttemptService`/`StudentRepository` (for the retake
  eligibility guard), `quiz_id.dart`'s `builtinQuizId`.

**Exact schemas to write** (reverse-engineered from `redeem()`'s reads —
restated here so this task's implementer doesn't have to re-read that file
line by line):

`/unlockCodes/{code}` (doc id **is** the code string, uppercase):
```
{
  "type": "subject" | "lesson",       // "quiz" type also read by redeem()
                                        // step 5, but this service issues
                                        // retake codes via /quizUnlockCodes
                                        // instead (cleaner typed model,
                                        // see Global Constraints) — do not
                                        // also implement the "quiz" /unlockCodes
                                        // path unless a later task finds a
                                        // concrete reason redeem() step 5 vs
                                        // step 1 matters for this app.
  "subjects": ["chemistry"],           // full-subject code (type: subject, no lessonIds)
  "lessonIds": ["q1w1", "q1w2"],       // subject code w/ explicit lesson list (type: subject)
  "targetId": "q1w3",                  // single-lesson code (type: lesson)
  "targetStudentId": "123456",         // present only for a student-targeted code
  "usedByStudentIds": [],              // always start empty
  "isUsed": false                      // unused by redeem() for type != "quiz", but
                                        // write it anyway for schema consistency
}
```

`/quizUnlockCodes/{autoId}` (auto-generated doc id — matches existing
`QuizUnlockCode` model exactly, use its own `toJson()`):
```dart
QuizUnlockCode(
  id: ..., // Firestore auto-id
  quizId: builtinQuizId(lessonId, QuizPhase.post), // retakes are always post-test (Part 7.1)
  studentId: studentId,
  code: generatedCode,
  generatedAt: DateTime.now().toIso8601String(),
  isUsed: false,
)
```

**Proposed public API:**

```dart
class AccessCodeIssuanceService {
  AccessCodeIssuanceService({
    required FirebaseFirestore firestore,
    required QuizAttemptService quizAttemptService,
  });

  /// Type 1 — subject/lesson-wide, untargeted. lessonIds null/empty = whole subject.
  Future<String> issueSubjectCode({
    required List<String> subjects,
    List<String>? lessonIds,
    String? customCode, // teacher may want a memorable code; else auto-generate
  });

  /// Type 2 — single lesson, targeted to one student.
  Future<String> issueLessonCode({
    required String lessonId,
    required String studentId,
    String? customCode,
  });

  /// Type 3 — quiz retake, targeted, one-time-use. Throws
  /// StateError/returns a typed failure if the student has no recorded
  /// attempt yet on this lesson's post-test (Part 9.1's hard requirement).
  Future<String> issueQuizRetakeCode({
    required String lessonId,
    required String studentId,
  });

  Stream<List<Map<String, dynamic>>> watchIssuedUnlockCodes(); // for the codes table
  Stream<List<QuizUnlockCode>> watchIssuedRetakeCodes();
}
```

- [ ] **Step 1: Write failing tests**, each as a full round-trip:
  1. `issueSubjectCode` (whole-subject variant) → call the real
     `AccessCodeService.redeem` with a student not in any target list →
     succeeds, matches redeem() step 3's success message.
  2. `issueSubjectCode` with `lessonIds` → `redeem()` targeting a lesson
     in the list succeeds (step 2); targeting a lesson NOT in the list
     fails with the "isn't valid for this lesson" message.
  3. `issueLessonCode` → `redeem()` from the targeted student succeeds
     (step 6); from a different student fails with the
     "assigned to a different student" message (this is the
     `targetStudentId` mismatch path already in `redeem()`).
  4. `issueQuizRetakeCode` when the student has **zero** attempts on that
     lesson's post-test → throws/returns failure, **no document written**.
  5. `issueQuizRetakeCode` when the student has ≥1 recorded post-test
     attempt → succeeds, and the resulting code round-trips through
     `redeem()`'s step 1 (`AccessCodeTarget.quiz`, `targetId: lessonId`)
     successfully, and a second `redeem()` call with the same code fails
     (already used).
  6. A duplicate custom code (teacher types a code that already exists in
     `/unlockCodes`) is rejected or auto-suffixed — decide one behavior and
     test it; don't leave this undefined.
- [ ] **Step 2:** Run `flutter test test/core/services/access_code_issuance_service_test.dart`
  — expect FAIL (class doesn't exist).
- [ ] **Step 3:** Implement, including the random-code generator (e.g. 6
  uppercase alphanumeric characters, collision-checked against
  `/unlockCodes` before writing — reuse the same generator for the
  `/quizUnlockCodes` `code` field for a consistent look).
- [ ] **Step 4:** Run again — expect PASS, all 6+ cases green.
- [ ] **Step 5:** Run the *existing* `access_code_service_test.dart` too —
  confirm zero changes needed there; this task must not modify `redeem()`
  (Global Constraints).
- [ ] **Step 6:** Run `flutter analyze`.
- [ ] **Step 7:** Commit: `feat(teacher): add AccessCodeIssuanceService for the 3 code types`.
