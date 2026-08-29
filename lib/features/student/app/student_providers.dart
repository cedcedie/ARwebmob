// lib/features/student/app/student_providers.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/data/curriculum_data.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/subject_key.dart';
import '../../../core/services/access_code_service.dart';
import '../../../core/services/auth_service.dart' show isStudentEmail;
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/quiz_attempt_service.dart';
import '../../../core/services/student_repository.dart';
import '../ar_lab/ar_lab_providers.dart';
import '../home/home_providers.dart';
import '../learn/learn_providers.dart';
import '../progress/progress_providers.dart';

/// Bundles every core/ service a student screen needs, so app startup only
/// has to construct these once (each takes the same FirebaseFirestore
/// instance) and pass the bundle around.
class StudentServices {
  const StudentServices({
    required this.lessonRepository,
    required this.studentRepository,
    required this.quizAttemptService,
    required this.accessCodeService,
  });

  final LessonRepository lessonRepository;
  final StudentRepository studentRepository;
  final QuizAttemptService quizAttemptService;
  final AccessCodeService accessCodeService;
}

/// The signed-in student's id, derived from their Firebase Auth email
/// (Phase 1's student email convention: `{digits}@arscience.school`). Null
/// while signed out or signed in as a teacher.
final currentStudentIdProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) {
    final email = user?.email;
    if (email == null || !isStudentEmail(email)) return null;
    return email.split('@').first;
  });
});

/// The merged (built-in + teacher-authored) lesson list, kept as a provider
/// so router.dart can resolve a lesson id without a synchronous
/// `kBuiltInLessons.firstWhere` lookup — which throws for any
/// teacher-authored lesson id, since those only exist in Firestore
/// (`LessonRepository.mergedLessons`), never in `kBuiltInLessons`.
final mergedLessonsProvider = StreamProvider.autoDispose<List<Lesson>>((ref) {
  throw UnimplementedError(
    'mergedLessonsProvider must be overridden at app startup — see '
    'studentProviderOverridesFor.',
  );
});

/// Every `ProviderScope` override the student screens need once a signed-in
/// student id is known. Closes out the "wired at app startup" comments left
/// in home_providers.dart, learn_providers.dart, progress_providers.dart,
/// and lesson_detail_providers.dart.
List<Override> studentProviderOverridesFor(
  String studentId, {
  required StudentServices services,
  SubjectKey initialLearnSubject = SubjectKey.chemistry,
}) {
  return [
    activeLearnSubjectProvider.overrideWith((ref) => initialLearnSubject),
    mergedLessonsProvider.overrideWith(
      (ref) => services.lessonRepository
          .watchTeacherLessons()
          .map((teacherLessons) => services.lessonRepository.mergedLessons(teacherLessons)),
    ),
    homeViewModelProvider.overrideWith(
      (ref) => buildHomeViewModel(
        studentId: studentId,
        studentRepository: services.studentRepository,
        accessCodeService: services.accessCodeService,
        orderedLessons: kBuiltInLessons,
      ),
    ),
    learnViewModelProvider.overrideWith(
      (ref) {
        // Watching this provider is what makes tapping a Learn subject tab
        // actually change which lessons render — see
        // learn_providers.dart's `activeLearnSubjectProvider` doc comment.
        final activeSubject = ref.watch(activeLearnSubjectProvider);
        return buildLearnViewModel(
          studentId: studentId,
          initialSubject: activeSubject,
          lessonRepository: services.lessonRepository,
          studentRepository: services.studentRepository,
          accessCodeService: services.accessCodeService,
          preTestLessonIds: kPreTestQuestionsByLesson.keys.toSet(),
          onSelectSubject: (subject) => ref.read(activeLearnSubjectProvider.notifier).state = subject,
        );
      },
    ),
    progressViewModelProvider.overrideWith(
      (ref) => buildProgressViewModel(
        studentId: studentId,
        lessonRepository: services.lessonRepository,
        studentRepository: services.studentRepository,
      ),
    ),
  ];
}

/// Per-lesson override for `arLabViewModelProvider` — a `.family` provider,
/// so it's overridden per lessonId at the call site (the route builder in
/// router.dart), not bundled into the list above.
Override arLabOverrideFor(
  String studentId,
  String lessonId, {
  required StudentServices services,
  required void Function() onStartPreTest,
  required void Function() onStartPostTest,
}) {
  return arLabViewModelProvider(lessonId).overrideWith(
    (ref) => buildArLabViewModel(
      studentId: studentId,
      lessonId: lessonId,
      lessonRepository: services.lessonRepository,
      studentRepository: services.studentRepository,
      quizAttemptService: services.quizAttemptService,
      accessCodeService: services.accessCodeService,
      preTestLessonIds: kPreTestQuestionsByLesson.keys.toSet(),
      onStartPreTest: onStartPreTest,
      onStartPostTest: onStartPostTest,
    ),
  );
}
