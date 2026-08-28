import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/lesson_repository.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/features/student/app/student_providers.dart';
import 'package:ar_science_explorer/features/student/home/home_providers.dart';
import 'package:ar_science_explorer/features/student/learn/learn_providers.dart';
import 'package:ar_science_explorer/features/student/progress/progress_providers.dart';

void main() {
  test('studentProviderOverridesFor wires Home/Learn/Progress to a real student stream', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    await studentRepo.saveStudent(StudentRecord(
      id: '111111', name: 'Juan Dela Cruz', studentId: '111111', grade: '7', section: 'Rizal',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [], completedLabExperimentIds: const [],
      completedQuizIds: const [], unlockedLessonIds: const [], unlockedQuizIds: const [],
      quizAttempts: const [],
    ));

    final services = StudentServices(
      lessonRepository: LessonRepository(firestore: firestore),
      studentRepository: studentRepo,
      quizAttemptService: QuizAttemptService(firestore: firestore),
      accessCodeService: AccessCodeService(
        firestore: firestore,
        quizAttemptService: QuizAttemptService(firestore: firestore),
      ),
    );

    final container = ProviderContainer(
      overrides: studentProviderOverridesFor('111111', services: services),
    );
    addTearDown(container.dispose);

    final home = await container.read(homeViewModelProvider.future);
    expect(home.studentDisplayName, 'Juan');

    final learn = await container.read(learnViewModelProvider.future);
    expect(learn.cards, isNotEmpty);

    final progress = await container.read(progressViewModelProvider.future);
    expect(progress.subjectSections, hasLength(3));
  });
}
