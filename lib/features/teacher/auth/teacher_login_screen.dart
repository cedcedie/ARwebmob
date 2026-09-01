import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'teacher_auth_providers.dart';

/// Responsive teacher sign-in gate for the Flutter Web target.
///
/// This screen sits outside `TeacherShell` (there's no signed-in teacher yet
/// to show a rail/drawer for), so it's fully self-contained: a centered
/// brand moment + card on wide viewports that scales its width and padding
/// down to a near-full-bleed card on phone-width viewports, rather than
/// assuming a fixed desktop canvas.
class TeacherLoginScreen extends HookConsumerWidget {
  const TeacherLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(teacherAuthViewModelProvider);
    final auth = ref.read(teacherAuthViewModelProvider.notifier);
    final emailController = useTextEditingController(text: authState.email);
    final passwordController = useTextEditingController(
      text: authState.password,
    );

    Future<void> onSubmit() async {
      auth.email = emailController.text;
      auth.password = passwordController.text;
      await auth.submit();
    }

    final width = MediaQuery.sizeOf(context).width;
    // Same 720px breakpoint `TeacherShell` uses for its own compact layout,
    // so this pre-auth screen and the post-auth shell agree on what counts
    // as "narrow".
    final isCompact = width < 720;
    // Below ~480px there's no room left for side margins around a
    // fixed-width card — let it fill the viewport (minus a small gutter)
    // instead of clipping or leaving it oddly narrow.
    final isPhone = width < 480;
    final cardMaxWidth = isPhone ? double.infinity : 440.0;
    final horizontalPadding = isPhone ? 16.0 : 24.0;

    final scheme = ShadTheme.of(context).colorScheme;

    // `SizedBox.expand` forces the Scaffold body to take on the full
    // available size before `Center` runs — without it, `Center`'s render
    // object can collapse to its child's size when it receives unbounded
    // constraints, which is what produced the "card pinned near the top,
    // ~70% blank space below" bug this replaces (Center still centers
    // correctly, but only within whatever size it was actually given).
    return Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
          // A very subtle radial tint (built from theme roles, never a
          // hardcoded light-only color) so the very first screen a teacher
          // sees reads as an intentional brand moment rather than a bare
          // form on a flat background.
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.6),
              radius: 1.4,
              colors: [scheme.muted, scheme.background],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardMaxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LoginHero(isCompact: isCompact),
                      SizedBox(height: isCompact ? 20 : 28),
                      ShadCard(
                            title: const Text('Sign in'),
                            description: const Text(
                              'Use your school email to manage lessons, '
                              'quizzes, and students.',
                            ),
                            padding: EdgeInsets.all(isCompact ? 16 : 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (authState.errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: scheme.destructive.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: scheme.destructive.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          LucideIcons.circleAlert,
                                          size: 18,
                                          color: scheme.destructive,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            authState.errorMessage!,
                                            style: TextStyle(
                                              color: scheme.destructive,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Text(
                                  'Email',
                                  style: ShadTheme.of(context).textTheme.small,
                                ),
                                const SizedBox(height: 6),
                                ShadInput(
                                  controller: emailController,
                                  placeholder: const Text('you@school.edu'),
                                  leading: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Icon(
                                      LucideIcons.mail,
                                      size: 16,
                                      color: scheme.mutedForeground,
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (value) => auth.email = value,
                                  onSubmitted: (_) => onSubmit(),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Password',
                                  style: ShadTheme.of(context).textTheme.small,
                                ),
                                const SizedBox(height: 6),
                                ShadInput(
                                  controller: passwordController,
                                  placeholder: const Text('••••••••'),
                                  leading: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Icon(
                                      LucideIcons.lock,
                                      size: 16,
                                      color: scheme.mutedForeground,
                                    ),
                                  ),
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (value) => auth.password = value,
                                  onSubmitted: (_) => onSubmit(),
                                ),
                                const SizedBox(height: 20),
                                ShadButton(
                                  width: double.infinity,
                                  leading: authState.isSubmitting
                                      ? null
                                      : const Icon(LucideIcons.logIn, size: 16),
                                  onPressed: authState.isSubmitting
                                      ? null
                                      : onSubmit,
                                  child: authState.isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Sign in'),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.04,
                            end: 0,
                            duration: 260.ms,
                            curve: Curves.easeOut,
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Brand moment above the sign-in card: a subject-accented icon badge plus a
/// short name/tagline, giving this — the very first screen a teacher sees —
/// some visual identity instead of a bare form.
class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final textTheme = ShadTheme.of(context).textTheme;
    final chemistry = scheme.custom['chemistry'] ?? scheme.primary;
    final biology = scheme.custom['biology'] ?? scheme.primary;
    final physics = scheme.custom['physics'] ?? scheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
              width: isCompact ? 52 : 60,
              height: isCompact ? 52 : 60,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                LucideIcons.flaskConical,
                color: scheme.primaryForeground,
                size: isCompact ? 26 : 30,
              ),
            )
            .animate()
            .fadeIn(duration: 220.ms)
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
              duration: 220.ms,
              curve: Curves.easeOut,
            ),
        const SizedBox(height: 16),
        Text(
          'Teacher Portal',
          textAlign: TextAlign.center,
          style: (isCompact ? textTheme.h4 : textTheme.h3).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Author lessons, run quizzes, and track student progress.',
          textAlign: TextAlign.center,
          style: textTheme.muted,
        ),
        const SizedBox(height: 14),
        // Three subject-accent dots — a quiet nod to the app's subject
        // palette without pulling in any content the teacher hasn't signed
        // in to see yet.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Dot(color: chemistry),
            const SizedBox(width: 6),
            _Dot(color: biology),
            const SizedBox(width: 6),
            _Dot(color: physics),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
