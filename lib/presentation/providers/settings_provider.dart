import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/reading_settings.dart';

/// Provider for managing application settings
///
/// This provider handles:
/// - App theme mode (light/dark/system)
/// - Default reading settings (font, margins, etc.)
/// - Books directory path
/// - Sync preferences
/// - Persistence to SharedPreferences
class SettingsProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _fontSizeKey = 'reading_font_size';
  static const String _fontFamilyKey = 'reading_font_family';
  static const String _lineHeightKey = 'reading_line_height';
  static const String _marginHorizontalKey = 'reading_margin_horizontal';
  static const String _marginVerticalKey = 'reading_margin_vertical';
  static const String _readingThemeKey = 'reading_theme';
  static const String _textAlignKey = 'reading_text_align';
  static const String _booksDirectoryKey = 'books_directory';
  static const String _syncEnabledKey = 'sync_enabled';
  static const String _hapticFeedbackKey = 'haptic_feedback';
  static const String _keepScreenAwakeKey = 'keep_screen_awake';

  SharedPreferences? _prefs;

  // State
  ThemeMode _themeMode = ThemeMode.system;
  ReadingSettings _defaultReadingSettings = ReadingSettings.defaults();
  String _booksDirectory = '';
  bool _syncEnabled = false;
  bool _hapticFeedback = true;
  bool _keepScreenAwake = true;
  bool _isInitialized = false;

  // Getters

  /// Current theme mode for the app
  ThemeMode get themeMode => _themeMode;

  /// Default reading settings for new books
  ReadingSettings get defaultReadingSettings => _defaultReadingSettings;

  /// Directory where book files are stored
  String get booksDirectory => _booksDirectory;

  /// Whether sync is enabled
  bool get syncEnabled => _syncEnabled;

  /// Whether haptic feedback is enabled
  bool get hapticFeedback => _hapticFeedback;

  /// Whether screen should be kept awake during reading
  bool get keepScreenAwake => _keepScreenAwake;

  /// Whether the provider has loaded settings from storage
  bool get isInitialized => _isInitialized;

  // Methods

  /// Initialize the provider and load settings from storage
  ///
  /// This should be called once at app startup before using the provider.
  /// Loads all persisted settings from SharedPreferences.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize SettingsProvider: $e');
      _isInitialized = true; // Continue with defaults
      notifyListeners();
    }
  }

  /// Set the app theme mode
  ///
  /// Changes the app's theme (light, dark, or system).
  /// The setting is persisted to SharedPreferences.
  ///
  /// [mode] The new theme mode to apply
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _prefs?.setInt(_themeModeKey, mode.index);
    notifyListeners();
  }

  /// Update the default reading settings
  ///
  /// Changes the default settings used when opening books.
  /// Individual setting changes are persisted to SharedPreferences.
  ///
  /// [settings] The new default reading settings
  Future<void> updateReadingSettings(ReadingSettings settings) async {
    if (_defaultReadingSettings == settings) return;

    _defaultReadingSettings = settings;

    // Persist individual settings
    await Future.wait([
      _prefs?.setDouble(_fontSizeKey, settings.fontSize) ?? Future.value(),
      _prefs?.setString(_fontFamilyKey, settings.fontFamily) ?? Future.value(),
      _prefs?.setDouble(_lineHeightKey, settings.lineHeight) ?? Future.value(),
      _prefs?.setDouble(_marginHorizontalKey, settings.marginHorizontal) ??
          Future.value(),
      _prefs?.setDouble(_marginVerticalKey, settings.marginVertical) ??
          Future.value(),
      _prefs?.setInt(_readingThemeKey, settings.theme.index) ?? Future.value(),
      _prefs?.setInt(_textAlignKey, settings.textAlign.index) ?? Future.value(),
    ]);

    notifyListeners();
  }

  /// Update individual reading setting - font size
  ///
  /// [fontSize] The new font size (in points)
  Future<void> setFontSize(double fontSize) async {
    if (_defaultReadingSettings.fontSize == fontSize) return;

    _defaultReadingSettings = _defaultReadingSettings.copyWith(
      fontSize: fontSize,
    );
    await _prefs?.setDouble(_fontSizeKey, fontSize);
    notifyListeners();
  }

  /// Update individual reading setting - font family
  ///
  /// [fontFamily] The new font family name
  Future<void> setFontFamily(String fontFamily) async {
    if (_defaultReadingSettings.fontFamily == fontFamily) return;

    _defaultReadingSettings = _defaultReadingSettings.copyWith(
      fontFamily: fontFamily,
    );
    await _prefs?.setString(_fontFamilyKey, fontFamily);
    notifyListeners();
  }

  /// Update individual reading setting - line height
  ///
  /// [lineHeight] The new line height multiplier
  Future<void> setLineHeight(double lineHeight) async {
    if (_defaultReadingSettings.lineHeight == lineHeight) return;

    _defaultReadingSettings = _defaultReadingSettings.copyWith(
      lineHeight: lineHeight,
    );
    await _prefs?.setDouble(_lineHeightKey, lineHeight);
    notifyListeners();
  }

  /// Update individual reading setting - horizontal margin
  ///
  /// [margin] The new horizontal margin (in pixels)
  Future<void> setMarginHorizontal(double margin) async {
    if (_defaultReadingSettings.marginHorizontal == margin) return;

    _defaultReadingSettings = _defaultReadingSettings.copyWith(
      marginHorizontal: margin,
    );
    await _prefs?.setDouble(_marginHorizontalKey, margin);
    notifyListeners();
  }

  /// Update individual reading setting - vertical margin
  ///
  /// [margin] The new vertical margin (in pixels)
  Future<void> setMarginVertical(double margin) async {
    if (_defaultReadingSettings.marginVertical == margin) return;

    _defaultReadingSettings = _defaultReadingSettings.copyWith(
      marginVertical: margin,
    );
    await _prefs?.setDouble(_marginVerticalKey, margin);
    notifyListeners();
  }

  /// Update individual reading setting - reading theme
  ///
  /// [theme] The new reading theme (light, dark, sepia)
  Future<void> setReadingTheme(ReadingTheme theme) async {
    if (_defaultReadingSettings.theme == theme) return;

    _defaultReadingSettings = _defaultReadingSettings.copyWith(theme: theme);
    await _prefs?.setInt(_readingThemeKey, theme.index);
    notifyListeners();
  }

  /// Update individual reading setting - text alignment
  ///
  /// [alignment] The new text alignment
  Future<void> setTextAlign(TextAlign alignment) async {
    if (_defaultReadingSettings.textAlign == alignment) return;

    _defaultReadingSettings = _defaultReadingSettings.copyWith(
      textAlign: alignment,
    );
    await _prefs?.setInt(_textAlignKey, alignment.index);
    notifyListeners();
  }

  /// Set the books directory path
  ///
  /// Changes where book files are stored.
  /// The setting is persisted to SharedPreferences.
  ///
  /// [directory] The new directory path
  Future<void> setBooksDirectory(String directory) async {
    if (_booksDirectory == directory) return;

    _booksDirectory = directory;
    await _prefs?.setString(_booksDirectoryKey, directory);
    notifyListeners();
  }

  /// Enable or disable sync functionality
  ///
  /// [enabled] Whether sync should be enabled
  Future<void> setSyncEnabled(bool enabled) async {
    if (_syncEnabled == enabled) return;

    _syncEnabled = enabled;
    await _prefs?.setBool(_syncEnabledKey, enabled);
    notifyListeners();
  }

  /// Toggle haptic feedback on/off
  ///
  /// Enables or disables haptic feedback throughout the app.
  /// When enabled, the app will provide tactile feedback for certain actions.
  Future<void> toggleHapticFeedback() async {
    _hapticFeedback = !_hapticFeedback;
    await _prefs?.setBool(_hapticFeedbackKey, _hapticFeedback);
    notifyListeners();
  }

  /// Set haptic feedback state
  ///
  /// [enabled] Whether haptic feedback should be enabled
  Future<void> setHapticFeedback(bool enabled) async {
    if (_hapticFeedback == enabled) return;

    _hapticFeedback = enabled;
    await _prefs?.setBool(_hapticFeedbackKey, enabled);
    notifyListeners();
  }

  /// Toggle keep screen awake on/off
  ///
  /// Enables or disables keeping the screen awake during reading.
  /// When enabled, the screen will not automatically turn off while reading.
  Future<void> toggleKeepScreenAwake() async {
    _keepScreenAwake = !_keepScreenAwake;
    await _prefs?.setBool(_keepScreenAwakeKey, _keepScreenAwake);
    notifyListeners();
  }

  /// Set keep screen awake state
  ///
  /// [enabled] Whether screen should be kept awake during reading
  Future<void> setKeepScreenAwake(bool enabled) async {
    if (_keepScreenAwake == enabled) return;

    _keepScreenAwake = enabled;
    await _prefs?.setBool(_keepScreenAwakeKey, enabled);
    notifyListeners();
  }

  /// Reset all settings to defaults
  ///
  /// Clears all persisted settings and resets to default values.
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _defaultReadingSettings = ReadingSettings.defaults();
    _booksDirectory = '';
    _syncEnabled = false;
    _hapticFeedback = true;
    _keepScreenAwake = true;

    // Clear all preferences
    await Future.wait([
      _prefs?.remove(_themeModeKey) ?? Future.value(),
      _prefs?.remove(_fontSizeKey) ?? Future.value(),
      _prefs?.remove(_fontFamilyKey) ?? Future.value(),
      _prefs?.remove(_lineHeightKey) ?? Future.value(),
      _prefs?.remove(_marginHorizontalKey) ?? Future.value(),
      _prefs?.remove(_marginVerticalKey) ?? Future.value(),
      _prefs?.remove(_readingThemeKey) ?? Future.value(),
      _prefs?.remove(_textAlignKey) ?? Future.value(),
      _prefs?.remove(_booksDirectoryKey) ?? Future.value(),
      _prefs?.remove(_syncEnabledKey) ?? Future.value(),
      _prefs?.remove(_hapticFeedbackKey) ?? Future.value(),
      _prefs?.remove(_keepScreenAwakeKey) ?? Future.value(),
    ]);

    notifyListeners();
  }

  // Private helper methods

  /// Load all settings from SharedPreferences
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    // Load theme mode
    final themeModeIndex = _prefs!.getInt(_themeModeKey);
    if (themeModeIndex != null && themeModeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeModeIndex];
    }

    // Load reading settings
    final fontSize = _prefs!.getDouble(_fontSizeKey);
    final fontFamily = _prefs!.getString(_fontFamilyKey);
    final lineHeight = _prefs!.getDouble(_lineHeightKey);
    final marginHorizontal = _prefs!.getDouble(_marginHorizontalKey);
    final marginVertical = _prefs!.getDouble(_marginVerticalKey);
    final readingThemeIndex = _prefs!.getInt(_readingThemeKey);
    final textAlignIndex = _prefs!.getInt(_textAlignKey);

    ReadingTheme? readingTheme;
    if (readingThemeIndex != null &&
        readingThemeIndex < ReadingTheme.values.length) {
      readingTheme = ReadingTheme.values[readingThemeIndex];
    }

    TextAlign? textAlign;
    if (textAlignIndex != null && textAlignIndex < TextAlign.values.length) {
      textAlign = TextAlign.values[textAlignIndex];
    }

    // Create reading settings with loaded or default values
    _defaultReadingSettings = ReadingSettings(
      fontSize: fontSize ?? ReadingSettings.defaults().fontSize,
      fontFamily: fontFamily ?? ReadingSettings.defaults().fontFamily,
      lineHeight: lineHeight ?? ReadingSettings.defaults().lineHeight,
      marginHorizontal:
          marginHorizontal ?? ReadingSettings.defaults().marginHorizontal,
      marginVertical:
          marginVertical ?? ReadingSettings.defaults().marginVertical,
      theme: readingTheme ?? ReadingSettings.defaults().theme,
      textAlign: textAlign ?? ReadingSettings.defaults().textAlign,
    );

    // Load other settings
    _booksDirectory = _prefs!.getString(_booksDirectoryKey) ?? '';
    _syncEnabled = _prefs!.getBool(_syncEnabledKey) ?? false;
    _hapticFeedback = _prefs!.getBool(_hapticFeedbackKey) ?? true;
    _keepScreenAwake = _prefs!.getBool(_keepScreenAwakeKey) ?? true;
  }
}
