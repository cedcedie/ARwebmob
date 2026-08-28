import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/built_in_question.dart';
import '../../../core/models/quiz_attempt.dart';
import '../../../core/models/subject_key.dart';
import '../../../core/services/quiz_attempt_service.dart';

class QuizSessionState {
  const QuizSessionState({
    required this.questionIndex,
    required this.selectedAnswer,
    required this.answers,
    required this.showResult,
    required this.hintsUsed,
    required this.hintedQuestionIndices,
    required this.isComplete,
    required this.finalScore,
  });

  factory QuizSessionState.initial(int questionCount) => QuizSessionState(
        questionIndex: 0,
        selectedAnswer: null,
        answers: List<int>.filled(questionCount, -1),
        showResult: false,
        hintsUsed: 0,
        hintedQuestionIndices: const {},
        isComplete: false,
        finalScore: null,
      );

  final int questionIndex;
  final int? selectedAnswer;
  final List<int> answers;
  final bool showResult;
  final int hintsUsed;
  final Set<int> hintedQuestionIndices;
  final bool isComplete;
  final int? finalScore;

  QuizSessionState copyWith({
    int? questionIndex,
    int? selectedAnswer,
    bool clearSelectedAnswer = false,
    List<int>? answers,
    bool? showResult,
    int? hintsUsed,
    Set<int>? hintedQuestionIndices,
    bool? isComplete,
    int? finalScore,
  }) {
    return QuizSessionState(
      questionIndex: questionIndex ?? this.questionIndex,
      selectedAnswer: clearSelectedAnswer ? null : (selectedAnswer ?? this.selectedAnswer),
      answers: answers ?? this.answers,
      showResult: showResult ?? this.showResult,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      hintedQuestionIndices: hintedQuestionIndices ?? this.hintedQuestionIndices,
      isComplete: isComplete ?? this.isComplete,
      finalScore: finalScore ?? this.finalScore,
    );
  }
}

/// Owns the live state of one quiz attempt in progress. Not a screen widget
/// on purpose — QuizPlayerScreen only renders `state` and calls these
/// methods, so the hint/scoring/exit-submits-progress rules (Part 7.3) are
/// unit-testable without pumping any widget.
class QuizSessionController extends StateNotifier<QuizSessionState> {
  QuizSessionController({
    required this.studentId,
    required this.quizId,
    required this.subject,
    required this.questions,
    required this.quizAttemptService,
  })  : assert(questions.isNotEmpty, 'A quiz session requires at least one question'),
        super(QuizSessionState.initial(questions.length));

  final String studentId;
  final String quizId;
  final SubjectKey subject;
  final List<BuiltInQuestion> questions;
  final QuizAttemptService quizAttemptService;

  BuiltInQuestion get currentQuestion => questions[state.questionIndex];

  void selectAnswer(int optionIndex) {
    if (state.showResult) return;
    state = state.copyWith(selectedAnswer: optionIndex);
  }

  /// Records the current question's answer and shows right/wrong feedback.
  /// On the last question, this also persists the completed attempt.
  Future<void> submitAnswer() async {
    if (state.selectedAnswer == null) return;
    final updatedAnswers = [...state.answers];
    updatedAnswers[state.questionIndex] = state.selectedAnswer!;
    state = state.copyWith(answers: updatedAnswers, showResult: true);

    if (state.questionIndex == questions.length - 1) {
      await _persistAttempt(updatedAnswers);
    }
  }

  void useHint() {
    if (state.hintsUsed >= 3) return;
    if (state.hintedQuestionIndices.contains(state.questionIndex)) return;
    state = state.copyWith(
      hintsUsed: state.hintsUsed + 1,
      hintedQuestionIndices: {...state.hintedQuestionIndices, state.questionIndex},
    );
  }

  void nextQuestion() {
    if (state.questionIndex >= questions.length - 1) return;
    state = state.copyWith(
      questionIndex: state.questionIndex + 1,
      clearSelectedAnswer: true,
      showResult: false,
    );
  }

  /// Part 7.3: exiting mid-quiz submits whatever's currently answered, it
  /// does not discard progress. The in-progress question's selection counts
  /// even if `submitAnswer()` was never called for it.
  Future<void> submitAndExit() async {
    final updatedAnswers = [...state.answers];
    if (state.selectedAnswer != null) {
      updatedAnswers[state.questionIndex] = state.selectedAnswer!;
    }
    await _persistAttempt(updatedAnswers);
  }

