import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/student_record.dart';
import '../../../core/services/access_code_issuance_service.dart';
import '../../../core/services/student_account_service.dart';
import '../widgets/error_state.dart';
import 'student_csv_import.dart';
import '../../../core/services/student_repository.dart';

class StudentsViewModel {
  const StudentsViewModel({
    required this.students,
    required this.includeArchived,
    required this.onToggleIncludeArchived,
    required this.onCreateStudent,
    required this.onImportStudents,
    required this.onResetStudentPassword,
    required this.onArchiveStudent,
    required this.onResetAllProgress,
  });

  final List<StudentRecord> students;
  final bool includeArchived;
  final void Function(bool includeArchived) onToggleIncludeArchived;

  /// Creates the student's roster row *and* their login. The password is
  /// set by the teacher at this moment — UAT: "gusto nila yung add student
  /// na si teacher na yung magbibigay ng password".
  final Future<void> Function(StudentRecord student, String password)
  onCreateStudent;

  /// Sets a student's password, creating their login first if they have a
  /// roster row but no Firebase Auth account. Both halves need Admin-SDK
  /// privileges, so they go through callable Cloud Functions.
  final Future<void> Function(String studentId, String newPassword)
  onResetStudentPassword;

  final Future<void> Function(String studentId) onArchiveStudent;

  /// Bulk roster import. Returns one outcome per row so the dialog can show
  /// exactly which students were created and which failed — a partial
  /// failure must never look like a total one, or the teacher will re-run
  /// the whole file and hit "already exists" on every good row.
  final Future<List<StudentImportOutcome>> Function(List<StudentImportRow> rows)
  onImportStudents;
  final Future<void> Function() onResetAllProgress;
}

/// UI toggle for whether archived students appear in the roster table.
final studentsIncludeArchivedProvider = StateProvider<bool>((ref) => false);

final studentsViewModelProvider = StreamProvider.autoDispose<StudentsViewModel>(
  (ref) {
    throw UnimplementedError(
      'studentsViewModelProvider must be overridden at app startup — see '
      'teacherProviderOverridesFor.',
    );
  },
);

Stream<StudentsViewModel> buildStudentsViewModel({
  required StudentRepository studentRepository,
  required bool includeArchived,
  required void Function(bool includeArchived) onToggleIncludeArchived,
  AccessCodeIssuanceService? accessCodeIssuanceService,
  StudentAccountService? studentAccountService,
}) {
  return studentRepository
      .watchAllStudents(includeArchived: includeArchived)
      .map(
        (students) => StudentsViewModel(
          students: students,
          includeArchived: includeArchived,
          onToggleIncludeArchived: onToggleIncludeArchived,
          // With an account service (the real app) this also creates the
          // Firebase Auth login, so the student can actually sign in.
          // Without one (widget tests, no Firebase) it degrades to the
          // roster row alone rather than failing outright.
          onCreateStudent: (student, password) async {
            if (studentAccountService == null) {
              await studentRepository.createStudent(student);
              return;
            }
            await studentAccountService.createStudentWithLogin(
              student: student,
              password: password,
            );
          },
          onImportStudents: (rows) async {
            final outcomes = <StudentImportOutcome>[];
            // Sequential, not Future.wait: each row provisions a Firebase
            // Auth account on one shared secondary app, and firing dozens of
            // those concurrently races that app's auth state. Rosters are
            // tens of rows, so the wall-clock cost is irrelevant next to
            // getting per-row results right.
            for (final row in rows) {
              try {
                if (studentAccountService == null) {
                  await studentRepository.createStudent(row.toRecord());
                } else {
                  await studentAccountService.createStudentWithLogin(
                    student: row.toRecord(),
                    password: row.password,
                  );
                }
                outcomes.add(StudentImportOutcome(row: row, error: null));
              } catch (error) {
                // One bad row must not abort the rest of the file.
                outcomes.add(
                  StudentImportOutcome(
                    row: row,
                    error: humanizeSubmitError(
                      error,
                      actionLabel: 'create this student',
                    ),
                  ),
                );
              }
            }
            return outcomes;
          },
          onResetStudentPassword: (studentId, newPassword) async {
            if (studentAccountService == null) {
              throw StateError(
                'Password management is unavailable in this build.',
              );
            }
            // Try creating the login first. Creating an account needs no
            // elevated privilege, so this path works even on a Firebase
            // project with no Cloud Functions — and it is the case that
            // actually matters right now, since every student added before
            // Add Student started provisioning logins has a roster row and
            // no account. Only if a login already exists do we need the
            // privileged reset path.
            try {
              await studentAccountService.createLoginForExistingStudent(
                studentId: studentId,
                password: newPassword,
              );
              return;
            } on StateError catch (error) {
              if (error.message !=
                  StudentAccountService.kStudentAlreadyHasLogin) {
                rethrow;
              }
            }
            await studentAccountService.resetPassword(
              studentId: studentId,
              newPassword: newPassword,
            );
          },
          onArchiveStudent: studentRepository.archiveStudent,
          // Client feedback (UAT): resetting everyone's progress must also
          // invalidate the codes already handed out, otherwise teachers are
          // left guessing which of a growing pile of codes are still
          // current. Codes are archived (not deleted) so the record of what
          // was issued survives; `AccessCodeService.redeem` rejects archived
          // codes, so this genuinely invalidates them.
          onResetAllProgress: () async {
            await studentRepository.resetAllProgress();
            await accessCodeIssuanceService?.archiveAllCodes();
          },
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
