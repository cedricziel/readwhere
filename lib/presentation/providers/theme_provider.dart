import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app theme state
///
/// This provider handles:
/// - App theme mode (light, dark, system)
/// - Theme persistence to SharedPreferences
/// - Theme toggling and switching
///
/// This is a simplified theme provider focused specifically on theme mode.
/// For more comprehensive app settings, see [SettingsProvider].
class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'app_theme_mode';

  SharedPreferences? _prefs;

  // State
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  // Getters

  /// Current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Whether the provider has loaded the theme from storage
  bool get isInitialized => _isInitialized;

  /// Whether the current mode is light
  bool get isLightMode => _themeMode == ThemeMode.light;

  /// Whether the current mode is dark
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Whether the current mode is system
  bool get isSystemMode => _themeMode == ThemeMode.system;

  // Methods

  /// Initialize the provider and load theme from storage
  ///
  /// This should be called once at app startup before using the provider.
  /// Loads the persisted theme mode from SharedPreferences.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadThemeMode();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize ThemeProvider: $e');
      _isInitialized = true; // Continue with default
      notifyListeners();
    }
  }

  /// Set the theme to light mode
  ///
  /// Changes the app theme to light mode and persists the choice.
  Future<void> setLightMode() async {
    await _setThemeMode(ThemeMode.light);
  }

  /// Set the theme to dark mode
  ///
  /// Changes the app theme to dark mode and persists the choice.
  Future<void> setDarkMode() async {
    await _setThemeMode(ThemeMode.dark);
  }

  /// Set the theme to follow system settings
  ///
  /// Changes the app theme to match the system theme and persists the choice.
  Future<void> setSystemMode() async {
    await _setThemeMode(ThemeMode.system);
  }

  /// Toggle between light and dark mode
  ///
  /// If currently in light mode, switches to dark.
  /// If currently in dark mode, switches to light.
  /// If currently in system mode, switches to the opposite of the current system theme.
  ///
  /// [brightness] The current system brightness (used when in system mode)
  Future<void> toggleTheme({Brightness? brightness}) async {
    ThemeMode newMode;

    if (_themeMode == ThemeMode.light) {
      newMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      newMode = ThemeMode.light;
    } else {
      // System mode - toggle based on current system brightness
      final currentBrightness = brightness ?? Brightness.light;
      newMode = currentBrightness == Brightness.light
          ? ThemeMode.dark
          : ThemeMode.light;
    }

    await _setThemeMode(newMode);
  }

  /// Set a specific theme mode
  ///
  /// [mode] The theme mode to apply
  Future<void> setThemeMode(ThemeMode mode) async {
    await _setThemeMode(mode);
  }

  /// Get the effective brightness for the current theme mode
  ///
  /// [systemBrightness] The current system brightness
  /// Returns the actual brightness that should be used
  Brightness getEffectiveBrightness(Brightness systemBrightness) {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return systemBrightness;
    }
  }

  // Private helper methods

  /// Internal method to set theme mode and persist it
  Future<void> _setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _prefs?.setInt(_themeModeKey, mode.index);
    notifyListeners();
  }

  /// Load theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    if (_prefs == null) return;

    final themeModeIndex = _prefs!.getInt(_themeModeKey);
    if (themeModeIndex != null && themeModeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeModeIndex];
    } else {
      // Default to system mode if no preference is stored
      _themeMode = ThemeMode.system;
    }
  }
}
