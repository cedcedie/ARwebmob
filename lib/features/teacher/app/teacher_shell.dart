import 'package:flutter/material.dart';

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
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: Text('Lessons'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.quiz_outlined),
                selectedIcon: Icon(Icons.quiz),
                label: Text('Quizzes'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Students'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.vpn_key_outlined),
                selectedIcon: Icon(Icons.vpn_key),
                label: Text('Access Codes'),
              ),
              NavigationRailDestination(
                icon: Tooltip(
                  message: 'Coming in Phase 5',
                  child: Icon(Icons.analytics_outlined, color: Theme.of(context).disabledColor),
                ),
                selectedIcon: Tooltip(
                  message: 'Coming in Phase 5',
                  child: Icon(Icons.analytics, color: Theme.of(context).disabledColor),
                ),
                label: Text('Item Analysis', style: TextStyle(color: Theme.of(context).disabledColor)),
                disabled: true,
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
