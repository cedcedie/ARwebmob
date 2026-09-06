import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/services/teacher_directory_service.dart';
import '../auth/teacher_auth_providers.dart';
import '../widgets/error_state.dart';

final teacherAccountsProvider =
    StreamProvider.autoDispose<List<TeacherAccount>>(
      (ref) => ref.watch(teacherDirectoryServiceProvider).watchTeachers(),
    );

/// Manages who may sign in to the teacher portal.
///
/// This screen exists because teacher access is now explicit membership of an
/// allowlist rather than "any account that isn't a student". Without a way to
/// manage that list in the app, adding a colleague would mean hand-editing
/// Firestore in the Firebase console — which no teacher should have to do,
/// and which would make the safe design the inconvenient one.
class TeacherAccessScreen extends ConsumerWidget {
  const TeacherAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = MediaQuery.sizeOf(context).width < 720;
    final accounts = ref.watch(teacherAccountsProvider);
    final currentEmail = ref.watch(currentTeacherEmailProvider).valueOrNull;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teacher Access',
                      style: ShadTheme.of(context).textTheme.h3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Only the email addresses listed here can sign in to '
                      'the teacher portal.',
                      style: ShadTheme.of(context).textTheme.muted.copyWith(
                        color: ShadTheme.of(
                          context,
                        ).colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ShadButton(
                onPressed: currentEmail == null
                    ? null
                    : () => _showAddDialog(context, ref, addedBy: currentEmail),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.userPlus, size: 16),
                    SizedBox(width: 8),
                    Text('Add Teacher'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: accounts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: humanizeLoadError(error, subjectLabel: 'teacher list'),
                onRetry: () => ref.invalidate(teacherAccountsProvider),
              ),
              data: (list) => ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _TeacherRow(
                  account: list[i],
                  currentEmail: currentEmail,
                  onRemove: () => _confirmRemove(
                    context,
                    ref,
                    account: list[i],
                    requestedBy: currentEmail ?? '',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(
    BuildContext context,
    WidgetRef ref, {
    required String addedBy,
  }) async {
    final controller = TextEditingController();
    final nameController = TextEditingController();
    await showShadDialog<void>(
      context: context,
      builder: (dialogContext) => ShadDialog(
        title: const Text('Add Teacher'),
        description: const Text(
          'The address must already be able to sign in to Google, Microsoft, '
          'or with an email and password you have created for them.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ShadButton(
            onPressed: () async {
              final messenger = ShadToaster.of(dialogContext);
              final navigator = Navigator.of(dialogContext);
              try {
                await ref
                    .read(teacherDirectoryServiceProvider)
                    .addTeacher(
                      email: controller.text,
                      displayName: nameController.text.trim().isEmpty
                          ? null
                          : nameController.text.trim(),
                      addedBy: addedBy,
                    );
              } catch (error) {
                messenger.show(
                  ShadToast.destructive(
                    description: Text(
                      humanizeSubmitError(
                        error,
                        actionLabel: 'add this teacher',
                      ),
                    ),
                  ),
                );
                return;
              }
              navigator.pop();
              messenger.show(
                const ShadToast(description: Text('Teacher access granted')),
              );
            },
            child: const Text('Add'),
          ),
        ],
        child: SizedBox(
          width: 380,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    hintText: 'teacher@school.edu.ph',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name (optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref, {
    required TeacherAccount account,
    required String requestedBy,
  }) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (dialogContext) => ShadDialog.alert(
        title: const Text('Remove teacher access?'),
        description: Text(
          '${account.email} will no longer be able to sign in to the teacher '
          'portal. Their account itself is not deleted, and student data is '
          'not affected.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove access'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ShadToaster.of(context);
    try {
      await ref
          .read(teacherDirectoryServiceProvider)
          .removeTeacher(email: account.email, requestedBy: requestedBy);
    } catch (error) {
      messenger.show(
        ShadToast.destructive(
          description: Text(
            humanizeSubmitError(error, actionLabel: 'remove this teacher'),
          ),
        ),
      );
      return;
    }
    messenger.show(
      const ShadToast(description: Text('Teacher access removed')),
    );
  }
}

class _TeacherRow extends StatelessWidget {
  const _TeacherRow({
    required this.account,
    required this.currentEmail,
    required this.onRemove,
  });

  final TeacherAccount account;
  final String? currentEmail;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final isSelf =
        currentEmail != null &&
        TeacherDirectoryService.normalizeEmail(currentEmail!) ==
            TeacherDirectoryService.normalizeEmail(account.email);
    // Neither the project owner nor the signed-in teacher can be removed —
    // the first because it is the way back in if the list is ever broken,
    // the second because removing yourself would eject you mid-session.
    final canRemove = !account.isBootstrap && !isSelf;

    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(LucideIcons.user, size: 18, color: scheme.mutedForeground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.displayName?.isNotEmpty == true
                      ? '${account.displayName} · ${account.email}'
                      : account.email,
                  style: ShadTheme.of(context).textTheme.p,
                  overflow: TextOverflow.ellipsis,
                ),
                if (account.isBootstrap)
                  Text(
                    'Project owner — access cannot be removed',
                    style: ShadTheme.of(
                      context,
                    ).textTheme.small.copyWith(color: scheme.mutedForeground),
                  )
                else if (isSelf)
                  Text(
                    'You',
                    style: ShadTheme.of(
                      context,
                    ).textTheme.small.copyWith(color: scheme.mutedForeground),
                  )
                else if (account.addedBy != null)
                  Text(
                    'Added by ${account.addedBy}',
                    style: ShadTheme.of(
                      context,
                    ).textTheme.small.copyWith(color: scheme.mutedForeground),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (canRemove)
            ShadIconButton.ghost(
              icon: Icon(LucideIcons.trash2, color: scheme.destructive),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
