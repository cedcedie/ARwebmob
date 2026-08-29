// lib/core/services/quiz_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/built_in_question.dart';
import '../models/lesson.dart';
import '../models/quiz_phase.dart';
import '../models/teacher_quiz.dart';
import '../models/teacher_quiz_question.dart';

/// A single row for a teacher-facing quiz list: either a real
/// Firestore-authored [TeacherQuiz], or a read-only view synthesized from a
/// built-in question bank (`kPreTestQuestionsByLesson`/
/// `kPostTestQuestionsByLesson`) — [isBuiltIn] tells the UI whether edit/
/// delete actions should be offered.
class DisplayQuiz {
  const DisplayQuiz({required this.quiz, required this.isBuiltIn});

  final TeacherQuiz quiz;
  final bool isBuiltIn;
}

/// CRUD access to teacher-authored quizzes at `/quizzes/{quiz.id}`, plus a
/// merge helper that folds the built-in pre/post-test question banks in as
/// read-only [DisplayQuiz] rows (PROJECT_FLOW.md Part 4.2's collection map).
/// Mirrors `LessonRepository`'s constructor-injected-Firestore,
/// stream+future pair style; built-ins are passed in by the caller rather
/// than imported directly, since this class has no reason to know about
/// `curriculum_data.dart`.
class QuizRepository {
  QuizRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<List<TeacherQuiz>> watchTeacherQuizzes() {
    return _firestore.collection('quizzes').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => TeacherQuiz.fromJson(doc.data())).toList(),
        );
  }

  Future<List<TeacherQuiz>> fetchTeacherQuizzes() async {
    final snapshot = await _firestore.collection('quizzes').get();
    return snapshot.docs.map((doc) => TeacherQuiz.fromJson(doc.data())).toList();
  }

  Future<void> createQuiz(TeacherQuiz quiz) {
    return _firestore.collection('quizzes').doc(quiz.id).set(quiz.toJson());
  }

  Future<void> updateQuiz(TeacherQuiz quiz) {
    return _firestore.collection('quizzes').doc(quiz.id).set(quiz.toJson());
  }

  Future<void> deleteQuiz(String quizId) {
    return _firestore.collection('quizzes').doc(quizId).delete();
  }

  /// Synthesizes one read-only [DisplayQuiz] per lesson+phase that has a
  /// non-empty built-in question bank, titled from the matching [lessons]
  /// entry, then appends the real Firestore-authored [teacherQuizzes] after
  /// them.
  List<DisplayQuiz> mergedQuizzes({
    required List<TeacherQuiz> teacherQuizzes,
    required List<Lesson> lessons,
    required Map<String, List<BuiltInQuestion>> preTestQuestionsByLesson,
    required Map<String, List<BuiltInQuestion>> postTestQuestionsByLesson,
  }) {
    final lessonTitleById = {for (final lesson in lessons) lesson.id: lesson.title};

    final builtIns = <DisplayQuiz>[
      ...preTestQuestionsByLesson.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => _synthesize(
                lessonId: entry.key,
                phase: QuizPhase.pre,
                questions: entry.value,
                lessonTitleById: lessonTitleById,
              )),
      ...postTestQuestionsByLesson.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => _synthesize(
                lessonId: entry.key,
                phase: QuizPhase.post,
                questions: entry.value,
                lessonTitleById: lessonTitleById,
              )),
    ];

    final authored = teacherQuizzes.map((quiz) => DisplayQuiz(quiz: quiz, isBuiltIn: false));

    return [...builtIns, ...authored];
  }

  DisplayQuiz _synthesize({
    required String lessonId,
    required QuizPhase phase,
    required List<BuiltInQuestion> questions,
    required Map<String, String> lessonTitleById,
  }) {
    final lessonTitle = lessonTitleById[lessonId] ?? lessonId;
    final phaseLabel = phase == QuizPhase.pre ? 'Pre-Test' : 'Post-Test';
    final first = questions.first;

    return DisplayQuiz(
      isBuiltIn: true,
      quiz: TeacherQuiz(
        id: 'builtin-$lessonId-${phase.name}',
        title: '$lessonTitle $phaseLabel',
        subject: first.subject,
        topicId: first.topicId,
        createdAt: '',
        phase: phase,
        questions: questions
            .map((q) => TeacherQuizQuestion(
                  question: q.question,
                  options: q.options,
                  correctIndex: q.correctIndex,
                  hint: q.hint,
                  type: q.type,
                ))
            .toList(),
      ),
    );
  }
}
