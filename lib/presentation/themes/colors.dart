import 'package:flutter/material.dart';

/// Application color palette.
///
/// Provides a centralized location for all color constants used throughout
/// the application, including primary colors, semantic colors, and
/// reading-specific theme colors.
class AppColors {
  AppColors._();

  // ============================================
  // Primary Color Palette
  // ============================================

  /// Primary brand color - Purple
  static const Color primary = Color(0xFF6750A4);

  /// Light variant of primary color
  static const Color primaryLight = Color(0xFFD0BCFF);

  /// Dark variant of primary color
  static const Color primaryDark = Color(0xFF4F378B);

  /// Container color for primary
  static const Color primaryContainer = Color(0xFFEADDFF);

  /// Secondary brand color - Mauve
  static const Color secondary = Color(0xFF625B71);

  /// Light variant of secondary color
  static const Color secondaryLight = Color(0xFFCCC2DC);

  /// Dark variant of secondary color
  static const Color secondaryDark = Color(0xFF4A4458);

  /// Container color for secondary
  static const Color secondaryContainer = Color(0xFFE8DEF8);

  /// Tertiary accent color - Rose
  static const Color tertiary = Color(0xFF7D5260);

  /// Light variant of tertiary color
  static const Color tertiaryLight = Color(0xFFEFB8C8);

  /// Dark variant of tertiary color
  static const Color tertiaryDark = Color(0xFF633B48);

  /// Container color for tertiary
  static const Color tertiaryContainer = Color(0xFFFFD8E4);

  // ============================================
  // Semantic Colors
  // ============================================

  /// Success color - Green
  static const Color success = Color(0xFF4CAF50);

  /// Light variant of success color
  static const Color successLight = Color(0xFF81C784);

  /// Dark variant of success color
  static const Color successDark = Color(0xFF388E3C);

  /// Container color for success
  static const Color successContainer = Color(0xFFC8E6C9);

  /// Warning color - Amber
  static const Color warning = Color(0xFFFF9800);

  /// Light variant of warning color
  static const Color warningLight = Color(0xFFFFB74D);

  /// Dark variant of warning color
  static const Color warningDark = Color(0xFFF57C00);

  /// Container color for warning
  static const Color warningContainer = Color(0xFFFFE0B2);

  /// Error color - Red
  static const Color error = Color(0xFFB3261E);

  /// Light variant of error color
  static const Color errorLight = Color(0xFFF2B8B5);

  /// Dark variant of error color
  static const Color errorDark = Color(0xFF8C1D18);

  /// Container color for error
  static const Color errorContainer = Color(0xFFF9DEDC);

  /// Info color - Blue
  static const Color info = Color(0xFF2196F3);

  /// Light variant of info color
  static const Color infoLight = Color(0xFF64B5F6);

  /// Dark variant of info color
  static const Color infoDark = Color(0xFF1976D2);

  /// Container color for info
  static const Color infoContainer = Color(0xFFBBDEFB);

  // ============================================
  // Neutral Colors (Light Theme)
  // ============================================

  /// Light surface background
  static const Color surfaceLight = Color(0xFFFFFBFE);

  /// Light surface variant
  static const Color surfaceVariantLight = Color(0xFFE7E0EC);

  /// Light surface container
  static const Color surfaceContainerLight = Color(0xFFF3EDF7);

  /// Light surface container highest
  static const Color surfaceContainerHighestLight = Color(0xFFE7E0EC);

  /// Text color on light background
  static const Color onSurfaceLight = Color(0xFF1C1B1F);

  /// Variant text color on light background
  static const Color onSurfaceVariantLight = Color(0xFF49454F);

  /// Outline color for light theme
  static const Color outlineLight = Color(0xFF79747E);

  /// Outline variant color for light theme
  static const Color outlineVariantLight = Color(0xFFCAC4D0);

  // ============================================
  // Neutral Colors (Dark Theme)
  // ============================================

  /// Dark surface background
  static const Color surfaceDark = Color(0xFF1C1B1F);

