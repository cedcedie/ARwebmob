import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'teacher_auth_providers.dart';

/// Desktop-friendly teacher sign-in gate for the Flutter Web target.
class TeacherLoginScreen extends HookConsumerWidget {
  const TeacherLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(teacherAuthViewModelProvider);
    final auth = ref.read(teacherAuthViewModelProvider.notifier);
    final emailController = useTextEditingController(text: authState.email);
    final passwordController = useTextEditingController(text: authState.password);

    Future<void> onSubmit() async {
      auth.email = emailController.text;
      auth.password = passwordController.text;
      await auth.submit();
    }

    return ShadApp(
      title: 'AR Science Explorer — Teacher',
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ShadCard(
                title: const Text('Teacher sign in'),
                description: const Text(
                  'Use your school email to manage lessons, quizzes, and students.',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (authState.errorMessage != null) ...[
                      Text(
                        authState.errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ShadInput(
                      controller: emailController,
                      placeholder: const Text('Email'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (value) => auth.email = value,
                      onSubmitted: (_) => onSubmit(),
                    ),
                    const SizedBox(height: 12),
                    ShadInput(
                      controller: passwordController,
                      placeholder: const Text('Password'),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onChanged: (value) => auth.password = value,
                      onSubmitted: (_) => onSubmit(),
                    ),
                    const SizedBox(height: 20),
                    ShadButton(
                      width: double.infinity,
                      onPressed: authState.isSubmitting ? null : onSubmit,
                      child: Text(authState.isSubmitting ? 'Signing in…' : 'Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
