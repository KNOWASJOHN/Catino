/// Enum for color print mode
enum ColorMode {
  blackAndWhite,
  color;

  /// Get display text for the color mode
  String get displayText {
    switch (this) {
      case ColorMode.blackAndWhite:
        return 'Black & White';
      case ColorMode.color:
        return 'Color';
    }
  }

  /// Convert from string
  static ColorMode fromString(String mode) {
    switch (mode.toLowerCase()) {
      case 'blackandwhite':
      case 'black & white':
      case 'bw':
        return ColorMode.blackAndWhite;
      case 'color':
        return ColorMode.color;
      default:
        return ColorMode.blackAndWhite;
    }
  }

  /// Convert to string for database
  String toDbString() {
    switch (this) {
      case ColorMode.blackAndWhite:
        return 'blackAndWhite';
      case ColorMode.color:
        return 'color';
    }
  }
}

/// Enum for print sides
enum Sides {
  single,
  double;

  /// Get display text for the sides
  String get displayText {
    switch (this) {
      case Sides.single:
        return 'Single-sided';
      case Sides.double:
        return 'Double-sided';
    }
  }

  /// Convert from string
  static Sides fromString(String sides) {
    switch (sides.toLowerCase()) {
      case 'single':
      case 'single-sided':
        return Sides.single;
      case 'double':
      case 'double-sided':
        return Sides.double;
      default:
        return Sides.single;
    }
  }

  /// Convert to string for database
  String toDbString() {
    switch (this) {
      case Sides.single:
        return 'single';
      case Sides.double:
        return 'double';
    }
  }
}

/// Pricing configuration and calculation
class PricingConfig {
  // Pricing rates per page in rupees
  static const double blackAndWhiteSingleRate = 2.0;
  static const double blackAndWhiteDoubleRate = 1.5;
  static const double colorSingleRate = 5.0;
  static const double colorDoubleRate = 4.0;

  /// Calculate total price based on page count and options
  static double calculatePrice({
    required int pageCount,
    required ColorMode colorMode,
    required Sides sides,
  }) {
    if (pageCount <= 0) return 0.0;

    double ratePerPage;

    if (colorMode == ColorMode.blackAndWhite) {
      ratePerPage = sides == Sides.single
          ? blackAndWhiteSingleRate
          : blackAndWhiteDoubleRate;
    } else {
      ratePerPage = sides == Sides.single ? colorSingleRate : colorDoubleRate;
    }

    return pageCount * ratePerPage;
  }

  /// Format price for display (e.g., "₹25.00")
  static String formatPrice(double price) {
    return '₹${price.toStringAsFixed(2)}';
  }

  /// Get rate per page for given options
  static double getRatePerPage(ColorMode colorMode, Sides sides) {
    if (colorMode == ColorMode.blackAndWhite) {
      return sides == Sides.single
          ? blackAndWhiteSingleRate
          : blackAndWhiteDoubleRate;
    } else {
      return sides == Sides.single ? colorSingleRate : colorDoubleRate;
    }
  }
}
