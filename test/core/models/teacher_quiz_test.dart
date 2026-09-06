import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/built_in_question.dart';
import 'package:ar_science_explorer/core/models/question_type.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/teacher_quiz.dart';
import 'package:ar_science_explorer/core/models/teacher_quiz_question.dart';

void main() {
  test('TeacherQuizQuestion defaults type to mc when absent', () {
    final question = TeacherQuizQuestion.fromJson(const {
      'question': 'What is H2O?',
      'options': ['Water', 'Oxygen', 'Hydrogen', 'Salt'],
      'correctIndex': 0,
      'hint': 'It is a liquid at room temperature.',
    });

    expect(question.type, QuestionType.mc);
  });

  test('TeacherQuiz defaults phase to post when absent (legacy quiz)', () {
    final quiz = TeacherQuiz.fromJson({
      'id': 'quiz-1',
      'title': 'Q1W1 Post-Test',
      'subject': 'chemistry',
      'questions': <Map<String, dynamic>>[],
      'createdAt': '2026-08-20T09:00:00.000Z',
    });

    expect(quiz.subject, SubjectKey.chemistry);
    expect(quiz.phase, QuizPhase.post);
  });

  test(
    'BuiltInQuestion round-trips a tf question using the 4-slot convention',
    () {
      final question = BuiltInQuestion.fromJson(const {
        'id': 'q1w1-tf-1',
        'subject': 'chemistry',
        'question': 'Atoms are indivisible.',
        'options': ['True', 'False', '-', '-'],
        'correctIndex': 0,
        'hint': 'Think about what "atomos" means.',
        'type': 'tf',
      });

      expect(question.type, QuestionType.tf);
      expect(question.options, ['True', 'False', '-', '-']);
    },
  );
}
