import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Side-nav desktop shell for the Teacher Web target (Part 2.2).
class TeacherShell extends StatelessWidget {
  const TeacherShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            // The rail's sections (Lessons/Quizzes/Students/Access Codes)
            // aren't subject-scoped, so the active-item indicator uses a
            // single accent (physics blue, doubling as the app's general
            // "current selection" signal) rather than a per-subject color —
            // see appMaterialTheme.navigationRailTheme.
            //
            // Item Analysis intentionally has no rail entry of its own: it
            // is inherently quiz-scoped (there is no standalone "all item
            // analysis" list to land on), so it's reachable only via the
            // quiz table's per-row icon button, which always carries the
            // quiz id/title it needs. A rail entry with no real independent
            // destination would either silently redirect elsewhere or need
            // an explanatory hint bolted onto another screen — an honest
            // "quiz-scoped only" affordance beats either.
            destinations: const [
              NavigationRailDestination(
                icon: Icon(LucideIcons.bookOpen),
                label: Text('Lessons'),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.clipboardList),
                label: Text('Quizzes'),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.users),
                label: Text('Students'),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.keyRound),
                label: Text('Access Codes'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
