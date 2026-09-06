import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/access_code_service.dart';
import '../access_code/access_code_sheet.dart';
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
          Text(
            'Lesson Complete',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
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
          // A locked post-test used to be a dead end: the button above went
          // disabled reading "Ask your teacher for a retake code" with
          // nowhere to actually type one. The only retake-code entry point
          // in the whole app was the results screen shown immediately after
          // an attempt — so a student who left that screen before their
          // teacher issued the code could never take the test again. Home's
          // generic code box can't redeem retakes either: those branches of
          // AccessCodeService.redeem require targetType/targetId, which it
          // doesn't pass.
          if (vm.hasPostTest && !vm.postTestEligible) ...[
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              key: const Key('review-tab-enter-retake-code'),
              onPressed: () => showAccessCodeSheet(
                context,
                studentId: vm.studentId,
                accessCodeService: vm.accessCodeService,
                targetId: vm.lessonId,
                targetType: AccessCodeTarget.quiz,
                title: 'Enter retake code',
              ),
              icon: const Icon(Icons.vpn_key_outlined, size: 18),
              label: const Text('Enter retake code'),
            ),
          ],
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
