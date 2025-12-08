import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/reading_settings.dart';
import 'colors.dart';

/// Theme configuration for the reading experience.
///
/// This class defines the visual appearance of the reader including
/// colors, typography, and spacing specific to reading content.
class ReadingThemeData {
  /// Background color of the reading area.
  final Color backgroundColor;

  /// Primary text color for content.
  final Color textColor;

  /// Color for hyperlinks.
  final Color linkColor;

  /// Font family for reading text.
  final String fontFamily;

  /// Default font size for reading text.
  final double fontSize;

  /// Default line height multiplier.
  final double lineHeight;

  /// Horizontal margin/padding for reading content.
  final double marginHorizontal;

  /// Vertical margin/padding for reading content.
  final double marginVertical;

  /// Text selection color.
  final Color selectionColor;

  /// Highlight color for annotations.
  final Color highlightColor;

  const ReadingThemeData({
    required this.backgroundColor,
    required this.textColor,
    required this.linkColor,
    required this.fontFamily,
    this.fontSize = 16.0,
    this.lineHeight = 1.5,
    this.marginHorizontal = 16.0,
    this.marginVertical = 24.0,
    required this.selectionColor,
    required this.highlightColor,
  });

  /// Creates a TextStyle for reading content.
  ///
  /// [fontSize] overrides the default font size if provided.
  /// [lineHeight] overrides the default line height if provided.
  /// [fontWeight] specifies the text weight (defaults to normal).
  TextStyle createTextStyle({
    double? fontSizeOverride,
    double? lineHeightOverride,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSizeOverride ?? fontSize,
      height: lineHeightOverride ?? lineHeight,
      color: textColor,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
    );
  }

  /// Creates a TextStyle for hyperlinks.
  TextStyle get linkTextStyle {
    return createTextStyle().copyWith(
      color: linkColor,
      decoration: TextDecoration.underline,
    );
  }

  /// Copies this ReadingThemeData with the given fields replaced.
  ReadingThemeData copyWith({
    Color? backgroundColor,
    Color? textColor,
    Color? linkColor,
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    double? marginHorizontal,
    double? marginVertical,
    Color? selectionColor,
    Color? highlightColor,
  }) {
    return ReadingThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      linkColor: linkColor ?? this.linkColor,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      marginHorizontal: marginHorizontal ?? this.marginHorizontal,
      marginVertical: marginVertical ?? this.marginVertical,
      selectionColor: selectionColor ?? this.selectionColor,
      highlightColor: highlightColor ?? this.highlightColor,
    );
  }
}

/// Predefined reading themes.
class ReadingThemes {
  ReadingThemes._();

  // Font family name for reading (Merriweather)
  static String get _readingFontFamily {
    try {
      return GoogleFonts.merriweather().fontFamily ?? 'Georgia';
    } catch (e) {
      return 'Georgia';
    }
  }

  /// Light reading theme with white background and dark text.
  static ReadingThemeData get lightTheme {
    return ReadingThemeData(
      backgroundColor: AppColors.readingLightBackground,
      textColor: AppColors.readingLightText,
      linkColor: AppColors.readingLightLink,
      fontFamily: _readingFontFamily,
      fontSize: 16.0,
      lineHeight: 1.6,
      marginHorizontal: 16.0,
      marginVertical: 24.0,
      selectionColor: AppColors.selectionLight.withOpacity(0.5),
      highlightColor: AppColors.highlightYellow.withOpacity(0.3),
    );
  }

  /// Dark reading theme with dark background and light text.
  static ReadingThemeData get darkTheme {
    return ReadingThemeData(
      backgroundColor: AppColors.readingDarkBackground,
      textColor: AppColors.readingDarkText,
      linkColor: AppColors.readingDarkLink,
      fontFamily: _readingFontFamily,
      fontSize: 16.0,
      lineHeight: 1.6,
      marginHorizontal: 16.0,
      marginVertical: 24.0,
      selectionColor: AppColors.selectionDark.withOpacity(0.5),
      highlightColor: AppColors.highlightYellow.withOpacity(0.3),
    );
  }