  Future<void> _persistAttempt(List<int> answers) async {
    final correctCount = [
      for (var i = 0; i < questions.length; i++)
        if (answers[i] == questions[i].correctIndex) 1,
    ].length;
    final score = questions.isEmpty ? 0 : (correctCount / questions.length * 100).round();

    final eligibility = await quizAttemptService.checkEligibility(studentId, quizId);
    final attempt = QuizAttempt(
      id: 'attempt-$quizId-$studentId-${DateTime.now().millisecondsSinceEpoch}',
      quizId: quizId,
      studentId: studentId,
      attemptNumber: eligibility.attemptCount + 1,
      score: score,
      totalQuestions: questions.length,
      correctAnswers: correctCount,
      answers: answers,
      timestamp: DateTime.now().toIso8601String(),
      locked: !quizId.endsWith('-pre'), // pre-tests never lock, post-tests always do
    );

    await quizAttemptService.recordAttempt(studentId: studentId, attempt: attempt, subject: subject);

    state = state.copyWith(isComplete: true, finalScore: score);
  }
}

/// Identifies one quiz-in-progress session. Equality/hashCode are
/// deliberately based on `studentId` + `quizId` only — the rest of the
/// fields (`questions`, `subject`, `quizAttemptService`) are needed to
/// *construct* the controller the first time this key is seen, but must not
/// affect the `.family` provider's cache key, or two `QuizSessionKey`
/// instances built from different closures (but the same underlying quiz
/// attempt) would be treated as different sessions.
class QuizSessionKey {
  const QuizSessionKey({
    required this.studentId,
    required this.quizId,
    required this.subject,
    required this.questions,
    required this.quizAttemptService,
  });

  final String studentId;
  final String quizId;
  final SubjectKey subject;
  final List<BuiltInQuestion> questions;
  final QuizAttemptService quizAttemptService;

  /// Builds a key that identifies an existing cached session by
  /// [studentId] + [quizId] only — for `ref.invalidate(...)` calls, never
  /// for `ref.watch`/`ref.read`. Equality/hashCode ignore every other
  /// field (see the class doc above), so the placeholder `subject`/
  /// `questions` below are never read: `ref.invalidate` only needs a
  /// `==`-equal key to find (and dispose) whatever cached controller
  /// exists for this student+quiz — it never calls the provider's
  /// `create` callback. Do NOT `ref.watch`/`ref.read` a key built this
  /// way: with no cached entry yet, that would construct a real
  /// `QuizSessionController` from the empty placeholder question list and
  /// crash on its `assert(questions.isNotEmpty)`.
  QuizSessionKey.identity({
    required this.studentId,
    required this.quizId,
    required this.quizAttemptService,
  })  : subject = SubjectKey.chemistry,
        questions = const [];

  @override
  bool operator ==(Object other) =>
      other is QuizSessionKey && other.studentId == studentId && other.quizId == quizId;

  @override
  int get hashCode => Object.hash(studentId, quizId);
}

/// A single, top-level `.family` provider for the in-progress quiz session
/// — keyed on `(studentId, quizId)` via `QuizSessionKey`. Riverpod caches
/// family instances by key equality, so calling
/// `quizSessionControllerProvider(key)` with an equal key always returns the
/// *same* `QuizSessionController` instance, even across widget rebuilds.
/// This is the fix for a bug where the quiz route used to build a brand new
/// `StateNotifierProvider` inline on every rebuild, silently discarding
/// in-progress answers — see router.dart's `/quiz/:lessonId/:phase` route,
/// the only caller.
///
/// `.autoDispose`: without it, a completed session (`isComplete: true`,
/// stale `finalScore`) stayed cached forever, so re-entering the same quiz
/// after a retake-code unlock handed back the SAME finished controller and
/// `QuizPlayerScreen` jumped straight to the old results — the student
/// could never actually answer the retake (see this file's tests: "a
/// completed session does not leak into a fresh re-entry"). Callers also
/// call `ref.invalidate(quizSessionControllerProvider(key))` right before
/// navigating into a fresh attempt (see `LessonDetailScreen`'s
/// onStartPreTest/onStartPostTest wiring in router.dart) so a fresh session
/// is guaranteed deterministically at that exact moment, rather than
/// relying on widget-disposal timing alone. Ordinary mid-quiz rebuilds
/// (a hint tap, an answer selection) never trigger either path — they keep
/// watching the same key while the quiz screen stays mounted, so the
/// cached, in-progress controller is untouched (Part 7.3 / the original I2
/// fix).
final quizSessionControllerProvider = StateNotifierProvider.autoDispose
    .family<QuizSessionController, QuizSessionState, QuizSessionKey>(
  (ref, key) => QuizSessionController(
    studentId: key.studentId,
    quizId: key.quizId,
    subject: key.subject,
    questions: key.questions,
    quizAttemptService: key.quizAttemptService,
  ),
);
