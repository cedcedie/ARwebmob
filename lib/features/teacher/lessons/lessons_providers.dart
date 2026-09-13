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
    required this.onArchiveBuiltInLesson,
    required this.fetchLessonById,
  });

  final List<DisplayLesson> rows;
  final List<TeacherQuiz> quizOptions;
  final Future<void> Function(TeacherLesson lesson) onCreateLesson;
  final Future<void> Function(TeacherLesson lesson) onUpdateLesson;
  final Future<void> Function(String lessonId) onArchiveLesson;

  /// Soft-deletes a built-in lesson (hides it from students) without ever
  /// touching the compiled curriculum entry itself, and independent of
  /// student-progress resets -- see `LessonRepository.archiveBuiltInLesson`.
  /// Reversible via `LessonRepository.restoreBuiltInLesson` (no UI for that
  /// yet -- clear `isArchived` on the `/lessons/{id}` doc directly if a
  /// mistaken delete needs undoing).
  final Future<void> Function(Lesson builtIn) onArchiveBuiltInLesson;

  /// Re-fetches a single lesson doc's current Firestore state — passed to
  /// `LessonForm` so it can check for an already-completed server-side
  /// content conversion right before submit, instead of blindly
  /// overwriting it with stale local upload state (Fix 5).
  final Future<TeacherLesson?> Function(String lessonId) fetchLessonById;
}

final lessonsViewModelProvider = StreamProvider.autoDispose<LessonsViewModel>((
  ref,
) {
  throw UnimplementedError(
    'lessonsViewModelProvider must be overridden at app startup — see '
    'teacherProviderOverridesFor.',
  );
});

Stream<LessonsViewModel> buildLessonsViewModel({
  required LessonRepository lessonRepository,
  required QuizRepository quizRepository,
}) {
  return lessonRepository.watchTeacherLessons().asyncMap((
    teacherLessons,
  ) async {
    final merged = lessonRepository.mergedLessons(teacherLessons);
    final builtInIds = kBuiltInLessons.map((lesson) => lesson.id).toSet();
    final teacherById = {for (final tl in teacherLessons) tl.id: tl};

    final rows = merged
        .map(
          (lesson) => DisplayLesson(
            lesson: lesson,
            isBuiltIn: builtInIds.contains(lesson.id),
            // A built-in row's "teacherLesson" is synthesized from its
            // current *effective* (already-merged) values rather than the
            // raw override doc, so opening the edit form pre-fills with
            // what's actually shown today -- the built-in's own defaults
            // when no override exists yet, or the override's values once
            // one does. Submitting without changing anything is therefore
            // a safe no-op, never a silent reset to blank fields.
            teacherLesson: builtInIds.contains(lesson.id)
                ? _teacherLessonFromMergedBuiltIn(lesson)
                : teacherById[lesson.id],
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
      onArchiveBuiltInLesson: lessonRepository.archiveBuiltInLesson,
      fetchLessonById: lessonRepository.fetchLessonById,
    );
  });
}

/// Builds the `TeacherLesson` used to pre-fill `LessonForm` when editing a
/// built-in row -- taken from [lesson]'s already-merged, currently-effective
/// values (see `buildLessonsViewModel`) rather than the raw override doc, so
/// a teacher who opens the form and immediately hits save writes back
/// exactly what's already showing, not a blank reset.
TeacherLesson _teacherLessonFromMergedBuiltIn(Lesson lesson) {
  return TeacherLesson(
    id: lesson.id,
    title: lesson.title,
    subject: lesson.subject,
    summary: lesson.summary,
    steps: lesson.steps,
    quarter: lesson.quarter,
    week: lesson.week,
    linkedQuizId: lesson.linkedQuizId,
    pdfUrl: lesson.pdfUrl,
    contentImageUrls: lesson.contentImageUrls,
    contentStatus: lesson.contentStatus,
    hasAR: lesson.hasAR,
    arPayload: lesson.arPayload,
  );
}

String subjectKeyLabel(SubjectKey subject) {
  switch (subject) {
    case SubjectKey.chemistry:
      return 'Chemistry';
    case SubjectKey.biology:
      return 'Biology';
    case SubjectKey.physics:
      return 'Physics';
    case SubjectKey.earthScience:
      return 'Earth Science';
  }
}
