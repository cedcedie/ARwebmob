import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _autoContinueSeconds = 4;

/// Part 7.4: pass shows a visibly cancelable auto-continue countdown; fail
/// never auto-redirects and states the retry rule plainly.
class QuizResultsScreen extends StatefulWidget {
  const QuizResultsScreen({super.key, required this.score, required this.isPreTest});
  final int score;

  /// Which retry-rule copy to show on fail: pre-tests retry anytime with no
  /// code, post-tests require a teacher-issued retake code.
  final bool isPreTest;

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  late int _secondsLeft = _passed ? _autoContinueSeconds : 0;
  Timer? _timer;
  bool get _passed => widget.score >= 50;

  @override
  void initState() {
    super.initState();
    if (_passed) _scheduleTick();
  }

  void _scheduleTick() {
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        context.go('/progress');
        return;
      }
      setState(() => _secondsLeft -= 1);
      _scheduleTick();
    });
  }

  void _cancelAutoContinue() {
    _timer?.cancel();
    setState(() => _secondsLeft = -1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_passed ? 'Nice work!' : 'Not quite there yet',
                style: Theme.of(context).textTheme.headlineMedium),
            Text('${widget.score}%'),
            if (!_passed)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.isPreTest
                      ? "This is a pre-test — you can retry it anytime, no code needed."
                      : 'Ask your teacher for a retake code to try this test again.',
                ),
              ),
            FilledButton(
              onPressed: () => context.go('/progress'),
              child: const Text('View My Progress'),
            ),
            if (_passed && _secondsLeft > 0)
              TextButton(
                onPressed: _cancelAutoContinue,
                child: Text('Continuing in $_secondsLeft s — tap to stay here'),
              ),
          ],
        ),
      ),
    );
  }
}
