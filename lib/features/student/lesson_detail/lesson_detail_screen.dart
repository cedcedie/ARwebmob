import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'lesson_detail_providers.dart';

class LessonDetailScreen extends ConsumerWidget {
  const LessonDetailScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncViewModel = ref.watch(lessonDetailViewModelProvider(lessonId));

    return Scaffold(
      appBar: AppBar(title: const Text('Lesson')),
      body: asyncViewModel.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Could not load this lesson: $error')),
        data: (vm) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(vm.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(vm.summary),
            const SizedBox(height: 24),
            // TEMPORARY: stands in for Phase 3's real AR Review-phase
            // completion signal — see lesson_detail_providers.dart's doc
            // comment. Phase 3 replaces this button with the real flow.
            if (!vm.isRead)
              FilledButton(
                onPressed: () async {
                  await vm.onMarkAsRead();
                },
                child: const Text('Mark as Read'),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                vm.onStartPreTest();
                context.push('/quiz/${vm.lessonId}/pre');
              },
              child: const Text('Pre-Test'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: vm.postTestEligible
                  ? () {
                      vm.onStartPostTest();
                      context.push('/quiz/${vm.lessonId}/post');
                    }
                  : null,
              child: Text(vm.postTestEligible ? 'Post-Test' : (vm.postTestReason ?? 'Post-Test locked')),
            ),
          ],
        ),
      ),
    );
  }
}
