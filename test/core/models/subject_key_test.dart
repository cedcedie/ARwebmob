// test/core/models/subject_key_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/question_type.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';

void main() {
  group('SubjectKey', () {
    test('round-trips known values', () {
      expect(SubjectKey.fromFirestore('chemistry'), SubjectKey.chemistry);
      expect(SubjectKey.chemistry.firestoreValue, 'chemistry');
      expect(SubjectKey.fromFirestore('biology'), SubjectKey.biology);
      expect(SubjectKey.fromFirestore('physics'), SubjectKey.physics);
    });
  });

  group('QuestionType', () {
    test('defaults to mc when absent or unrecognized', () {
      expect(QuestionType.fromFirestore(null), QuestionType.mc);
      expect(QuestionType.fromFirestore('bogus'), QuestionType.mc);
      expect(QuestionType.fromFirestore('tf'), QuestionType.tf);
      expect(QuestionType.tf.firestoreValue, 'tf');
    });
  });

  group('QuizPhase', () {
    test('defaults to post when absent or unrecognized', () {
      expect(QuizPhase.fromFirestore(null), QuizPhase.post);
      expect(QuizPhase.fromFirestore('bogus'), QuizPhase.post);
      expect(QuizPhase.fromFirestore('pre'), QuizPhase.pre);
      expect(QuizPhase.pre.firestoreValue, 'pre');
    });
  });
}
