import 'package:readwhere_cbr/readwhere_cbr.dart';
import 'package:test/test.dart';

void main() {
  group('CbrReadException', () {
    test('creates exception with message', () {
      final exception = CbrReadException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.cause, isNull);
      expect(exception.stackTrace, isNull);
      expect(exception.filePath, isNull);
    });

    test('creates exception with file path', () {
      final exception = CbrReadException(
        'Test error',
        filePath: '/path/to/comic.cbr',
      );
      expect(exception.message, 'Test error');
      expect(exception.filePath, '/path/to/comic.cbr');
    });

    test('creates exception with cause and stack trace', () {
      final cause = Exception('Root cause');
      final stackTrace = StackTrace.current;
      final exception = CbrReadException(
        'Test error',
        cause: cause,
        stackTrace: stackTrace,
      );
      expect(exception.cause, cause);
      expect(exception.stackTrace, stackTrace);
    });

    test('toString includes message', () {
      final exception = CbrReadException('Test error');
      expect(exception.toString(), contains('Test error'));
    });

    test('toString includes file path when present', () {
      final exception = CbrReadException(
        'Test error',
        filePath: '/path/to/comic.cbr',
      );
      expect(exception.toString(), contains('/path/to/comic.cbr'));
    });
  });

  group('CbrPageNotFoundException', () {
    test('creates exception with page index', () {
      final exception = CbrPageNotFoundException(5);
      expect(exception.pageIndex, 5);
      expect(exception.message, contains('5'));
    });

    test('toString includes page index', () {
      final exception = CbrPageNotFoundException(10);
      expect(exception.toString(), contains('10'));
    });

    test('cause and stackTrace are null', () {
      final exception = CbrPageNotFoundException(0);
      expect(exception.cause, isNull);
      expect(exception.stackTrace, isNull);
    });
  });

  group('CbrExtractionException', () {
    test('creates exception with message', () {
      final exception = CbrExtractionException('Extraction failed');
      expect(exception.message, 'Extraction failed');
      expect(exception.cause, isNull);
      expect(exception.stackTrace, isNull);
    });

    test('creates exception with cause and stack trace', () {
      final cause = Exception('RAR error');
      final stackTrace = StackTrace.current;
      final exception = CbrExtractionException(
        'Extraction failed',
        cause: cause,
        stackTrace: stackTrace,
      );
      expect(exception.cause, cause);
      expect(exception.stackTrace, stackTrace);
    });

    test('toString includes message', () {
      final exception = CbrExtractionException('Extraction failed');
      expect(exception.toString(), contains('Extraction failed'));
    });
  });

  group('CbrException sealed class', () {
    test('CbrReadException is a CbrException', () {
      final exception = CbrReadException('Test');
      expect(exception, isA<CbrException>());
    });

    test('CbrPageNotFoundException is a CbrException', () {
      final exception = CbrPageNotFoundException(0);
      expect(exception, isA<CbrException>());
    });

    test('CbrExtractionException is a CbrException', () {
      final exception = CbrExtractionException('Test');
      expect(exception, isA<CbrException>());
    });
  });
}
