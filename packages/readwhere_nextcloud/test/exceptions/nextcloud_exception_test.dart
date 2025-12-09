import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';

void main() {
  group('NextcloudException', () {
    test('creates exception with message only', () {
      final exception = NextcloudException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.statusCode, isNull);
      expect(exception.response, isNull);
      expect(exception.cause, isNull);
    });

    test('creates exception with status code', () {
      final exception = NextcloudException('Not found', statusCode: 404);
      expect(exception.message, 'Not found');
      expect(exception.statusCode, 404);
    });

    test('creates exception with response body', () {
      final exception = NextcloudException(
        'Error',
        statusCode: 500,
        response: '{"error": "Internal error"}',
      );
      expect(exception.message, 'Error');
      expect(exception.statusCode, 500);
      expect(exception.response, '{"error": "Internal error"}');
    });

    test('creates exception with cause', () {
      final originalError = FormatException('Invalid format');
      final exception = NextcloudException(
        'Parse error',
        cause: originalError,
      );
      expect(exception.message, 'Parse error');
      expect(exception.cause, originalError);
    });

    test('creates exception with all parameters', () {
      final cause = FormatException('Bad JSON');
      final exception = NextcloudException(
        'API error',
        statusCode: 400,
        response: '{"error": "Bad request"}',
        cause: cause,
      );
      expect(exception.message, 'API error');
      expect(exception.statusCode, 400);
      expect(exception.response, '{"error": "Bad request"}');
      expect(exception.cause, cause);
    });

    test('toString includes message', () {
      final exception = NextcloudException('Something went wrong');
      expect(exception.toString(), contains('Something went wrong'));
    });

    test('toString includes status code when present', () {
      final exception = NextcloudException('Unauthorized', statusCode: 401);
      final str = exception.toString();
      expect(str, contains('Unauthorized'));
      expect(str, contains('401'));
    });

    test('toString format without status code', () {
      final exception = NextcloudException('Network error');
      expect(exception.toString(), 'NextcloudException: Network error');
    });

    test('toString format with status code', () {
      final exception = NextcloudException('Forbidden', statusCode: 403);
      expect(
          exception.toString(), 'NextcloudException: Forbidden (status: 403)');
    });

    test('implements Exception', () {
      final exception = NextcloudException('Test');
      expect(exception, isA<Exception>());
    });
  });
}
