import 'package:flutter/material.dart';

/// Central color token palette for the Catino app.
///
/// All hardcoded colors throughout the app should be replaced with references
/// to constants defined here. To change the app's look, update values here.
abstract class AppColors {
  AppColors._();

  // ── Primary accent family ──────────────────────────────────────────────────
  /// Main brand green — progress indicators, success states, CTA buttons.
  static const Color primary = Color(0xFF00C853);

  /// Bright chartreuse — order history accent, empty-state icon.
  static const Color primaryBright = Color(0xFFCDFF00);

  /// Neon lime gradient stop — upload price gradient.
  static const Color primaryLight = Color(0xFF00E676);

  /// limeAccent.shade700 — form field focus borders, login/signup buttons,
  /// profile interactive controls.
  static final Color primaryCta = Colors.limeAccent.shade700;

  /// lime.shade400 — nav-bar bubble fill, cart checkout button.
  static final Color primaryCtaAlt = Colors.lime.shade400;

  /// lime.shade300 — nav-bar bubble gradient start.
  static final Color primaryCtaGradientStart = Colors.lime.shade300;

  /// lime.shade500 — nav-bar bubble gradient end.
  static final Color primaryCtaGradientEnd = Colors.lime.shade500;

  // ── Cart lime family ───────────────────────────────────────────────────────
  /// lime.shade900 — cart total amount text, pay-bill amount text.
  static final Color cartTotalText = Colors.lime.shade900;

  /// lime.shade50 — cart bottom-sheet gradient start, totals box.
  static final Color cartSurface50 = Colors.lime.shade50;

  /// lime.shade100 — cart bottom-sheet gradient mid.
  static final Color cartSurface100 = Colors.lime.shade100;

  /// lime.shade200 — cart bottom-sheet gradient end.
  static final Color cartSurface200 = Colors.lime.shade200;

  /// lime.shade600 — cart empty-state icon color.
  static final Color cartEmptyIcon = Colors.lime.shade600;

  // ── Surface / card family ──────────────────────────────────────────────────
  /// Deepest dark surface — page/dialog backgrounds.
  static const Color surface = Color(0xFF1e1e1e);

  /// Mid dark surface — card backgrounds, QR dialog date chip.
  static const Color surfaceCard = Color(0xFF2a2a2a);

  /// Subtle border on dark surfaces.
  static const Color border = Color(0xFF2d2d2d);

  /// Slightly lighter border used as an item/card separator.
  static const Color borderHighlight = Color(0xFF3a3a3a);

  /// Light scaffold background for food/cart pages.
  static final Color surfaceLight = Colors.grey.shade100;

  // ── Dialog gradient ────────────────────────────────────────────────────────
  /// Gradient start for print-job detail dialog.
  static const Color dialogGradientStart = Color(0xFF1A1A1A);

  /// Gradient mid.
  static const Color dialogGradientMid = Color(0xFF2D2D2D);

  /// Gradient end.
  static const Color dialogGradientEnd = Color(0xFF424242);

  // ── Skeleton loader ────────────────────────────────────────────────────────
  /// Base color for animated skeleton placeholders.
  static const Color skeletonBase = Color(0xFF2d2d2d);

  /// Highlight sweep color for the shimmer animation.
  static const Color skeletonHighlight = Color(0xFF3d3d3d);

  // ── Status / semantic ─────────────────────────────────────────────────────
  /// Payment / print-job PAID badge.
  static const Color statusSuccess = Color(0xFF69F0AE);

  /// Payment / print-job FAILED badge.
  static const Color statusError = Color(0xFFFF5252);

  /// Payment / print-job PENDING badge.
  static const Color statusWarning = Color(0xFFFFD740);

  /// Pending print / "unknown" status chip, cancelled payment.
  static const Color statusPending = Colors.orange;

  /// Print order "ready" status chip.
  static const Color statusReady = Colors.teal;

  // ── Danger / destructive ─────────────────────────────────────────────────-
  /// Swipe-to-delete background gradient on order cards.
  static const Color danger = Color(0xFFFF006E);

  /// Delete-confirm button background.
  static const Color deleteConfirmButton = Color(0xFFdc3545);

  // ── Network error card ────────────────────────────────────────────────────
  /// Background icon container on network-error card.
  static const Color networkErrorSurface = Color(0xFF1B1F3B);

  /// Exclamation badge on network-error card.
  static const Color networkErrorBadge = Color(0xFFE53935);

  // ── Neutral / utility ─────────────────────────────────────────────────────
  /// Pure white — text on dark surfaces.
  static const Color white = Colors.white;

  /// White at 70 % — slightly muted text on dark surfaces.
  static const Color white70 = Color(0xB3FFFFFF);

  /// White at 54 % — further muted text.
  static const Color white54 = Color(0x8AFFFFFF);

  /// Notification badge / error / delete indicators.
  static final Color red = Colors.red;
  static final Color redShade400 = Colors.red.shade400;

  /// Success / discount labels.
  static final Color green = Colors.green;
  static final Color greenShade600 = Colors.green.shade600;

  /// Unread notification dot.
  static const Color notificationDot = Colors.blue;

  /// Food price text (limeAccent, unshaded).
  static const Color priceText = Colors.limeAccent;

  // ── Glass / backdrop layers ───────────────────────────────────────────────
  /// Semi-transparent white used behind the header BackdropFilter.
  static const Color glassHeader = Color(0x33FFFFFF); // withOpacity(0.2)

  /// Semi-transparent white used for nav-bar glass background.
  static const Color glassNavBar = Color(0x1AFFFFFF); // withOpacity(0.10)

  /// Nav-bar border glass color.
  static const Color glassNavBarBorder = Color(0x40FFFFFF); // withOpacity(0.25)

  // ── Overlay / barrier ────────────────────────────────────────────────────
  /// Standard dialog barrier (70 % black).
  static const Color barrierDark = Color(0xB3000000);

  /// Lighter dialog barrier (55 % black).
  static const Color barrierMedium = Color(0x8C000000);

  /// Subtle overlay (35 % black).
  static const Color barrierLight = Color(0x59000000);
}
