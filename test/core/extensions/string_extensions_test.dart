import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/core/extensions/string_extensions.dart';

void main() {
  group('StringExtensions', () {
    group('capitalize', () {
      test('capitalizes first letter', () {
        expect('hello'.capitalize(), equals('Hello'));
      });

      test('handles empty string', () {
        expect(''.capitalize(), equals(''));
      });

      test('handles single character', () {
        expect('a'.capitalize(), equals('A'));
      });

      test('preserves rest of string', () {
        expect('hELLO'.capitalize(), equals('HELLO'));
      });

      test('handles already capitalized string', () {
        expect('Hello'.capitalize(), equals('Hello'));
      });

      test('handles non-letter first character', () {
        expect('123abc'.capitalize(), equals('123abc'));
      });
    });

    group('capitalizeWords', () {
      test('capitalizes each word', () {
        expect('hello world'.capitalizeWords(), equals('Hello World'));
      });

      test('lowercases rest of each word', () {
        expect('HELLO WORLD'.capitalizeWords(), equals('Hello World'));
      });

      test('handles empty string', () {
        expect(''.capitalizeWords(), equals(''));
      });

      test('handles single word', () {
        expect('hello'.capitalizeWords(), equals('Hello'));
      });

      test('handles multiple spaces between words', () {
        expect('hello  world'.capitalizeWords(), equals('Hello  World'));
      });
    });

    group('truncate', () {
      test('returns original when shorter than max', () {
        expect('Hello'.truncate(10), equals('Hello'));
      });

      test('truncates with ellipsis', () {
        expect('Hello World'.truncate(8), equals('Hello...'));
      });

      test('handles custom ellipsis', () {
        expect('Hello World'.truncate(8, ellipsis: '…'), equals('Hello W…'));
      });

      test('handles maxLength equal to string length', () {
        expect('Hello'.truncate(5), equals('Hello'));
      });

      test('handles very short maxLength', () {
        expect('Hello'.truncate(3), equals('...'));
      });

      test('handles maxLength less than ellipsis length', () {
        expect('Hello'.truncate(2), equals('...'));
      });

      test('handles maxLength of 0', () {
        expect('Hello'.truncate(0), equals('...'));
      });
    });

    group('isValidUrl', () {
      test('returns true for https URL', () {
        expect('https://example.com'.isValidUrl(), isTrue);
      });

      test('returns true for http URL', () {
        expect('http://example.com'.isValidUrl(), isTrue);
      });

      test('returns true for URL with path', () {
        expect('https://example.com/path/to/page'.isValidUrl(), isTrue);
      });

      test('returns true for URL with query params', () {
        expect('https://example.com?param=value'.isValidUrl(), isTrue);
      });

      test('returns false for ftp URL', () {
        expect('ftp://example.com'.isValidUrl(), isFalse);
      });

      test('returns false for invalid URL', () {
        expect('not a url'.isValidUrl(), isFalse);
      });

      test('returns false for empty string', () {
        expect(''.isValidUrl(), isFalse);
      });

      test('returns false for URL without scheme', () {
        expect('example.com'.isValidUrl(), isFalse);
      });
    });

    group('isValidEmail', () {
      test('returns true for valid email', () {
        expect('user@example.com'.isValidEmail(), isTrue);
      });

      test('returns true for email with subdomain', () {
        expect('user@mail.example.com'.isValidEmail(), isTrue);
      });

      test('returns true for email with plus sign', () {
        expect('user+tag@example.com'.isValidEmail(), isTrue);
      });

      test('returns true for email with dots', () {
        expect('first.last@example.com'.isValidEmail(), isTrue);
      });

      test('returns false for invalid email', () {
        expect('invalid.email'.isValidEmail(), isFalse);
      });

      test('returns false for email without domain', () {
        expect('user@'.isValidEmail(), isFalse);
      });

      test('returns false for email without @', () {
        expect('userexample.com'.isValidEmail(), isFalse);
      });

      test('returns false for empty string', () {
        expect(''.isValidEmail(), isFalse);
      });
    });

    group('removeWhitespace', () {
      test('removes spaces', () {
        expect('Hello World'.removeWhitespace(), equals('HelloWorld'));
      });

      test('removes leading and trailing spaces', () {
        expect('  Hello  '.removeWhitespace(), equals('Hello'));
      });

      test('removes tabs', () {
        expect('Hello\tWorld'.removeWhitespace(), equals('HelloWorld'));
      });

      test('removes newlines', () {
        expect('Hello\nWorld'.removeWhitespace(), equals('HelloWorld'));
      });

      test('handles empty string', () {
        expect(''.removeWhitespace(), equals(''));
      });

      test('handles string with only whitespace', () {
        expect('   '.removeWhitespace(), equals(''));
      });
    });

    group('isNumeric', () {
      test('returns true for numeric string', () {
        expect('12345'.isNumeric(), isTrue);
      });

      test('returns true for single digit', () {
        expect('5'.isNumeric(), isTrue);
      });

      test('returns false for decimal number', () {
        expect('123.45'.isNumeric(), isFalse);
      });

      test('returns false for alphanumeric', () {
        expect('abc123'.isNumeric(), isFalse);
      });

      test('returns false for negative number', () {
        expect('-123'.isNumeric(), isFalse);
      });

      test('returns false for empty string', () {
        expect(''.isNumeric(), isFalse);
      });

      test('returns false for string with spaces', () {
        expect('123 456'.isNumeric(), isFalse);
      });
    });

    group('toIntOrNull', () {
      test('returns int for numeric string', () {
        expect('123'.toIntOrNull(), equals(123));
      });

      test('returns int for negative number', () {
        expect('-123'.toIntOrNull(), equals(-123));
      });

      test('returns null for decimal number', () {
        expect('123.45'.toIntOrNull(), isNull);
      });

      test('returns null for non-numeric string', () {
        expect('abc'.toIntOrNull(), isNull);
      });

      test('returns null for empty string', () {
        expect(''.toIntOrNull(), isNull);
      });
    });

    group('toDoubleOrNull', () {
      test('returns double for decimal number', () {
        expect('123.45'.toDoubleOrNull(), equals(123.45));
      });

      test('returns double for integer string', () {
        expect('123'.toDoubleOrNull(), equals(123.0));
      });

      test('returns double for negative number', () {
        expect('-123.45'.toDoubleOrNull(), equals(-123.45));
      });

      test('returns null for non-numeric string', () {
        expect('abc'.toDoubleOrNull(), isNull);
      });

      test('returns null for empty string', () {
        expect(''.toDoubleOrNull(), isNull);
      });
    });

    group('reverse', () {
      test('reverses string', () {
        expect('hello'.reverse(), equals('olleh'));
      });

      test('reverses numbers', () {
        expect('12345'.reverse(), equals('54321'));
      });

      test('handles empty string', () {
        expect(''.reverse(), equals(''));
      });

      test('handles single character', () {
        expect('a'.reverse(), equals('a'));
      });

      test('handles palindrome', () {
        expect('radar'.reverse(), equals('radar'));
      });
    });

    group('isNullOrEmpty', () {
      test('returns true for empty string', () {
        expect(''.isNullOrEmpty(), isTrue);
      });

      test('returns true for whitespace only', () {
        expect('   '.isNullOrEmpty(), isTrue);
      });

      test('returns true for tabs and newlines', () {
        expect('\t\n'.isNullOrEmpty(), isTrue);
      });

      test('returns false for non-empty string', () {
        expect('Hello'.isNullOrEmpty(), isFalse);
      });

      test('returns false for string with content and spaces', () {
        expect('  Hello  '.isNullOrEmpty(), isFalse);
      });
    });
  });

  group('NullableStringExtensions', () {
    // Note: There's a getter `isNullOrEmpty` in NullableStringExtensions
    // and a method `isNullOrEmpty()` in StringExtensions. When the nullable
    // variable has a non-null value, Dart prefers the String extension.
    // We test the getter behavior only for truly null values, and use
    // orDefault for other nullability tests.

    group('isNullOrEmpty getter', () {
      test('returns true for null string', () {
        // ignore: avoid_init_to_null
        String? str = null;
        expect(str.isNullOrEmpty, equals(true));
      });
    });

    group('orDefault', () {
      test('returns default for null string', () {
        // ignore: avoid_init_to_null
        String? str = null;
        expect(str.orDefault('N/A'), equals('N/A'));
      });

      test('returns default for empty string', () {
        String? str = '';
        expect(str.orDefault('N/A'), equals('N/A'));
      });

      test('returns default for whitespace only', () {
        String? str = '   ';
        expect(str.orDefault('N/A'), equals('N/A'));
      });

      test('returns original for non-empty string', () {
        String? str = 'Hello';
        expect(str.orDefault('N/A'), equals('Hello'));
      });
    });
  });
}
