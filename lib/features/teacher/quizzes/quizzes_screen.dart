import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/quiz_phase.dart';
import '../../../core/models/subject_key.dart';
import '../../../core/models/teacher_quiz.dart';
import '../../../core/services/quiz_repository.dart';
import '../lessons/lessons_providers.dart' show subjectKeyLabel;
import '../widgets/error_state.dart';
import '../widgets/subject_accent_cell.dart';
import 'quiz_form.dart';
import 'quizzes_providers.dart';

/// Narrow-viewport breakpoint, matching `TeacherShell`'s own `isCompact`
/// cutoff (`lib/features/teacher/app/teacher_shell.dart`) — below this width
/// the nav shell has already collapsed to a Drawer, so a fixed-width
/// `DataTable2` (960px `minWidth`) forces horizontal scrolling on top of
/// horizontal scrolling. A single-column card list reads far better there.
const _kCompactBreakpoint = 720.0;

/// Theme-aware subject accent lookup — see `lessons_screen.dart`'s identical
/// helper. Prefer this over calling `subjectColor()`/`.accentColor` directly
/// (`app_theme.dart`) — those always resolve to the *light* palette
/// regardless of the active theme mode, whereas
/// `ShadTheme.of(context).colorScheme.custom` carries the dark-mode variant
/// automatically once `appShadColorSchemeDark` is active.
Color _subjectAccent(BuildContext context, SubjectKey subject) {
  final custom = ShadTheme.of(context).colorScheme.custom;
  final key = switch (subject) {
    SubjectKey.chemistry => 'chemistry',
    SubjectKey.biology => 'biology',
    SubjectKey.physics => 'physics',
  };
  // Fall back to the static palette when the active ShadThemeData carries
  // no `custom` map (a bare `ShadApp` with no theme, as in widget tests) —
  // a missing accent must never crash a whole screen.
  return custom[key] ?? subjectColor(subject);
}

class QuizzesScreen extends ConsumerWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVm = ref.watch(quizzesViewModelProvider);

    return asyncVm.when(
      loading: () => const _QuizzesSkeleton(),
      error: (error, _) => ErrorState(
        message: humanizeLoadError(error, subjectLabel: 'quizzes'),
        onRetry: () => ref.invalidate(quizzesViewModelProvider),
      ),
      data: (vm) => _QuizzesBody(viewModel: vm),
    );
  }
}

/// Loading placeholder shaped like the eventual content (header + a stack of
/// card-sized bars) rather than a bare centered spinner — mirrors
/// `lessons_screen.dart`'s `_LessonsSkeleton`.
class _QuizzesSkeleton extends StatelessWidget {
  const _QuizzesSkeleton();

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
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 700.ms, begin: 0.5);
  }
}

class _QuizzesBody extends StatelessWidget {
  const _QuizzesBody({required this.viewModel});

  final QuizzesViewModel viewModel;

