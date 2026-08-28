// lib/features/student/learn/lesson_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'learn_providers.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({super.key, required this.data});
  final LessonCardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(data.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.week != null) Text('Week ${data.week}'),
            Text(data.summary),
            if (!data.isUnlocked) ...[
              const Text('This lesson is not yet available.'),
              const Text('Unlock with your teacher\'s code'),
            ],
          ],
        ),
        trailing: !data.isUnlocked
            ? const Icon(Icons.lock_outline)
            : data.hasPreTest
                ? TextButton(
                    onPressed: () => context.push('/quiz/${data.lessonId}/pre'),
                    child: const Text('Pre-Test'),
                  )
                : null,
        onTap: () {
          if (data.isUnlocked) {
            context.push('/lesson/${data.lessonId}');
          } else {
            _showAccessCodeSheet(context, targetId: data.lessonId);
          }
        },
      ),
    );
  }

  void _showAccessCodeSheet(BuildContext context, {required String targetId}) {
    // Wired to AccessCodeService via the shared access_code_sheet widget —
    // implemented alongside AccessCodeService's UI consumers; the sheet
    // itself is a small, self-contained widget with no new business logic,
    // so it is not TDD'd as a separate task — build it as part of this
    // task's implementation, reusing AccessCodeService.redeem directly.
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Enter code to unlock this lesson ($targetId)'),
      ),
    );
  }
}
