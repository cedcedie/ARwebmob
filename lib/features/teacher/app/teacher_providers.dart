import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/access_code_issuance_service.dart';
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/quiz_attempt_service.dart';
import '../../../core/services/quiz_repository.dart';
import '../../../core/services/student_repository.dart';
import '../access_codes/access_codes_providers.dart';
import '../lessons/lessons_providers.dart';
import '../quizzes/quizzes_providers.dart';
import '../students/students_providers.dart';

/// Bundles every core/ service a teacher screen needs.
class TeacherServices {
  const TeacherServices({
    required this.lessonRepository,
    required this.quizRepository,
    required this.studentRepository,
    required this.accessCodeIssuanceService,
    required this.quizAttemptService,
  });

  final LessonRepository lessonRepository;
  final QuizRepository quizRepository;
  final StudentRepository studentRepository;
  final AccessCodeIssuanceService accessCodeIssuanceService;
  final QuizAttemptService quizAttemptService;
}

/// Every `ProviderScope` override the teacher screens need once services are
/// constructed at app startup.
List<Override> teacherProviderOverridesFor({required TeacherServices services}) {
  return [
    lessonsViewModelProvider.overrideWith(
      (ref) => buildLessonsViewModel(
        lessonRepository: services.lessonRepository,
        quizRepository: services.quizRepository,
      ),
    ),
    quizzesViewModelProvider.overrideWith(
      (ref) => buildQuizzesViewModel(
        lessonRepository: services.lessonRepository,
        quizRepository: services.quizRepository,
      ),
    ),
    studentsViewModelProvider.overrideWith((ref) {
      final includeArchived = ref.watch(studentsIncludeArchivedProvider);
      return buildStudentsViewModel(
        studentRepository: services.studentRepository,
        includeArchived: includeArchived,
        onToggleIncludeArchived: (value) =>
            ref.read(studentsIncludeArchivedProvider.notifier).state = value,
      );
    }),
    accessCodesViewModelProvider.overrideWith(
      (ref) => buildAccessCodesViewModel(
        issuanceService: services.accessCodeIssuanceService,
        studentRepository: services.studentRepository,
        quizAttemptService: services.quizAttemptService,
      ),
    ),
  ];
}

/// Convenience factory for tests and app startup.
TeacherServices teacherServicesFromFirestore(FirebaseFirestore firestore) {
  final quizAttemptService = QuizAttemptService(firestore: firestore);
  return TeacherServices(
    lessonRepository: LessonRepository(firestore: firestore),
    quizRepository: QuizRepository(firestore: firestore),
    studentRepository: StudentRepository(firestore: firestore),
    quizAttemptService: quizAttemptService,
    accessCodeIssuanceService: AccessCodeIssuanceService(
      firestore: firestore,
      quizAttemptService: quizAttemptService,
    ),
  );
}
