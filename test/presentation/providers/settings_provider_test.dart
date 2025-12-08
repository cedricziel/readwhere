import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/domain/entities/reading_settings.dart';
import 'package:readwhere/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider', () {
    late SettingsProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = SettingsProvider();
    });

    group('initial state', () {
      test('has default theme mode as system', () {
        expect(provider.themeMode, equals(ThemeMode.system));
      });

      test('has default reading settings', () {
        expect(provider.defaultReadingSettings, isNotNull);
        expect(
          provider.defaultReadingSettings.fontSize,
          equals(ReadingSettings.defaults().fontSize),
        );
      });

      test('has empty books directory', () {
        expect(provider.booksDirectory, isEmpty);
      });

      test('has sync disabled by default', () {
        expect(provider.syncEnabled, isFalse);
      });

      test('has haptic feedback enabled by default', () {
        expect(provider.hapticFeedback, isTrue);
      });

      test('has keep screen awake enabled by default', () {
        expect(provider.keepScreenAwake, isTrue);
      });

      test('is not initialized before calling initialize', () {
        expect(provider.isInitialized, isFalse);
      });
    });

    group('initialize', () {
      test('marks provider as initialized', () async {
        await provider.initialize();

        expect(provider.isInitialized, isTrue);
      });

      test('loads theme mode from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'theme_mode': ThemeMode.dark.index,
        });
        provider = SettingsProvider();

        await provider.initialize();

        expect(provider.themeMode, equals(ThemeMode.dark));
      });

      test('loads reading settings from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'reading_font_size': 20.0,
          'reading_font_family': 'Georgia',
          'reading_line_height': 1.8,
        });
        provider = SettingsProvider();

        await provider.initialize();

        expect(provider.defaultReadingSettings.fontSize, equals(20.0));
        expect(provider.defaultReadingSettings.fontFamily, equals('Georgia'));
        expect(provider.defaultReadingSettings.lineHeight, equals(1.8));
      });

      test('loads books directory from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'books_directory': '/custom/path',
        });
        provider = SettingsProvider();

        await provider.initialize();

        expect(provider.booksDirectory, equals('/custom/path'));
      });

      test('loads boolean settings from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'sync_enabled': true,
          'haptic_feedback': false,
          'keep_screen_awake': false,
        });
        provider = SettingsProvider();

        await provider.initialize();

        expect(provider.syncEnabled, isTrue);
        expect(provider.hapticFeedback, isFalse);
        expect(provider.keepScreenAwake, isFalse);
      });

      test('only initializes once', () async {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.initialize();
        await provider.initialize();

        expect(notifyCount, equals(1));
      });
    });

    group('setThemeMode', () {
      test('changes theme mode', () async {
        await provider.initialize();

        await provider.setThemeMode(ThemeMode.dark);

        expect(provider.themeMode, equals(ThemeMode.dark));
      });

      test('persists theme mode', () async {
        await provider.initialize();

        await provider.setThemeMode(ThemeMode.dark);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('theme_mode'), equals(ThemeMode.dark.index));
      });

      test('does not notify if same mode', () async {
        await provider.initialize();

        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.setThemeMode(ThemeMode.system);

        expect(notifyCount, equals(0));
      });
    });

    group('updateReadingSettings', () {
      test('updates all reading settings', () async {
        await provider.initialize();

        final newSettings = ReadingSettings(
          fontSize: 24.0,
          fontFamily: 'Georgia',
          lineHeight: 2.0,
          marginHorizontal: 30.0,
          marginVertical: 20.0,
          theme: ReadingTheme.sepia,
          textAlign: TextAlign.justify,
        );

        await provider.updateReadingSettings(newSettings);

        expect(provider.defaultReadingSettings.fontSize, equals(24.0));
        expect(provider.defaultReadingSettings.fontFamily, equals('Georgia'));
        expect(provider.defaultReadingSettings.lineHeight, equals(2.0));
        expect(provider.defaultReadingSettings.marginHorizontal, equals(30.0));
        expect(provider.defaultReadingSettings.marginVertical, equals(20.0));
        expect(
          provider.defaultReadingSettings.theme,
          equals(ReadingTheme.sepia),
        );
        expect(
          provider.defaultReadingSettings.textAlign,
          equals(TextAlign.justify),
        );
      });

      test('does not notify if same settings', () async {
        await provider.initialize();

        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.updateReadingSettings(provider.defaultReadingSettings);

        expect(notifyCount, equals(0));
      });
    });

    group('setFontSize', () {
      test('updates font size', () async {
        await provider.initialize();

        await provider.setFontSize(20.0);

        expect(provider.defaultReadingSettings.fontSize, equals(20.0));
      });

      test('persists font size', () async {
        await provider.initialize();

        await provider.setFontSize(20.0);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getDouble('reading_font_size'), equals(20.0));
      });
    });

    group('setFontFamily', () {
      test('updates font family', () async {
        await provider.initialize();

        await provider.setFontFamily('Times New Roman');

        expect(
          provider.defaultReadingSettings.fontFamily,
          equals('Times New Roman'),
        );
      });

      test('persists font family', () async {
        await provider.initialize();

        await provider.setFontFamily('Times New Roman');

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('reading_font_family'),
          equals('Times New Roman'),
        );
      });
    });

    group('setLineHeight', () {
      test('updates line height', () async {
        await provider.initialize();

        await provider.setLineHeight(1.8);

        expect(provider.defaultReadingSettings.lineHeight, equals(1.8));
      });
    });

    group('setMarginHorizontal', () {
      test('updates horizontal margin', () async {
        await provider.initialize();

        await provider.setMarginHorizontal(30.0);

        expect(provider.defaultReadingSettings.marginHorizontal, equals(30.0));
      });
    });

    group('setMarginVertical', () {
      test('updates vertical margin', () async {
        await provider.initialize();

        await provider.setMarginVertical(20.0);

        expect(provider.defaultReadingSettings.marginVertical, equals(20.0));
      });
    });

    group('setReadingTheme', () {
      test('updates reading theme', () async {
        await provider.initialize();

        await provider.setReadingTheme(ReadingTheme.dark);

        expect(
          provider.defaultReadingSettings.theme,
          equals(ReadingTheme.dark),
        );
      });
    });

    group('setTextAlign', () {
      test('updates text alignment', () async {
        await provider.initialize();

        await provider.setTextAlign(TextAlign.justify);

        expect(
          provider.defaultReadingSettings.textAlign,
          equals(TextAlign.justify),
        );
      });
    });

    group('setBooksDirectory', () {
      test('updates books directory', () async {
        await provider.initialize();

        await provider.setBooksDirectory('/new/path');

        expect(provider.booksDirectory, equals('/new/path'));
      });

      test('persists books directory', () async {
        await provider.initialize();

        await provider.setBooksDirectory('/new/path');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('books_directory'), equals('/new/path'));
      });

      test('does not notify if same directory', () async {
        await provider.initialize();

        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.setBooksDirectory('');

        expect(notifyCount, equals(0));
      });
    });

    group('setSyncEnabled', () {
      test('enables sync', () async {
        await provider.initialize();

        await provider.setSyncEnabled(true);

        expect(provider.syncEnabled, isTrue);
      });

      test('persists sync setting', () async {
        await provider.initialize();

        await provider.setSyncEnabled(true);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('sync_enabled'), isTrue);
      });
    });

    group('toggleHapticFeedback', () {
      test('toggles haptic feedback', () async {
        await provider.initialize();

        await provider.toggleHapticFeedback();
        expect(provider.hapticFeedback, isFalse);

        await provider.toggleHapticFeedback();
        expect(provider.hapticFeedback, isTrue);
      });
    });

    group('setHapticFeedback', () {
      test('sets haptic feedback state', () async {
        await provider.initialize();

        await provider.setHapticFeedback(false);

        expect(provider.hapticFeedback, isFalse);
      });

      test('does not notify if same state', () async {
        await provider.initialize();

        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.setHapticFeedback(true);

        expect(notifyCount, equals(0));
      });
    });

    group('toggleKeepScreenAwake', () {
      test('toggles keep screen awake', () async {
        await provider.initialize();

        await provider.toggleKeepScreenAwake();
        expect(provider.keepScreenAwake, isFalse);

        await provider.toggleKeepScreenAwake();
        expect(provider.keepScreenAwake, isTrue);
      });
    });

    group('setKeepScreenAwake', () {
      test('sets keep screen awake state', () async {
        await provider.initialize();

        await provider.setKeepScreenAwake(false);

        expect(provider.keepScreenAwake, isFalse);
      });
    });

    group('resetToDefaults', () {
      test('resets all settings to defaults', () async {
        await provider.initialize();

        // Change some settings
        await provider.setThemeMode(ThemeMode.dark);
        await provider.setFontSize(24.0);
        await provider.setBooksDirectory('/custom');
        await provider.setSyncEnabled(true);

        // Reset
        await provider.resetToDefaults();

        expect(provider.themeMode, equals(ThemeMode.system));
        expect(
          provider.defaultReadingSettings.fontSize,
          equals(ReadingSettings.defaults().fontSize),
        );
        expect(provider.booksDirectory, isEmpty);
        expect(provider.syncEnabled, isFalse);
        expect(provider.hapticFeedback, isTrue);
        expect(provider.keepScreenAwake, isTrue);
      });

      test('clears SharedPreferences', () async {
        await provider.initialize();

        await provider.setThemeMode(ThemeMode.dark);
        await provider.resetToDefaults();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('theme_mode'), isNull);
        expect(prefs.getDouble('reading_font_size'), isNull);
      });
    });
  });
}
