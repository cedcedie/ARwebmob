// test/integration/item_analysis_data_test.dart
//
// Cross-target integration coverage for PROJECT_FLOW.md Part 7.5 — item
// analysis. A teacher (Web target) creates a lesson linked to an authored
// quiz via the real `LessonRepository`/`QuizRepository`; ten students
// (Android target) each take that quiz through the real
// `QuizAttemptService.recordAttempt` — the same call the on-device quiz
// player makes; the teacher's real `buildItemAnalysisViewModel` (which the
// Item Analysis screen consumes) is then read back and checked against the
// simulated attempts, all through one shared `FakeFirebaseFirestore`.
//
// This does not reimplement the difficulty/discrimination math — it drives
// the actual `computeItemAnalysis` function transitively through
// `buildItemAnalysisViewModel` and only asserts on its output.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/question_type.dart';
import 'package:ar_science_explorer/core/models/quiz_attempt.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/models/student_record.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/teacher_lesson.dart';
import 'package:ar_science_explorer/core/models/teacher_quiz.dart';
import 'package:ar_science_explorer/core/models/teacher_quiz_question.dart';
import 'package:ar_science_explorer/core/quiz_id.dart';
import 'package:ar_science_explorer/core/services/lesson_repository.dart';
import 'package:ar_science_explorer/core/services/quiz_attempt_service.dart';
import 'package:ar_science_explorer/core/services/quiz_repository.dart';
import 'package:ar_science_explorer/core/services/student_repository.dart';
import 'package:ar_science_explorer/features/teacher/quizzes/item_analysis_providers.dart';

StudentRecord _blankStudent(String id) => StudentRecord(
  id: id,
  name: 'Student $id',
  studentId: id,
  grade: '7',
  section: 'Rizal',
  scores: const {'chemistry': null, 'biology': null, 'physics': null},
  completedLessonIds: const [],
  completedLabExperimentIds: const [],
  completedQuizIds: const [],
  unlockedLessonIds: const [],
  unlockedQuizIds: const [],
  quizAttempts: const [],
);

