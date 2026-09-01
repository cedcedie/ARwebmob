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

/// Dark counterpart to [AppColors] — same cool blue-grey undertone (never
/// warm/near-black-brown), just inverted lightness. Subject accents and the
/// destructive/success roles are lifted a touch (higher L*) versus their
/// light-mode values so they still clear WCAG contrast against the dark
/// surfaces below; hues are kept identical to [AppColors] so a teacher
/// switching themes never sees a subject's "color identity" change, only
/// its exact shade.
abstract final class AppColorsDark {
  static const background = Color(0xFF0E1218);
  static const surface = Color(0xFF161B23);
  static const ink = Color(0xFFF2F4F8);
  static const inkMuted = Color(0xFF9AA4B2);
  static const border = Color(0xFF2A3140);
  static const muted = Color(0xFF1D232E);

  static const destructive = Color(0xFFE2604A);
  static const destructiveForeground = Color(0xFF0E1218);

  static const success = Color(0xFF4FB6DB);
  static const successForeground = Color(0xFF0E1218);

  static const chemistry = Color(0xFFF0913F);
  static const biology = Color(0xFF35C784);
  static const physics = Color(0xFF7C8CFF);
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

// ---------------------------------------------------------------------------
// Dark mode
//
// Mirrors [appShadColorScheme]/[appShadTheme]/[appMaterialTheme] role-for-
// role against [AppColorsDark] instead of [AppColors]. Kept as a literal
// parallel structure (not derived programmatically) so the two themes stay
// easy to read side by side and a future palette tweak to one role is an
// obvious two-line diff rather than a rewrite of a generation function.
// ---------------------------------------------------------------------------

final ShadColorScheme appShadColorSchemeDark = ShadColorScheme(
  background: AppColorsDark.background,
  foreground: AppColorsDark.ink,
  card: AppColorsDark.surface,
  cardForeground: AppColorsDark.ink,
  popover: AppColorsDark.surface,
  popoverForeground: AppColorsDark.ink,
  primary: AppColorsDark.ink,
  primaryForeground: AppColorsDark.background,
  secondary: AppColorsDark.muted,
  secondaryForeground: AppColorsDark.ink,
  muted: AppColorsDark.muted,
  mutedForeground: AppColorsDark.inkMuted,
  accent: AppColorsDark.muted,
  accentForeground: AppColorsDark.ink,
  destructive: AppColorsDark.destructive,
  destructiveForeground: AppColorsDark.destructiveForeground,
  border: AppColorsDark.border,
  input: AppColorsDark.border,
  ring: AppColorsDark.physics,
  selection: AppColorsDark.physics.withValues(alpha: 0.28),
  custom: {
    'chemistry': AppColorsDark.chemistry,
    'biology': AppColorsDark.biology,
    'physics': AppColorsDark.physics,
  },
);

final ShadThemeData appShadThemeDark = ShadThemeData(
  brightness: Brightness.dark,
  colorScheme: appShadColorSchemeDark,
  textTheme: appShadTextTheme,
  radius: _kBrandRadius,
);

final ThemeData appMaterialThemeDark = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColorsDark.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColorsDark.ink,
    brightness: Brightness.dark,
    surface: AppColorsDark.background,
    onSurface: AppColorsDark.ink,
    primary: AppColorsDark.ink,
    onPrimary: AppColorsDark.background,
    primaryContainer: AppColorsDark.muted,
    onPrimaryContainer: AppColorsDark.ink,
    secondary: AppColorsDark.muted,
    onSecondary: AppColorsDark.ink,
    secondaryContainer: AppColorsDark.muted,
    onSecondaryContainer: AppColorsDark.ink,
    tertiary: AppColorsDark.physics,
    onTertiary: AppColorsDark.background,
    tertiaryContainer: AppColorsDark.physics.withValues(alpha: 0.24),
    onTertiaryContainer: AppColorsDark.physics,
    error: AppColorsDark.destructive,
    onError: AppColorsDark.destructiveForeground,
    errorContainer: AppColorsDark.destructive.withValues(alpha: 0.18),
    onErrorContainer: AppColorsDark.destructive,
    outline: AppColorsDark.border,
    outlineVariant: AppColorsDark.muted,
  ),
  textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme)
      .apply(bodyColor: AppColorsDark.ink, displayColor: AppColorsDark.ink),
  dividerColor: AppColorsDark.border,
  cardTheme: const CardThemeData(
    color: AppColorsDark.surface,
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.zero,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColorsDark.muted,
    selectedColor: AppColorsDark.physics.withValues(alpha: 0.24),
    disabledColor: AppColorsDark.muted,
    labelStyle: const TextStyle(color: AppColorsDark.ink),
    side: const BorderSide(color: AppColorsDark.border),
    shape: const StadiumBorder(),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColorsDark.muted,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: _kBrandRadius,
      borderSide: const BorderSide(color: AppColorsDark.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: _kBrandRadius,
      borderSide: const BorderSide(color: AppColorsDark.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: _kBrandRadius,
      borderSide: const BorderSide(color: AppColorsDark.physics, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: _kBrandRadius,
      borderSide: const BorderSide(color: AppColorsDark.destructive),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: _kBrandRadius,
      borderSide: const BorderSide(color: AppColorsDark.destructive, width: 2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: _kBrandRadius,
      borderSide: const BorderSide(color: AppColorsDark.muted),
    ),
    labelStyle: const TextStyle(color: AppColorsDark.inkMuted),
    floatingLabelStyle: const TextStyle(color: AppColorsDark.physics),
    hintStyle: const TextStyle(color: AppColorsDark.inkMuted),
    errorStyle: const TextStyle(color: AppColorsDark.destructive),
  ),
  navigationRailTheme: NavigationRailThemeData(
    backgroundColor: AppColorsDark.surface,
    indicatorColor: AppColorsDark.physics.withValues(alpha: 0.24),
    selectedIconTheme: const IconThemeData(color: AppColorsDark.physics),
    unselectedIconTheme: IconThemeData(color: AppColorsDark.inkMuted),
    selectedLabelTextStyle: const TextStyle(
      color: AppColorsDark.physics,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelTextStyle: TextStyle(color: AppColorsDark.inkMuted),
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: _kBrandRadius),
      ),
      side: const WidgetStatePropertyAll(
        BorderSide(color: AppColorsDark.border),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorsDark.physics.withValues(alpha: 0.24);
        }
        return AppColorsDark.surface;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorsDark.physics;
        }
        return AppColorsDark.inkMuted;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorsDark.physics;
        }
        return AppColorsDark.inkMuted;
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
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: AppColorsDark.physics,
    circularTrackColor: AppColorsDark.muted,
    linearTrackColor: AppColorsDark.muted,
    strokeWidth: 3,
  ),
);
