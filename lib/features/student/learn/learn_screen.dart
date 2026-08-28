import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/subject_key.dart';
import 'learn_providers.dart';
import 'lesson_card.dart';

const _subjectOrder = [SubjectKey.chemistry, SubjectKey.biology, SubjectKey.physics];

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncViewModel = ref.watch(learnViewModelProvider);

    return asyncViewModel.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Could not load lessons: $error')),
      data: (vm) => DefaultTabController(
        length: _subjectOrder.length,
        initialIndex: _subjectOrder.indexOf(vm.activeSubject),
        child: Column(
          children: [
            TabBar(
              onTap: (i) => vm.onSelectSubject(_subjectOrder[i]),
              tabs: const [Tab(text: 'Chemistry'), Tab(text: 'Biology'), Tab(text: 'Physics')],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [for (final card in vm.cards) LessonCard(data: card)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