  /// Dark surface variant
  static const Color surfaceVariantDark = Color(0xFF49454F);

  /// Dark surface container
  static const Color surfaceContainerDark = Color(0xFF211F26);

  /// Dark surface container highest
  static const Color surfaceContainerHighestDark = Color(0xFF36343B);

  /// Text color on dark background
  static const Color onSurfaceDark = Color(0xFFE6E1E5);

  /// Variant text color on dark background
  static const Color onSurfaceVariantDark = Color(0xFFCAC4D0);

  /// Outline color for dark theme
  static const Color outlineDark = Color(0xFF938F99);

  /// Outline variant color for dark theme
  static const Color outlineVariantDark = Color(0xFF49454F);

  // ============================================
  // Reading Theme Background Colors
  // ============================================

  /// Light reading background - Pure white
  static const Color readingLightBackground = Color(0xFFFFFFFF);

  /// Light reading text color
  static const Color readingLightText = Color(0xFF1C1B1F);

  /// Light reading link color
  static const Color readingLightLink = Color(0xFF6750A4);

  /// Dark reading background - Dark gray
  static const Color readingDarkBackground = Color(0xFF1C1B1F);

  /// Dark reading text color
  static const Color readingDarkText = Color(0xFFE6E1E5);

  /// Dark reading link color
  static const Color readingDarkLink = Color(0xFFD0BCFF);

  /// Sepia reading background - Warm cream
  static const Color readingSepiaBackground = Color(0xFFF4ECD8);

  /// Sepia reading text color - Dark brown
  static const Color readingSepiaText = Color(0xFF3E2723);

  /// Sepia reading link color - Medium brown
  static const Color readingSepiaLink = Color(0xFF6D4C41);

  /// AMOLED reading background - Pure black
  static const Color readingAmoledBackground = Color(0xFF000000);

  /// AMOLED reading text color - Light gray
  static const Color readingAmoledText = Color(0xFFE6E1E5);

  /// AMOLED reading link color - Light purple
  static const Color readingAmoledLink = Color(0xFFD0BCFF);

  // ============================================
  // Highlight & Selection Colors
  // ============================================

  /// Light theme selection color
  static const Color selectionLight = Color(0xFFEADDFF);

  /// Dark theme selection color
  static const Color selectionDark = Color(0xFF4F378B);

  /// Sepia theme selection color
  static const Color selectionSepia = Color(0xFFD7CCC8);

  /// AMOLED theme selection color
  static const Color selectionAmoled = Color(0xFF4F378B);

  /// Yellow highlight color for annotations
  static const Color highlightYellow = Color(0xFFFFEB3B);

  /// Green highlight color for annotations
  static const Color highlightGreen = Color(0xFF8BC34A);

  /// Blue highlight color for annotations
  static const Color highlightBlue = Color(0xFF03A9F4);

  /// Pink highlight color for annotations
  static const Color highlightPink = Color(0xFFE91E63);

  /// Orange highlight color for annotations
  static const Color highlightOrange = Color(0xFFFF9800);

  // ============================================
  // Utility Colors
  // ============================================

  /// Fully transparent
  static const Color transparent = Color(0x00000000);

  /// Pure white
  static const Color white = Color(0xFFFFFFFF);

  /// Pure black
  static const Color black = Color(0xFF000000);

  /// Shadow color
  static const Color shadow = Color(0xFF000000);

  /// Scrim overlay color
  static const Color scrim = Color(0xFF000000);

  // ============================================
  // Helper Methods
  // ============================================

  /// Returns a color with the specified opacity (0.0 to 1.0).
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity.clamp(0.0, 1.0));
  }

  /// Returns a lighter version of the given color.
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Returns a darker version of the given color.
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Returns true if the color is considered dark.
  static bool isDark(Color color) {
    final luminance = color.computeLuminance();
    return luminance < 0.5;
  }

  /// Returns a contrasting text color (black or white) based on background.
  static Color getContrastingTextColor(Color backgroundColor) {
    return isDark(backgroundColor) ? white : black;
  }
}
