// lib/core/theme/app_theme.dart
//
// Single source of truth for the Teacher Web surface's design system:
// a cool-toned neutral palette (off-white background, near-black ink text)
// plus three named subject-accent colors, Plus Jakarta Sans typography via
// `google_fonts`, and both a `ShadThemeData` (shadcn_ui — system of record
// for teacher screens) and a companion Material `ThemeData` that mirrors the
// same colors/type for the handful of widgets that still need plain
// Material primitives (e.g. `NavigationRail`, `FormBuilderTextField`).
//
// Deliberately presentation-only: no business logic lives here.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/subject_key.dart';

/// Named color roles for the Teacher Web surface.
///
/// The background is a cool-toned off-white (blue-grey undertone) —
/// deliberately not a warm cream, which reads as an AI-generated-template
/// cliché. Text is a near-black "ink" rather than pure black.
abstract final class AppColors {
  // Neutrals (cool-toned, blue-grey undertone — never warm/cream).
  static const background = Color(0xFFF6F8FB);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF12151C);
  static const inkMuted = Color(0xFF5B6472);
  static const border = Color(0xFFDCE2EA);
  static const muted = Color(0xFFEBEEF3);

  static const destructive = Color(0xFFD6452F);
  static const destructiveForeground = Color(0xFFFFFFFF);

  // Named subject-accent colors — chosen to be distinguishable and
  // intentional rather than default Material blue/green/red.
  /// Chemistry — amber/flame-toned (bunsen-burner warmth).
  static const chemistry = Color(0xFFE2711D);

  /// Biology — a leaf green.
  static const biology = Color(0xFF1F9D63);

  /// Physics — an indigo-blue.
  static const physics = Color(0xFF4457E8);
}

/// Returns the named accent color for a given [SubjectKey].
///
/// This is the single mapping used everywhere a subject needs to read as
/// visually distinct — the row-edge accent strip on lesson/quiz tables, and
/// (contextually) elsewhere a subject badge or chip appears.
Color subjectColor(SubjectKey subject) {
  switch (subject) {
    case SubjectKey.chemistry:
      return AppColors.chemistry;
    case SubjectKey.biology:
      return AppColors.biology;
    case SubjectKey.physics:
      return AppColors.physics;
  }
}

/// Convenience extension mirroring [subjectColor] for call-site ergonomics.
extension SubjectKeyColor on SubjectKey {
  Color get accentColor => subjectColor(this);
}

const _kBrandRadius = BorderRadius.all(Radius.circular(8));

/// The shadcn color scheme for the Teacher Web surface — cool off-white
/// background, near-black ink foreground, neutral primary (the subject
/// accents are intentionally kept out of `primary` so they read as
/// context-specific signal, not the app's generic action color).
final ShadColorScheme appShadColorScheme = ShadColorScheme(
  background: AppColors.background,
  foreground: AppColors.ink,
  card: AppColors.surface,
  cardForeground: AppColors.ink,
  popover: AppColors.surface,
  popoverForeground: AppColors.ink,
  primary: AppColors.ink,
  primaryForeground: AppColors.background,
  secondary: AppColors.muted,
  secondaryForeground: AppColors.ink,
  muted: AppColors.muted,
  mutedForeground: AppColors.inkMuted,
  accent: AppColors.muted,
  accentForeground: AppColors.ink,
  destructive: AppColors.destructive,
  destructiveForeground: AppColors.destructiveForeground,
  border: AppColors.border,
  input: AppColors.border,
  ring: AppColors.physics,
  selection: AppColors.physics.withValues(alpha: 0.20),
  custom: {
    'chemistry': AppColors.chemistry,
    'biology': AppColors.biology,
    'physics': AppColors.physics,
  },
);

/// `ShadTextTheme` built on Plus Jakarta Sans via `google_fonts`.
final ShadTextTheme appShadTextTheme = ShadTextTheme.fromGoogleFont(
  GoogleFonts.plusJakartaSans,
);

/// The shadcn theme applied to the Teacher Web `ShadApp` — the sole system
/// of record for teacher screens.
final ShadThemeData appShadTheme = ShadThemeData(
  brightness: Brightness.light,
  colorScheme: appShadColorScheme,
  textTheme: appShadTextTheme,
  radius: _kBrandRadius,
);

/// Companion Material `ThemeData`, color- and type-matched to [appShadTheme],
/// for the handful of teacher-surface widgets that still need a plain
/// Material ancestor (e.g. `NavigationRail`, form fields, `Scaffold`) so
/// they never look like a different, unthemed app mid-migration.
final ThemeData appMaterialTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.ink,
    brightness: Brightness.light,
    surface: AppColors.background,
    primary: AppColors.ink,
    onPrimary: AppColors.background,
    error: AppColors.destructive,
    onError: AppColors.destructiveForeground,
  ),
  textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  ),
  dividerColor: AppColors.border,
  cardTheme: const CardThemeData(
    color: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.zero,
  ),
  navigationRailTheme: NavigationRailThemeData(
    backgroundColor: AppColors.surface,
    indicatorColor: AppColors.physics.withValues(alpha: 0.16),
    selectedIconTheme: const IconThemeData(color: AppColors.physics),
    unselectedIconTheme: IconThemeData(color: AppColors.inkMuted),
    selectedLabelTextStyle: const TextStyle(
      color: AppColors.physics,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelTextStyle: TextStyle(color: AppColors.inkMuted),
  ),
);
