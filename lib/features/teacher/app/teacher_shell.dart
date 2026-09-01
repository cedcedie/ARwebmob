import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/theme_mode_provider.dart';

/// Adaptive shell for the Teacher Web target.
///
/// Three layouts, chosen by viewport width:
/// - `>= 1000`: full-width `NavigationRail` with icon + label.
/// - `720–999`: icon-only `NavigationRail` (labels dropped, destinations
///   stay reachable by icon + tooltip via `Text` label acting as the
///   rail's built-in tooltip source).
/// - `< 720`: an `AppBar` + `Drawer` — the rail's fixed side column doesn't
///   fit a narrow/tablet-portrait viewport, so navigation moves behind a
///   hamburger menu, the same pattern the rest of the web reaches for at
///   this breakpoint.
///
/// A light/dark toggle (see `theme_mode_provider.dart`) lives in the rail's
/// leading slot on wide layouts and the `AppBar`'s actions on narrow ones.
class TeacherShell extends ConsumerWidget {
  const TeacherShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _labels = [
    'Dashboard',
    'Lessons',
    'Quizzes',
    'Students',
    'Access Codes',
  ];

  static const _icons = [
    LucideIcons.layoutDashboard,
    LucideIcons.bookOpen,
    LucideIcons.clipboardList,
    LucideIcons.users,
    LucideIcons.keyRound,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 720;
    final isExtended = width >= 1000;

    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final themeToggle = IconButton(
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon),
      onPressed: () => toggleThemeMode(ref),
    );

    final destinations = [
      for (var i = 0; i < _labels.length; i++)
        NavigationRailDestination(
          icon: Icon(_icons[i]),
          label: Text(_labels[i]),
        ),
    ];

    final clampedIndex = selectedIndex.clamp(0, _labels.length - 1);

    if (isCompact) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_labels[clampedIndex]),
          actions: [themeToggle, const SizedBox(width: 8)],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (var i = 0; i < _labels.length; i++)
                  ListTile(
                    leading: Icon(_icons[i]),
                    title: Text(_labels[i]),
                    selected: i == clampedIndex,
                    onTap: () {
                      Navigator.of(context).pop();
                      onDestinationSelected(i);
                    },
                  ),
              ],
            ),
          ),
        ),
        body: child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: clampedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: isExtended
                ? NavigationRailLabelType.all
                : NavigationRailLabelType.none,
            // Item Analysis intentionally has no rail entry of its own: it
            // is inherently quiz-scoped (there is no standalone "all item
            // analysis" list to land on), so it's reachable only via the
            // quiz table's per-row icon button, which always carries the
            // quiz id/title it needs. A rail entry with no real independent
            // destination would either silently redirect elsewhere or need
            // an explanatory hint bolted onto another screen — an honest
            // "quiz-scoped only" affordance beats either.
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: themeToggle,
            ),
            destinations: destinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
