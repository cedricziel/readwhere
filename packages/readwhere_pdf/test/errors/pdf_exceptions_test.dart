import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_pdf/readwhere_pdf.dart';

void main() {
  group('PdfReadException', () {
    test('creates exception with message', () {
      const exception = PdfReadException('Failed to read file');

      expect(exception.message, 'Failed to read file');
      expect(exception.filePath, isNull);
      expect(exception.cause, isNull);
    });

    test('creates exception with filePath', () {
      const exception = PdfReadException(
        'Failed to read file',
        filePath: '/path/to/file.pdf',
      );

      expect(exception.message, 'Failed to read file');
      expect(exception.filePath, '/path/to/file.pdf');
    });

    test('creates exception with cause', () {
      final cause = Exception('IO Error');
      final exception = PdfReadException('Failed to read file', cause: cause);

      expect(exception.cause, cause);
    });

    test('toString includes message and filePath', () {
      const exception = PdfReadException(
        'Failed to read file',
        filePath: '/path/to/file.pdf',
      );

      final str = exception.toString();
      expect(str, contains('PdfReadException'));
      expect(str, contains('Failed to read file'));
      expect(str, contains('/path/to/file.pdf'));
    });

    test('toString without filePath', () {
      const exception = PdfReadException('Failed to read file');

      final str = exception.toString();
      expect(str, contains('PdfReadException'));
      expect(str, contains('Failed to read file'));
    });
  });

  group('PdfParseException', () {
    test('creates exception with message', () {
      const exception = PdfParseException('Invalid PDF structure');

      expect(exception.message, 'Invalid PDF structure');
      expect(exception.filePath, isNull);
      expect(exception.cause, isNull);
    });

    test('creates exception with filePath', () {
      const exception = PdfParseException(
        'Invalid PDF structure',
        filePath: '/path/to/corrupt.pdf',
      );

      expect(exception.filePath, '/path/to/corrupt.pdf');
    });

    test('toString includes message and filePath', () {
      const exception = PdfParseException(
        'Invalid PDF structure',
        filePath: '/path/to/corrupt.pdf',
      );

      final str = exception.toString();
      expect(str, contains('PdfParseException'));
      expect(str, contains('Invalid PDF structure'));
      expect(str, contains('/path/to/corrupt.pdf'));
    });
  });

  group('PdfPasswordRequiredException', () {
    test('creates exception with default message', () {
      const exception = PdfPasswordRequiredException();

      expect(exception.message, 'PDF requires a password to open');
      expect(exception.filePath, isNull);
    });

    test('creates exception with filePath', () {
      const exception = PdfPasswordRequiredException(
        filePath: '/path/to/encrypted.pdf',
      );

      expect(exception.filePath, '/path/to/encrypted.pdf');
    });

    test('creates exception with custom message', () {
      const exception = PdfPasswordRequiredException(
        message: 'Custom password message',
      );

      expect(exception.message, 'Custom password message');
    });

    test('toString includes message and filePath', () {
      const exception = PdfPasswordRequiredException(
        filePath: '/path/to/encrypted.pdf',
      );

      final str = exception.toString();
      expect(str, contains('PdfPasswordRequiredException'));
      expect(str, contains('PDF requires a password'));
      expect(str, contains('/path/to/encrypted.pdf'));
    });
  });

  group('PdfIncorrectPasswordException', () {
    test('creates exception with default message', () {
      const exception = PdfIncorrectPasswordException();

      expect(exception.message, 'Incorrect password provided');
      expect(exception.filePath, isNull);
    });

    test('creates exception with filePath', () {
      const exception = PdfIncorrectPasswordException(
        filePath: '/path/to/encrypted.pdf',
      );

      expect(exception.filePath, '/path/to/encrypted.pdf');
    });

    test('creates exception with custom message', () {
      const exception = PdfIncorrectPasswordException(
        message: 'Wrong password',
      );

      expect(exception.message, 'Wrong password');
    });

    test('toString includes message and filePath', () {
      const exception = PdfIncorrectPasswordException(
        filePath: '/path/to/encrypted.pdf',
      );

      final str = exception.toString();
      expect(str, contains('PdfIncorrectPasswordException'));
      expect(str, contains('Incorrect password'));
      expect(str, contains('/path/to/encrypted.pdf'));
    });
  });

  group('PdfRenderException', () {
    test('creates exception with message', () {
      const exception = PdfRenderException('Failed to render page');

      expect(exception.message, 'Failed to render page');
      expect(exception.pageIndex, isNull);
      expect(exception.cause, isNull);
    });

    test('creates exception with pageIndex', () {
      const exception = PdfRenderException(
        'Failed to render page',
        pageIndex: 5,
      );

      expect(exception.pageIndex, 5);
    });

    test('creates exception with cause', () {
      final cause = Exception('Graphics error');
      final exception = PdfRenderException(
        'Failed to render page',
        cause: cause,
      );

      expect(exception.cause, cause);
    });

    test('toString includes message and pageIndex', () {
      const exception = PdfRenderException(
        'Failed to render page',
        pageIndex: 5,
      );

      final str = exception.toString();
      expect(str, contains('PdfRenderException'));
      expect(str, contains('Failed to render page'));
      expect(str, contains('page: 5'));
    });

    test('toString without pageIndex', () {
      const exception = PdfRenderException('Failed to render page');

      final str = exception.toString();
      expect(str, contains('PdfRenderException'));
      expect(str, contains('Failed to render page'));
    });
  });

  group('PdfResourceNotFoundException', () {
    test('creates exception with resourceId', () {
      const exception = PdfResourceNotFoundException('font-123');

      expect(exception.resourceId, 'font-123');
      expect(exception.message, 'Resource not found: font-123');
    });

    test('toString includes resourceId', () {
      const exception = PdfResourceNotFoundException('image-456');

      final str = exception.toString();
      expect(str, contains('PdfResourceNotFoundException'));
      expect(str, contains('Resource not found: image-456'));
    });
  });

  group('PdfException hierarchy', () {
    test('all exceptions implement PdfException', () {
      const readException = PdfReadException('test');
      const parseException = PdfParseException('test');
      const passwordRequired = PdfPasswordRequiredException();
      const incorrectPassword = PdfIncorrectPasswordException();
      const renderException = PdfRenderException('test');
      const resourceNotFound = PdfResourceNotFoundException('test');

      expect(readException, isA<PdfException>());
      expect(parseException, isA<PdfException>());
      expect(passwordRequired, isA<PdfException>());
      expect(incorrectPassword, isA<PdfException>());
      expect(renderException, isA<PdfException>());
      expect(resourceNotFound, isA<PdfException>());
    });

    test('exceptions can be caught as PdfException', () {
      expect(
        () => throw const PdfReadException('test'),
        throwsA(isA<PdfException>()),
      );
      expect(
        () => throw const PdfParseException('test'),
        throwsA(isA<PdfException>()),
      );
      expect(
        () => throw const PdfPasswordRequiredException(),
        throwsA(isA<PdfException>()),
      );
      expect(
        () => throw const PdfIncorrectPasswordException(),
        throwsA(isA<PdfException>()),
      );
      expect(
        () => throw const PdfRenderException('test'),
        throwsA(isA<PdfException>()),
      );
      expect(
        () => throw const PdfResourceNotFoundException('test'),
        throwsA(isA<PdfException>()),
      );
    });
  });
}
