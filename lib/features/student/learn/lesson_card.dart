// lib/features/student/learn/lesson_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/access_code_service.dart';
import '../access_code/access_code_sheet.dart';
import 'learn_providers.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.data,
    required this.studentId,
    required this.accessCodeService,
  });

  final LessonCardData data;
  final String studentId;
  final AccessCodeService accessCodeService;

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
            _showAccessCodeSheet(context);
          }
        },
      ),
    );
  }

  void _showAccessCodeSheet(BuildContext context) {
    showAccessCodeSheet(
      context,
      studentId: studentId,
      accessCodeService: accessCodeService,
      targetId: data.lessonId,
      targetType: AccessCodeTarget.lesson,
      title: 'Enter code to unlock ${data.title}',
    );
  }
}
