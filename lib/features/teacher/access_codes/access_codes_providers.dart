import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/data/curriculum_data.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/quiz_phase.dart';
import '../../../core/models/quiz_unlock_code.dart';
import '../../../core/models/student_record.dart';
import '../../../core/models/subject_key.dart';
import '../../../core/quiz_id.dart';
import '../../../core/services/access_code_issuance_service.dart';
import '../../../core/services/quiz_attempt_service.dart';
import '../../../core/services/student_repository.dart';

enum IssuedCodeType { subject, lesson, retake }

class IssuedCodeRow {
  const IssuedCodeRow({
    required this.code,
    required this.type,
    required this.target,
    required this.status,
    required this.issuedAt,
    this.subject,
    this.retakeDocId,
  });

  final String code;
  final IssuedCodeType type;
  final String target;
  final String status;
  final String issuedAt;

  /// The subject this code's lesson (or subject scope) belongs to, when
  /// resolvable — drives the issued-codes table's row accent strip. `null`
  /// for a subject code scoped to multiple subjects at once, or when the
  /// underlying lesson/subject couldn't be resolved.
  final SubjectKey? subject;

  /// Firestore document id, for retake codes only. `/quizUnlockCodes` docs
  /// have auto-generated ids with the code as a mere field, so deleting one
  /// needs the id; subject/lesson codes are keyed by the code itself and so
  /// need nothing extra.
  final String? retakeDocId;
}

class AccessCodesViewModel {
  const AccessCodesViewModel({
    required this.students,
    required this.lessons,
    required this.issuedCodes,
    required this.onIssueSubjectCode,
    required this.onIssueLessonCode,
    required this.onIssueQuizRetakeCode,
    required this.checkRetakeEligible,
    required this.onDeleteCode,
  });

  final List<StudentRecord> students;
  final List<Lesson> lessons;
  final List<IssuedCodeRow> issuedCodes;
  final Future<String> Function({
    required List<String> subjects,
    List<String>? lessonIds,
    String? customCode,
  })
  onIssueSubjectCode;
  final Future<String> Function({
    required String lessonId,
    required String studentId,
    String? customCode,
  })
  onIssueLessonCode;
  final Future<String> Function({
    required String lessonId,
    required String studentId,
  })
  onIssueQuizRetakeCode;
  final Future<bool> Function({
    required String studentId,
    required String lessonId,
  })
  checkRetakeEligible;

  /// Permanently removes an issued code. Separate from archiving, which
  /// invalidates a code but keeps it listed.
  final Future<void> Function(IssuedCodeRow row) onDeleteCode;
}

final accessCodesViewModelProvider =
    StreamProvider.autoDispose<AccessCodesViewModel>((ref) {
      throw UnimplementedError(
        'accessCodesViewModelProvider must be overridden at app startup — see '
        'teacherProviderOverridesFor.',
      );
    });

Stream<AccessCodesViewModel> buildAccessCodesViewModel({
  required AccessCodeIssuanceService issuanceService,
  required StudentRepository studentRepository,
  required QuizAttemptService quizAttemptService,
  List<Lesson>? lessons,
}) {
  final resolvedLessons = lessons ?? kBuiltInLessons;
  return _combineLatest3(
    issuanceService.watchIssuedUnlockCodes(),
    issuanceService.watchIssuedRetakeCodes(),
    studentRepository.watchAllStudents(includeArchived: true),
    (unlockCodes, retakeCodes, students) {
      final issuedCodes = [
        ...unlockCodes.map(
          (doc) => _rowFromUnlockCode(doc, resolvedLessons, students),
        ),
        ...retakeCodes.map(
          (code) => _rowFromRetakeCode(code, resolvedLessons, students),
        ),
      ]..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));

      return AccessCodesViewModel(
        students: students,
        lessons: resolvedLessons,
        issuedCodes: issuedCodes,
        onIssueSubjectCode: ({required subjects, lessonIds, customCode}) =>
            issuanceService.issueSubjectCode(
              subjects: subjects,
              lessonIds: lessonIds,
              customCode: customCode,
            ),
        onIssueLessonCode:
            ({required lessonId, required studentId, customCode}) =>
                issuanceService.issueLessonCode(
                  lessonId: lessonId,
                  studentId: studentId,
                  customCode: customCode,
                ),
        onIssueQuizRetakeCode: ({required lessonId, required studentId}) =>
            issuanceService.issueQuizRetakeCode(
              lessonId: lessonId,
              studentId: studentId,
            ),
        checkRetakeEligible: ({required studentId, required lessonId}) async {
          final quizId = builtinQuizId(lessonId, QuizPhase.post);
          final eligibility = await quizAttemptService.checkEligibility(
            studentId,
            quizId,
          );
          return eligibility.attemptCount >= 1;
        },
        onDeleteCode: (row) {
          // Retake codes live in a different collection, keyed differently
          // (auto id + code field) from subject/lesson codes (keyed by the
          // code itself), so the row's own type decides which delete to run.
          if (row.type == IssuedCodeType.retake) {
            final docId = row.retakeDocId;
            if (docId == null) {
              throw StateError(
                'This retake code is missing its record id and cannot be '
                'deleted. Refresh the page and try again.',
              );
            }
            return issuanceService.deleteRetakeCode(docId);
          }
          return issuanceService.deleteUnlockCode(row.code);
        },
      );
    },
  );
}

