import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/data/curriculum_data.dart';
import '../../../core/models/quiz_phase.dart';
import '../../../core/models/subject_key.dart';
import '../../../core/quiz_id.dart';
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/student_repository.dart';

class LessonProgressRow {
  const LessonProgressRow({
    required this.lessonId,
    required this.title,
    required this.isCompleted,
  });
  final String lessonId;
  final String title;
  final bool isCompleted;
}

class QuizAttemptRow {
  const QuizAttemptRow({
    required this.quizId,
    required this.bestScore,
    required this.latestScore,
    required this.perQuestionCorrect,
  });
  final String quizId;
  final num bestScore;
  final num latestScore;
  final List<bool> perQuestionCorrect;
}

class SubjectProgressSection {
  const SubjectProgressSection({
    required this.subject,
    required this.lessons,
    required this.quizAttempts,
  });
  final SubjectKey subject;
  final List<LessonProgressRow> lessons;
  final List<QuizAttemptRow> quizAttempts;
}

class ProgressViewModel {
  const ProgressViewModel({required this.subjectSections});
  final List<SubjectProgressSection> subjectSections;
}

final progressViewModelProvider = StreamProvider.autoDispose<ProgressViewModel>(
  (ref) {
    throw UnimplementedError(
      'progressViewModelProvider must be overridden with a real student-scoped '
      'stream at app startup.',
    );
  },
);

const _subjectOrder = [
  SubjectKey.chemistry,
  SubjectKey.biology,
  SubjectKey.physics,
];

/// Resolves real per-question correctness for a quiz attempt by comparing
/// each selected answer against the matching question's `correctIndex` in
/// the built-in question bank (PROJECT_FLOW.md Part 10.3 requires an
/// accurate indicator, not a placeholder). Falls back to `false` for any
/// index with no matching question — e.g. a teacher-authored quiz with no
/// built-in question bank — rather than crashing.
List<bool> _perQuestionCorrectness(String quizId, List<int> answers) {
  final parsed = parseBuiltinId(quizId);
  List<dynamic>? questions;
  if (parsed.isBuiltin && parsed.lessonId != null) {
    questions = parsed.phase == QuizPhase.pre
        ? kPreTestQuestionsByLesson[parsed.lessonId]
        : kPostTestQuestionsByLesson[parsed.lessonId];
  }
  return [
    for (var i = 0; i < answers.length; i++)
      if (questions != null && i < questions.length)
        answers[i] == questions[i].correctIndex
      else
        false,
  ];
}

Stream<ProgressViewModel> buildProgressViewModel({
  required String studentId,
  required LessonRepository lessonRepository,
  required StudentRepository studentRepository,
}) {
  return studentRepository.watchStudent(studentId).asyncMap((student) async {
    final teacherLessons = await lessonRepository.watchTeacherLessons().first;
    final merged = lessonRepository.mergedLessons(teacherLessons);
    final completed = student?.completedLessonIds.toSet() ?? const <String>{};

    final sections = _subjectOrder.map((subject) {
      final lessons = merged
          .where((l) => l.subject == subject)
          .map(
            (l) => LessonProgressRow(
              lessonId: l.id,
              title: l.title,
              isCompleted: completed.contains(l.id),
            ),
          )
          .toList();

      final attemptsBySubject = (student?.quizAttempts ?? const [])
          .where(
            (a) => merged.any(
              (l) => a.quizId.contains(l.id) && l.subject == subject,
            ),
          )
          .toList();
      final byQuizId = <String, List<dynamic>>{};
      for (final a in attemptsBySubject) {
        byQuizId.putIfAbsent(a.quizId, () => []).add(a);
      }
      final quizRows = byQuizId.entries.map((entry) {
        final attempts = entry.value.cast<dynamic>();
        final scores = attempts.map((a) => a.score as num).toList();
        final latest = attempts.reduce(
          (a, b) =>
              DateTime.parse(a.timestamp).isAfter(DateTime.parse(b.timestamp))
              ? a
              : b,
        );
        final perQuestion = _perQuestionCorrectness(
          entry.key,
          (latest.answers as List).cast<int>(),
        );
        return QuizAttemptRow(
          quizId: entry.key,
          bestScore: scores.reduce((a, b) => a > b ? a : b),
          latestScore: latest.score as num,
          perQuestionCorrect: perQuestion,
        );
      }).toList();

      return SubjectProgressSection(
        subject: subject,
        lessons: lessons,
        quizAttempts: quizRows,
      );
    }).toList();

    return ProgressViewModel(subjectSections: sections);
  });
}
