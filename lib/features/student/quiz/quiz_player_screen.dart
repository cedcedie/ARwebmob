import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/built_in_question.dart';
import 'quiz_session_controller.dart';
import 'quiz_results_screen.dart';

/// Renders whatever `QuizSessionController.state` says — all Part 7.3 rules
/// (hints, scoring, exit-submits-progress) live in the controller, tested
/// separately; this widget is presentation only.
class QuizPlayerScreen extends ConsumerWidget {
  const QuizPlayerScreen({
    super.key,
    required this.controllerProvider,
  });

  final StateNotifierProvider<QuizSessionController, QuizSessionState> controllerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(controllerProvider);
    final controller = ref.read(controllerProvider.notifier);
    final question = controller.currentQuestion;
    final isTrueFalse = question.type.name == 'tf';
    final visibleOptions = isTrueFalse ? question.options.sublist(0, 2) : question.options;

    if (state.isComplete) {
      return QuizResultsScreen(score: state.finalScore ?? 0);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${state.questionIndex + 1} of ${controller.questions.length}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context, controller),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(question.question, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            for (var i = 0; i < visibleOptions.length; i++)
              RadioListTile<int>(
                value: i,
                groupValue: state.selectedAnswer,
                onChanged: state.showResult ? null : (v) => controller.selectAnswer(v!),
                title: Text(visibleOptions[i]),
              ),
            if (!state.showResult)
              TextButton.icon(
                onPressed: state.hintsUsed < 3 && !state.hintedQuestionIndices.contains(state.questionIndex)
                    ? controller.useHint
                    : null,
                icon: const Icon(Icons.lightbulb_outline),
                label: Text('Hint (${3 - state.hintsUsed} left)'),
              ),
            if (state.hintedQuestionIndices.contains(state.questionIndex) && !state.showResult)
              Text('Hint: ${question.hint}'),
            if (state.showResult)
              Text(
                state.selectedAnswer == question.correctIndex ? 'Correct!' : 'Incorrect',
                style: TextStyle(
                  color: state.selectedAnswer == question.correctIndex ? Colors.green : Colors.orange,
                ),
              ),
            const Spacer(),
            FilledButton(
              onPressed: state.showResult
                  ? controller.nextQuestion
                  : (state.selectedAnswer == null ? null : controller.submitAnswer),
              child: Text(state.showResult ? 'Next Question' : 'Submit Answer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context, QuizSessionController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Test?'),
        content: const Text('Going back will submit your test with your current answers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continue Quiz')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit & Exit')),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.submitAndExit();
      if (context.mounted) context.pop();
    }
  }
}
