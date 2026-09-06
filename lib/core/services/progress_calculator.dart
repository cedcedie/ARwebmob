import '../models/lesson.dart';
import '../models/quiz_attempt.dart';
import '../models/student_record.dart';

/// PROJECT_FLOW.md Part 10.1's exact score-color thresholds.
enum ScoreBand { good, caution, needsWork }

ScoreBand scoreBandFor(num score) {
  if (score >= 80) return ScoreBand.good;
  if (score >= 50) return ScoreBand.caution;
  return ScoreBand.needsWork;
}

/// First lesson in curriculum order not yet in [student]'s completedLessonIds.
Lesson? nextIncompleteLesson(
  List<Lesson> orderedLessons,
  StudentRecord student,
) {
  final completed = student.completedLessonIds.toSet();
  for (final lesson in orderedLessons) {
    if (!completed.contains(lesson.id)) return lesson;
  }
  return null;
}

double percentComplete(StudentRecord student, {int totalLessons = 24}) {
  return student.completedLessonIds.length / totalLessons;
}

({int quarter, int week})? currentQuarterWeek(
  List<Lesson> orderedLessons,
  StudentRecord student,
) {
  final next = nextIncompleteLesson(orderedLessons, student);
  if (next == null || next.quarter == null || next.week == null) return null;
  return (quarter: next.quarter!, week: next.week!);
}

List<QuizAttempt> lastNAttempts(StudentRecord student, {int n = 3}) {
  final sorted = [...student.quizAttempts]
    ..sort(
      (a, b) =>
          DateTime.parse(b.timestamp).compareTo(DateTime.parse(a.timestamp)),
    );
  return sorted.take(n).toList();
}
