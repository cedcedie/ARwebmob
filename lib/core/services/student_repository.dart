import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student_record.dart';

/// Firestore access for `/students/{studentId}` — the single source of
/// truth for a student's unlocked/completed lessons, quiz attempts, and
/// per-subject scores (PROJECT_FLOW.md Part 3.4). The document id is the
/// plain student id, not the Firebase Auth uid.
class StudentRepository {
  StudentRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection('students');

  Future<StudentRecord?> getStudent(String studentId) async {
    final snapshot = await _students.doc(studentId).get();
    final data = snapshot.data();
    if (data == null) return null;
    return StudentRecord.fromJson(data);
  }

  Future<void> saveStudent(StudentRecord student) {
    return _students.doc(student.studentId).set(student.toJson());
  }

  Stream<StudentRecord?> watchStudent(String studentId) {
    return _students.doc(studentId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return StudentRecord.fromJson(data);
    });
  }

  /// Streams the full student roster, filtering out archived students by
  /// default — teacher roster views should only see active students unless
  /// explicitly asked to include archived ones.
  Stream<List<StudentRecord>> watchAllStudents({bool includeArchived = false}) {
    return _students.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => StudentRecord.fromJson(doc.data()))
          .where((student) => includeArchived || !student.isArchived)
          .toList(),
    );
  }

  /// Creates a student doc at `/students/{student.studentId}`.
  ///
  /// Refuses to overwrite an existing student. `saveStudent` is a `.set()`,
  /// so without this check a teacher who retyped an existing ID — a typo,
  /// or re-adding someone they'd forgotten was archived — silently replaced
  /// that student's real record with a blank one: scores, completed and
  /// unlocked lessons, and every quiz attempt gone, under a toast saying
  /// "Student saved". `humanizeSubmitError` surfaces a StateError's message
  /// verbatim, so this reads correctly in the form.
  Future<void> createStudent(StudentRecord student) async {
    final existing = await _students.doc(student.studentId).get();
    if (existing.exists) {
      throw StateError(
        'A student with ID ${student.studentId} already exists. '
        'Use a different ID, or find them in the roster (turn on "Show '
        'archived" if you don\'t see them).',
      );
    }
    return saveStudent(student);
  }

  /// Hard-deletes a student document. Only used to roll back a *just
  /// created* roster row when provisioning that student's login fails —
  /// everyday removal is [archiveStudent], which preserves their history.
  Future<void> deleteStudent(String studentId) {
    return _students.doc(studentId).delete();
  }

  /// Soft-archives a student by setting `isArchived: true`, without touching
  /// any other field — `scores`, `completedLessonIds`, `unlockedLessonIds`,
  /// and `quizAttempts` must survive untouched, since Part 9/7's logic
  /// elsewhere depends on those lists never being silently reset.
  Future<void> archiveStudent(String studentId) {
    return _students.doc(studentId).update({'isArchived': true});
  }

  /// Resets every student's activity fields back to a brand-new-student
  /// state (matches `blankStudentRecord` in students_providers.dart) —
  /// scores, completed/unlocked lesson & quiz lists, and quiz attempts all
  /// clear. Name/id/grade/section/archived status are untouched. Applies to
  /// every student doc, including archived ones — this is an explicit,
  /// teacher-triggered "reset progress for all" action, not an incidental
  /// side effect, so there's no reason to carve out an exception.
  ///
  /// Uses batched writes (Firestore caps a single batch at 500 ops) so this
  /// scales past a single classroom's roster without extra plumbing.
  Future<void> resetAllProgress() async {
    final snapshot = await _students.get();
    const resetFields = {
      'scores': {'chemistry': null, 'biology': null, 'physics': null},
      'completedLessonIds': <String>[],
      'completedLabExperimentIds': <String>[],
      'completedQuizIds': <String>[],
      'unlockedLessonIds': <String>[],
      'unlockedQuizIds': <String>[],
      'quizAttempts': <Map<String, dynamic>>[],
    };

    const batchLimit = 500;
    for (var i = 0; i < snapshot.docs.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = snapshot.docs.skip(i).take(batchLimit);
      for (final doc in chunk) {
        batch.update(doc.reference, resetFields);
      }
      await batch.commit();
    }
  }
}
