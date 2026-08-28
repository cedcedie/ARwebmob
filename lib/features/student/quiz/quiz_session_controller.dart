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
  }) : super(QuizSessionState.initial(questions.length));

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
