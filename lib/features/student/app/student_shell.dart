import 'package:flutter/material.dart';

/// Bottom-nav scaffold shared by Home / Learn / Progress (Part 10). Screens
/// themselves are free to redesign (Part 12); this only fixes the three
/// destinations and their order.
class StudentShell extends StatelessWidget {
  const StudentShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Learn'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Progress'),
        ],
      ),
    );
  }
}
