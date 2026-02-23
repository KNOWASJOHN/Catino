import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Assembles the [ThemeData] used by [MaterialApp].
///
/// Wiring this to [MaterialApp.theme] means:
///   - `fontFamily: 'Unbounded'` is inherited by every Text and Material widget
///     (eliminating ~150 explicit `fontFamily` declarations).
///   - [ColorScheme] values map to the Catino brand palette so built-in
///     Material widgets (switches, progress indicators, etc.) automatically
///     use the correct colors.
///
/// Dark-mode: swap [appLightTheme] for [appDarkTheme] on [MaterialApp.darkTheme]
/// once the visual design is finalised.  The structure is already in place;
/// only the specific color values need to change.
ThemeData get appLightTheme {
  final baseTextTheme = ThemeData.light().textTheme.apply(
    fontFamily: 'Unbounded',
    bodyColor: Colors.black87,
    displayColor: Colors.black,
  );

  return ThemeData(
    useMaterial3: false,

    // ── Font ──────────────────────────────────────────────────────────────────
    // Setting fontFamily here means widgets no longer need to set it one-by-one.
    fontFamily: 'Unbounded',

    // ── Color scheme ──────────────────────────────────────────────────────────
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary, // brand green
      secondary: AppColors.primaryBright, // chartreuse accent
      surface: Colors.white,
      error: AppColors.statusError, // 0xFFFF5252
      onPrimary: AppColors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black,
      onError: AppColors.white,
    ),

    scaffoldBackgroundColor: AppColors.surfaceLight,

    // ── Text theme ─────────────────────────────────────────────────────────────
    textTheme: baseTextTheme,
    primaryTextTheme: baseTextTheme,

    // ── App bar ────────────────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTextStyles.headerAppName,
      iconTheme: IconThemeData(color: Colors.black),
    ),

    // ── Card ───────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
    ),

    // ── Dialog ─────────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      titleTextStyle: AppTextStyles.dialogTitle,
      contentTextStyle: AppTextStyles.bodyMuted,
    ),

    // ── Input decoration ───────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: AppTextStyles.fieldLabel,
      hintStyle: AppTextStyles.bodyMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryCta, width: 2),
      ),
    ),

    // ── Elevated button ────────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        textStyle: AppTextStyles.actionButton,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),

    // ── Text button ────────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryCta,
        textStyle: AppTextStyles.actionButton,
      ),
    ),

    // ── Switch ───────────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryCta
            : Colors.grey,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryCta.withValues(alpha: 0.4)
            : Colors.grey.withValues(alpha: 0.4),
      ),
    ),

    // ── Circular progress indicator ───────────────────────────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),

    // ── Snack bar ─────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceCard,
      contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Divider ───────────────────────────────────────────────────────────────
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade300,
      thickness: 1,
      space: 0,
    ),
  );
}

/// Stub dark theme — identical visual to [appLightTheme] for now, ready to
/// receive custom overrides when a separate dark-mode palette is designed.
ThemeData get appDarkTheme => appLightTheme;
