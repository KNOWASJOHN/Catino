import 'package:flutter/material.dart';

/// Spacing and border-radius tokens for the Catino app.
///
/// Using these constants instead of raw literals means a single edit here
/// propagates everywhere in the codebase.
abstract class AppSpacing {
  AppSpacing._();

  // ── Spacing ───────────────────────────────────────────────────────────────
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xxl  = 24;
  static const double xxxl = 32;
}

/// Border-radius tokens.
abstract class AppRadius {
  AppRadius._();

  static const double sm   = 8;    // small chips, badges
  static const double md   = 12;   // buttons, small cards
  static const double lg   = 16;   // food cards, skeletons
  static const double xl   = 18;   // order history cards
  static const double xxl  = 20;   // dialog shapes, confirm buttons
  static const double xxxl = 24;   // dialogs, order history container
  static const double pill = 40;   // nav-bar glass background
  static const double pill2 = 50;  // nav-bar outer container
}

/// Shared [BoxShadow] definitions used by multiple widgets.
abstract class AppShadows {
  AppShadows._();

  /// Standard elevation shadow for dark card surfaces.
  static List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x33000000), // black 20 %
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Stronger shadow for floating containers (dialogs, bottom sheets).
  static List<BoxShadow> dialog = [
    BoxShadow(
      color: Color(0x4D000000), // black 30 %
      blurRadius: 15,
      spreadRadius: 2,
      offset: Offset(0, 4),
    ),
  ];

  /// Glow shadow for accent-colored elements (nav bubble, CTA buttons).
  static BoxShadow accentGlow(Color color) => BoxShadow(
    color: color.withValues(alpha: 0.5),
    blurRadius: 12,
    spreadRadius: 2,
    offset: const Offset(0, 2),
  );

  /// Subtle notification-badge shadow.
  static BoxShadow badgeShadow(Color color) => BoxShadow(
    color: color.withValues(alpha: 0.3),
    blurRadius: 4,
    spreadRadius: 1,
    offset: const Offset(0, 1),
  );
}
