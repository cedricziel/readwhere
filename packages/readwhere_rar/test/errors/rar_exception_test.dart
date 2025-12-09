import 'package:readwhere_rar/src/errors/rar_exception.dart';
import 'package:test/test.dart';

void main() {
  group('RarException', () {
    test('all exception types implement Exception', () {
      // Test that all concrete exceptions can be used as exceptions
      final exceptions = <Exception>[
        RarReadException('test'),
        RarFormatException('test'),
        RarUnsupportedCompressionException('test',
            fileName: 'file', compressionMethod: 0x31),
        RarEncryptedArchiveException('test', isHeaderEncrypted: true),
        RarFileNotFoundException('test'),
        RarCrcException('test', expected: 0, actual: 1),
        RarVersionException('test', version: 5),
      ];
      expect(exceptions, hasLength(7));
      for (final e in exceptions) {
        expect(e.toString(), isNotEmpty);
      }
    });
  });

  group('RarReadException', () {
    test('creates with message only', () {
      final exception = RarReadException('Failed to read');
      expect(exception.message, equals('Failed to read'));
      expect(exception.filePath, isNull);
      expect(exception.cause, isNull);
      expect(exception.stackTrace, isNull);
    });

    test('creates with all parameters', () {
      final cause = Exception('underlying');
      final exception = RarReadException(
        'Failed to read',
        filePath: '/path/to/file.rar',
        cause: cause,
      );
      expect(exception.message, equals('Failed to read'));
      expect(exception.filePath, equals('/path/to/file.rar'));
      expect(exception.cause, equals(cause));
    });

    test('toString includes file path', () {
      final exception = RarReadException(
        'Failed to read',
        filePath: '/path/to/file.rar',
      );
      expect(exception.toString(), contains('Failed to read'));
      expect(exception.toString(), contains('/path/to/file.rar'));
    });
  });

  group('RarFormatException', () {
    test('creates with message only', () {
      final exception = RarFormatException('Invalid format');
      expect(exception.message, equals('Invalid format'));
      expect(exception.offset, isNull);
    });

    test('creates with offset', () {
      final exception = RarFormatException('Invalid format', offset: 100);
      expect(exception.message, equals('Invalid format'));
      expect(exception.offset, equals(100));
    });

    test('toString includes offset', () {
      final exception = RarFormatException('Invalid format', offset: 100);
      expect(exception.toString(), contains('Invalid format'));
      expect(exception.toString(), contains('100'));
    });
  });

  group('RarUnsupportedCompressionException', () {
    test('creates with required parameters', () {
      final exception = RarUnsupportedCompressionException(
        'Unsupported compression',
        fileName: 'test.jpg',
        compressionMethod: 0x33,
      );
      expect(exception.message, equals('Unsupported compression'));
      expect(exception.fileName, equals('test.jpg'));
      expect(exception.compressionMethod, equals(0x33));
      expect(exception.cause, isNull);
      expect(exception.stackTrace, isNull);
    });

    test('toString includes method in hex', () {
      final exception = RarUnsupportedCompressionException(
        'Unsupported',
        fileName: 'file.jpg',
        compressionMethod: 0x33,
      );
      expect(exception.toString(), contains('33'));
    });
  });

  group('RarEncryptedArchiveException', () {
    test('creates for header encryption', () {
      final exception = RarEncryptedArchiveException(
        'Headers encrypted',
        isHeaderEncrypted: true,
      );
      expect(exception.message, equals('Headers encrypted'));
      expect(exception.isHeaderEncrypted, isTrue);
    });

    test('creates for file encryption', () {
      final exception = RarEncryptedArchiveException(
        'File encrypted',
        isHeaderEncrypted: false,
      );
      expect(exception.message, equals('File encrypted'));
      expect(exception.isHeaderEncrypted, isFalse);
    });

    test('toString distinguishes encryption type', () {
      final headerException = RarEncryptedArchiveException(
        'test',
        isHeaderEncrypted: true,
      );
      final fileException = RarEncryptedArchiveException(
        'test',
        isHeaderEncrypted: false,
      );
      expect(headerException.toString(), contains('header'));
      expect(fileException.toString(), contains('file'));
    });
  });

  group('RarFileNotFoundException', () {
    test('creates with filename', () {
      final exception = RarFileNotFoundException('missing.jpg');
      expect(exception.fileName, equals('missing.jpg'));
      expect(exception.message, contains('missing.jpg'));
    });

    test('message indicates file not found', () {
      final exception = RarFileNotFoundException('test.txt');
      expect(exception.message.toLowerCase(), contains('not found'));
    });
  });

  group('RarCrcException', () {
    test('creates with all parameters', () {
      final exception = RarCrcException(
        'CRC mismatch',
        fileName: 'test.jpg',
        expected: 0x12345678,
        actual: 0x87654321,
      );
      expect(exception.message, equals('CRC mismatch'));
      expect(exception.fileName, equals('test.jpg'));
      expect(exception.expected, equals(0x12345678));
      expect(exception.actual, equals(0x87654321));
    });

    test('toString includes CRC values in hex', () {
      final exception = RarCrcException(
        'CRC mismatch',
        expected: 0xABCD,
        actual: 0x1234,
      );
      final str = exception.toString().toLowerCase();
      expect(str, contains('abcd'));
      expect(str, contains('1234'));
    });
  });

  group('RarVersionException', () {
    test('creates with version', () {
      final exception = RarVersionException(
        'Unsupported version',
        version: 5,
      );
      expect(exception.message, equals('Unsupported version'));
      expect(exception.version, equals(5));
    });

    test('toString includes version', () {
      final exception = RarVersionException('test', version: 5);
      expect(exception.toString(), contains('5'));
    });
  });

  group('Exception hierarchy', () {
    test('can pattern match on sealed class', () {
      RarException exception = RarFileNotFoundException('test');

      final result = switch (exception) {
        RarReadException() => 'read',
        RarFormatException() => 'format',
        RarUnsupportedCompressionException() => 'compression',
        RarEncryptedArchiveException() => 'encrypted',
        RarFileNotFoundException() => 'not found',
        RarCrcException() => 'crc',
        RarVersionException() => 'version',
      };

      expect(result, equals('not found'));
    });
  });
}
