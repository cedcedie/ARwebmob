// lib/features/teacher/widgets/subject_accent_cell.dart
import 'package:flutter/widgets.dart';

import '../../../core/models/subject_key.dart';
import '../../../core/theme/app_theme.dart';

/// Wraps a lesson/quiz table cell's content with a colored left-edge strip
/// in that row's subject-accent color — the signature touch that lets a
/// subject read at a glance without a badge buried in a cell.
class SubjectAccentCell extends StatelessWidget {
  const SubjectAccentCell({
    super.key,
    required this.subject,
    required this.child,
  });

  final SubjectKey subject;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: subjectColor(subject), width: 4),
        ),
      ),
      child: child,
    );
  }
}
