import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/data/curriculum_data.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/subject_key.dart';
import '../../../core/models/teacher_lesson.dart';
import '../../../core/models/teacher_quiz.dart';
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/quiz_repository.dart';

/// One row in the teacher lessons table — built-in curriculum or Firestore doc.
class DisplayLesson {
  const DisplayLesson({
    required this.lesson,
    required this.isBuiltIn,
    this.teacherLesson,
  });

  final Lesson lesson;
  final bool isBuiltIn;
  final TeacherLesson? teacherLesson;
}

class LessonsViewModel {
  const LessonsViewModel({
    required this.rows,
    required this.quizOptions,
    required this.onCreateLesson,
    required this.onUpdateLesson,
    required this.onArchiveLesson,
    required this.fetchLessonById,
  });

  final List<DisplayLesson> rows;
  final List<TeacherQuiz> quizOptions;
  final Future<void> Function(TeacherLesson lesson) onCreateLesson;
  final Future<void> Function(TeacherLesson lesson) onUpdateLesson;
  final Future<void> Function(String lessonId) onArchiveLesson;

  /// Re-fetches a single lesson doc's current Firestore state — passed to
  /// `LessonForm` so it can check for an already-completed server-side
  /// content conversion right before submit, instead of blindly
  /// overwriting it with stale local upload state (Fix 5).
  final Future<TeacherLesson?> Function(String lessonId) fetchLessonById;
}

final lessonsViewModelProvider = StreamProvider.autoDispose<LessonsViewModel>((ref) {
  throw UnimplementedError(
    'lessonsViewModelProvider must be overridden at app startup — see '
    'teacherProviderOverridesFor.',
  );
});

Stream<LessonsViewModel> buildLessonsViewModel({
  required LessonRepository lessonRepository,
  required QuizRepository quizRepository,
}) {
  return lessonRepository.watchTeacherLessons().asyncMap((teacherLessons) async {
    final merged = lessonRepository.mergedLessons(teacherLessons);
    final builtInIds = kBuiltInLessons.map((lesson) => lesson.id).toSet();
    final teacherById = {for (final tl in teacherLessons) tl.id: tl};

    final rows = merged
        .map(
          (lesson) => DisplayLesson(
            lesson: lesson,
            isBuiltIn: builtInIds.contains(lesson.id),
            teacherLesson: builtInIds.contains(lesson.id) ? null : teacherById[lesson.id],
          ),
        )
        .toList();

    final quizOptions = await quizRepository.fetchTeacherQuizzes();

    return LessonsViewModel(
      rows: rows,
      quizOptions: quizOptions,
      onCreateLesson: lessonRepository.createLesson,
      onUpdateLesson: lessonRepository.updateLesson,
      onArchiveLesson: lessonRepository.archiveLesson,
      fetchLessonById: lessonRepository.fetchLessonById,
    );
  });
}

String subjectKeyLabel(SubjectKey subject) {
  switch (subject) {
    case SubjectKey.chemistry:
      return 'Chemistry';
    case SubjectKey.biology:
      return 'Biology';
    case SubjectKey.physics:
      return 'Physics';
  }
}
