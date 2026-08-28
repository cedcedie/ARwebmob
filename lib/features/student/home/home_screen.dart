import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/access_code_service.dart';
import '../../../core/services/progress_calculator.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncViewModel = ref.watch(homeViewModelProvider);

    return asyncViewModel.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Could not load your progress: $error')),
      data: (vm) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hi, ${vm.studentDisplayName}!', style: Theme.of(context).textTheme.headlineSmall),
          if (vm.currentQuarter != null && vm.currentWeek != null)
            Text('Quarter ${vm.currentQuarter} · Week ${vm.currentWeek}'),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: vm.percentComplete),
          Text('${(vm.percentComplete * 100).round()}% complete'),
          const SizedBox(height: 16),
          if (vm.continueLesson != null)
            Card(
              child: ListTile(
                title: const Text('Continue where you left off'),
                subtitle: Text(vm.continueLesson!.title),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => context.push('/lesson/${vm.continueLesson!.id}'),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatTile(label: 'Lessons completed', value: '${vm.lessonsCompletedCount}')),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(label: 'Quizzes taken', value: '${vm.quizzesTakenCount}')),
            ],
          ),
          const SizedBox(height: 16),
          Text('Recent quiz attempts', style: Theme.of(context).textTheme.titleMedium),
          for (final attempt in vm.lastAttempts)
            ListTile(
              title: Text(attempt.quizId),
              trailing: _ScoreBadge(score: attempt.score),
            ),
          const SizedBox(height: 16),
          _AccessCodeBox(onRedeem: vm.onRedeemCode),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});
  final num score;

  @override
  Widget build(BuildContext context) {
    final band = scoreBandFor(score);
    final color = switch (band) {
      ScoreBand.good => Colors.green,
      ScoreBand.caution => Colors.amber,
      ScoreBand.needsWork => Colors.red,
    };
    return Chip(
      label: Text('$score%'),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color),
    );
  }
}

class _AccessCodeBox extends StatefulWidget {
  const _AccessCodeBox({required this.onRedeem});
  final Future<AccessCodeResult> Function(String) onRedeem;

  @override
  State<_AccessCodeBox> createState() => _AccessCodeBoxState();
}

class _AccessCodeBoxState extends State<_AccessCodeBox> {
  final _controller = TextEditingController();
  String? _message;
  bool _loading = false;

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final result = await widget.onRedeem(_controller.text);
    setState(() {
      _loading = false;
      _message = result.message;
      if (result.success) _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter code from teacher'),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'ENTER CODE HERE'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Applying...' : 'Apply Code'),
            ),
            if (_message != null) Text(_message!),
          ],
        ),
      ),
    );
  }
}
