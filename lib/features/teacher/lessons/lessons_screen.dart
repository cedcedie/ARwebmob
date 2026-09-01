import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/subject_key.dart';
import '../../../core/models/teacher_lesson.dart';
import '../widgets/error_state.dart';
import '../widgets/subject_accent_cell.dart';
import 'lesson_form.dart';
import 'lessons_providers.dart';

/// Narrow-viewport breakpoint, matching `TeacherShell`'s own `isCompact`
/// cutoff (`lib/features/teacher/app/teacher_shell.dart`) — below this width
/// the nav shell has already collapsed to a Drawer, so a fixed-width
/// `DataTable2` (900px `minWidth`) forces horizontal scrolling on top of
/// horizontal scrolling. A single-column card list reads far better there.
const _kCompactBreakpoint = 720.0;

/// Theme-aware subject accent lookup. Prefer this over calling
/// `subjectColor()`/`.accentColor` directly (`app_theme.dart`) — those
/// always resolve to the *light* palette regardless of the active theme
/// mode, whereas `ShadTheme.of(context).colorScheme.custom` carries the
/// dark-mode variant automatically once `appShadColorSchemeDark` is active.
Color _subjectAccent(BuildContext context, SubjectKey subject) {
  final custom = ShadTheme.of(context).colorScheme.custom;
  final key = switch (subject) {
    SubjectKey.chemistry => 'chemistry',
    SubjectKey.biology => 'biology',
    SubjectKey.physics => 'physics',
  };
  return custom[key] as Color;
}

class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVm = ref.watch(lessonsViewModelProvider);

    return asyncVm.when(
      loading: () => const _LessonsSkeleton(),
      error: (error, _) => ErrorState(
        message: humanizeLoadError(error, subjectLabel: 'lessons'),
        onRetry: () => ref.invalidate(lessonsViewModelProvider),
      ),
      data: (vm) => _LessonsBody(viewModel: vm),
    );
  }
}

/// Loading placeholder shaped like the eventual content (header + a stack of
/// card-sized bars) rather than a bare centered spinner — gives the teacher
/// an immediate sense of "a lessons list is coming" instead of a blank beat.
class _LessonsSkeleton extends StatelessWidget {
  const _LessonsSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _skeletonBar(scheme, width: 120, height: 28),
              const Spacer(),
              _skeletonBar(scheme, width: 130, height: 36),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < 5; i++) ...[
            _skeletonBar(scheme, width: double.infinity, height: 56),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _skeletonBar(
    ShadColorScheme scheme, {
    required double width,
    required double height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(color: scheme.muted),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
      duration: 700.ms,
      begin: 0.5,
    );
  }
}

class _LessonsBody extends HookWidget {
  const _LessonsBody({required this.viewModel});

  final LessonsViewModel viewModel;

