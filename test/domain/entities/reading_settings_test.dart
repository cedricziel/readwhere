import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/domain/entities/reading_settings.dart';

void main() {
  group('ReadingSettings', () {
    ReadingSettings createTestSettings({
      double fontSize = 16.0,
      String fontFamily = 'Georgia',
      double lineHeight = 1.5,
      double marginHorizontal = 16.0,
      double marginVertical = 24.0,
      ReadingTheme theme = ReadingTheme.light,
      TextAlign textAlign = TextAlign.justify,
    }) {
      return ReadingSettings(
        fontSize: fontSize,
        fontFamily: fontFamily,
        lineHeight: lineHeight,
        marginHorizontal: marginHorizontal,
        marginVertical: marginVertical,
        theme: theme,
        textAlign: textAlign,
      );
    }

    group('constructor', () {
      test('creates settings with required fields', () {
        final settings = createTestSettings();

        expect(settings.fontSize, equals(16.0));
        expect(settings.fontFamily, equals('Georgia'));
        expect(settings.lineHeight, equals(1.5));
        expect(settings.marginHorizontal, equals(16.0));
        expect(settings.marginVertical, equals(24.0));
        expect(settings.theme, equals(ReadingTheme.light));
        expect(settings.textAlign, equals(TextAlign.justify));
      });

      test('creates settings with custom values', () {
        final settings = ReadingSettings(
          fontSize: 20.0,
          fontFamily: 'Helvetica',
          lineHeight: 2.0,
          marginHorizontal: 32.0,
          marginVertical: 48.0,
          theme: ReadingTheme.dark,
          textAlign: TextAlign.left,
        );

        expect(settings.fontSize, equals(20.0));
        expect(settings.fontFamily, equals('Helvetica'));
        expect(settings.lineHeight, equals(2.0));
        expect(settings.marginHorizontal, equals(32.0));
        expect(settings.marginVertical, equals(48.0));
        expect(settings.theme, equals(ReadingTheme.dark));
        expect(settings.textAlign, equals(TextAlign.left));
      });
    });

    group('defaults factory', () {
      test('creates settings with default values', () {
        final settings = ReadingSettings.defaults();

        expect(settings.fontSize, equals(16.0));
        expect(settings.fontFamily, equals('Georgia'));
        expect(settings.lineHeight, equals(1.5));
        expect(settings.marginHorizontal, equals(16.0));
        expect(settings.marginVertical, equals(24.0));
        expect(settings.theme, equals(ReadingTheme.light));
        expect(settings.textAlign, equals(TextAlign.justify));
      });
    });

    group('copyWith', () {
      test('creates new instance with changed fields', () {
        final settings = createTestSettings();

        final updated = settings.copyWith(
          fontSize: 20.0,
          theme: ReadingTheme.dark,
        );

        expect(updated.fontSize, equals(20.0));
        expect(updated.theme, equals(ReadingTheme.dark));
      });

      test('preserves unchanged fields', () {
        final settings = createTestSettings();

        final updated = settings.copyWith(fontSize: 20.0);

        expect(updated.fontFamily, equals(settings.fontFamily));
        expect(updated.lineHeight, equals(settings.lineHeight));
        expect(updated.marginHorizontal, equals(settings.marginHorizontal));
        expect(updated.marginVertical, equals(settings.marginVertical));
        expect(updated.theme, equals(settings.theme));
        expect(updated.textAlign, equals(settings.textAlign));
      });

      test('can update all fields', () {
        final settings = createTestSettings();

        final updated = settings.copyWith(
          fontSize: 24.0,
          fontFamily: 'Arial',
          lineHeight: 1.8,
          marginHorizontal: 24.0,
          marginVertical: 32.0,
          theme: ReadingTheme.sepia,
          textAlign: TextAlign.center,
        );

        expect(updated.fontSize, equals(24.0));
        expect(updated.fontFamily, equals('Arial'));
        expect(updated.lineHeight, equals(1.8));
        expect(updated.marginHorizontal, equals(24.0));
        expect(updated.marginVertical, equals(32.0));
        expect(updated.theme, equals(ReadingTheme.sepia));
        expect(updated.textAlign, equals(TextAlign.center));
      });
    });

    group('equality', () {
      test('equals same settings with identical properties', () {
        final settings1 = createTestSettings();
        final settings2 = createTestSettings();

        expect(settings1, equals(settings2));
      });

      test('not equals settings with different fontSize', () {
        final settings1 = createTestSettings(fontSize: 16.0);
        final settings2 = createTestSettings(fontSize: 20.0);

        expect(settings1, isNot(equals(settings2)));
      });

      test('not equals settings with different theme', () {
        final settings1 = createTestSettings(theme: ReadingTheme.light);
        final settings2 = createTestSettings(theme: ReadingTheme.dark);

        expect(settings1, isNot(equals(settings2)));
      });

      test('hashCode is equal for equal settings', () {
        final settings1 = createTestSettings();
        final settings2 = createTestSettings();

        expect(settings1.hashCode, equals(settings2.hashCode));
      });
    });

    group('toString', () {
      test('includes fontSize, fontFamily, theme, textAlign', () {
        final settings = createTestSettings();
        final str = settings.toString();

        expect(str, contains('fontSize: 16.0'));
        expect(str, contains('fontFamily: Georgia'));
        expect(str, contains('theme: ReadingTheme.light'));
        expect(str, contains('textAlign: TextAlign.justify'));
      });
    });

    group('ReadingTheme enum', () {
      test('has light theme', () {
        expect(ReadingTheme.values, contains(ReadingTheme.light));
      });

      test('has dark theme', () {
        expect(ReadingTheme.values, contains(ReadingTheme.dark));
      });

      test('has sepia theme', () {
        expect(ReadingTheme.values, contains(ReadingTheme.sepia));
      });

      test('has exactly 3 themes', () {
        expect(ReadingTheme.values.length, equals(3));
      });
    });
  });
}
