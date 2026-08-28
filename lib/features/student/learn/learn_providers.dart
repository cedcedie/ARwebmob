// lib/features/student/learn/learn_providers.dart
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/subject_key.dart';
import '../../../core/services/lesson_repository.dart';
import '../../../core/services/student_repository.dart';

class LessonCardData {
  const LessonCardData({
    required this.lessonId,
    required this.title,
    required this.week,
    required this.summary,
    required this.isUnlocked,
    required this.hasPreTest,
    required this.isCompleted,
  });

  final String lessonId;
  final String title;
  final int? week;
  final String summary;
  final bool isUnlocked;
  final bool hasPreTest;
  final bool isCompleted;
}

class LearnViewModel {
  const LearnViewModel({
    required this.activeSubject,
    required this.cards,
    required this.onSelectSubject,
  });

  final SubjectKey activeSubject;
  final List<LessonCardData> cards;
  final ValueChanged<SubjectKey> onSelectSubject;
}

final learnViewModelProvider = StreamProvider.autoDispose<LearnViewModel>((ref) {
  throw UnimplementedError(
    'learnViewModelProvider must be overridden with a real student-scoped '
    'stream at app startup.',
  );
});

/// Builds the real streaming view model. [preTestLessonIds] is the set of
/// lesson ids that have a non-empty pre-test bank (from
/// kPreTestQuestionsByLesson.keys in the real app-startup wiring) — passed
/// in rather than imported here so this function stays testable without
/// pulling in the full curriculum data set.
Stream<LearnViewModel> buildLearnViewModel({
  required String studentId,
  required SubjectKey initialSubject,
  required LessonRepository lessonRepository,
  required StudentRepository studentRepository,
  required Set<String> preTestLessonIds,
  required void Function(SubjectKey) onSelectSubject,
}) {
  return lessonRepository.watchTeacherLessons().asyncMap((teacherLessons) async {
    final merged = lessonRepository.mergedLessons(teacherLessons);
    final student = await studentRepository.getStudent(studentId);
    final unlockedIds = student?.unlockedLessonIds.toSet() ?? const <String>{};
    final completedIds = student?.completedLessonIds.toSet() ?? const <String>{};

    final cards = merged
        .where((l) => l.subject == initialSubject)
        .map((l) => LessonCardData(
              lessonId: l.id,
              title: l.title,
              week: l.week,
              summary: l.summary,
              isUnlocked: l.isUnlockedByDefault || unlockedIds.contains(l.id),
              hasPreTest: preTestLessonIds.contains(l.id),
              isCompleted: completedIds.contains(l.id),
            ))
        .toList();

    return LearnViewModel(activeSubject: initialSubject, cards: cards, onSelectSubject: onSelectSubject);
  });
}
