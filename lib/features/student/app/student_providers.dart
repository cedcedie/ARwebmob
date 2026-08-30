// lib/features/student/app/student_providers.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/data/curriculum_data.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/subject_key.dart';
import '../../../core/services/access_code_service.dart';
import '../../../core/services/auth_service.dart' show isStudentEmail;
import '../../../core/models/teacher_quiz.dart';
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/quiz_attempt_service.dart';
import '../../../core/services/quiz_repository.dart';
import '../../../core/services/student_repository.dart';
import '../ar_lab/ar_lab_providers.dart';
import '../auth/student_auth_providers.dart' show studentAuthRepositoryProvider;
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
    required this.quizRepository,
  });

  final LessonRepository lessonRepository;
  final StudentRepository studentRepository;
  final QuizAttemptService quizAttemptService;
  final AccessCodeService accessCodeService;
  final QuizRepository quizRepository;
}

/// The raw Firebase Auth user stream `currentStudentIdProvider` maps over.
/// Pulled out as its own overridable provider (rather than
/// `currentStudentIdProvider` reaching for `FirebaseAuth.instance` inline)
/// purely so tests can drive `currentStudentIdProvider`'s own archive-check
/// logic below with a fake user stream, without needing a live Firebase
/// app — the archive-check race this exists to close can only be proven
/// closed by exercising this provider's real mapping logic, not by
/// overriding `currentStudentIdProvider` wholesale as most other tests do.
final studentAuthStateChangesProvider = Provider<Stream<User?>>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// The signed-in student's id, derived from their Firebase Auth email
/// (Phase 1's student email convention: `{digits}@arscience.school`). Null
/// while signed out, signed in as a teacher, or — critically — signed in as
/// a student whose Firestore record has `isArchived == true`.
///
/// This is the single choke point `main.dart` reads to decide whether to
/// mount the real student app shell, so the archive check has to live here,
/// not only in `StudentAuthViewModel.submit()`. Firebase's own auth-state
/// stream flips to "signed in" the instant `signInWithEmailAndPassword`
/// resolves, which is *before* the view model's separate, awaited
/// `getStudent`/`isArchived`/`signOut()` sequence completes. Without this
/// provider itself checking `isArchived`, that gap is a real window (under
/// real network latency) where an archived student's app shell renders
/// before being kicked back out a moment later. Re-checking `isArchived`
/// here — using the same `StudentRepository` the view model uses, so there
/// is one authoritative source for "is this student archived", not two
/// copies of the check — means an archived student's id never resolves to
/// a non-null value in the first place, so the shell is never reachable at
/// all, not merely reachable-then-reverted.
final currentStudentIdProvider = StreamProvider<String?>((ref) {
  final studentRepository = ref.watch(studentAuthRepositoryProvider);
  final authStateChanges = ref.watch(studentAuthStateChangesProvider);
  return authStateChanges.asyncMap((user) async {
    final email = user?.email;
    if (email == null || !isStudentEmail(email)) return null;
    final studentId = email.split('@').first;
    final record = await studentRepository.getStudent(studentId);
    if (record != null && record.isArchived) return null;
    return studentId;
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

/// One-shot fetch of a single teacher-authored quiz by id, keyed so router.dart
/// can resolve a `TeacherLesson.linkedQuizId` post-test source. Kept as a
/// `.family` provider (like `arLabViewModelProvider`) rather than a bare
/// `services.quizRepository.fetchQuizById` call inline in the router, so
/// Riverpod caches/dedupes the fetch per quizId instead of re-fetching on
/// every rebuild of the quiz route.
final teacherQuizByIdProvider = FutureProvider.autoDispose
    .family<TeacherQuiz?, String>((ref, quizId) {
      throw UnimplementedError(
        'teacherQuizByIdProvider must be overridden at app startup — see '
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
      (ref) => services.lessonRepository.watchTeacherLessons().map(
        (teacherLessons) =>
            services.lessonRepository.mergedLessons(teacherLessons),
      ),
    ),
    teacherQuizByIdProvider.overrideWith(
      (ref, quizId) => services.quizRepository.fetchQuizById(quizId),
    ),
    homeViewModelProvider.overrideWith(
      (ref) => buildHomeViewModel(
        studentId: studentId,
        studentRepository: services.studentRepository,
        accessCodeService: services.accessCodeService,
        orderedLessons: kBuiltInLessons,
      ),
    ),
    learnViewModelProvider.overrideWith((ref) {
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
        onSelectSubject: (subject) =>
            ref.read(activeLearnSubjectProvider.notifier).state = subject,
      );
    }),
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
      postTestLessonIds: kPostTestQuestionsByLesson.keys.toSet(),
      onStartPreTest: onStartPreTest,
      onStartPostTest: onStartPostTest,
    ),
  );
}
