import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/core/errors/failures.dart';

void main() {
  group('Failure', () {
    // Since Failure is abstract, we test it through its subclasses
    group('DatabaseFailure', () {
      test('creates failure with message', () {
        const failure = DatabaseFailure('Database error');

        expect(failure.message, equals('Database error'));
        expect(failure.details, isNull);
      });

      test('creates failure with message and details', () {
        const failure = DatabaseFailure(
          'Database error',
          details: 'Connection refused',
        );

        expect(failure.message, equals('Database error'));
        expect(failure.details, equals('Connection refused'));
      });

      test('equals same failure with identical properties', () {
        const failure1 = DatabaseFailure('error', details: 'details');
        const failure2 = DatabaseFailure('error', details: 'details');

        expect(failure1, equals(failure2));
      });

      test('not equals failure with different message', () {
        const failure1 = DatabaseFailure('error1');
        const failure2 = DatabaseFailure('error2');

        expect(failure1, isNot(equals(failure2)));
      });

      test('toString includes message', () {
        const failure = DatabaseFailure('Database error');
        expect(failure.toString(), contains('DatabaseFailure'));
        expect(failure.toString(), contains('Database error'));
      });

      test('toString includes details when present', () {
        const failure = DatabaseFailure(
          'Database error',
          details: 'Connection refused',
        );

        expect(failure.toString(), contains('Details: Connection refused'));
      });
    });

    group('FileFailure', () {
      test('creates failure with message', () {
        const failure = FileFailure('File not found');
        expect(failure.message, equals('File not found'));
      });

      test('toString includes message', () {
        const failure = FileFailure('File error');
        expect(failure.toString(), contains('FileFailure'));
        expect(failure.toString(), contains('File error'));
      });
    });
  });

  group('ParsingFailure', () {
    test('creates failure with message', () {
      const failure = ParsingFailure('Invalid XML');
      expect(failure.message, equals('Invalid XML'));
      expect(failure.format, isNull);
    });

    test('creates failure with message and format', () {
      const failure = ParsingFailure('Invalid file', format: 'epub');

      expect(failure.message, equals('Invalid file'));
      expect(failure.format, equals('epub'));
    });

    test('equals same failure including format', () {
      const failure1 = ParsingFailure('error', format: 'epub');
      const failure2 = ParsingFailure('error', format: 'epub');

      expect(failure1, equals(failure2));
    });

    test('not equals failure with different format', () {
      const failure1 = ParsingFailure('error', format: 'epub');
      const failure2 = ParsingFailure('error', format: 'pdf');

      expect(failure1, isNot(equals(failure2)));
    });

    test('toString includes format when present', () {
      const failure = ParsingFailure('Invalid file', format: 'epub');

      expect(failure.toString(), contains('ParsingFailure'));
      expect(failure.toString(), contains('Format: epub'));
    });

    test('toString excludes format when null', () {
      const failure = ParsingFailure('Invalid file');

      expect(failure.toString(), contains('ParsingFailure'));
      expect(failure.toString(), isNot(contains('Format:')));
    });
  });

  group('UnsupportedFormatFailure', () {
    test('creates failure with message and extension', () {
      const failure = UnsupportedFormatFailure('Format not supported', 'xyz');

      expect(failure.message, equals('Format not supported'));
      expect(failure.fileExtension, equals('xyz'));
    });

    test('equals same failure with identical properties', () {
      const failure1 = UnsupportedFormatFailure('error', 'xyz');
      const failure2 = UnsupportedFormatFailure('error', 'xyz');

      expect(failure1, equals(failure2));
    });

    test('not equals failure with different extension', () {
      const failure1 = UnsupportedFormatFailure('error', 'abc');
      const failure2 = UnsupportedFormatFailure('error', 'xyz');

      expect(failure1, isNot(equals(failure2)));
    });

    test('toString includes format', () {
      const failure = UnsupportedFormatFailure('Format not supported', 'xyz');

      expect(failure.toString(), contains('UnsupportedFormatFailure'));
      expect(failure.toString(), contains('Format: .xyz'));
    });
  });

  group('NetworkFailure', () {
    test('creates failure with message', () {
      const failure = NetworkFailure('Network error');
      expect(failure.message, equals('Network error'));
      expect(failure.statusCode, isNull);
    });

    test('creates failure with message and status code', () {
      const failure = NetworkFailure('Not found', statusCode: 404);

      expect(failure.message, equals('Not found'));
      expect(failure.statusCode, equals(404));
    });

    test('equals same failure with identical properties', () {
      const failure1 = NetworkFailure('error', statusCode: 500);
      const failure2 = NetworkFailure('error', statusCode: 500);

      expect(failure1, equals(failure2));
    });

    test('not equals failure with different status code', () {
      const failure1 = NetworkFailure('error', statusCode: 404);
      const failure2 = NetworkFailure('error', statusCode: 500);

      expect(failure1, isNot(equals(failure2)));
    });

    test('toString includes status code when present', () {
      const failure = NetworkFailure('Server error', statusCode: 500);

      expect(failure.toString(), contains('NetworkFailure'));
      expect(failure.toString(), contains('Status code: 500'));
    });

    test('toString excludes status code when null', () {
      const failure = NetworkFailure('Network error');

      expect(failure.toString(), contains('NetworkFailure'));
      expect(failure.toString(), isNot(contains('Status code:')));
    });
  });

  group('ValidationFailure', () {
    test('creates failure with message', () {
      const failure = ValidationFailure('Validation failed');
      expect(failure.message, equals('Validation failed'));
      expect(failure.fieldErrors, isNull);
    });

    test('creates failure with message and field errors', () {
      const failure = ValidationFailure(
        'Validation failed',
        fieldErrors: {'email': 'Invalid email', 'name': 'Required'},
      );

      expect(failure.message, equals('Validation failed'));
      expect(failure.fieldErrors, isNotNull);
      expect(failure.fieldErrors!['email'], equals('Invalid email'));
    });

    test('equals same failure with identical properties', () {
      const failure1 = ValidationFailure(
        'error',
        fieldErrors: {'email': 'Invalid'},
      );
      const failure2 = ValidationFailure(
        'error',
        fieldErrors: {'email': 'Invalid'},
      );

      expect(failure1, equals(failure2));
    });

    test('toString includes field errors when present', () {
      const failure = ValidationFailure(
        'Validation failed',
        fieldErrors: {'email': 'Invalid'},
      );

      expect(failure.toString(), contains('ValidationFailure'));
      expect(failure.toString(), contains('Field Errors:'));
    });

    test('toString excludes field errors when empty', () {
      const failure = ValidationFailure('Validation failed', fieldErrors: {});

      expect(failure.toString(), contains('ValidationFailure'));
      expect(failure.toString(), isNot(contains('Field Errors:')));
    });
  });

  group('NotFoundFailure', () {
    test('creates failure with message, type and id', () {
      const failure = NotFoundFailure('Resource not found', 'Book', '123');

      expect(failure.message, equals('Resource not found'));
      expect(failure.resourceType, equals('Book'));
      expect(failure.resourceId, equals('123'));
    });

    test('equals same failure with identical properties', () {
      const failure1 = NotFoundFailure('error', 'Book', '123');
      const failure2 = NotFoundFailure('error', 'Book', '123');

      expect(failure1, equals(failure2));
    });

    test('not equals failure with different resource id', () {
      const failure1 = NotFoundFailure('error', 'Book', '123');
      const failure2 = NotFoundFailure('error', 'Book', '456');

      expect(failure1, isNot(equals(failure2)));
    });

    test('toString includes resource type and id', () {
      const failure = NotFoundFailure('Resource not found', 'Book', '123');

      expect(failure.toString(), contains('NotFoundFailure'));
      expect(failure.toString(), contains('Book'));
      expect(failure.toString(), contains('ID: 123'));
      expect(failure.toString(), contains('not found'));
    });
  });

  group('CacheFailure', () {
    test('creates failure with message', () {
      const failure = CacheFailure('Cache miss');
      expect(failure.message, equals('Cache miss'));
    });
  });

  group('PermissionFailure', () {
    test('creates failure with message and permission', () {
      const failure = PermissionFailure('Permission denied', 'storage');

      expect(failure.message, equals('Permission denied'));
      expect(failure.permission, equals('storage'));
    });

    test('equals same failure with identical properties', () {
      const failure1 = PermissionFailure('error', 'storage');
      const failure2 = PermissionFailure('error', 'storage');

      expect(failure1, equals(failure2));
    });

    test('not equals failure with different permission', () {
      const failure1 = PermissionFailure('error', 'storage');
      const failure2 = PermissionFailure('error', 'camera');

      expect(failure1, isNot(equals(failure2)));
    });

    test('toString includes permission', () {
      const failure = PermissionFailure('Permission denied', 'camera');

      expect(failure.toString(), contains('PermissionFailure'));
      expect(failure.toString(), contains('Permission: camera'));
    });
  });

  group('UnexpectedFailure', () {
    test('creates failure with message', () {
      const failure = UnexpectedFailure('Unexpected error');
      expect(failure.message, equals('Unexpected error'));
    });

    test('creates failure with message and details', () {
      const failure = UnexpectedFailure(
        'Unexpected error',
        details: 'Stack trace here',
      );

      expect(failure.message, equals('Unexpected error'));
      expect(failure.details, equals('Stack trace here'));
    });
  });

  group('Failure equality', () {
    test('hashCode is equal for equal failures', () {
      const failure1 = DatabaseFailure('error');
      const failure2 = DatabaseFailure('error');

      expect(failure1.hashCode, equals(failure2.hashCode));
    });

    test('props includes message and details', () {
      const failure = DatabaseFailure('error', details: 'details');
      expect(failure.props, contains('error'));
      expect(failure.props, contains('details'));
    });
  });
}
