import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/core/utils/file_utils.dart';

void main() {
  group('FileUtils', () {
    group('getFileExtension', () {
      test('returns extension without dot', () {
        expect(
          FileUtils.getFileExtension('/path/to/book.epub'),
          equals('epub'),
        );
      });

      test('returns lowercase extension', () {
        expect(
          FileUtils.getFileExtension('/path/to/book.EPUB'),
          equals('epub'),
        );
      });

      test('returns empty string for no extension', () {
        expect(FileUtils.getFileExtension('/path/to/file'), equals(''));
      });

      test('handles double extensions', () {
        expect(
          FileUtils.getFileExtension('/path/to/file.tar.gz'),
          equals('gz'),
        );
      });

      test('handles hidden files with extension', () {
        expect(
          FileUtils.getFileExtension('/path/to/.hidden.txt'),
          equals('txt'),
        );
      });

      test('handles filename only', () {
        expect(FileUtils.getFileExtension('book.pdf'), equals('pdf'));
      });

      test('handles extension only filename', () {
        expect(FileUtils.getFileExtension('.gitignore'), equals(''));
      });
    });

    group('isSupportedFormat', () {
      test('returns true for epub', () {
        expect(FileUtils.isSupportedFormat('/path/to/book.epub'), isTrue);
      });

      test('returns true for EPUB uppercase', () {
        expect(FileUtils.isSupportedFormat('/path/to/book.EPUB'), isTrue);
      });

      test('returns false for unsupported format', () {
        expect(FileUtils.isSupportedFormat('/path/to/book.xyz'), isFalse);
      });

      test('returns false for no extension', () {
        expect(FileUtils.isSupportedFormat('/path/to/file'), isFalse);
      });
    });

    group('formatFileSize', () {
      test('formats bytes', () {
        expect(FileUtils.formatFileSize(500), equals('500 B'));
      });

      test('formats kilobytes', () {
        expect(FileUtils.formatFileSize(1024), equals('1.0 KB'));
      });

      test('formats kilobytes with decimal', () {
        expect(FileUtils.formatFileSize(1536), equals('1.5 KB'));
      });

      test('formats megabytes', () {
        expect(FileUtils.formatFileSize(1024 * 1024), equals('1.0 MB'));
      });

      test('formats megabytes with decimal', () {
        expect(FileUtils.formatFileSize(1572864), equals('1.5 MB'));
      });

      test('formats gigabytes', () {
        expect(FileUtils.formatFileSize(1024 * 1024 * 1024), equals('1.0 GB'));
      });

      test('formats zero bytes', () {
        expect(FileUtils.formatFileSize(0), equals('0 B'));
      });

      test('formats 1023 bytes as bytes', () {
        expect(FileUtils.formatFileSize(1023), equals('1023 B'));
      });
    });

    // Note: The following tests require file system access which would be
    // integration tests. For unit tests, we test the pure functions above.
    // Integration tests for getAppDocumentsDirectory, getBooksDirectory,
    // getCoversDirectory, getTempDirectory, copyFileToAppStorage, deleteFile,
    // getFileSize, and cleanupTempFiles would be in a separate integration
    // test file using actual file system operations.
  });
}
