// test/features/student/learn/learn_providers_test.dart
//
// Regression test for a real bug found during live device testing: a
// student redeeming an access code (which only updates their own Firestore
// doc) never saw the Learn screen reflect the unlock until navigating away
// and back. Root cause: buildLearnViewModel's stream only re-emitted when
// the teacher-lessons stream emitted, doing a one-time getStudent() fetch
// inside that callback -- a change to the student's own record never
// triggered a re-emission on its own. Fixed by combining both live streams
// (Rx.combineLatest2) so either source updating refreshes the view model.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/lesson_repository.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/features/student/learn/learn_providers.dart';

StudentRecord _blankStudent(String studentId) => StudentRecord(
  id: studentId,
  name: 'Test Student',
  studentId: studentId,
  grade: '10',
  section: 'A',
  scores: const {},
  completedLessonIds: const [],
  completedLabExperimentIds: const [],
  completedQuizIds: const [],
  unlockedLessonIds: const [],
  unlockedQuizIds: const [],
  quizAttempts: const [],
);

void main() {
  test('a change to the student\'s own doc (an unlock) re-emits the view model '
      'without the teacher-lessons stream changing at all', () async {
    final firestore = FakeFirebaseFirestore();
    final lessonRepository = LessonRepository(firestore: firestore);
    final studentRepository = StudentRepository(firestore: firestore);
    final quizAttemptService = QuizAttemptService(firestore: firestore);
    final accessCodeService = AccessCodeService(
      firestore: firestore,
      quizAttemptService: quizAttemptService,
    );
    const studentId = '100001';

    await firestore
        .collection('students')
        .doc(studentId)
        .set(_blankStudent(studentId).toJson());

    final stream = buildLearnViewModel(
      studentId: studentId,
      initialSubject: SubjectKey.chemistry,
      lessonRepository: lessonRepository,
      studentRepository: studentRepository,
      accessCodeService: accessCodeService,
      preTestLessonIds: const {},
      onSelectSubject: (_) {},
    );

    final emissions = <bool>[]; // tracks q1w5's isUnlocked per emission
    final subscription = stream.listen((vm) {
      final q1w5 = vm.cards.firstWhere((c) => c.lessonId == 'q1w5');
      emissions.add(q1w5.isUnlocked);
    });

    // First emission: locked, exactly like the built-in curriculum data
    // says (isUnlockedByDefault: false) and no unlockedLessonIds yet.
    await Future.delayed(Duration.zero);
    expect(emissions, [false]);

    // Simulate a successful code redemption -- the real path
    // (AccessCodeService._unlockLessons) does exactly this write to the
    // student's own doc, nothing to the lessons collection.
    final student = await studentRepository.getStudent(studentId);
    await firestore
        .collection('students')
        .doc(studentId)
        .set(student!.copyWith(unlockedLessonIds: const ['q1w5']).toJson());

    // The bug: with the old one-time getStudent() fetch, no second
    // emission would ever arrive here -- this await would time out if
    // the fix regressed.
    await Future.delayed(Duration.zero);
    expect(emissions, [false, true]);

    await subscription.cancel();
  });
}
