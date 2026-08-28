import 'models/quiz_phase.dart';

/// Result of parsing a quiz id string. Non-builtin (teacher-authored) quiz
/// ids return `lessonId: null`; `phase` still defaults to `post` in that case
/// but callers should check `isBuiltin` before relying on it.
typedef ParsedBuiltinId = ({bool isBuiltin, String? lessonId, QuizPhase phase});

const String _prefix = 'builtin-';
const String _preSuffix = '-pre';
const String _postSuffix = '-post';

/// Build a phase-scoped built-in quiz id for a lesson, e.g.
/// `builtinQuizId('q1w1', QuizPhase.pre)` → `'builtin-q1w1-pre'`.
String builtinQuizId(String lessonId, QuizPhase phase) {
  return '$_prefix$lessonId-${phase.firestoreValue}';
}

/// Parse a quiz id string. Mirrors `parseBuiltinId` from the retired web
/// app's `src/lib/quizId.ts` exactly — a legacy unsuffixed built-in id
/// (`builtin-{lessonId}`, no `-pre`/`-post`) is treated as a post-test.
ParsedBuiltinId parseBuiltinId(String quizId) {
  if (!quizId.startsWith(_prefix)) {
    return (isBuiltin: false, lessonId: null, phase: QuizPhase.post);
  }
  final rest = quizId.substring(_prefix.length);
  if (rest.endsWith(_preSuffix)) {
    return (
      isBuiltin: true,
      lessonId: rest.substring(0, rest.length - _preSuffix.length),
      phase: QuizPhase.pre,
    );
  }
  if (rest.endsWith(_postSuffix)) {
    return (
      isBuiltin: true,
      lessonId: rest.substring(0, rest.length - _postSuffix.length),
      phase: QuizPhase.post,
    );
  }
  // Legacy unsuffixed id — the whole remainder is the lessonId.
  return (isBuiltin: true, lessonId: rest, phase: QuizPhase.post);
}
