import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider', () {
    late ThemeProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = ThemeProvider();
    });

    group('initial state', () {
      test('has default theme mode as system', () {
        expect(provider.themeMode, equals(ThemeMode.system));
      });

      test('is not initialized before calling initialize', () {
        expect(provider.isInitialized, isFalse);
      });

      test('isSystemMode is true by default', () {
        expect(provider.isSystemMode, isTrue);
      });

      test('isLightMode is false by default', () {
        expect(provider.isLightMode, isFalse);
      });

      test('isDarkMode is false by default', () {
        expect(provider.isDarkMode, isFalse);
      });
    });

    group('initialize', () {
      test('marks provider as initialized', () async {
        await provider.initialize();

        expect(provider.isInitialized, isTrue);
      });

      test('loads theme mode from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'app_theme_mode': ThemeMode.dark.index,
        });
        provider = ThemeProvider();

        await provider.initialize();

        expect(provider.themeMode, equals(ThemeMode.dark));
      });

      test('defaults to system mode if no stored value', () async {
        SharedPreferences.setMockInitialValues({});

        await provider.initialize();

        expect(provider.themeMode, equals(ThemeMode.system));
      });

      test('handles invalid stored index', () async {
        SharedPreferences.setMockInitialValues({
          'app_theme_mode': 999, // Invalid index
        });
        provider = ThemeProvider();

        await provider.initialize();

        expect(provider.themeMode, equals(ThemeMode.system));
      });

      test('only initializes once', () async {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.initialize();
        await provider.initialize();

        expect(notifyCount, equals(1));
      });
    });

    group('setLightMode', () {
      test('sets theme to light mode', () async {
        await provider.initialize();

        await provider.setLightMode();

        expect(provider.themeMode, equals(ThemeMode.light));
        expect(provider.isLightMode, isTrue);
      });

      test('persists light mode to SharedPreferences', () async {
        await provider.initialize();

        await provider.setLightMode();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('app_theme_mode'), equals(ThemeMode.light.index));
      });
    });

    group('setDarkMode', () {
      test('sets theme to dark mode', () async {
        await provider.initialize();

        await provider.setDarkMode();

        expect(provider.themeMode, equals(ThemeMode.dark));
        expect(provider.isDarkMode, isTrue);
      });

      test('persists dark mode to SharedPreferences', () async {
        await provider.initialize();

        await provider.setDarkMode();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('app_theme_mode'), equals(ThemeMode.dark.index));
      });
    });

    group('setSystemMode', () {
      test('sets theme to system mode', () async {
        await provider.initialize();
        await provider.setDarkMode();

        await provider.setSystemMode();

        expect(provider.themeMode, equals(ThemeMode.system));
        expect(provider.isSystemMode, isTrue);
      });

      test('persists system mode to SharedPreferences', () async {
        await provider.initialize();
        // First set to dark mode so we can verify system mode is persisted
        await provider.setDarkMode();

        await provider.setSystemMode();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('app_theme_mode'), equals(ThemeMode.system.index));
      });
    });

    group('setThemeMode', () {
      test('sets any theme mode', () async {
        await provider.initialize();

        await provider.setThemeMode(ThemeMode.dark);
        expect(provider.themeMode, equals(ThemeMode.dark));

        await provider.setThemeMode(ThemeMode.light);
        expect(provider.themeMode, equals(ThemeMode.light));

        await provider.setThemeMode(ThemeMode.system);
        expect(provider.themeMode, equals(ThemeMode.system));
      });

      test('does not notify if same mode', () async {
        await provider.initialize();

        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.setThemeMode(ThemeMode.system);

        expect(notifyCount, equals(0));
      });
    });

    group('toggleTheme', () {
      test('toggles from light to dark', () async {
        await provider.initialize();
        await provider.setLightMode();

        await provider.toggleTheme();

        expect(provider.themeMode, equals(ThemeMode.dark));
      });

      test('toggles from dark to light', () async {
        await provider.initialize();
        await provider.setDarkMode();

        await provider.toggleTheme();

        expect(provider.themeMode, equals(ThemeMode.light));
      });

      test('toggles from system to dark when system is light', () async {
        await provider.initialize();

        await provider.toggleTheme(brightness: Brightness.light);

        expect(provider.themeMode, equals(ThemeMode.dark));
      });

      test('toggles from system to light when system is dark', () async {
        await provider.initialize();

        await provider.toggleTheme(brightness: Brightness.dark);

        expect(provider.themeMode, equals(ThemeMode.light));
      });

      test(
        'defaults to dark when no brightness provided in system mode',
        () async {
          await provider.initialize();

          await provider.toggleTheme();

          expect(provider.themeMode, equals(ThemeMode.dark));
        },
      );
    });

    group('getEffectiveBrightness', () {
      test('returns light for light mode', () async {
        await provider.initialize();
        await provider.setLightMode();

        expect(
          provider.getEffectiveBrightness(Brightness.dark),
          equals(Brightness.light),
        );
      });

      test('returns dark for dark mode', () async {
        await provider.initialize();
        await provider.setDarkMode();

        expect(
          provider.getEffectiveBrightness(Brightness.light),
          equals(Brightness.dark),
        );
      });

      test('returns system brightness for system mode', () async {
        await provider.initialize();

        expect(
          provider.getEffectiveBrightness(Brightness.light),
          equals(Brightness.light),
        );
        expect(
          provider.getEffectiveBrightness(Brightness.dark),
          equals(Brightness.dark),
        );
      });
    });

    group('notifyListeners', () {
      test('notifies on theme mode change', () async {
        await provider.initialize();

        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.setDarkMode();
        await provider.setLightMode();
        await provider.setSystemMode();

        expect(notifyCount, equals(3));
      });
    });
  });
}