  /// Sepia reading theme with warm beige tones.
  static ReadingThemeData get sepiaTheme {
    return ReadingThemeData(
      backgroundColor: AppColors.readingSepiaBackground,
      textColor: AppColors.readingSepiaText,
      linkColor: AppColors.readingSepiaLink,
      fontFamily: _readingFontFamily,
      fontSize: 16.0,
      lineHeight: 1.6,
      marginHorizontal: 16.0,
      marginVertical: 24.0,
      selectionColor: AppColors.selectionSepia.withOpacity(0.5),
      highlightColor: AppColors.highlightYellow.withOpacity(0.3),
    );
  }

  /// AMOLED reading theme with pure black background for OLED displays.
  static ReadingThemeData get amoledTheme {
    return ReadingThemeData(
      backgroundColor: AppColors.readingAmoledBackground,
      textColor: AppColors.readingAmoledText,
      linkColor: AppColors.readingAmoledLink,
      fontFamily: _readingFontFamily,
      fontSize: 16.0,
      lineHeight: 1.6,
      marginHorizontal: 16.0,
      marginVertical: 24.0,
      selectionColor: AppColors.selectionAmoled.withOpacity(0.5),
      highlightColor: AppColors.highlightYellow.withOpacity(0.3),
    );
  }

  /// Gets the appropriate reading theme based on the ReadingTheme enum.
  ///
  /// [theme] is the reading theme type from the user's settings.
  static ReadingThemeData getTheme(ReadingTheme theme) {
    switch (theme) {
      case ReadingTheme.light:
        return lightTheme;
      case ReadingTheme.dark:
        return darkTheme;
      case ReadingTheme.sepia:
        return sepiaTheme;
    }
  }

  /// Creates a reading theme data from user's reading settings.
  ///
  /// [settings] contains the user's reading preferences.
  static ReadingThemeData fromSettings(ReadingSettings settings) {
    final baseTheme = getTheme(settings.theme);

    // Override font family if specified in settings
    String fontFamily = baseTheme.fontFamily;
    try {
      if (settings.fontFamily == 'Merriweather') {
        fontFamily = GoogleFonts.merriweather().fontFamily ?? 'Georgia';
      } else if (settings.fontFamily == 'Inter') {
        fontFamily = GoogleFonts.inter().fontFamily ?? 'Arial';
      } else {
        fontFamily = settings.fontFamily;
      }
    } catch (e) {
      fontFamily = settings.fontFamily;
    }

    return baseTheme.copyWith(
      fontFamily: fontFamily,
      fontSize: settings.fontSize,
      lineHeight: settings.lineHeight,
    );
  }

  /// All available theme options as a list.
  static List<ReadingTheme> get allThemes => [
    ReadingTheme.light,
    ReadingTheme.dark,
    ReadingTheme.sepia,
  ];

  /// Gets a human-readable name for a reading theme.
  static String getThemeName(ReadingTheme theme) {
    switch (theme) {
      case ReadingTheme.light:
        return 'Light';
      case ReadingTheme.dark:
        return 'Dark';
      case ReadingTheme.sepia:
        return 'Sepia';
    }
  }
}

/// Extension to provide reading theme data through BuildContext.
extension ReadingThemeExtension on BuildContext {
  /// Gets the current reading theme from the nearest ReadingThemeProvider.
  ///
  /// Returns a default light theme if no provider is found.
  ReadingThemeData get readingTheme {
    try {
      return ReadingThemeProvider.of(this);
    } catch (e) {
      return ReadingThemes.lightTheme;
    }
  }
}

/// InheritedWidget for providing reading theme data down the widget tree.
class ReadingThemeProvider extends InheritedWidget {
  final ReadingThemeData themeData;

  const ReadingThemeProvider({
    super.key,
    required this.themeData,
    required super.child,
  });

  static ReadingThemeData of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ReadingThemeProvider>();
    if (provider == null) {
      throw FlutterError(
        'ReadingThemeProvider not found in widget tree.\n'
        'Make sure to wrap your widget with ReadingThemeProvider.',
      );
    }
    return provider.themeData;
  }

  /// Tries to get the reading theme from context, returning null if not found.
  static ReadingThemeData? maybeOf(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ReadingThemeProvider>();
    return provider?.themeData;
  }

  @override
  bool updateShouldNotify(ReadingThemeProvider oldWidget) {
    return themeData != oldWidget.themeData;
  }
}