  Future<void> _openForm(BuildContext context, {TeacherQuiz? initial}) async {
    final isCreate = initial == null;
    final width = MediaQuery.sizeOf(context).width;
    await showShadDialog<void>(
      context: context,
      // Require the explicit Cancel action (or a successful submit) to
      // close — an accidental outside click shouldn't silently discard an
      // in-progress multi-question quiz edit.
      barrierDismissible: false,
      builder: (dialogContext) {
        return ShadDialog(
          title: Text(isCreate ? 'Add quiz' : 'Edit quiz'),
          // Full-bleed-ish on narrow viewports instead of a fixed 720px that
          // would overflow a phone-width window.
          child: SizedBox(
            width: width < _kCompactBreakpoint ? width - 64 : 720,
            // See lessons_screen.dart's `_openForm` for why the transparent
            // Material ancestor is needed here.
            child: Material(
              type: MaterialType.transparency,
              child: QuizForm(
                initial: initial,
                submitLabel: isCreate ? 'Create' : 'Save',
                onSubmit: (quiz) async {
                  if (isCreate) {
                    await viewModel.onCreateQuiz(quiz);
                  } else {
                    await viewModel.onUpdateQuiz(quiz);
                  }
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    ShadToaster.of(context).show(
                      ShadToast(
                        description: Text(
                          isCreate ? 'Quiz created' : 'Quiz saved',
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

  Future<void> _confirmDelete(BuildContext context, String quizId) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Delete quiz?'),
        description: const Text(
          'This permanently removes the teacher-authored quiz.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Item 3: same gap as lessons_screen.dart's archive (item 2) — no
    // try/catch and no success toast, on a permanent destructive delete
    // this time, so a failed delete silently did nothing.
    try {
      await viewModel.onDeleteQuiz(quizId);
      if (!context.mounted) return;
      ShadToaster.of(
        context,
      ).show(const ShadToast(description: Text('Quiz deleted')));
    } catch (error) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            humanizeSubmitError(error, actionLabel: 'delete this quiz'),
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
    final rows = viewModel.rows;

    final countLabel =
        '${rows.length} ${rows.length == 1 ? 'quiz' : 'quizzes'}';

    final header = isCompact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quizzes', style: ShadTheme.of(context).textTheme.h3),
              const SizedBox(height: 4),
              Text(
                countLabel,
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
                      Text('Add Quiz'),
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
                  Text('Quizzes', style: ShadTheme.of(context).textTheme.h3),
                  const SizedBox(height: 4),
                  Text(
                    countLabel,
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
                    Text('Add Quiz'),
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
            child: rows.isEmpty
                ? _EmptyQuizzesState(onAdd: () => _openForm(context))
                : (isCompact
                      ? _QuizzesCardList(
                          rows: rows,
                          onEdit: (quiz) => _openForm(context, initial: quiz),
                          onDelete: (id) => _confirmDelete(context, id),
                        )
                      : ShadCard(
                          padding: EdgeInsets.zero,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: DataTable2(
                              columnSpacing: 12,
                              horizontalMargin: 16,
                              minWidth: 960,
                              headingRowColor: WidgetStatePropertyAll(
                                scheme.muted,
                              ),
                              columns: const [
                                DataColumn2(
                                  label: Text('Title'),
                                  size: ColumnSize.L,
                                ),
                                DataColumn2(
                                  label: Text('Subject'),
                                  size: ColumnSize.S,
                                ),
                                DataColumn2(
                                  label: Text('Phase'),
                                  size: ColumnSize.S,
                                ),
                                DataColumn2(
                                  label: Text('Questions'),
                                  size: ColumnSize.S,
                                ),
                                DataColumn2(
                                  label: Text('Built-in?'),
                                  size: ColumnSize.S,
                                ),
                                DataColumn2(
                                  label: Text('Actions'),
                                  size: ColumnSize.M,
                                ),
                              ],
                              rows: rows.map((row) {
                                final quiz = row.quiz;
                                final phaseLabel = quiz.phase == QuizPhase.pre
                                    ? 'Pre-Test'
                                    : 'Post-Test';

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      SubjectAccentCell(
                                        subject: quiz.subject,
                                        child: Text(
                                          quiz.title,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(subjectKeyLabel(quiz.subject)),
                                    ),
                                    DataCell(Text(phaseLabel)),
                                    DataCell(Text('${quiz.questions.length}')),
                                    DataCell(
                                      row.isBuiltIn
                                          ? const ShadBadge(
                                              child: Text('Built-in'),
                                            )
                                          : const Text('—'),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Tooltip(
                                            message: 'Item analysis',
                                            child: ShadIconButton.ghost(
                                              icon: const Icon(
                                                LucideIcons.barChart,
                                              ),
                                              onPressed: () => context.push(
                                                '/teacher/quizzes/${quiz.id}/item-analysis',
                                                extra: quiz.title,
                                              ),
                                            ),
                                          ),
                                          if (!row.isBuiltIn) ...[
                                            Tooltip(
                                              message: 'Edit',
                                              child: ShadIconButton.ghost(
                                                icon: const Icon(
                                                  LucideIcons.pencil,
                                                ),
                                                onPressed: () => _openForm(
                                                  context,
                                                  initial: quiz,
                                                ),
                                              ),
                                            ),
                                            Tooltip(
                                              message: 'Delete',
                                              child: ShadIconButton.ghost(
                                                icon: const Icon(
                                                  LucideIcons.trash2,
                                                ),
                                                onPressed: () => _confirmDelete(
                                                  context,
                                                  quiz.id,
                                                ),
                                              ),
                                            ),
                                          ],
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

/// Item 5: an empty quiz list previously rendered a bare `DataTable2` with
/// headers and zero rows — no cue that this is the expected empty state
/// rather than a stuck/broken load. Mirrors `lessons_screen.dart`'s
/// `_EmptyLessonsState`.
class _EmptyQuizzesState extends StatelessWidget {
  const _EmptyQuizzesState({required this.onAdd});

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
                  LucideIcons.listChecks,
                  size: 28,
                  color: scheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              Text('No quizzes yet', style: ShadTheme.of(context).textTheme.h4),
              const SizedBox(height: 4),
              Text(
                'Add your first quiz to get started.',
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
                    Text('Add Quiz'),
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
/// per-quiz `ShadCard`s instead of forcing horizontal table scroll on a
/// phone-width window (matches `TeacherShell`'s own <720px collapse).
class _QuizzesCardList extends StatelessWidget {
  const _QuizzesCardList({
    required this.rows,
    required this.onEdit,
    required this.onDelete,
  });

  final List<DisplayQuiz> rows;
  final void Function(TeacherQuiz quiz) onEdit;
  final void Function(String quizId) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final row = rows[index];
        return _QuizCard(row: row, onEdit: onEdit, onDelete: onDelete)
            .animate()
            .fadeIn(duration: 220.ms, delay: (index * 20).ms)
            .slideY(begin: 0.04, end: 0, duration: 220.ms);
      },
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.row,
    required this.onEdit,
    required this.onDelete,
  });

  final DisplayQuiz row;
  final void Function(TeacherQuiz quiz) onEdit;
  final void Function(String quizId) onDelete;

  @override
  Widget build(BuildContext context) {
    final quiz = row.quiz;
    final accent = _subjectAccent(context, quiz.subject);
    final phaseLabel = quiz.phase == QuizPhase.pre ? 'Pre-Test' : 'Post-Test';

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
                            quiz.title,
                            style: ShadTheme.of(
                              context,
                            ).textTheme.p.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!row.isBuiltIn)
                          _QuizCardMenu(
                            onEdit: () => onEdit(quiz),
                            onDelete: () => onDelete(quiz.id),
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
                          child: Text(subjectKeyLabel(quiz.subject)),
                        ),
                        ShadBadge.secondary(child: Text(phaseLabel)),
                        ShadBadge.secondary(
                          child: Text('${quiz.questions.length} questions'),
                        ),
                        if (row.isBuiltIn)
                          const ShadBadge(child: Text('Built-in')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ShadButton.outline(
                        onPressed: () => context.push(
                          '/teacher/quizzes/${quiz.id}/item-analysis',
                          extra: quiz.title,
                        ),
                        leading: const Icon(LucideIcons.barChart, size: 16),
                        child: const Text('Item Analysis'),
                      ),
                    ),
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

/// Compact overflow menu for a quiz card's actions — mirrors
/// `lessons_screen.dart`'s `_LessonCardMenu` (`ShadPopover`, the app's one
/// treatment for a card's overflow menu; shadcn_ui has no dedicated
/// context-menu component in this package version). "Item Analysis" gets its
/// own always-visible button below instead of living in this menu, since
/// it's the single most-used action on this screen.
class _QuizCardMenu extends HookWidget {
  const _QuizCardMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // `ShadPopover` (0.56.2) has no static `.of(context)` accessor — it's
    // driven by an explicit `ShadPopoverController`, the same pattern
    // `lessons_screen.dart`'s `_LessonCardMenu` uses.
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
              leading: const Icon(LucideIcons.trash2, size: 16),
              onPressed: () {
                controller.hide();
                onDelete();
              },
              child: const Text('Delete'),
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
