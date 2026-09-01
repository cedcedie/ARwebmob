// lib/core/theme/theme_mode_provider.dart
//
// Light/dark mode state for the Teacher Web surface. Kept deliberately
// small: a `StateProvider<ThemeMode>` plus two free functions, mirroring
// this codebase's existing "plain provider + free-function helpers" style
// (see teacher_providers.dart) rather than introducing a new
// StateNotifier/Notifier class for a single boolean-ish toggle.
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModePrefKey = 'teacher_theme_mode';

/// Current [ThemeMode] for the Teacher Web surface.
///
/// Defaults to [ThemeMode.light] — matching the shell's original
/// single-theme look — until [loadPersistedThemeMode]'s result is applied
/// as a provider override at app startup (see main.dart).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// Reads the last-persisted [ThemeMode] before the first frame, so a
/// teacher who chose dark mode doesn't see a light-then-dark flash on
/// reload. Falls back to [ThemeMode.light] (never [ThemeMode.system] — a
/// teacher's explicit choice, once made, should stick regardless of what
/// their OS/browser reports).
Future<ThemeMode> loadPersistedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kThemeModePrefKey) == 'dark'
      ? ThemeMode.dark
      : ThemeMode.light;
}

/// Flips light↔dark and persists the choice for next launch.
Future<void> toggleThemeMode(WidgetRef ref) async {
  final notifier = ref.read(themeModeProvider.notifier);
  final next = notifier.state == ThemeMode.dark
      ? ThemeMode.light
      : ThemeMode.dark;
  notifier.state = next;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kThemeModePrefKey,
    next == ThemeMode.dark ? 'dark' : 'light',
  );
}
