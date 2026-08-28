import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';

StudentRecord _sampleStudent() => StudentRecord.fromJson(const {
      'id': '123456',
      'studentId': '123456',
      'name': 'Juan Dela Cruz',
      'grade': '7',
      'section': 'Rizal',
      'scores': {'chemistry': 85, 'biology': null, 'physics': null},
      'completedLessonIds': ['q1w1'],
      'completedLabExperimentIds': <String>[],
      'completedQuizIds': <String>[],
      'unlockedLessonIds': ['q1w1', 'q1w2'],
      'unlockedQuizIds': <String>[],
      'quizAttempts': <Map<String, dynamic>>[],
      'isArchived': false,
    });

void main() {
  test('getStudent returns null when the document does not exist', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = StudentRepository(firestore: firestore);

    final result = await repo.getStudent('nonexistent');

    expect(result, isNull);
  });

  test('saveStudent writes to /students/{studentId}, then getStudent reads it back', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = StudentRepository(firestore: firestore);
    final student = _sampleStudent();

    await repo.saveStudent(student);
    final result = await repo.getStudent('123456');

    expect(result, isNotNull);
    expect(result!.name, 'Juan Dela Cruz');
    expect(result.completedLessonIds, ['q1w1']);

    // Confirm the document id is the plain studentId, not a generated id.
    final rawDoc = await firestore.collection('students').doc('123456').get();
    expect(rawDoc.exists, true);
  });

  test('watchStudent streams updates as the document changes', () async {
    // Note: this keeps ONE subscription open across both the initial value
    // and the update, rather than doing `stream.first` followed by a fresh
    // `stream.firstWhere(...)` on the same Stream instance. fake_cloud_firestore
    // ^3.1.0's doc().snapshots() replays a stale cached value when the same
    // Stream object is relistened after its subscription is cancelled (i.e.
    // after `.first` completes) — a package quirk, not something
    // StudentRepository controls. Real Firestore's snapshots() doesn't have
    // this issue, but a single long-lived subscription is also the pattern
    // real screens use, so this is the more representative test anyway.
    final firestore = FakeFirebaseFirestore();
    final repo = StudentRepository(firestore: firestore);
    final student = _sampleStudent();
    await repo.saveStudent(student);

    final events = <StudentRecord?>[];
    final subscription = repo.watchStudent('123456').listen(events.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    expect(events, isNotEmpty);
    expect(events.first?.name, 'Juan Dela Cruz');

    await firestore
        .collection('students')
        .doc('123456')
        .update({'name': 'Juan Dela Cruz Jr.'});
    await pumpEventQueue();

    expect(events.last?.name, 'Juan Dela Cruz Jr.');
  });
}
