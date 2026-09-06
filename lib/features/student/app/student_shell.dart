import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/student_auth_providers.dart';

const _kTabTitles = ['Home', 'Learn', 'Progress'];

/// Bottom-nav scaffold shared by Home / Learn / Progress (Part 10). Screens
/// themselves are free to redesign (Part 12); this only fixes the three
/// destinations and their order.
///
/// Also the one shared place a sign-out action can live: none of the three
/// tab screens build their own `AppBar` (see home_screen.dart/
/// learn_screen.dart), so — same gap Teacher Web had — there was previously
/// no way to sign out short of clearing the browser/app's stored session.
class StudentShell extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final title = _kTabTitles[currentIndex.clamp(0, _kTabTitles.length - 1)];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text("You'll need to sign in again to continue."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await ref.read(studentAuthServiceProvider).signOut();
  }
}
