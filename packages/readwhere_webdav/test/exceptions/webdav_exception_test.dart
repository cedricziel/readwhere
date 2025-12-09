import 'package:readwhere_webdav/readwhere_webdav.dart';
import 'package:test/test.dart';

void main() {
  group('WebDavException', () {
    test('creates exception with message', () {
      final exception = WebDavException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.statusCode, isNull);
      expect(exception.cause, isNull);
    });

    test('creates exception with status code', () {
      final exception = WebDavException('Not found', statusCode: 404);
      expect(exception.message, 'Not found');
      expect(exception.statusCode, 404);
    });

    test('creates exception with cause', () {
      final originalError = FormatException('Invalid format');
      final exception = WebDavException(
        'Error',
        statusCode: 500,
        cause: originalError,
      );
      expect(exception.message, 'Error');
      expect(exception.statusCode, 500);
      expect(exception.cause, originalError);
    });

    test('toString includes message', () {
      final exception = WebDavException('Something went wrong');
      expect(exception.toString(), contains('Something went wrong'));
    });

    test('toString includes status code when present', () {
      final exception = WebDavException('Unauthorized', statusCode: 401);
      final str = exception.toString();
      expect(str, contains('Unauthorized'));
      expect(str, contains('401'));
    });

    test('toString format without status code', () {
      final exception = WebDavException('Network error');
      expect(exception.toString(), 'WebDavException: Network error');
    });

    test('toString format with status code', () {
      final exception = WebDavException('Forbidden', statusCode: 403);
      expect(exception.toString(), 'WebDavException: Forbidden (status: 403)');
    });

    test('implements Exception', () {
      final exception = WebDavException('Test');
      expect(exception, isA<Exception>());
    });
  });
}
