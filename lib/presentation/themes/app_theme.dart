import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application theming configuration.
///
/// Provides Material 3 themes for light and dark modes with
/// consistent styling across the application.
class AppTheme {
  AppTheme._();

  // Color schemes
  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF6750A4),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEADDFF),
    onPrimaryContainer: Color(0xFF21005D),
    secondary: Color(0xFF625B71),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE8DEF8),
    onSecondaryContainer: Color(0xFF1D192B),
    tertiary: Color(0xFF7D5260),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFD8E4),
    onTertiaryContainer: Color(0xFF31111D),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFFFFBFE),
    onSurface: Color(0xFF1C1B1F),
    surfaceContainerHighest: Color(0xFFE7E0EC),
    onSurfaceVariant: Color(0xFF49454F),
    outline: Color(0xFF79747E),
    outlineVariant: Color(0xFFCAC4D0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: Color(0xFFD0BCFF),
    surfaceTint: Color(0xFF6750A4),
  );

  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFD0BCFF),
    onPrimary: Color(0xFF381E72),
    primaryContainer: Color(0xFF4F378B),
    onPrimaryContainer: Color(0xFFEADDFF),
    secondary: Color(0xFFCCC2DC),
    onSecondary: Color(0xFF332D41),
    secondaryContainer: Color(0xFF4A4458),
    onSecondaryContainer: Color(0xFFE8DEF8),
    tertiary: Color(0xFFEFB8C8),
    onTertiary: Color(0xFF492532),
    tertiaryContainer: Color(0xFF633B48),
    onTertiaryContainer: Color(0xFFFFD8E4),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF1C1B1F),
    onSurface: Color(0xFFE6E1E5),
    surfaceContainerHighest: Color(0xFF36343B),
    onSurfaceVariant: Color(0xFFCAC4D0),
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454F),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE6E1E5),
    onInverseSurface: Color(0xFF313033),
    inversePrimary: Color(0xFF6750A4),
    surfaceTint: Color(0xFFD0BCFF),
  );

  /// Light theme configuration.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      brightness: Brightness.light,

      // Typography using Google Fonts (Inter for UI)
      // Apply color scheme colors to ensure proper contrast in light mode
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(colorScheme: _lightColorScheme, useMaterial3: true).textTheme,
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: _lightColorScheme.surface,
        foregroundColor: _lightColorScheme.onSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _lightColorScheme.onSurface,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightColorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lightColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lightColorScheme.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 3,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _lightColorScheme.onSurface,
            );
          }
          return GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _lightColorScheme.onSurfaceVariant,
          );
        }),
      ),

      // Navigation rail theme
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: _lightColorScheme.surface,
        labelType: NavigationRailLabelType.all,
        useIndicator: true,
        selectedLabelTextStyle: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _lightColorScheme.onSurface,
        ),
        unselectedLabelTextStyle: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _lightColorScheme.onSurfaceVariant,
        ),
        selectedIconTheme: IconThemeData(color: _lightColorScheme.onSurface),
        unselectedIconTheme: IconThemeData(
          color: _lightColorScheme.onSurfaceVariant,
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: _lightColorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // Popup menu theme
      popupMenuTheme: PopupMenuThemeData(
        color: _lightColorScheme.surfaceContainer,
        textStyle: TextStyle(color: _lightColorScheme.onSurface, fontSize: 14),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: _lightColorScheme.onSurface),
        ),
      ),

      // Dropdown menu theme
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: _lightColorScheme.onSurface),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(
            _lightColorScheme.surfaceContainer,
          ),
        ),
      ),

      // Menu theme
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(
            _lightColorScheme.surfaceContainer,
          ),
        ),
      ),

      // Menu button theme
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(_lightColorScheme.onSurface),
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Dark theme configuration.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      brightness: Brightness.dark,

      // Typography using Google Fonts (Inter for UI)
      // Apply color scheme colors to ensure proper contrast in dark mode
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(colorScheme: _darkColorScheme, useMaterial3: true).textTheme,
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: _darkColorScheme.surface,
        foregroundColor: _darkColorScheme.onSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _darkColorScheme.onSurface,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkColorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _darkColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _darkColorScheme.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 3,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _darkColorScheme.onSurface,
            );
          }
          return GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _darkColorScheme.onSurfaceVariant,
          );
        }),
      ),

      // Navigation rail theme
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: _darkColorScheme.surface,
        labelType: NavigationRailLabelType.all,
        useIndicator: true,
        selectedLabelTextStyle: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _darkColorScheme.onSurface,
        ),
        unselectedLabelTextStyle: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _darkColorScheme.onSurfaceVariant,
        ),
        selectedIconTheme: IconThemeData(color: _darkColorScheme.onSurface),
        unselectedIconTheme: IconThemeData(
          color: _darkColorScheme.onSurfaceVariant,
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: _darkColorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // Popup menu theme
      popupMenuTheme: PopupMenuThemeData(
        color: _darkColorScheme.surfaceContainer,
        textStyle: TextStyle(color: _darkColorScheme.onSurface, fontSize: 14),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: _darkColorScheme.onSurface),
        ),
      ),

      // Dropdown menu theme
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: _darkColorScheme.onSurface),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(
            _darkColorScheme.surfaceContainer,
          ),
        ),
      ),

      // Menu theme
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(
            _darkColorScheme.surfaceContainer,
          ),
        ),
      ),

      // Menu button theme
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(_darkColorScheme.onSurface),
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
