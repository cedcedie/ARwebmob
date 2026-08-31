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

  /// Positive-affect confirmation color (e.g. "code issued", "saved").
  ///
  /// Item 6: the previous value (`0xFF0D8A72`) was only ~168° hue — a mere
  /// ~16° from [biology]'s ~152°, too close for the two to read as
  /// unambiguously different colors when they appear together (e.g. the
  /// access-codes screen's success banner alongside biology-accented
  /// table rows). Widened by hue shift rather than a lightness/saturation
  /// delta: keeping saturation and lightness identical to the original
  /// (82.8% / 29.6%) isolates the change to hue alone, so this stays
  /// exactly as vivid/dark as before and no other visual property (contrast
  /// against `successForeground`, "how saturated/dark does this look" next
  /// to the rest of the palette) shifts as a side effect — only which hue
  /// family it reads as. Moved to ~195°, a cyan-leaning teal-blue, which
  /// widens the separation from biology to ~43° (and stays ~38° clear of
  /// [physics]'s ~233° indigo-blue on the other side) while still reading
  /// as a cool, calm "this worked" color rather than a warning tone.
  static const success = Color(0xFF0D6B8A);
  static const successForeground = Color(0xFFFFFFFF);

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
  // Every tonal role is pinned to a curated `AppColors` value rather than
  // left to `fromSeed`'s Material-3 tonal-palette algorithm — otherwise
  // roles nobody explicitly overrides (primaryContainer, secondaryContainer,
  // tertiary, errorContainer, …) quietly resolve to an auto-generated color
  // that doesn't belong to this palette, and leak into call sites that read
  // them (e.g. a `Card(color: colorScheme.primaryContainer)`).
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.ink,
    brightness: Brightness.light,
    surface: AppColors.background,
    onSurface: AppColors.ink,
    primary: AppColors.ink,
    onPrimary: AppColors.background,
    primaryContainer: AppColors.muted,
    onPrimaryContainer: AppColors.ink,
    secondary: AppColors.muted,
    onSecondary: AppColors.ink,
    secondaryContainer: AppColors.muted,
    onSecondaryContainer: AppColors.ink,
    tertiary: AppColors.physics,
    onTertiary: AppColors.background,
    tertiaryContainer: AppColors.physics.withValues(alpha: 0.16),
    onTertiaryContainer: AppColors.physics,
    // Same curated red the Shad theme calls `destructive` — a single
    // source of truth so `ShadTheme.of(context).colorScheme.destructive`
    // and `Theme.of(context).colorScheme.error` always render identically,
    // regardless of which API a given widget happens to call.
    error: AppColors.destructive,
    onError: AppColors.destructiveForeground,
    errorContainer: AppColors.destructive.withValues(alpha: 0.12),
    onErrorContainer: AppColors.destructive,
    outline: AppColors.border,
    outlineVariant: AppColors.muted,
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
  // `Chip`/`FilterChip` have no direct shadcn_ui equivalent (no chip/toggle
  // component exists in this package version) — themed to match the
  // palette here instead of forcing a bad shadcn fit.
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.muted,
    selectedColor: AppColors.physics.withValues(alpha: 0.16),
    disabledColor: AppColors.muted,
    labelStyle: const TextStyle(color: AppColors.ink),
    side: const BorderSide(color: AppColors.border),
    shape: const StadiumBorder(),
  ),
  // Every `FormBuilderTextField`/`FormBuilderDropdown`/
  // `DropdownButtonFormField`/`TextField` in the teacher forms is a plain
  // Material form field (no shadcn_ui form-field component exists in this
  // package version) — themed here once so every field inherits it
  // automatically, filled + rounded to match the rest of the palette rather
  // than falling back to stock Material's underline/outline defaults.
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.muted,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: _kBrandRadius,
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: _kBrandRadius,
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: _kBrandRadius,
      borderSide: const BorderSide(color: AppColors.physics, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: _kBrandRadius,
      borderSide: const BorderSide(color: AppColors.destructive),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: _kBrandRadius,
      borderSide: const BorderSide(color: AppColors.destructive, width: 2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: _kBrandRadius,
      borderSide: const BorderSide(color: AppColors.muted),
    ),
    labelStyle: const TextStyle(color: AppColors.inkMuted),
    floatingLabelStyle: const TextStyle(color: AppColors.physics),
    hintStyle: const TextStyle(color: AppColors.inkMuted),
    errorStyle: const TextStyle(color: AppColors.destructive),
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
  // `SegmentedButton` (access_codes_screen.dart's subject/lesson/retake tab
  // switcher) has no direct shadcn_ui equivalent, same situation as
  // `Chip`/`FilterChip` above — left untouched it renders in stock
  // Material-3 pill/stadium chrome, which reads as a visually distinct
  // "third" button idiom next to `ShadButton`'s rounded-rect brand shape.
  // Themed to match: `_kBrandRadius` rounded corners (not a stadium) so it
  // reads as the same button family as `ShadButton`/`inputDecorationTheme`,
  // `AppColors.border` outline like every other bordered surface in this
  // theme, and the same physics-accent selected state `navigationRailTheme`
  // above uses for "this is the current selection" (this screen's tabs are
  // the same kind of selection signal as the nav rail's active destination,
  // not a subject-scoped choice).
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: _kBrandRadius),
      ),
      side: const WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.physics.withValues(alpha: 0.16);
        }
        return AppColors.surface;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.physics;
        }
        return AppColors.inkMuted;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.physics;
        }
        return AppColors.inkMuted;
      }),
      textStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
        );
      }),
    ),
  ),
  // Every bare `CircularProgressIndicator()` across the list screens
  // (lessons/quizzes/students/access-codes/item-analysis) previously fell
  // through to stock Material defaults for stroke width and track color —
  // themed here once so they all pick up the same brand look automatically.
  // Uses `AppColors.physics`, the same accent already used for focus rings
  // (`ring`/`focusedBorder` above) and selected-state chrome
  // (`navigationRailTheme`, `segmentedButtonTheme`) — the app's established
  // "this is active/in-progress" signal color — rather than `AppColors.ink`,
  // which is reserved for static foreground/primary content.
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: AppColors.physics,
    circularTrackColor: AppColors.muted,
    linearTrackColor: AppColors.muted,
    strokeWidth: 3,
  ),
);
