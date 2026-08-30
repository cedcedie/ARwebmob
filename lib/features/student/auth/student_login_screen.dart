import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../teacher/students/student_id_format.dart';
import 'student_auth_providers.dart';

/// Minimal student sign-in gate for the Android target (dev/screenshot use).
class StudentLoginScreen extends HookConsumerWidget {
  const StudentLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(studentAuthViewModelProvider);
    final auth = ref.read(studentAuthViewModelProvider.notifier);
    final idController = useTextEditingController(text: authState.idOrEmail);
    final passwordController = useTextEditingController(text: authState.password);

    Future<void> onSubmit() async {
      auth.idOrEmail = idController.text;
      auth.password = passwordController.text;
      await auth.submit();
    }

    return MaterialApp(
      title: 'AR Science Explorer',
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Student sign in',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use your 6-digit student ID (or full @arscience.school email).',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (authState.errorMessage != null) ...[
                      Text(
                        authState.errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: idController,
                      decoration: const InputDecoration(
                        labelText: 'Student ID',
                        hintText: '12-3456 or name@arscience.school',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [StudentIdInputFormatter()],
                      onChanged: (value) => auth.idOrEmail = value,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onChanged: (value) => auth.password = value,
                      onSubmitted: (_) => onSubmit(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: authState.isSubmitting ? null : onSubmit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(authState.isSubmitting ? 'Signing in…' : 'Sign in'),
                      ),
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
