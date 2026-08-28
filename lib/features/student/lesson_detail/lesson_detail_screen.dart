import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/access_code_service.dart';
import '../access_code/access_code_sheet.dart';
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
            // A lesson with no pre-test bank (most of the curriculum — Task
            // 1's data is intentionally sparse) must not offer a Pre-Test
            // action; the /quiz/:lessonId/pre route has no question bank to
            // render for it.
            if (vm.hasPreTest)
              OutlinedButton(
                onPressed: () {
                  vm.onStartPreTest();
                  context.push('/quiz/${vm.lessonId}/pre');
                },
                child: const Text('Pre-Test'),
              ),
            if (vm.hasPreTest) const SizedBox(height: 8),
            OutlinedButton(
              onPressed: vm.postTestEligible
                  ? () {
                      vm.onStartPostTest();
                      context.push('/quiz/${vm.lessonId}/post');
                    }
                  : null,
              child: Text(vm.postTestEligible ? 'Post-Test' : (vm.postTestReason ?? 'Post-Test locked')),
            ),
            if (!vm.postTestEligible) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => showAccessCodeSheet(
                  context,
                  studentId: vm.studentId,
                  accessCodeService: vm.accessCodeService,
                  targetId: vm.lessonId,
                  targetType: AccessCodeTarget.quiz,
                  title: 'Enter retake code for ${vm.title}',
                ),
                child: const Text('Have a retake code?'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
