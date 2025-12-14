import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_synology/readwhere_synology.dart';

void main() {
  group('SynologyFile', () {
    test('fromJson parses directory correctly', () {
      final json = {
        'file_id': '123',
        'name': 'Books',
        'path': '/mydrive/Books',
        'display_path': '/mydrive/Books',
        'type': 'dir',
        'content_type': 'dir',
        'modified_time': 1700000000,
        'created_time': 1699000000,
      };

      final file = SynologyFile.fromJson(json);

      expect(file.fileId, equals('123'));
      expect(file.name, equals('Books'));
      expect(file.path, equals('/mydrive/Books'));
      expect(file.isDirectory, isTrue);
      expect(file.modifiedTime, isNotNull);
      expect(file.createdTime, isNotNull);
    });

    test('fromJson parses file correctly', () {
      final json = {
        'file_id': '456',
        'name': 'book.epub',
        'path': '/mydrive/Books/book.epub',
        'display_path': '/mydrive/Books/book.epub',
        'type': 'file',
        'content_type': 'document',
        'size': 1024000,
        'hash': 'abc123',
        'parent_id': '123',
        'starred': true,
        'shared': false,
        'encrypted': false,
      };

      final file = SynologyFile.fromJson(json);

      expect(file.fileId, equals('456'));
      expect(file.name, equals('book.epub'));
      expect(file.isDirectory, isFalse);
      expect(file.size, equals(1024000));
      expect(file.hash, equals('abc123'));
      expect(file.parentId, equals('123'));
      expect(file.isStarred, isTrue);
      expect(file.isShared, isFalse);
      expect(file.isEncrypted, isFalse);
    });

    group('extension detection', () {
      test('extracts extension correctly', () {
        const file = SynologyFile(
          fileId: '1',
          name: 'book.EPUB',
          path: '/mydrive/book.EPUB',
          displayPath: '/mydrive/book.EPUB',
          type: 'file',
        );

        expect(file.extension, equals('epub'));
      });

      test('returns empty for no extension', () {
        const file = SynologyFile(
          fileId: '1',
          name: 'readme',
          path: '/mydrive/readme',
          displayPath: '/mydrive/readme',
          type: 'file',
        );

        expect(file.extension, isEmpty);
      });

      test('handles dot at end of filename', () {
        const file = SynologyFile(
          fileId: '1',
          name: 'file.',
          path: '/mydrive/file.',
          displayPath: '/mydrive/file.',
          type: 'file',
        );

        expect(file.extension, isEmpty);
      });
    });

    group('format detection', () {
      test('isEpub returns true for epub files', () {
        const file = SynologyFile(
          fileId: '1',
          name: 'book.epub',
          path: '/mydrive/book.epub',
          displayPath: '/mydrive/book.epub',
          type: 'file',
        );

        expect(file.isEpub, isTrue);
        expect(file.isPdf, isFalse);
        expect(file.isComic, isFalse);
        expect(file.isSupportedBook, isTrue);
      });

      test('isPdf returns true for pdf files', () {
        const file = SynologyFile(
          fileId: '1',
          name: 'document.pdf',
          path: '/mydrive/document.pdf',
          displayPath: '/mydrive/document.pdf',
          type: 'file',
        );

        expect(file.isEpub, isFalse);
        expect(file.isPdf, isTrue);
        expect(file.isComic, isFalse);
        expect(file.isSupportedBook, isTrue);
      });

      test('isComic returns true for cbz files', () {
        const file = SynologyFile(
          fileId: '1',
          name: 'comic.cbz',
          path: '/mydrive/comic.cbz',
          displayPath: '/mydrive/comic.cbz',
          type: 'file',
        );

        expect(file.isEpub, isFalse);
        expect(file.isPdf, isFalse);
        expect(file.isCbz, isTrue);
        expect(file.isCbr, isFalse);
        expect(file.isComic, isTrue);
        expect(file.isSupportedBook, isTrue);
      });

      test('isComic returns true for cbr files', () {
        const file = SynologyFile(
          fileId: '1',
          name: 'comic.cbr',
          path: '/mydrive/comic.cbr',
          displayPath: '/mydrive/comic.cbr',
          type: 'file',
        );

        expect(file.isCbz, isFalse);
        expect(file.isCbr, isTrue);
        expect(file.isComic, isTrue);
        expect(file.isSupportedBook, isTrue);
      });

      test('isSupportedBook returns false for unsupported formats', () {
        const file = SynologyFile(
          fileId: '1',
          name: 'image.jpg',
          path: '/mydrive/image.jpg',
          displayPath: '/mydrive/image.jpg',
          type: 'file',
        );

        expect(file.isEpub, isFalse);
        expect(file.isPdf, isFalse);
        expect(file.isComic, isFalse);
        expect(file.isSupportedBook, isFalse);
      });
    });

    group('mimeType', () {
      test('returns correct mime types', () {
        expect(
          const SynologyFile(
            fileId: '1',
            name: 'book.epub',
            path: '/path',
            displayPath: '/path',
            type: 'file',
          ).mimeType,
          equals('application/epub+zip'),
        );

        expect(
          const SynologyFile(
            fileId: '1',
            name: 'doc.pdf',
            path: '/path',
            displayPath: '/path',
            type: 'file',
          ).mimeType,
          equals('application/pdf'),
        );

        expect(
          const SynologyFile(
            fileId: '1',
            name: 'comic.cbz',
            path: '/path',
            displayPath: '/path',
            type: 'file',
          ).mimeType,
          equals('application/vnd.comicbook+zip'),
        );

        expect(
          const SynologyFile(
            fileId: '1',
            name: 'comic.cbr',
            path: '/path',
            displayPath: '/path',
            type: 'file',
          ).mimeType,
          equals('application/vnd.comicbook-rar'),
        );

        expect(
          const SynologyFile(
            fileId: '1',
            name: 'folder',
            path: '/path',
            displayPath: '/path',
            type: 'dir',
          ).mimeType,
          equals('inode/directory'),
        );
      });
    });

    group('formattedSize', () {
      test('formats bytes correctly', () {
        expect(
          const SynologyFile(
            fileId: '1',
            name: 'f',
            path: '/p',
            displayPath: '/p',
            type: 'file',
            size: 500,
          ).formattedSize,
          equals('500 B'),
        );
      });

      test('formats kilobytes correctly', () {
        expect(
          const SynologyFile(
            fileId: '1',
            name: 'f',
            path: '/p',
            displayPath: '/p',
            type: 'file',
            size: 2048,
          ).formattedSize,
          equals('2.0 KB'),
        );
      });

      test('formats megabytes correctly', () {
        expect(
          const SynologyFile(
            fileId: '1',
            name: 'f',
            path: '/p',
            displayPath: '/p',
            type: 'file',
            size: 5242880,
          ).formattedSize,
          equals('5.0 MB'),
        );
      });

      test('formats gigabytes correctly', () {
        expect(
          const SynologyFile(
            fileId: '1',
            name: 'f',
            path: '/p',
            displayPath: '/p',
            type: 'file',
            size: 2147483648,
          ).formattedSize,
          equals('2.00 GB'),
        );
      });

      test('returns empty for null size', () {
        expect(
          const SynologyFile(
            fileId: '1',
            name: 'f',
            path: '/p',
            displayPath: '/p',
            type: 'file',
          ).formattedSize,
          isEmpty,
        );
      });
    });

    test('equality works correctly', () {
      const file1 = SynologyFile(
        fileId: '123',
        name: 'test.epub',
        path: '/mydrive/test.epub',
        displayPath: '/mydrive/test.epub',
        type: 'file',
      );
      const file2 = SynologyFile(
        fileId: '123',
        name: 'test.epub',
        path: '/mydrive/test.epub',
        displayPath: '/mydrive/test.epub',
        type: 'file',
      );
      const file3 = SynologyFile(
        fileId: '456',
        name: 'other.epub',
        path: '/mydrive/other.epub',
        displayPath: '/mydrive/other.epub',
        type: 'file',
      );

      expect(file1, equals(file2));
      expect(file1, isNot(equals(file3)));
    });
  });
}
