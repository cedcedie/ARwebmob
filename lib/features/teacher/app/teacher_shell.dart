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

  static const itemAnalysisIndex = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            // The rail's sections (Lessons/Quizzes/Students/Access
            // Codes/Item Analysis) aren't subject-scoped, so the active-item
            // indicator uses a single accent (physics blue, doubling as the
            // app's general "current selection" signal) rather than a
            // per-subject color — see appMaterialTheme.navigationRailTheme.
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
              NavigationRailDestination(
                icon: Icon(LucideIcons.chartColumn),
                label: Text('Item Analysis'),
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
