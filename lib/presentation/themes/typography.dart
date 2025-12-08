import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application typography definitions.
///
/// Provides consistent text styles throughout the application using
/// Google Fonts (Nunito for UI, Literata for reading content).
class AppTypography {
  AppTypography._();

  // ============================================
  // Font Families
  // ============================================

  /// Reading content font family (Literata)
  static String get _readingFontFamily {
    try {
      return GoogleFonts.literata().fontFamily ?? 'Georgia';
    } catch (e) {
      return 'Georgia';
    }
  }

  // ============================================
  // Display Styles (Extra Large)
  // ============================================

  /// Display large - Extra large display text
  static TextStyle displayLarge({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      height: 1.12,
      letterSpacing: -0.25,
      color: color,
    );
  }

  /// Display medium - Large display text
  static TextStyle displayMedium({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      height: 1.16,
      color: color,
    );
  }

  /// Display small - Small display text
  static TextStyle displaySmall({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      height: 1.22,
      color: color,
    );
  }

  // ============================================
  // Headline Styles
  // ============================================

  /// Headline 1 - Largest headline
  static TextStyle headline1({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0,
      color: color,
    );
  }

  /// Headline 2 - Large headline
  static TextStyle headline2({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.29,
      letterSpacing: 0,
      color: color,
    );
  }

  /// Headline 3 - Medium headline
  static TextStyle headline3({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.33,
      letterSpacing: 0,
      color: color,
    );
  }

  /// Headline large - Material 3 style
  static TextStyle headlineLarge({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      height: 1.25,
      color: color,
    );
  }

  /// Headline medium - Material 3 style
  static TextStyle headlineMedium({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: 1.29,
      color: color,
    );
  }

  /// Headline small - Material 3 style
  static TextStyle headlineSmall({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 1.33,
      color: color,
    );
  }

  // ============================================
  // Title Styles
  // ============================================

  /// Title large - Large title text
  static TextStyle titleLarge({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.27,
      letterSpacing: 0,
      color: color,
    );
  }

  /// Title medium - Medium title text
  static TextStyle titleMedium({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      letterSpacing: 0.15,
      color: color,
    );
  }

  /// Title small - Small title text
  static TextStyle titleSmall({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
      color: color,
    );
  }

  // ============================================
  // Body Styles
  // ============================================

  /// Body large - Large body text
  static TextStyle bodyLarge({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.5,
      color: color,
    );
  }

  /// Body medium - Medium body text (default)
  static TextStyle bodyMedium({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0.25,
      color: color,
    );
  }

  /// Body small - Small body text
  static TextStyle bodySmall({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.4,
      color: color,
    );
  }

  // ============================================
  // Label Styles
  // ============================================

  /// Label large - Large label/button text
  static TextStyle labelLarge({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
      color: color,
    );
  }

  /// Label medium - Medium label text
  static TextStyle labelMedium({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.33,
      letterSpacing: 0.5,
      color: color,
    );
  }

  /// Label small - Small label text
  static TextStyle labelSmall({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.45,
      letterSpacing: 0.5,
      color: color,
    );
  }

  // ============================================
  // Additional UI Styles
  // ============================================

  /// Caption - Small helper text
  static TextStyle caption({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.4,
      color: color,
    );
  }

  /// Button - Text on buttons
  static TextStyle button({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
      color: color,
    );
  }

  /// Overline - Small uppercase text
  static TextStyle overline({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      height: 1.6,
      letterSpacing: 1.5,
      color: color,
    ).copyWith(
      // Force uppercase for overline
      fontFeatures: [const FontFeature.enable('smcp')],
    );
  }

  // ============================================
  // Reading Content Styles
  // ============================================

  /// Reading body - Default reading text
  static TextStyle readingBody({
    Color? color,
    double fontSize = 16.0,
    double lineHeight = 1.6,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: _readingFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: lineHeight,
      letterSpacing: 0,
      color: color,
    );
  }

  /// Reading heading - Headings in reading content
  static TextStyle readingHeading({
    Color? color,
    double fontSize = 24.0,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: _readingFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.3,
      letterSpacing: 0,
      color: color,
    );
  }

  /// Reading quote - Block quotes in reading content
  static TextStyle readingQuote({Color? color, double fontSize = 16.0}) {
    return TextStyle(
      fontFamily: _readingFontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      height: 1.6,
      letterSpacing: 0,
      color: color,
    );
  }

  /// Reading code - Code blocks in reading content
  static TextStyle readingCode({Color? color, double fontSize = 14.0}) {
    return TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
      color: color,
    );
  }

  // ============================================
  // Material 3 TextTheme Generator
  // ============================================

  /// Generates a complete Material 3 TextTheme for light mode
  static TextTheme lightTextTheme() {
    return TextTheme(
      displayLarge: displayLarge(),
      displayMedium: displayMedium(),
      displaySmall: displaySmall(),
      headlineLarge: headlineLarge(),
      headlineMedium: headlineMedium(),
      headlineSmall: headlineSmall(),
      titleLarge: titleLarge(),
      titleMedium: titleMedium(),
      titleSmall: titleSmall(),
      bodyLarge: bodyLarge(),
      bodyMedium: bodyMedium(),
      bodySmall: bodySmall(),
      labelLarge: labelLarge(),
      labelMedium: labelMedium(),
      labelSmall: labelSmall(),
    );
  }

  /// Generates a complete Material 3 TextTheme for dark mode
  static TextTheme darkTextTheme() {
    return TextTheme(
      displayLarge: displayLarge(),
      displayMedium: displayMedium(),
      displaySmall: displaySmall(),
      headlineLarge: headlineLarge(),
      headlineMedium: headlineMedium(),
      headlineSmall: headlineSmall(),
      titleLarge: titleLarge(),
      titleMedium: titleMedium(),
      titleSmall: titleSmall(),
      bodyLarge: bodyLarge(),
      bodyMedium: bodyMedium(),
      bodySmall: bodySmall(),
      labelLarge: labelLarge(),
      labelMedium: labelMedium(),
      labelSmall: labelSmall(),
    );
  }

  // ============================================
  // Font Weight Constants
  // ============================================

  /// Font weight thin (100)
  static const FontWeight thin = FontWeight.w100;

  /// Font weight extra light (200)
  static const FontWeight extraLight = FontWeight.w200;

  /// Font weight light (300)
  static const FontWeight light = FontWeight.w300;

  /// Font weight regular (400)
  static const FontWeight regular = FontWeight.w400;

  /// Font weight medium (500)
  static const FontWeight medium = FontWeight.w500;

  /// Font weight semi bold (600)
  static const FontWeight semiBold = FontWeight.w600;

  /// Font weight bold (700)
  static const FontWeight bold = FontWeight.w700;

  /// Font weight extra bold (800)
  static const FontWeight extraBold = FontWeight.w800;

  /// Font weight black (900)
  static const FontWeight black = FontWeight.w900;
}
