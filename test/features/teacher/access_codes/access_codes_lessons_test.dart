import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/teacher_lesson.dart';
import 'package:ar_science_explorer/core/services/access_code_issuance_service.dart';
import 'package:ar_science_explorer/core/services/lesson_repository.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/features/teacher/access_codes/access_codes_providers.dart';

void main() {
  test('a lesson a teacher adds appears in the access-code lesson list', () async {
    final firestore = FakeFirebaseFirestore();
    final lessonRepository = LessonRepository(firestore: firestore);
    final quizAttempts = QuizAttemptService(firestore: firestore);

    final stream = buildAccessCodesViewModel(
      issuanceService: AccessCodeIssuanceService(
        firestore: firestore,
        quizAttemptService: quizAttempts,
      ),
      studentRepository: StudentRepository(firestore: firestore),
      quizAttemptService: quizAttempts,
      lessonRepository: lessonRepository,
    );

    final beforeAndAfter = <List<String>>[];
    final sub = stream.listen(
      (vm) => beforeAndAfter.add(vm.lessons.map((l) => l.id).toList()),
    );

    await pumpEventQueue();
    expect(beforeAndAfter.last, isNot(contains('teacher-1')));

    await lessonRepository.createLesson(
      const TeacherLesson(
        id: 'teacher-1',
        title: 'Q1W9',
        subject: SubjectKey.chemistry,
      ),
    );
    await pumpEventQueue();

    final ids = beforeAndAfter.last;
    expect(ids, contains('teacher-1'));
    // Sorted by name: the added "Q1W9" sits between q1w8 and q2w1.
    expect(ids.indexOf('teacher-1'), greaterThan(ids.indexOf('q1w8')));
    expect(ids.indexOf('teacher-1'), lessThan(ids.indexOf('q2w1')));
    await sub.cancel();
  });

  test('teacher lessons are labelled by title, built-ins by id', () {
    expect(
      lessonPickerLabel(
        LessonRepository(firestore: FakeFirebaseFirestore()).mergedLessons(
          const [
            TeacherLesson(
              id: 'teacher-9',
              title: 'Q1W9',
              subject: SubjectKey.chemistry,
            ),
          ],
        ).last,
      ),
      'Q1W9',
    );
  });
}
