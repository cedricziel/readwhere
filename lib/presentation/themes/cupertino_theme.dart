import 'package:flutter/cupertino.dart';

import 'colors.dart';

/// Cupertino theme configuration for iOS and macOS platforms.
///
/// Provides [CupertinoThemeData] configurations that map the app's
/// color palette to Cupertino-style widgets. Used alongside the Material
/// theme to support adaptive widgets on Apple platforms.
///
/// Usage:
/// ```dart
/// CupertinoTheme(
///   data: AppCupertinoTheme.light,
///   child: MaterialApp.router(...),
/// )
/// ```
class AppCupertinoTheme {
  AppCupertinoTheme._();

  /// Light theme for Cupertino widgets.
  ///
  /// Maps [AppColors] to Cupertino's color system for consistent
  /// branding across Material and Cupertino widgets.
  static CupertinoThemeData get light => CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    primaryContrastingColor: CupertinoColors.white,
    scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
    barBackgroundColor: const Color(0xF0F9F9F9), // iOS nav bar translucent
    textTheme: _textTheme(Brightness.light),
  );

  /// Dark theme for Cupertino widgets.
  ///
  /// Uses lighter color variants for better visibility on dark backgrounds.
  static CupertinoThemeData get dark => CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryLight,
    primaryContrastingColor: CupertinoColors.black,
    scaffoldBackgroundColor: CupertinoColors.darkBackgroundGray,
    barBackgroundColor: const Color(0xF01C1C1E), // iOS dark nav bar
    textTheme: _textTheme(Brightness.dark),
  );

  /// Returns the appropriate theme based on brightness.
  static CupertinoThemeData fromBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }

  /// Text theme configuration for Cupertino widgets.
  ///
  /// Uses system fonts (San Francisco on Apple platforms) for native feel.
  static CupertinoTextThemeData _textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    final actionColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return CupertinoTextThemeData(
      primaryColor: actionColor,
      textStyle: TextStyle(
        color: textColor,
        fontSize: 17.0,
        letterSpacing: -0.41,
      ),
      actionTextStyle: TextStyle(
        color: actionColor,
        fontSize: 17.0,
        letterSpacing: -0.41,
      ),
      tabLabelTextStyle: TextStyle(
        color: textColor,
        fontSize: 10.0,
        letterSpacing: -0.24,
      ),
      navTitleTextStyle: TextStyle(
        color: textColor,
        fontSize: 17.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.41,
      ),
      navLargeTitleTextStyle: TextStyle(
        color: textColor,
        fontSize: 34.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
      ),
      navActionTextStyle: TextStyle(
        color: actionColor,
        fontSize: 17.0,
        letterSpacing: -0.41,
      ),
      pickerTextStyle: TextStyle(
        color: textColor,
        fontSize: 21.0,
        letterSpacing: -0.6,
      ),
      dateTimePickerTextStyle: TextStyle(
        color: textColor,
        fontSize: 21.0,
        letterSpacing: -0.6,
      ),
    );
  }
}
