import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/access_code_service.dart';
import '../../../core/services/progress_calculator.dart';
import '../../../core/theme/app_theme.dart';
import 'home_providers.dart';

/// Student home — the first screen a student sees after signing in, so it
/// carries the same brand-moment weight the login screen already has
/// (avatar badge, warm greeting) rather than defaulting to a bare data
/// dump. Previously this was stock `Card`/`ListTile` with no color, no
/// empty states, and no motion — completely disconnected from the rest of
/// the app's subject-accent visual language and the product's stated
/// Duolingo-warmth principle for student-facing surfaces.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncViewModel = ref.watch(homeViewModelProvider);

    return asyncViewModel.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _HomeError(error: error),
      data: (vm) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          _Greeting(vm: vm),
          const SizedBox(height: 20),
          _ProgressCard(vm: vm),
          const SizedBox(height: 16),
          _ContinueLessonCard(vm: vm),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.menu_book_rounded,
                  label: 'Lessons completed',
                  value: '${vm.lessonsCompletedCount}',
                  accent: AppColors.chemistry,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.fact_check_rounded,
                  label: 'Quizzes taken',
                  value: '${vm.quizzesTakenCount}',
                  accent: AppColors.physics,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Recent quiz attempts',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _RecentAttempts(attempts: vm.lastAttempts),
          const SizedBox(height: 20),
          _AccessCodeBox(onRedeem: vm.onRedeemCode),
        ],
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AppColors.inkMuted,
            ),
            const SizedBox(height: 12),
            Text(
              "Couldn't load your progress",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Check your connection and try again.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar-badge + name, mirroring the login screen's own hero treatment so
/// the "you're signed in" moment reads as continuous with the "sign in"
/// moment rather than a completely different visual language.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.vm});

  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.physics.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  vm.studentDisplayName.isNotEmpty
                      ? vm.studentDisplayName[0].toUpperCase()
                      : '?',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.physics,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${vm.studentDisplayName}!',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (vm.currentQuarter != null && vm.currentWeek != null)
                    Text(
                      'Quarter ${vm.currentQuarter} · Week ${vm.currentWeek}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 260.ms, curve: Curves.easeOut)
        .slideY(begin: 0.06, end: 0, duration: 260.ms, curve: Curves.easeOut);
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.vm});

  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final percent = (vm.percentComplete * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Your progress',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.physics,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: vm.percentComplete,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 60.ms, curve: Curves.easeOut);
  }
}

/// The primary CTA on this screen — styled as an inviting next-step, not a
/// bare `ListTile` row, since "what do I do next" is the one thing this
/// screen most needs to answer at a glance. Falls back to a "browse
/// lessons" prompt rather than silently disappearing when there's nothing
/// to continue (e.g. every lesson already completed).
class _ContinueLessonCard extends StatelessWidget {
  const _ContinueLessonCard({required this.vm});

  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final lesson = vm.continueLesson;
    final accent = lesson?.subject.accentColor ?? AppColors.physics;

    return Material(
          color: accent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => lesson != null
                ? context.push('/lesson/${lesson.id}')
                : context.go('/learn'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      lesson != null
                          ? Icons.play_arrow_rounded
                          : Icons.explore_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson != null
                              ? 'Continue where you left off'
                              : "You're all caught up!",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lesson?.title ?? 'Browse lessons to review anything',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: 120.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.06,
          end: 0,
          duration: 300.ms,
          delay: 120.ms,
          curve: Curves.easeOut,
        );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 160.ms, curve: Curves.easeOut);
  }
}

class _RecentAttempts extends StatelessWidget {
  const _RecentAttempts({required this.attempts});

  final List<dynamic> attempts;

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.quiz_outlined, color: AppColors.inkMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "No quiz attempts yet — they'll show up here once you take one.",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < attempts.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              title: Text(attempts[i].quizId as String),
              trailing: _ScoreBadge(score: attempts[i].score as num),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms, curve: Curves.easeOut);
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});
  final num score;

  @override
  Widget build(BuildContext context) {
    final band = scoreBandFor(score);
    final color = switch (band) {
      ScoreBand.good => AppColors.success,
      ScoreBand.caution => AppColors.chemistry,
      ScoreBand.needsWork => AppColors.destructive,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _AccessCodeBox extends StatefulWidget {
  const _AccessCodeBox({required this.onRedeem});
  final Future<AccessCodeResult> Function(String) onRedeem;

  @override
  State<_AccessCodeBox> createState() => _AccessCodeBoxState();
}

class _AccessCodeBoxState extends State<_AccessCodeBox> {
  final _controller = TextEditingController();
  String? _message;
  bool? _wasSuccess;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final result = await widget.onRedeem(_controller.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _message = result.message;
      _wasSuccess = result.success;
      if (result.success) _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.vpn_key_rounded,
                  size: 18,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  'Have a code from your teacher?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // This box only ever redeems a whole-subject code (it has no
            // specific lesson/test to scope the redemption to) — a
            // lesson-specific or test-retake code has to be entered where
            // that lesson/test actually is (the locked lesson card, or the
            // "Enter retake code" button on a failed post-test), otherwise
            // AccessCodeService.redeem correctly rejects it as "not valid
            // for this lesson/test", which reads confusingly here without
            // this context.
            Text(
              'For a subject unlock code. A lesson or test-retake code goes '
              'on that lesson/test\'s own screen.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _loading ? null : _submit(),
              decoration: const InputDecoration(hintText: 'Enter code here'),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Apply code'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _wasSuccess == true
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    size: 16,
                    color: _wasSuccess == true
                        ? AppColors.success
                        : AppColors.destructive,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _wasSuccess == true
                            ? AppColors.success
                            : AppColors.destructive,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 240.ms, curve: Curves.easeOut);
  }
}
