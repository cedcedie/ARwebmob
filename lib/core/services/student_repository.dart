import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student_record.dart';

/// Firestore access for `/students/{studentId}` — the single source of
/// truth for a student's unlocked/completed lessons, quiz attempts, and
/// per-subject scores (PROJECT_FLOW.md Part 3.4). The document id is the
/// plain student id, not the Firebase Auth uid.
class StudentRepository {
  StudentRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

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

  /// Creates (or overwrites) a student doc at `/students/{student.studentId}`.
  Future<void> createStudent(StudentRecord student) {
    return saveStudent(student);
  }

  /// Soft-archives a student by setting `isArchived: true`, without touching
  /// any other field — `scores`, `completedLessonIds`, `unlockedLessonIds`,
  /// and `quizAttempts` must survive untouched, since Part 9/7's logic
  /// elsewhere depends on those lists never being silently reset.
  Future<void> archiveStudent(String studentId) {
    return _students.doc(studentId).update({'isArchived': true});
  }
}
