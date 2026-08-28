import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/quiz_phase.dart';
import 'package:ar_science_explorer/core/quiz_id.dart';

void main() {
  test('builtinQuizId builds phase-scoped ids', () {
    expect(builtinQuizId('q1w1', QuizPhase.pre), 'builtin-q1w1-pre');
    expect(builtinQuizId('q1w1', QuizPhase.post), 'builtin-q1w1-post');
  });

  test('parseBuiltinId parses a pre-test id', () {
    final parsed = parseBuiltinId('builtin-q1w1-pre');
    expect(parsed.isBuiltin, true);
    expect(parsed.lessonId, 'q1w1');
    expect(parsed.phase, QuizPhase.pre);
  });

  test('parseBuiltinId parses a post-test id', () {
    final parsed = parseBuiltinId('builtin-q2w5-post');
    expect(parsed.isBuiltin, true);
    expect(parsed.lessonId, 'q2w5');
    expect(parsed.phase, QuizPhase.post);
  });

  test('parseBuiltinId treats a legacy unsuffixed id as post', () {
    final parsed = parseBuiltinId('builtin-q1w1');
    expect(parsed.isBuiltin, true);
    expect(parsed.lessonId, 'q1w1');
    expect(parsed.phase, QuizPhase.post);
  });

  test('parseBuiltinId reports non-builtin ids with a null lessonId', () {
    final parsed = parseBuiltinId('teacher-quiz-abc123');
    expect(parsed.isBuiltin, false);
    expect(parsed.lessonId, null);
    expect(parsed.phase, QuizPhase.post);
  });
}
