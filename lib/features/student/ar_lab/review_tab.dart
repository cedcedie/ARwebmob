import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'ar_lab_providers.dart';

class ReviewTab extends StatelessWidget {
  const ReviewTab({super.key, required this.vm});

  final ArLabViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.celebration, size: 48),
          const SizedBox(height: 12),
          Text('Lesson Complete', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: vm.hasPostTest && vm.postTestEligible
                ? () {
                    vm.onStartPostTest();
                    context.push('/quiz/${vm.lessonId}/post');
                  }
                : null,
            child: Text(
              !vm.hasPostTest
                  ? 'No Post-Test for this lesson'
                  : vm.postTestEligible
                      ? 'Start Post-Test'
                      : (vm.postTestReason ?? 'Post-Test locked'),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => context.go('/progress'),
            child: const Text('Go to Progress'),
          ),
        ],
      ),
    );
  }
}
