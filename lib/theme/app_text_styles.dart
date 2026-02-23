import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Central typography system for the Catino app.
///
/// Provides two access patterns:
///   1. [textTheme] — a full [TextTheme] registered on [ThemeData]; Material
///      widgets inherit it automatically once [appLightTheme] is applied to
///      [MaterialApp].
///   2. Named static [TextStyle] constants — used directly in widgets that
///      need a specific, named style (e.g. [priceAccent], [badgeLabel]).
///
/// All styles use the `Unbounded` font family, which is bundled locally.
abstract class AppTextStyles {
  AppTextStyles._();

  // ── Font family ───────────────────────────────────────────────────────────
  static const String _font = 'Unbounded';

  // ── Size scale ────────────────────────────────────────────────────────────
  // Maps the ad-hoc 6–28 pt range to 8 semantic levels.
  static const double _szDisplay = 28;   // cart empty heading, login app name
  static const double _szHeadline = 24;  // welcome greeting, section card title
  static const double _szTitle = 20;     // section headers, price display
  static const double _szSubtitle = 18;  // dialog/panel titles
  static const double _szBody = 16;      // item names, quantity
  static const double _szCaption = 14;   // order codes, date text, field text
  static const double _szSmall = 12;     // subtotals, muted metadata
  static const double _szLabel = 10;     // search field micro text, uploading %
  // Micro labels used only on dense print-job cards:
  static const double _szMicro = 8;      // food descriptions, pricing labels (also used by SkeletonLoader)
  static const double _szNano = 7;       // DATE / PAGES / AMOUNT column headers
  static const double _szPico = 6;       // "PDF only, max 10 MB" hint

  // ── TextTheme (for ThemeData) ─────────────────────────────────────────────
  static TextTheme get textTheme => const TextTheme(
    // Maps to Material 3 slots used by built-in widgets.
    displayLarge: TextStyle(
      fontFamily: _font,
      fontSize: _szDisplay,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    ),
    displayMedium: TextStyle(
      fontFamily: _font,
      fontSize: _szHeadline,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    titleLarge: TextStyle(
      fontFamily: _font,
      fontSize: _szTitle,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    titleMedium: TextStyle(
      fontFamily: _font,
      fontSize: _szSubtitle,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    titleSmall: TextStyle(
      fontFamily: _font,
      fontSize: _szBody,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    bodyLarge: TextStyle(
      fontFamily: _font,
      fontSize: _szCaption,
      fontWeight: FontWeight.w400,
      color: Colors.black87,
    ),
    bodyMedium: TextStyle(
      fontFamily: _font,
      fontSize: _szSmall,
      fontWeight: FontWeight.w400,
      color: Colors.black87,
    ),
    bodySmall: TextStyle(
      fontFamily: _font,
      fontSize: _szLabel,
      fontWeight: FontWeight.w400,
      color: Colors.black54,
    ),
    labelLarge: TextStyle(
      fontFamily: _font,
      fontSize: _szCaption,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
    labelMedium: TextStyle(
      fontFamily: _font,
      fontSize: _szSmall,
      fontWeight: FontWeight.w500,
      color: Colors.black54,
    ),
    labelSmall: TextStyle(
      fontFamily: _font,
      fontSize: _szLabel,
      fontWeight: FontWeight.w500,
      color: Colors.black54,
    ),
  );

  // ── Named static styles ───────────────────────────────────────────────────
  // These are ready-to-use combos that appear in 3+ places across the codebase.

  // -- Headings / titles --
  static const TextStyle pageTitle = TextStyle(
    fontFamily: _font,
    fontSize: _szTitle,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: _font,
    fontSize: _szBody,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static const TextStyle dialogTitle = TextStyle(
    fontFamily: _font,
    fontSize: _szSubtitle,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    letterSpacing: -0.5,
  );

  static const TextStyle panelTitle = TextStyle(
    fontFamily: _font,
    fontSize: _szSubtitle,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    letterSpacing: -0.3,
  );

  // -- Body / general --
  static const TextStyle body = TextStyle(
    fontFamily: _font,
    fontSize: _szCaption,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: _font,
    fontSize: _szCaption,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _font,
    fontSize: _szSmall,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  );

  // -- Buttons / CTAs --
  static const TextStyle ctaButton = TextStyle(
    fontFamily: _font,
    fontSize: _szBody,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
  );

  static const TextStyle actionButton = TextStyle(
    fontFamily: _font,
    fontSize: _szCaption,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  // -- Price / amount --
  static const TextStyle priceAccent = TextStyle(
    fontFamily: _font,
    fontSize: _szTitle,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );

  static const TextStyle priceSmall = TextStyle(
    fontFamily: _font,
    fontSize: _szBody,
    fontWeight: FontWeight.w700,
    color: AppColors.priceText,
  );

  // -- Badge / chip labels --
  static const TextStyle badgeLabel = TextStyle(
    fontFamily: _font,
    fontSize: _szLabel,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle chipLabel = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    letterSpacing: 0.3,
  );

  // -- Order / print card micro-labels --
  static const TextStyle orderCode = TextStyle(
    fontFamily: _font,
    fontSize: _szCaption,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    letterSpacing: -0.5,
  );

  static const TextStyle columnLabel = TextStyle(
    fontFamily: _font,
    fontSize: _szNano,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
    letterSpacing: 1.0,
  );

  static const TextStyle hintTiny = TextStyle(
    fontFamily: _font,
    fontSize: _szPico,
    fontWeight: FontWeight.w400,
    color: AppColors.white54,
  );

  /// Dense micro label for food card descriptions and upload pricing labels.
  static const TextStyle micro = TextStyle(
    fontFamily: _font,
    fontSize: _szMicro,
    fontWeight: FontWeight.w400,
    color: AppColors.white70,
  );

  // -- Form fields --
  static const TextStyle fieldText = TextStyle(
    fontFamily: _font,
    fontSize: _szSmall,
    fontWeight: FontWeight.w300,
    color: Colors.black87,
  );

  static const TextStyle fieldLabel = TextStyle(
    fontFamily: _font,
    fontSize: _szSmall,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
  );

  // -- Navigation --
  static const TextStyle navBadge = TextStyle(
    fontFamily: _font,
    fontSize: _szLabel,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  // -- App header --
  static const TextStyle headerWelcome = TextStyle(
    fontFamily: _font,
    fontSize: _szLabel,
    fontWeight: FontWeight.w400,
    color: Colors.black,
    height: 1.0,
  );

  static const TextStyle headerAppName = TextStyle(
    fontFamily: _font,
    fontSize: _szTitle,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );
}
