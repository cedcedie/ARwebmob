import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/student_theme.dart';
import '../../teacher/students/student_id_format.dart';
import 'student_auth_providers.dart';

/// Student sign-in gate.
///
/// Builds its own `MaterialApp` (this screen is shown before
/// `main.dart`'s `MaterialApp.router` for the signed-in student app is
/// reachable), but now themed with [studentTheme] — previously this
/// screen and the rest of the student app used two different themes (this
/// one used none at all, falling through to stock Material 3 purple),
/// so a student's very first screen looked like a different, unbranded
/// app from everything after it.
class StudentLoginScreen extends HookConsumerWidget {
  const StudentLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(studentAuthViewModelProvider);
    final auth = ref.read(studentAuthViewModelProvider.notifier);
    final idController = useTextEditingController(text: authState.idOrEmail);
    final passwordController = useTextEditingController(
      text: authState.password,
    );
    final obscurePassword = useState(true);

    Future<void> onSubmit() async {
      auth.idOrEmail = idController.text;
      auth.password = passwordController.text;
      await auth.submit();
    }

    return MaterialApp(
      title: 'AR Science Explorer',
      debugShowCheckedModeBanner: false,
      theme: studentTheme,
      home: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 20 : 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Brand/hero moment — mirrors the Teacher Web sign-in
                        // screen's icon badge + tagline + subject-accent dots,
                        // so both surfaces read as the same product.
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.physics.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.science_outlined,
                              size: 32,
                              color: AppColors.physics,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AR Science Explorer',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Use your 6-digit student ID (or full '
                          '@arscience.school email) to sign in.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.inkMuted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final color in [
                              AppColors.chemistry,
                              AppColors.biology,
                              AppColors.physics,
                            ]) ...[
                              Container(
                                width: 7,
                                height: 7,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 28),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (authState.errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.destructive.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          size: 18,
                                          color: AppColors.destructive,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            authState.errorMessage!,
                                            style: const TextStyle(
                                              color: AppColors.destructive,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                TextField(
                                  controller: idController,
                                  decoration: const InputDecoration(
                                    labelText: 'Student ID',
                                    hintText:
                                        '12-3456 or name@arscience.school',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                  inputFormatters: [StudentIdInputFormatter()],
                                  onChanged: (value) => auth.idOrEmail = value,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscurePassword.value
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      tooltip: obscurePassword.value
                                          ? 'Show password'
                                          : 'Hide password',
                                      onPressed: () => obscurePassword.value =
                                          !obscurePassword.value,
                                    ),
                                  ),
                                  obscureText: obscurePassword.value,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (value) => auth.password = value,
                                  onSubmitted: (_) => onSubmit(),
                                ),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: authState.isSubmitting
                                      ? null
                                      : onSubmit,
                                  icon: authState.isSubmitting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.login, size: 18),
                                  label: Text(
                                    authState.isSubmitting
                                        ? 'Signing in…'
                                        : 'Sign in',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
