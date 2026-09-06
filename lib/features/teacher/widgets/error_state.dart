// lib/features/teacher/widgets/error_state.dart
//
// Shared human-readable error display for teacher-surface list screens.
// Replaces raw `Text('Error loading X: $error')` interpolation (round 1's
// confirmed, never-fixed gap) with a consistent icon + plain-sentence
// message, following the pattern `access_codes_screen.dart` already used
// for its own (different, StateError-specific) error banner.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Maps a caught error object to a short, plain-English sentence suitable
/// for direct display to a teacher — never a raw exception `toString()`.
///
/// [subjectLabel] names the thing that failed to load in lowercase plural
/// form (e.g. `'lessons'`, `'quizzes'`, `'students'`), used only in the
/// generic fallback sentence.
String humanizeLoadError(Object error, {required String subjectLabel}) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return "You don't have permission to view $subjectLabel right now. "
            'Try signing out and back in.';
      case 'unavailable':
        return 'The connection to the server was interrupted. Check your '
            'network and try again.';
      case 'unauthenticated':
        return 'Your session has expired. Please sign in again.';
      default:
        return "Couldn't load $subjectLabel right now — check your "
            'connection and try again.';
    }
  }

  final message = error.toString().toLowerCase();
  if (message.contains('socket') ||
      message.contains('network') ||
      message.contains('connection')) {
    return "Couldn't reach the server — check your connection and try "
        'again.';
  }

  return "Couldn't load $subjectLabel right now — check your connection "
      'and try again.';
}

/// Maps a caught error from a create/update submit action (a dialog's
/// `onSubmit`) to a short, plain-English sentence suitable for a
/// `ShadToaster` error toast — never a raw exception `toString()`. Mirrors
/// [humanizeLoadError]'s Firebase-code handling but phrased for a save
/// action rather than a load.
///
/// [actionLabel] describes the thing that failed to save, phrased to follow
/// "Couldn't " (e.g. `'save this lesson'`, `'save this quiz'`).
String humanizeSubmitError(Object error, {required String actionLabel}) {
  // A `StateError` thrown by this app's own service layer (e.g.
  // `AccessCodeIssuanceService`'s "code already exists" / "no post-test
  // attempt yet" rejections) is already a deliberately-authored,
  // teacher-safe sentence — unlike a raw `FirebaseException` or a generic
  // `Exception`'s `toString()`, which is why only those two get mapped to a
  // generic sentence below. Showing it verbatim keeps callers free to route
  // every caught error through this one function uniformly (item 1) without
  // losing the specific, actionable text a business-rule rejection needs.
  if (error is StateError) {
    return error.message;
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return "You don't have permission to $actionLabel. Try signing out "
            'and back in.';
      case 'unavailable':
        return 'The connection to the server was interrupted. Check your '
            'network and try again.';
      case 'unauthenticated':
        return 'Your session has expired. Please sign in again.';
      default:
        return "Couldn't $actionLabel — check your connection and try "
            'again.';
    }
  }

  final message = error.toString().toLowerCase();
  if (message.contains('socket') ||
      message.contains('network') ||
      message.contains('connection')) {
    return "Couldn't reach the server — check your connection and try "
        'again.';
  }

  return "Couldn't $actionLabel — check your connection and try again.";
}

/// Consistent full-space error display for a teacher list screen: an icon,
/// a human-readable message, and an optional retry action.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  /// Plain-English message — build it via [humanizeLoadError], never pass a
  /// raw exception's `toString()` here.
  final String message;

  /// Optional retry callback. When null, no retry button is shown (e.g. a
  /// `StreamProvider` that will simply re-emit on its own).
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: 32,
              color: ShadTheme.of(context).colorScheme.destructive,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ShadButton.outline(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