void main() {
  test('item analysis over 10 real student attempts on a teacher-linked quiz: '
      'attempt count matches, an all-correct question scores difficulty ~1.0, '
      'an all-wrong question scores difficulty ~0.0, and questions correlated '
      'with total score show positive discrimination', () async {
    final firestore = FakeFirebaseFirestore();
    final studentRepo = StudentRepository(firestore: firestore);
    final lessonRepo = LessonRepository(firestore: firestore);
    final quizRepo = QuizRepository(firestore: firestore);
    final quizAttemptService = QuizAttemptService(firestore: firestore);

    const quizId = 'teacher-quiz-item-analysis';
    const lessonId = 'teacher-lesson-item-analysis';

    // Teacher (Web target): author a 4-question quiz and link it to a
    // lesson, exactly as lesson_form.dart's `linkedQuizId` field does.
    await quizRepo.createQuiz(
      TeacherQuiz(
        id: quizId,
        title: 'Cell Structures Post-Test',
        subject: SubjectKey.biology,
        createdAt: DateTime(2026, 8, 1).toIso8601String(),
        questions: [
          TeacherQuizQuestion(
            question: 'Q0 (everyone gets this right)',
            options: const ['Correct', 'B', 'C', 'D'],
            correctIndex: 0,
            hint: 'hint',
            type: QuestionType.mc,
          ),
          TeacherQuizQuestion(
            question: 'Q1 (nobody gets this right)',
            options: const ['A', 'Correct', 'C', 'D'],
            correctIndex: 1,
            hint: 'hint',
            type: QuestionType.mc,
          ),
          TeacherQuizQuestion(
            question: 'Q2 (only high scorers get this right)',
            options: const ['A', 'B', 'Correct', 'D'],
            correctIndex: 2,
            hint: 'hint',
            type: QuestionType.mc,
          ),
          TeacherQuizQuestion(
            question: 'Q3 (only high scorers get this right)',
            options: const ['A', 'B', 'C', 'Correct'],
            correctIndex: 3,
            hint: 'hint',
            type: QuestionType.mc,
          ),
        ],
      ),
    );
    await lessonRepo.createLesson(
      TeacherLesson(
        id: lessonId,
        title: 'Cell Structures',
        subject: SubjectKey.biology,
        linkedQuizId: quizId,
        createdAt: DateTime(2026, 8, 1).toIso8601String(),
      ),
    );

    // Ten students (Android target) take the post-test via the real
    // attempt-recording path. The real quiz player always records under
    // the synthesized builtin lesson+phase id (see router.dart), never
    // the teacher quiz's own doc id — mirrored here exactly.
    final recordedQuizId = builtinQuizId(lessonId, QuizPhase.post);

    // Top 3 scorers (rank by score): correct on Q0, Q2, Q3; wrong on Q1.
    const topScorers = ['S01', 'S02', 'S03'];
    // Middle 4: correct on Q0, Q2; wrong on Q1, Q3.
    const midScorers = ['S04', 'S05', 'S06', 'S07'];
    // Bottom 3 scorers: correct on Q0 only; wrong on Q1, Q2, Q3.
    const bottomScorers = ['S08', 'S09', 'S10'];

    Future<void> recordFor(
      String studentId, {
      required bool q2Correct,
      required bool q3Correct,
    }) async {
      await studentRepo.saveStudent(_blankStudent(studentId));
      final answers = [
        0, // Q0: always correct (correctIndex 0)
        2, // Q1: always wrong (correctIndex 1)
        q2Correct ? 2 : 0, // Q2: correctIndex 2
        q3Correct ? 3 : 0, // Q3: correctIndex 3
      ];
      final correctCount = answers.asMap().entries.where((e) {
        const correctIndexes = [0, 1, 2, 3];
        return e.value == correctIndexes[e.key];
      }).length;
      final score = ((correctCount / 4) * 100).round();

      await quizAttemptService.recordAttempt(
        studentId: studentId,
        subject: SubjectKey.biology,
        attempt: QuizAttempt(
          id: '$studentId-attempt-1',
          quizId: recordedQuizId,
          studentId: studentId,
          attemptNumber: 1,
          score: score,
          totalQuestions: 4,
          correctAnswers: correctCount,
          answers: answers,
          timestamp: DateTime(2026, 8, 20).toIso8601String(),
          locked: true,
        ),
      );
    }

    for (final id in topScorers) {
      await recordFor(id, q2Correct: true, q3Correct: true);
    }
    for (final id in midScorers) {
      await recordFor(id, q2Correct: true, q3Correct: false);
    }
    for (final id in bottomScorers) {
      await recordFor(id, q2Correct: false, q3Correct: false);
    }

    // Teacher (Web target) opens item analysis from the authored-quiz
    // row — keyed on the teacher quiz's own doc id, exactly as
    // quizzes_screen.dart does — and the real view-model builder resolves
    // the linked lesson to find the attempts.
    final vm = await buildItemAnalysisViewModel(
      quizId: quizId,
      quizTitle: 'Cell Structures Post-Test',
      studentRepository: studentRepo,
      quizRepository: quizRepo,
      lessonRepository: lessonRepo,
    ).first;

    expect(vm.attemptCount, 10);
    expect(vm.results, hasLength(4));

    final q0 = vm.results[0];
    final q1 = vm.results[1];
    final q2 = vm.results[2];
    final q3 = vm.results[3];

    // Sanity-check the real formula's behavior at the two extremes.
    expect(
      q0.difficultyIndex,
      closeTo(1.0, 0.0001),
      reason: 'every student answered Q0 correctly',
    );
    expect(
      q1.difficultyIndex,
      closeTo(0.0, 0.0001),
      reason: 'no student answered Q1 correctly',
    );

    // Q2/Q3 sit strictly between the two extremes (7/10 and 3/10 correct).
    expect(q2.difficultyIndex, closeTo(0.7, 0.0001));
    expect(q3.difficultyIndex, closeTo(0.3, 0.0001));

    // A question every student gets right (or every student misses)
    // carries no information to discriminate top from bottom scorers.
    expect(q0.discriminationIndex, closeTo(0.0, 0.0001));
    expect(q1.discriminationIndex, closeTo(0.0, 0.0001));

    // Q2 and Q3 were both engineered so the top-score group (the students
    // who also got Q2/Q3 right, which is exactly why they scored highest)
    // answers correctly 100% of the time, and the bottom-score group 0%
    // of the time -> maximal positive discrimination, per Part 7.5's
    // documented formula. (Q2 is also answered correctly by the
    // mid-scoring group, but that group falls outside both the top-27%
    // and bottom-27% split, so it doesn't change the computed index.)
    expect(q2.discriminationIndex, closeTo(1.0, 0.0001));
    expect(q3.discriminationIndex, closeTo(1.0, 0.0001));
  });
}
