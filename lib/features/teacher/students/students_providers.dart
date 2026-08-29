import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/student_record.dart';
import '../../../core/services/student_repository.dart';

class StudentsViewModel {
  const StudentsViewModel({
    required this.students,
    required this.includeArchived,
    required this.onToggleIncludeArchived,
    required this.onCreateStudent,
    required this.onArchiveStudent,
  });

  final List<StudentRecord> students;
  final bool includeArchived;
  final void Function(bool includeArchived) onToggleIncludeArchived;
  final Future<void> Function(StudentRecord student) onCreateStudent;
  final Future<void> Function(String studentId) onArchiveStudent;
}

/// UI toggle for whether archived students appear in the roster table.
final studentsIncludeArchivedProvider = StateProvider<bool>((ref) => false);

final studentsViewModelProvider = StreamProvider.autoDispose<StudentsViewModel>((ref) {
  throw UnimplementedError(
    'studentsViewModelProvider must be overridden at app startup — see '
    'teacherProviderOverridesFor.',
  );
});

Stream<StudentsViewModel> buildStudentsViewModel({
  required StudentRepository studentRepository,
  required bool includeArchived,
  required void Function(bool includeArchived) onToggleIncludeArchived,
}) {
  return studentRepository.watchAllStudents(includeArchived: includeArchived).map(
        (students) => StudentsViewModel(
          students: students,
          includeArchived: includeArchived,
          onToggleIncludeArchived: onToggleIncludeArchived,
          onCreateStudent: studentRepository.createStudent,
          onArchiveStudent: studentRepository.archiveStudent,
        ),
      );
}

/// Brand-new roster entry with empty activity fields — scores and completion
/// lists are derived from quiz/lesson activity, not hand-edited here.
StudentRecord blankStudentRecord({
  required String name,
  required String studentId,
  required String grade,
  required String section,
}) {
  return StudentRecord(
    id: studentId,
    name: name,
    studentId: studentId,
    grade: grade,
    section: section,
    scores: const {'chemistry': null, 'biology': null, 'physics': null},
    completedLessonIds: const [],
    completedLabExperimentIds: const [],
    completedQuizIds: const [],
    unlockedLessonIds: const [],
    unlockedQuizIds: const [],
    quizAttempts: const [],
  );
}