  Future<void> _openForm(BuildContext context, {TeacherLesson? initial}) async {
    final isCreate = initial == null;
    final width = MediaQuery.sizeOf(context).width;
    await showShadDialog<void>(
      context: context,
      // An in-progress multi-field lesson edit is expensive to lose to an
      // accidental outside click — require the explicit Cancel action (or
      // a successful submit) to close instead.
      barrierDismissible: false,
      builder: (dialogContext) {
        return ShadDialog(
          title: Text(isCreate ? 'Add lesson' : 'Edit lesson'),
          // Full-bleed-ish on narrow viewports (leaves just enough margin
          // for the dialog chrome) instead of a fixed 640px that would
          // overflow a phone-width window.
          child: SizedBox(
            width: width < _kCompactBreakpoint ? width - 64 : 640,
            // `LessonForm` uses Material `FormBuilderTextField`s, which need
            // a `Material` ancestor — `ShadDialog` doesn't provide one (it's
            // built entirely from shadcn primitives), so supply a
            // transparent one here rather than changing every field.
            child: Material(
              type: MaterialType.transparency,
              child: LessonForm(
                initial: initial,
                quizOptions: viewModel.quizOptions,
                submitLabel: isCreate ? 'Create' : 'Save',
                refetchLesson: viewModel.fetchLessonById,
                onSubmit: (lesson) async {
                  if (isCreate) {
                    await viewModel.onCreateLesson(lesson);
                  } else {
                    await viewModel.onUpdateLesson(lesson);
                  }
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    ShadToaster.of(context).show(
                      ShadToast(
                        description: Text(
                          isCreate ? 'Lesson created' : 'Lesson saved',
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmArchive(BuildContext context, String lessonId) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Archive lesson?'),
        description: const Text(
          'Archived lessons disappear from this list but remain referenced elsewhere.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ShadButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Item 2: mirrors students_screen.dart's `_archiveSelected` feedback
    // pattern — this previously had no try/catch and no success toast at
    // all, so a failed archive silently did nothing and a successful one
    // gave no confirmation either.
    try {
      await viewModel.onArchiveLesson(lessonId);
      if (!context.mounted) return;
      ShadToaster.of(
        context,
      ).show(const ShadToast(description: Text('Lesson archived')));
    } catch (error) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            humanizeSubmitError(error, actionLabel: 'archive this lesson'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < _kCompactBreakpoint;

    // Column sorting (heuristic 7 — acceleration for a teacher managing a
    // growing lesson list): index 0 = Title (alphabetical), index 2 =
    // Quarter/Week (curriculum order) — the two orderings a teacher
    // actually reaches for for this table.
    final sortColumnIndex = useState<int?>(null);
    final sortAscending = useState(true);

    final rows = [...viewModel.rows];
    final List<DisplayLesson> displayRows;
    if (sortColumnIndex.value == 0) {
      rows.sort(
        (a, b) => a.lesson.title.toLowerCase().compareTo(
          b.lesson.title.toLowerCase(),
        ),
      );
      displayRows = sortAscending.value ? rows : rows.reversed.toList();
    } else if (sortColumnIndex.value == 2) {
      // A lesson missing quarter/week has no place in the curriculum
      // ordering — it must sort to the END regardless of direction, never
      // "before Quarter 1" the way `(quarter ?? 0) * 100 + (week ?? 0)`
      // used to place it on an ascending sort. So the direction flip is
      // baked into this comparator (rather than reversed afterward like
      // the other columns below) and only applies to the two-value
      // comparison; the null-goes-last branches are direction-independent.
      int? key(DisplayLesson row) {
        final quarter = row.lesson.quarter;
        final week = row.lesson.week;
        if (quarter == null || week == null) return null;
        return quarter * 100 + week;
      }

      rows.sort((a, b) {
        final keyA = key(a);
        final keyB = key(b);
        if (keyA == null && keyB == null) return 0;
        if (keyA == null) return 1;
        if (keyB == null) return -1;
        final cmp = keyA.compareTo(keyB);
        return sortAscending.value ? cmp : -cmp;
      });
      displayRows = rows;
    } else {
      displayRows = sortAscending.value ? rows : rows.reversed.toList();
    }

    void handleSort(int columnIndex, bool ascending) {
      sortColumnIndex.value = columnIndex;
      sortAscending.value = ascending;
    }

    final header = isCompact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lessons', style: ShadTheme.of(context).textTheme.h3),
              const SizedBox(height: 4),
              Text(
                '${displayRows.length} lesson'
                '${displayRows.length == 1 ? '' : 's'}',
                style: ShadTheme.of(
                  context,
                ).textTheme.muted.copyWith(color: scheme.mutedForeground),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ShadButton(
                  onPressed: () => _openForm(context),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.plus, size: 16),
                      SizedBox(width: 8),
                      Text('Add Lesson'),
                    ],
                  ),
                ),
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lessons', style: ShadTheme.of(context).textTheme.h3),
                  const SizedBox(height: 4),
                  Text(
                    '${displayRows.length} lesson'
                    '${displayRows.length == 1 ? '' : 's'}',
                    style: ShadTheme.of(
                      context,
                    ).textTheme.muted.copyWith(color: scheme.mutedForeground),
                  ),
                ],
              ),
              const Spacer(),
              ShadButton(
                onPressed: () => _openForm(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 16),
                    SizedBox(width: 8),
                    Text('Add Lesson'),
                  ],
                ),
              ),
            ],
          );

    return Padding(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          SizedBox(height: isCompact ? 16 : 20),
          Expanded(
            child: displayRows.isEmpty
                ? _EmptyLessonsState(onAdd: () => _openForm(context))
                : (isCompact
                      ? _LessonsCardList(
                          rows: displayRows,
                          onEdit: (lesson) =>
                              _openForm(context, initial: lesson),
                          onArchive: (id) => _confirmArchive(context, id),
                        )
                      : ShadCard(
                          padding: EdgeInsets.zero,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: DataTable2(
                              columnSpacing: 12,
                              horizontalMargin: 16,
                              minWidth: 900,
                              sortColumnIndex: sortColumnIndex.value,
                              sortAscending: sortAscending.value,
                              headingRowColor: WidgetStatePropertyAll(
                                scheme.muted,
                              ),
                              columns: [
                                DataColumn2(
                                  label: const Text('Title'),
                                  size: ColumnSize.L,
                                  onSort: handleSort,
                                ),
                                const DataColumn2(
                                  label: Text('Subject'),
                                  size: ColumnSize.S,
                                ),
                                DataColumn2(
                                  label: const Text('Quarter/Week'),
                                  size: ColumnSize.S,
                                  onSort: handleSort,
                                ),
                                const DataColumn2(
                                  label: Text('AR?'),
                                  size: ColumnSize.S,
                                ),
                                const DataColumn2(
                                  label: Text('Built-in?'),
                                  size: ColumnSize.S,
                                ),
                                const DataColumn2(
                                  label: Text('Actions'),
                                  size: ColumnSize.S,
                                ),
                              ],
                              rows: displayRows.map((row) {
                                final lesson = row.lesson;
                                final quarterWeek =
                                    lesson.quarter != null &&
                                        lesson.week != null
                                    ? 'Q${lesson.quarter}W${lesson.week}'
                                    : '—';
                                final hasAr = lesson.hasAR;

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      SubjectAccentCell(
                                        subject: lesson.subject,
                                        child: Text(
                                          lesson.title,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(subjectKeyLabel(lesson.subject)),
                                    ),
                                    DataCell(Text(quarterWeek)),
                                    DataCell(Text(hasAr ? 'Yes' : 'No')),
                                    DataCell(
                                      row.isBuiltIn
                                          ? const ShadBadge(
                                              child: Text('Built-in'),
                                            )
                                          : const Text('—'),
                                    ),
                                    DataCell(
                                      row.isBuiltIn
                                          ? const SizedBox.shrink()
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Tooltip(
                                                  message: 'Edit',
                                                  child: ShadIconButton.ghost(
                                                    icon: const Icon(
                                                      LucideIcons.pencil,
                                                    ),
                                                    onPressed: () =>
                                                        _openForm(
                                                          context,
                                                          initial:
                                                              row.teacherLesson,
                                                        ),
                                                  ),
                                                ),
                                                Tooltip(
                                                  message: 'Archive',
                                                  child: ShadIconButton.ghost(
                                                    icon: const Icon(
                                                      LucideIcons.archive,
                                                    ),
                                                    onPressed: () =>
                                                        _confirmArchive(
                                                          context,
                                                          lesson.id,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        )),
          ),
        ],
      ),
    );
  }
}

/// Item 5: an empty lesson list (a brand-new teacher account, or every
/// lesson archived) previously rendered a bare `DataTable2` with headers and
/// zero rows — no cue that this is the expected empty state rather than a
/// stuck/broken load. Mirrors `item_analysis_screen.dart`'s "No attempts yet
/// on this quiz." pattern, plus a direct "Add lesson" action so the empty
/// state isn't a dead end.
class _EmptyLessonsState extends StatelessWidget {
  const _EmptyLessonsState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return ShadCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.muted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.bookOpen,
                  size: 28,
                  color: scheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No lessons yet',
                style: ShadTheme.of(context).textTheme.h4,
              ),
              const SizedBox(height: 4),
              Text(
                'Add your first lesson to get started.',
                style: ShadTheme.of(
                  context,
                ).textTheme.muted.copyWith(color: scheme.mutedForeground),
              ),
              const SizedBox(height: 20),
              ShadButton(
                onPressed: onAdd,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 16),
                    SizedBox(width: 8),
                    Text('Add Lesson'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

/// Narrow-viewport substitute for the `DataTable2` — a scrollable stack of
/// per-lesson `ShadCard`s instead of forcing horizontal table scroll on a
/// phone-width window (matches `TeacherShell`'s own <720px collapse).
class _LessonsCardList extends StatelessWidget {
  const _LessonsCardList({
    required this.rows,
    required this.onEdit,
    required this.onArchive,
  });

  final List<DisplayLesson> rows;
  final void Function(TeacherLesson? lesson) onEdit;
  final void Function(String lessonId) onArchive;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final row = rows[index];
        return _LessonCard(row: row, onEdit: onEdit, onArchive: onArchive)
            .animate()
            .fadeIn(duration: 220.ms, delay: (index * 20).ms)
            .slideY(begin: 0.04, end: 0, duration: 220.ms);
      },
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.row,
    required this.onEdit,
    required this.onArchive,
  });

  final DisplayLesson row;
  final void Function(TeacherLesson? lesson) onEdit;
  final void Function(String lessonId) onArchive;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final lesson = row.lesson;
    final accent = _subjectAccent(context, lesson.subject);
    final quarterWeek = lesson.quarter != null && lesson.week != null
        ? 'Q${lesson.quarter}W${lesson.week}'
        : null;

    return ShadCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Same left-edge subject-accent signature the wide table uses
            // (`SubjectAccentCell`), just theme-aware here so it also reads
            // correctly in dark mode.
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            lesson.title,
                            style: ShadTheme.of(context).textTheme.p.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!row.isBuiltIn)
                          _LessonCardMenu(
                            onEdit: () => onEdit(row.teacherLesson),
                            onArchive: () => onArchive(lesson.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ShadBadge.outline(
                          backgroundColor: accent.withValues(alpha: 0.10),
                          foregroundColor: accent,
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: accent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(subjectKeyLabel(lesson.subject)),
                        ),
                        if (quarterWeek != null)
                          ShadBadge.secondary(child: Text(quarterWeek)),
                        if (lesson.hasAR)
                          ShadBadge.secondary(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(LucideIcons.box, size: 12),
                                SizedBox(width: 4),
                                Text('AR'),
                              ],
                            ),
                          ),
                        if (row.isBuiltIn)
                          const ShadBadge(child: Text('Built-in')),
                      ],
                    ),
                    if (lesson.summary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        lesson.summary,
                        style: ShadTheme.of(context).textTheme.muted.copyWith(
                          color: scheme.mutedForeground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact overflow menu replacing the wide table's two separate icon
/// buttons — on a card-width layout, two `ShadIconButton`s next to a
/// (potentially two-line) title compete for the same cramped row, whereas a
/// single trailing menu button keeps the card's header row predictable.
class _LessonCardMenu extends HookWidget {
  const _LessonCardMenu({required this.onEdit, required this.onArchive});

  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(ShadPopoverController.new);
    useEffect(() => controller.dispose, [controller]);

    return ShadPopover(
      controller: controller,
      popover: (context) => SizedBox(
        width: 160,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShadButton.ghost(
              leading: const Icon(LucideIcons.pencil, size: 16),
              onPressed: () {
                controller.hide();
                onEdit();
              },
              child: const Text('Edit'),
            ),
            ShadButton.ghost(
              leading: const Icon(LucideIcons.archive, size: 16),
              onPressed: () {
                controller.hide();
                onArchive();
              },
              child: const Text('Archive'),
            ),
          ],
        ),
      ),
      child: ShadIconButton.ghost(
        icon: const Icon(LucideIcons.ellipsisVertical),
        onPressed: controller.toggle,
      ),
    );
  }
}