/// Renders a code's assignee for the table's "Target" column.
///
/// Client feedback (UAT): this column used to show the bare student id, so a
/// teacher looking at a list of codes couldn't tell who each one was for
/// without cross-referencing the roster by hand. Shows "Name (id)" when the
/// student is on the roster, and falls back to the raw id when they aren't
/// (e.g. a code issued to a student who was later removed).
String _assigneeLabel(String? studentId, List<StudentRecord> students) {
  if (studentId == null || studentId.isEmpty) return '—';
  for (final student in students) {
    if (student.studentId == studentId) {
      return '${student.name} ($studentId)';
    }
  }
  return studentId;
}

IssuedCodeRow _rowFromUnlockCode(
  Map<String, dynamic> doc,
  List<Lesson> lessons,
  List<StudentRecord> students,
) {
  final typeRaw = doc['type'] as String? ?? 'subject';
  final type = typeRaw == 'lesson'
      ? IssuedCodeType.lesson
      : IssuedCodeType.subject;
  final isUsed = doc['isUsed'] as bool? ?? false;
  final isArchived = doc['isArchived'] as bool? ?? false;
  final target = type == IssuedCodeType.lesson
      ? _assigneeLabel(doc['targetStudentId'] as String?, students)
      : 'any';
  final issuedAt =
      doc['createdAt'] as String? ?? doc['generatedAt'] as String? ?? '—';

  SubjectKey? subject;
  if (type == IssuedCodeType.lesson) {
    final lessonId = doc['targetId'] as String?;
    subject = _subjectForLessonId(lessonId, lessons);
  } else {
    final subjects = (doc['subjects'] as List<dynamic>?)
        ?.cast<String>()
        .toList();
    // Only accent the row when the code is scoped to exactly one subject —
    // a code spanning multiple subjects has no single accent to show.
    if (subjects != null && subjects.length == 1) {
      subject = _subjectFromFirestoreValueOrNull(subjects.first);
    }
  }

  return IssuedCodeRow(
    code: doc['id'] as String? ?? '—',
    type: type,
    target: target,
    status: isArchived ? 'archived' : (isUsed ? 'used' : 'unused'),
    issuedAt: issuedAt,
    subject: subject,
  );
}

IssuedCodeRow _rowFromRetakeCode(
  QuizUnlockCode code,
  List<Lesson> lessons,
  List<StudentRecord> students,
) {
  final lessonId = parseBuiltinId(code.quizId).lessonId;
  return IssuedCodeRow(
    code: code.code,
    type: IssuedCodeType.retake,
    target: _assigneeLabel(code.studentId, students),
    status: code.isArchived ? 'archived' : (code.isUsed ? 'used' : 'unused'),
    issuedAt: code.generatedAt,
    subject: _subjectForLessonId(lessonId, lessons),
    retakeDocId: code.id,
  );
}

SubjectKey? _subjectForLessonId(String? lessonId, List<Lesson> lessons) {
  if (lessonId == null) return null;
  for (final lesson in lessons) {
    if (lesson.id == lessonId) return lesson.subject;
  }
  return null;
}

SubjectKey? _subjectFromFirestoreValueOrNull(String value) {
  try {
    return SubjectKey.fromFirestore(value);
  } on ArgumentError {
    return null;
  }
}

Stream<T> _combineLatest3<A, B, C, T>(
  Stream<A> streamA,
  Stream<B> streamB,
  Stream<C> streamC,
  T Function(A, B, C) combiner,
) {
  A? lastA;
  B? lastB;
  C? lastC;
  late StreamSubscription<A> subA;
  late StreamSubscription<B> subB;
  late StreamSubscription<C> subC;

  final controller = StreamController<T>();

  void maybeEmit() {
    if (lastA != null && lastB != null && lastC != null) {
      controller.add(combiner(lastA as A, lastB as B, lastC as C));
    }
  }

  // Every source needs `onError` forwarded. Without it a Firestore error on
  // any of the three (a momentary `unavailable`, a rules `permission-denied`)
  // went to the zone as an uncaught async error while this controller stayed
  // silent and open forever — so the StreamProvider never left `loading`,
  // the Access Codes screen span a spinner that could never resolve, its
  // ErrorState/Retry branch was unreachable, and the dashboard's "Unused
  // access codes" tile stayed a skeleton for the rest of the session.
  subA = streamA.listen((value) {
    lastA = value;
    maybeEmit();
  }, onError: controller.addError);
  subB = streamB.listen((value) {
    lastB = value;
    maybeEmit();
  }, onError: controller.addError);
  subC = streamC.listen((value) {
    lastC = value;
    maybeEmit();
  }, onError: controller.addError);

  controller.onCancel = () async {
    await subA.cancel();
    await subB.cancel();
    await subC.cancel();
  };

  return controller.stream;
}

String issuedCodeTypeLabel(IssuedCodeType type) {
  switch (type) {
    case IssuedCodeType.subject:
      return 'Subject';
    case IssuedCodeType.lesson:
      return 'Lesson';
    case IssuedCodeType.retake:
      return 'Retake';
  }
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
