// test/core/services/quiz_repository_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/built_in_question.dart';
import 'package:ar_science_explorer/core/models/lesson.dart';
import 'package:ar_science_explorer/core/models/question_type.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/teacher_quiz.dart';
import 'package:ar_science_explorer/core/models/teacher_quiz_question.dart';
import 'package:ar_science_explorer/core/services/quiz_repository.dart';

TeacherQuiz _quiz({String id = 'quiz-1', String title = 'Volcano Quiz'}) {
  return TeacherQuiz(
    id: id,
    title: title,
    subject: SubjectKey.chemistry,
    questions: const [
      TeacherQuizQuestion(
        question: 'What is lava?',
        options: ['Molten rock', 'Water', 'Gas', 'Ice'],
        correctIndex: 0,
        hint: 'Think hot.',
      ),
    ],
    createdAt: '2026-08-29T00:00:00.000Z',
    phase: QuizPhase.post,
  );
}

void main() {
  test('createQuiz writes a doc under /quizzes/{quiz.id}', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = QuizRepository(firestore: firestore);

    await repo.createQuiz(_quiz());

    final doc = await firestore.collection('quizzes').doc('quiz-1').get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['title'], 'Volcano Quiz');
  });

  test('updateQuiz overwrites an existing doc', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = QuizRepository(firestore: firestore);

    await repo.createQuiz(_quiz());
    await repo.updateQuiz(_quiz(title: 'Updated Title'));

    final doc = await firestore.collection('quizzes').doc('quiz-1').get();
    expect(doc.data()!['title'], 'Updated Title');
  });

  test('deleteQuiz removes a doc', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = QuizRepository(firestore: firestore);

    await repo.createQuiz(_quiz());
    await repo.deleteQuiz('quiz-1');

    final doc = await firestore.collection('quizzes').doc('quiz-1').get();
    expect(doc.exists, isFalse);
  });

  test('watchTeacherQuizzes streams /quizzes documents as TeacherQuiz', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = QuizRepository(firestore: firestore);

    await firestore.collection('quizzes').doc('quiz-1').set(_quiz().toJson());

    final quizzes = await repo.watchTeacherQuizzes().first;

    expect(quizzes, hasLength(1));
    expect(quizzes.first.title, 'Volcano Quiz');
  });

  test('fetchTeacherQuizzes returns a one-shot list of TeacherQuiz', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = QuizRepository(firestore: firestore);

    await firestore.collection('quizzes').doc('quiz-1').set(_quiz().toJson());

    final quizzes = await repo.fetchTeacherQuizzes();

    expect(quizzes, hasLength(1));
    expect(quizzes.first.id, 'quiz-1');
  });

  test('mergedQuizzes synthesizes a built-in display quiz per lesson+phase bank', () {
    final firestore = FakeFirebaseFirestore();
    final repo = QuizRepository(firestore: firestore);

    const lessons = [
      Lesson(
        id: 'q1w1',
        title: 'Scientific Models',
        subject: SubjectKey.chemistry,
        summary: '',
        steps: [],
      ),
    ];
    const preTestByLesson = {
      'q1w1': [
        BuiltInQuestion(
          id: 'q1w1-pre-1',
          subject: SubjectKey.chemistry,
          lessonId: 'q1w1',
          question: 'Is this a model?',
          options: ['True', 'False', '-', '-'],
          correctIndex: 0,
          hint: 'Think models.',
          type: QuestionType.tf,
        ),
      ],
    };
    const postTestByLesson = <String, List<BuiltInQuestion>>{};

    final merged = repo.mergedQuizzes(
      teacherQuizzes: const [],
      lessons: lessons,
      preTestQuestionsByLesson: preTestByLesson,
      postTestQuestionsByLesson: postTestByLesson,
    );

    expect(merged, hasLength(1));
    expect(merged.first.isBuiltIn, isTrue);
    expect(merged.first.quiz.phase, QuizPhase.pre);
    expect(merged.first.quiz.title, contains('Scientific Models'));
  });

  test('mergedQuizzes appends teacher-authored quizzes after built-ins', () {
    final firestore = FakeFirebaseFirestore();
    final repo = QuizRepository(firestore: firestore);

    final merged = repo.mergedQuizzes(
      teacherQuizzes: [_quiz()],
      lessons: const [],
      preTestQuestionsByLesson: const {},
      postTestQuestionsByLesson: const {},
    );

    expect(merged, hasLength(1));
    expect(merged.first.isBuiltIn, isFalse);
    expect(merged.first.quiz.id, 'quiz-1');
  });
}
