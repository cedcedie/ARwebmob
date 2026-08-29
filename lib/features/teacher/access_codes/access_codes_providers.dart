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
  });

  final String code;
  final IssuedCodeType type;
  final String target;
  final String status;
  final String issuedAt;
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
  });

  final List<StudentRecord> students;
  final List<Lesson> lessons;
  final List<IssuedCodeRow> issuedCodes;
  final Future<String> Function({
    required List<String> subjects,
    List<String>? lessonIds,
    String? customCode,
  }) onIssueSubjectCode;
  final Future<String> Function({
    required String lessonId,
    required String studentId,
    String? customCode,
  }) onIssueLessonCode;
  final Future<String> Function({
    required String lessonId,
    required String studentId,
  }) onIssueQuizRetakeCode;
  final Future<bool> Function({
    required String studentId,
    required String lessonId,
  }) checkRetakeEligible;
}

final accessCodesViewModelProvider = StreamProvider.autoDispose<AccessCodesViewModel>((ref) {
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
        ...unlockCodes.map(_rowFromUnlockCode),
        ...retakeCodes.map(_rowFromRetakeCode),
      ]..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));

      return AccessCodesViewModel(
        students: students,
        lessons: resolvedLessons,
        issuedCodes: issuedCodes,
        onIssueSubjectCode: ({
          required subjects,
          lessonIds,
          customCode,
        }) =>
            issuanceService.issueSubjectCode(
              subjects: subjects,
              lessonIds: lessonIds,
              customCode: customCode,
            ),
        onIssueLessonCode: ({
          required lessonId,
          required studentId,
          customCode,
        }) =>
            issuanceService.issueLessonCode(
              lessonId: lessonId,
              studentId: studentId,
              customCode: customCode,
            ),
        onIssueQuizRetakeCode: ({
          required lessonId,
          required studentId,
        }) =>
            issuanceService.issueQuizRetakeCode(
              lessonId: lessonId,
              studentId: studentId,
            ),
        checkRetakeEligible: ({
          required studentId,
          required lessonId,
        }) async {
          final quizId = builtinQuizId(lessonId, QuizPhase.post);
          final eligibility = await quizAttemptService.checkEligibility(studentId, quizId);
          return eligibility.attemptCount >= 1;
        },
      );
    },
  );
}

IssuedCodeRow _rowFromUnlockCode(Map<String, dynamic> doc) {
  final typeRaw = doc['type'] as String? ?? 'subject';
  final type = typeRaw == 'lesson' ? IssuedCodeType.lesson : IssuedCodeType.subject;
  final isUsed = doc['isUsed'] as bool? ?? false;
  final isArchived = doc['isArchived'] as bool? ?? false;
  final target = type == IssuedCodeType.lesson
      ? (doc['targetStudentId'] as String? ?? '—')
      : 'any';
  final issuedAt = doc['createdAt'] as String? ?? doc['generatedAt'] as String? ?? '—';

  return IssuedCodeRow(
    code: doc['id'] as String? ?? '—',
    type: type,
    target: target,
    status: isArchived ? 'archived' : (isUsed ? 'used' : 'unused'),
    issuedAt: issuedAt,
  );
}

IssuedCodeRow _rowFromRetakeCode(QuizUnlockCode code) {
  return IssuedCodeRow(
    code: code.code,
    type: IssuedCodeType.retake,
    target: code.studentId,
    status: code.isArchived ? 'archived' : (code.isUsed ? 'used' : 'unused'),
    issuedAt: code.generatedAt,
  );
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

  subA = streamA.listen((value) {
    lastA = value;
    maybeEmit();
  });
  subB = streamB.listen((value) {
    lastB = value;
    maybeEmit();
  });
  subC = streamC.listen((value) {
    lastC = value;
    maybeEmit();
  });

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
  }
}
