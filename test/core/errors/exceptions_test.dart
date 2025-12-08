import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/core/errors/exceptions.dart';

void main() {
  group('AppException', () {
    // Since AppException is abstract, we test it through its subclasses
    group('DatabaseException', () {
      test('creates exception with message', () {
        const exception = DatabaseException('Database error');

        expect(exception.message, equals('Database error'));
        expect(exception.originalException, isNull);
        expect(exception.stackTrace, isNull);
      });

      test('creates exception with message and original exception', () {
        final originalError = Exception('Original error');
        final exception = DatabaseException(
          'Database error',
          originalException: originalError,
        );

        expect(exception.message, equals('Database error'));
        expect(exception.originalException, equals(originalError));
      });

      test('toString includes message', () {
        const exception = DatabaseException('Database error');
        expect(exception.toString(), contains('DatabaseException'));
        expect(exception.toString(), contains('Database error'));
      });

      test('toString includes original exception when present', () {
        final originalError = Exception('Original error');
        final exception = DatabaseException(
          'Database error',
          originalException: originalError,
        );

        expect(exception.toString(), contains('Original:'));
        expect(exception.toString(), contains('Original error'));
      });
    });

    group('FileException', () {
      test('creates exception with message', () {
        const exception = FileException('File not found');
        expect(exception.message, equals('File not found'));
      });

      test('toString includes message', () {
        const exception = FileException('File not found');
        expect(exception.toString(), contains('FileException'));
        expect(exception.toString(), contains('File not found'));
      });
    });

    group('ParsingException', () {
      test('creates exception with message', () {
        const exception = ParsingException('Invalid XML');
        expect(exception.message, equals('Invalid XML'));
      });

      test('toString includes message', () {
        const exception = ParsingException('Invalid XML');
        expect(exception.toString(), contains('ParsingException'));
        expect(exception.toString(), contains('Invalid XML'));
      });
    });
  });

  group('UnsupportedFormatException', () {
    test('creates exception with message and extension', () {
      const exception = UnsupportedFormatException(
        'Format not supported',
        'xyz',
      );

      expect(exception.message, equals('Format not supported'));
      expect(exception.fileExtension, equals('xyz'));
    });

    test('toString includes format', () {
      const exception = UnsupportedFormatException(
        'Format not supported',
        'xyz',
      );

      expect(exception.toString(), contains('UnsupportedFormatException'));
      expect(exception.toString(), contains('Format: .xyz'));
    });
  });

  group('NetworkException', () {
    test('creates exception with message', () {
      const exception = NetworkException('Network error');
      expect(exception.message, equals('Network error'));
      expect(exception.statusCode, isNull);
    });

    test('creates exception with message and status code', () {
      const exception = NetworkException('Not found', statusCode: 404);

      expect(exception.message, equals('Not found'));
      expect(exception.statusCode, equals(404));
    });

    test('toString includes status code when present', () {
      const exception = NetworkException('Server error', statusCode: 500);

      expect(exception.toString(), contains('NetworkException'));
      expect(exception.toString(), contains('Status code: 500'));
    });

    test('toString excludes status code when null', () {
      const exception = NetworkException('Network error');

      expect(exception.toString(), contains('NetworkException'));
      expect(exception.toString(), isNot(contains('Status code:')));
    });
  });

  group('ValidationException', () {
    test('creates exception with message', () {
      const exception = ValidationException('Validation failed');
      expect(exception.message, equals('Validation failed'));
      expect(exception.fieldErrors, isNull);
    });

    test('creates exception with message and field errors', () {
      const exception = ValidationException(
        'Validation failed',
        fieldErrors: {'email': 'Invalid email', 'name': 'Required'},
      );

      expect(exception.message, equals('Validation failed'));
      expect(exception.fieldErrors, isNotNull);
      expect(exception.fieldErrors!['email'], equals('Invalid email'));
      expect(exception.fieldErrors!['name'], equals('Required'));
    });

    test('toString includes field errors when present', () {
      const exception = ValidationException(
        'Validation failed',
        fieldErrors: {'email': 'Invalid'},
      );

      expect(exception.toString(), contains('ValidationException'));
      expect(exception.toString(), contains('Errors:'));
      expect(exception.toString(), contains('email'));
    });

    test('toString excludes field errors when empty', () {
      const exception = ValidationException(
        'Validation failed',
        fieldErrors: {},
      );

      expect(exception.toString(), contains('ValidationException'));
      expect(exception.toString(), isNot(contains('Errors:')));
    });
  });

  group('NotFoundException', () {
    test('creates exception with message, type and id', () {
      const exception = NotFoundException('Resource not found', 'Book', '123');

      expect(exception.message, equals('Resource not found'));
      expect(exception.resourceType, equals('Book'));
      expect(exception.resourceId, equals('123'));
    });

    test('toString includes resource type and id', () {
      const exception = NotFoundException('Resource not found', 'Book', '123');

      expect(exception.toString(), contains('NotFoundException'));
      expect(exception.toString(), contains('Book'));
      expect(exception.toString(), contains('ID: 123'));
      expect(exception.toString(), contains('not found'));
    });
  });

  group('CacheException', () {
    test('creates exception with message', () {
      const exception = CacheException('Cache miss');
      expect(exception.message, equals('Cache miss'));
    });
  });

  group('PermissionException', () {
    test('creates exception with message and permission', () {
      const exception = PermissionException('Permission denied', 'storage');

      expect(exception.message, equals('Permission denied'));
      expect(exception.permission, equals('storage'));
    });

    test('toString includes permission', () {
      const exception = PermissionException('Permission denied', 'camera');

      expect(exception.toString(), contains('PermissionException'));
      expect(exception.toString(), contains('Permission: camera'));
    });
  });

  group('Exception inheritance', () {
    test('DatabaseException implements Exception', () {
      const exception = DatabaseException('test');
      expect(exception, isA<Exception>());
    });

    test('FileException implements Exception', () {
      const exception = FileException('test');
      expect(exception, isA<Exception>());
    });

    test('ParsingException implements Exception', () {
      const exception = ParsingException('test');
      expect(exception, isA<Exception>());
    });

    test('NetworkException implements Exception', () {
      const exception = NetworkException('test');
      expect(exception, isA<Exception>());
    });
  });
}
