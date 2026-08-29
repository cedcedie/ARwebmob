import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/services/access_code_service.dart';
import 'package:ar_science_explorer/core/services/lesson_repository.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/features/student/app/student_providers.dart';
import 'package:ar_science_explorer/features/student/ar_lab/ar_lab_providers.dart';
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

  test('arLabOverrideFor resolves a real stream, not a TypeError', () async {
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

    var preTestStarted = false;
    var postTestStarted = false;

    final container = ProviderContainer(
      overrides: [
        arLabOverrideFor(
          '111111',
          'q1w1',
          services: services,
          onStartPreTest: () => preTestStarted = true,
          onStartPostTest: () => postTestStarted = true,
        ),
      ],
    );
    addTearDown(container.dispose);

    final arLab = await container.read(arLabViewModelProvider('q1w1').future);

    expect(arLab.lessonId, 'q1w1');
    expect(arLab.isRead, false);

    arLab.onStartPreTest();
    arLab.onStartPostTest();
    expect(preTestStarted, true);
    expect(postTestStarted, true);
  });

  test('C1: switching activeLearnSubjectProvider changes which lessons learnViewModelProvider emits',
      () async {
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

    final chemistryLearn = await container.read(learnViewModelProvider.future);
    expect(chemistryLearn.activeSubject, SubjectKey.chemistry);
    expect(chemistryLearn.cards, isNotEmpty);
    expect(chemistryLearn.cards.every((c) => c.lessonId.startsWith('q1w')), true);

    // This is exactly what LearnScreen's TabBar.onTap does via
    // LearnViewModel.onSelectSubject — proving the real provider path, not
    // an injected view model, actually reacts to a subject switch.
    chemistryLearn.onSelectSubject(SubjectKey.biology);

    final biologyLearn = await container.read(learnViewModelProvider.future);
    expect(biologyLearn.activeSubject, SubjectKey.biology);
    expect(biologyLearn.cards, isNotEmpty);
    expect(biologyLearn.cards.every((c) => c.lessonId.startsWith('q2w')), true);
    expect(biologyLearn.cards.map((c) => c.lessonId), isNot(chemistryLearn.cards.map((c) => c.lessonId)));
  });

  test('C4: arLabOverrideFor resolves a teacher-authored lesson id without throwing', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    await studentRepo.saveStudent(StudentRecord(
      id: '111111', name: 'Juan Dela Cruz', studentId: '111111', grade: '7', section: 'Rizal',
      scores: const {'chemistry': null, 'biology': null, 'physics': null},
      completedLessonIds: const [], completedLabExperimentIds: const [],
      completedQuizIds: const [], unlockedLessonIds: const [], unlockedQuizIds: const [],
      quizAttempts: const [],
    ));
    await firestore.collection('lessons').doc('teacher-extra-1').set({
      'id': 'teacher-extra-1',
      'title': 'Extra Credit: Volcanoes',
      'subject': 'physics',
    });

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
      overrides: [
        arLabOverrideFor(
          '111111',
          'teacher-extra-1',
          services: services,
          onStartPreTest: () {},
          onStartPostTest: () {},
        ),
      ],
    );
    addTearDown(container.dispose);

    // Must not throw StateError('No element') — the old
    // kBuiltInLessons.firstWhere lookup with no orElse would have.
    final arLab = await container.read(arLabViewModelProvider('teacher-extra-1').future);

    expect(arLab.lessonId, 'teacher-extra-1');
    expect(arLab.title, 'Extra Credit: Volcanoes');
    expect(arLab.hasPreTest, false);
  });
}
