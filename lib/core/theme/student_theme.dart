// lib/core/theme/student_theme.dart
//
// Material theme for the student mobile app. Previously `MaterialApp.router`
// was built with no `theme:` at all (main.dart), so every student screen —
// home, learn, progress, quiz, AR lab — rendered in stock Flutter's default
// Material 3 seed (a generic purple), completely disconnected from the
// cool-neutral + subject-accent palette Teacher Web already established in
// `app_theme.dart`. This gives the student side the same brand language
// (reusing `AppColors`/`subjectColor()` rather than inventing a second
// palette) without requiring every screen to be rewritten — most student
// screens read colors/type from `Theme.of(context)` generically, so a single
// themed `MaterialApp.router` lifts all of them at once.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';

const _kStudentRadius = BorderRadius.all(Radius.circular(14));

/// Light Material theme for the student app. Deliberately light-only for
/// now — dark mode wasn't requested for the mobile surface and the AR
/// camera/lab screens have their own always-dark viewport regardless of
/// app theme, so a light/dark toggle here would mostly affect chrome.
final ThemeData studentTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.physics,
    brightness: Brightness.light,
    surface: AppColors.background,
    onSurface: AppColors.ink,
    primary: AppColors.physics,
    onPrimary: Colors.white,
    secondary: AppColors.biology,
    onSecondary: Colors.white,
    tertiary: AppColors.chemistry,
    onTertiary: Colors.white,
    error: AppColors.destructive,
    onError: AppColors.destructiveForeground,
    outline: AppColors.border,
    outlineVariant: AppColors.muted,
  ),
  textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.ink,
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: false,
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: _kStudentRadius,
      side: const BorderSide(color: AppColors.border),
    ),
    margin: EdgeInsets.zero,
  ),
  listTileTheme: ListTileThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    iconColor: AppColors.inkMuted,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    indicatorColor: AppColors.physics.withValues(alpha: 0.16),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        color: selected ? AppColors.physics : AppColors.inkMuted,
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return IconThemeData(color: selected ? AppColors.physics : AppColors.inkMuted);
    }),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.physics,
    circularTrackColor: AppColors.muted,
    linearTrackColor: AppColors.muted,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.muted,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.physics, width: 2),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.physics,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  dividerColor: AppColors.border,
);
