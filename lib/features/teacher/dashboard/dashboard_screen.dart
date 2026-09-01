// lib/features/teacher/dashboard/dashboard_screen.dart
//
// Teacher Web landing page — an at-a-glance overview of lesson/quiz/roster/
// access-code activity, plus quick links into each section. Previously the
// shell had no landing destination at all (it opened straight into
// Lessons), so a teacher got a data table with no orientation. This screen
// composes the same four `StreamProvider`s the list screens already use
// (lessonsViewModelProvider, quizzesViewModelProvider,
// studentsViewModelProvider, accessCodesViewModelProvider) rather than
// introduce a new aggregate provider — each stat tile fails/loads
// independently, so one slow or errored stream never blocks the rest of the
// dashboard from rendering.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/subject_key.dart';
import '../../../core/theme/app_theme.dart';
import '../access_codes/access_codes_providers.dart';
import '../lessons/lessons_providers.dart';
import '../quizzes/quizzes_providers.dart';
import '../students/students_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 720;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isNarrow ? 16 : 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: ShadTheme.of(context).textTheme.h2),
              const SizedBox(height: 4),
              Text(
                "Here's what's happening across your classes.",
                style: ShadTheme.of(
                  context,
                ).textTheme.muted.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 24),
              _StatGrid(isNarrow: isNarrow),
              const SizedBox(height: 32),
              Text(
                'Lessons by subject',
                style: ShadTheme.of(context).textTheme.h4,
              ),
              const SizedBox(height: 12),
              const _SubjectBreakdownCard(),
              const SizedBox(height: 32),
              Text('Quick actions', style: ShadTheme.of(context).textTheme.h4),
              const SizedBox(height: 12),
              _QuickActions(isNarrow: isNarrow),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatGrid extends ConsumerWidget {
  const _StatGrid({required this.isNarrow});

  final bool isNarrow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsViewModelProvider);
    final quizzes = ref.watch(quizzesViewModelProvider);
    final students = ref.watch(studentsViewModelProvider);
    final accessCodes = ref.watch(accessCodesViewModelProvider);

    final unusedCodes = accessCodes.valueOrNull?.issuedCodes
        .where((c) => c.status == 'unused')
        .length;

    final tiles = [
      _StatTile(
        icon: LucideIcons.bookOpen,
        label: 'Lessons',
        value: lessons.valueOrNull?.rows.length,
        isLoading: lessons.isLoading,
        hasError: lessons.hasError,
        accent: AppColors.chemistry,
        onTap: () => context.go('/teacher/lessons'),
      ),
      _StatTile(
        icon: LucideIcons.clipboardList,
        label: 'Quizzes',
        value: quizzes.valueOrNull?.rows.length,
        isLoading: quizzes.isLoading,
        hasError: quizzes.hasError,
        accent: AppColors.physics,
        onTap: () => context.go('/teacher/quizzes'),
      ),
      _StatTile(
        icon: LucideIcons.users,
        label: 'Active students',
        value: students.valueOrNull?.students
            .where((s) => !s.isArchived)
            .length,
        isLoading: students.isLoading,
        hasError: students.hasError,
        accent: AppColors.biology,
        onTap: () => context.go('/teacher/students'),
      ),
      _StatTile(
        icon: LucideIcons.keyRound,
        label: 'Unused access codes',
        value: unusedCodes,
        isLoading: accessCodes.isLoading,
        hasError: accessCodes.hasError,
        accent: AppColors.success,
        onTap: () => context.go('/teacher/access-codes'),
      ),
    ];

    return GridView.count(
      crossAxisCount: isNarrow ? 1 : (width(context) < 1040 ? 2 : 4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: isNarrow ? 2.6 : 1.6,
      children: tiles,
    );
  }

  double width(BuildContext context) => MediaQuery.sizeOf(context).width;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isLoading,
    required this.hasError,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int? value;
  final bool isLoading;
  final bool hasError;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: accent),
                  ),
                  Icon(
                    LucideIcons.arrowUpRight,
                    size: 16,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (hasError)
                Text(
                  '—',
                  style: theme.textTheme.h3.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                )
              else if (isLoading || value == null)
                const _StatValueSkeleton()
              else
                Text('$value', style: theme.textTheme.h2),
              const SizedBox(height: 2),
              Text(label, style: theme.textTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatValueSkeleton extends StatelessWidget {
  const _StatValueSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 48,
      decoration: BoxDecoration(
        color: ShadTheme.of(context).colorScheme.muted,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// Horizontal-bar breakdown of lesson count per subject — a simple colored
/// `Row`-of-`Expanded`-flex bar rather than pulling in a charting package
/// for one stat.
class _SubjectBreakdownCard extends ConsumerWidget {
  const _SubjectBreakdownCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsViewModelProvider);
    final theme = ShadTheme.of(context);

    return ShadCard(
      child: lessons.when(
        loading: () => const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, _) => Text(
          "Couldn't load subject breakdown.",
          style: theme.textTheme.muted,
        ),
        data: (vm) {
          final counts = <SubjectKey, int>{
            for (final subject in SubjectKey.values) subject: 0,
          };
          for (final row in vm.rows) {
            counts[row.lesson.subject] = (counts[row.lesson.subject] ?? 0) + 1;
          }
          final total = counts.values.fold(0, (a, b) => a + b);

          if (total == 0) {
            return Text('No lessons yet.', style: theme.textTheme.muted);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      for (final subject in SubjectKey.values)
                        if ((counts[subject] ?? 0) > 0)
                          Expanded(
                            flex: counts[subject]!,
                            child: Container(color: subject.accentColor),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  for (final subject in SubjectKey.values)
                    _LegendItem(
                      color: subject.accentColor,
                      label: subject.name,
                      count: counts[subject] ?? 0,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '${label[0].toUpperCase()}${label.substring(1)} · $count',
          style: theme.textTheme.small,
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.isNarrow});

  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: LucideIcons.plus,
        label: 'New lesson',
        route: '/teacher/lessons',
      ),
      (
        icon: LucideIcons.clipboardPlus,
        label: 'New quiz',
        route: '/teacher/quizzes',
      ),
      (
        icon: LucideIcons.userPlus,
        label: 'Add student',
        route: '/teacher/students',
      ),
      (
        icon: LucideIcons.keyRound,
        label: 'Issue access code',
        route: '/teacher/access-codes',
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final action in actions)
          ShadButton.outline(
            leading: Icon(action.icon, size: 16),
            onPressed: () => context.go(action.route),
            child: Text(action.label),
          ),
      ],
    );
  }
}
