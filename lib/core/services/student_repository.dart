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
}
