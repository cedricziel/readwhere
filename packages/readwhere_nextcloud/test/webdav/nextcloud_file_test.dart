import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';

void main() {
  group('NextcloudFile', () {
    group('constructor', () {
      test('creates file with required parameters', () {
        const file = NextcloudFile(
          path: '/documents/test.txt',
          name: 'test.txt',
          isDirectory: false,
        );

        expect(file.path, '/documents/test.txt');
        expect(file.name, 'test.txt');
        expect(file.isDirectory, false);
        expect(file.size, isNull);
        expect(file.lastModified, isNull);
        expect(file.mimeType, isNull);
        expect(file.etag, isNull);
      });

      test('creates file with all parameters', () {
        final lastModified = DateTime(2024, 1, 15, 10, 30);
        final file = NextcloudFile(
          path: '/documents/book.epub',
          name: 'book.epub',
          isDirectory: false,
          size: 1024000,
          lastModified: lastModified,
          mimeType: 'application/epub+zip',
          etag: '"abc123"',
        );

        expect(file.path, '/documents/book.epub');
        expect(file.name, 'book.epub');
        expect(file.isDirectory, false);
        expect(file.size, 1024000);
        expect(file.lastModified, lastModified);
        expect(file.mimeType, 'application/epub+zip');
        expect(file.etag, '"abc123"');
      });

      test('creates directory', () {
        const dir = NextcloudFile(
          path: '/documents/',
          name: 'documents',
          isDirectory: true,
        );

        expect(dir.isDirectory, true);
      });
    });

    group('fromWebDavFile', () {
      test('creates NextcloudFile from WebDavFile', () {
        final webDavFile = WebDavFile(
          path: '/books/novel.epub',
          name: 'novel.epub',
          isDirectory: false,
          size: 512000,
          mimeType: 'application/epub+zip',
          etag: '"xyz789"',
        );

        final ncFile = NextcloudFile.fromWebDavFile(webDavFile);

        expect(ncFile.path, webDavFile.path);
        expect(ncFile.name, webDavFile.name);
        expect(ncFile.isDirectory, webDavFile.isDirectory);
        expect(ncFile.size, webDavFile.size);
        expect(ncFile.mimeType, webDavFile.mimeType);
        expect(ncFile.etag, webDavFile.etag);
        expect(ncFile, isA<NextcloudFile>());
      });

      test('preserves all properties from WebDavFile', () {
        final lastModified = DateTime(2024, 6, 1);
        final webDavFile = WebDavFile(
          path: '/docs/file.pdf',
          name: 'file.pdf',
          isDirectory: false,
          size: 2048,
          lastModified: lastModified,
          mimeType: 'application/pdf',
          etag: '"etag123"',
        );

        final ncFile = NextcloudFile.fromWebDavFile(webDavFile);

        expect(ncFile.lastModified, lastModified);
      });
    });

    group('isEpub', () {
      test('returns true for EPUB MIME type', () {
        const file = NextcloudFile(
          path: '/book.epub',
          name: 'book.epub',
          isDirectory: false,
          mimeType: 'application/epub+zip',
        );
        expect(file.isEpub, true);
      });

      test('returns true for .epub extension', () {
        const file = NextcloudFile(
          path: '/book.epub',
          name: 'book.epub',
          isDirectory: false,
        );
        expect(file.isEpub, true);
      });

      test('returns true for uppercase .EPUB extension', () {
        const file = NextcloudFile(
          path: '/BOOK.EPUB',
          name: 'BOOK.EPUB',
          isDirectory: false,
        );
        expect(file.isEpub, true);
      });

      test('returns false for non-EPUB file', () {
        const file = NextcloudFile(
          path: '/document.pdf',
          name: 'document.pdf',
          isDirectory: false,
          mimeType: 'application/pdf',
        );
        expect(file.isEpub, false);
      });

      test('returns false for directory', () {
        const file = NextcloudFile(
          path: '/epubs/',
          name: 'epubs',
          isDirectory: true,
        );
        expect(file.isEpub, false);
      });
    });

    group('isPdf', () {
      test('returns true for PDF MIME type', () {
        const file = NextcloudFile(
          path: '/doc.pdf',
          name: 'doc.pdf',
          isDirectory: false,
          mimeType: 'application/pdf',
        );
        expect(file.isPdf, true);
      });

      test('returns true for .pdf extension', () {
        const file = NextcloudFile(
          path: '/doc.pdf',
          name: 'doc.pdf',
          isDirectory: false,
        );
        expect(file.isPdf, true);
      });

      test('returns true for uppercase .PDF extension', () {
        const file = NextcloudFile(
          path: '/DOC.PDF',
          name: 'DOC.PDF',
          isDirectory: false,
        );
        expect(file.isPdf, true);
      });

      test('returns false for non-PDF file', () {
        const file = NextcloudFile(
          path: '/book.epub',
          name: 'book.epub',
          isDirectory: false,
        );
        expect(file.isPdf, false);
      });
    });

    group('isComic', () {
      test('returns true for .cbz extension', () {
        const file = NextcloudFile(
          path: '/comic.cbz',
          name: 'comic.cbz',
          isDirectory: false,
        );
        expect(file.isComic, true);
      });

      test('returns true for .cbr extension', () {
        const file = NextcloudFile(
          path: '/comic.cbr',
          name: 'comic.cbr',
          isDirectory: false,
        );
        expect(file.isComic, true);
      });

      test('returns true for uppercase .CBZ extension', () {
        const file = NextcloudFile(
          path: '/COMIC.CBZ',
          name: 'COMIC.CBZ',
          isDirectory: false,
        );
        expect(file.isComic, true);
      });

      test('returns true for uppercase .CBR extension', () {
        const file = NextcloudFile(
          path: '/COMIC.CBR',
          name: 'COMIC.CBR',
          isDirectory: false,
        );
        expect(file.isComic, true);
      });

      test('returns false for non-comic file', () {
        const file = NextcloudFile(
          path: '/book.epub',
          name: 'book.epub',
          isDirectory: false,
        );
        expect(file.isComic, false);
      });
    });

    group('isSupportedBook', () {
      test('returns true for EPUB', () {
        const file = NextcloudFile(
          path: '/book.epub',
          name: 'book.epub',
          isDirectory: false,
        );
        expect(file.isSupportedBook, true);
      });

      test('returns true for PDF', () {
        const file = NextcloudFile(
          path: '/doc.pdf',
          name: 'doc.pdf',
          isDirectory: false,
        );
        expect(file.isSupportedBook, true);
      });

      test('returns true for CBZ', () {
        const file = NextcloudFile(
          path: '/comic.cbz',
          name: 'comic.cbz',
          isDirectory: false,
        );
        expect(file.isSupportedBook, true);
      });

      test('returns true for CBR', () {
        const file = NextcloudFile(
          path: '/comic.cbr',
          name: 'comic.cbr',
          isDirectory: false,
        );
        expect(file.isSupportedBook, true);
      });

      test('returns false for unsupported format', () {
        const file = NextcloudFile(
          path: '/image.jpg',
          name: 'image.jpg',
          isDirectory: false,
        );
        expect(file.isSupportedBook, false);
      });

      test('returns false for directory', () {
        const file = NextcloudFile(
          path: '/books/',
          name: 'books',
          isDirectory: true,
        );
        expect(file.isSupportedBook, false);
      });

      test('returns false for text file', () {
        const file = NextcloudFile(
          path: '/readme.txt',
          name: 'readme.txt',
          isDirectory: false,
        );
        expect(file.isSupportedBook, false);
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        const original = NextcloudFile(
          path: '/test.epub',
          name: 'test.epub',
          isDirectory: false,
          size: 100,
        );

        final copied = original.copyWith(
          size: 200,
          etag: '"new-etag"',
        );

        expect(copied.path, '/test.epub');
        expect(copied.name, 'test.epub');
        expect(copied.isDirectory, false);
        expect(copied.size, 200);
        expect(copied.etag, '"new-etag"');
        expect(copied, isA<NextcloudFile>());
      });

      test('preserves original values when not specified', () {
        final lastModified = DateTime(2024, 1, 15);
        final original = NextcloudFile(
          path: '/book.epub',
          name: 'book.epub',
          isDirectory: false,
          size: 1000,
          lastModified: lastModified,
          mimeType: 'application/epub+zip',
          etag: '"abc"',
        );

        final copied = original.copyWith();

        expect(copied.path, original.path);
        expect(copied.name, original.name);
        expect(copied.isDirectory, original.isDirectory);
        expect(copied.size, original.size);
        expect(copied.lastModified, original.lastModified);
        expect(copied.mimeType, original.mimeType);
        expect(copied.etag, original.etag);
      });

      test('returns NextcloudFile type', () {
        const original = NextcloudFile(
          path: '/test.pdf',
          name: 'test.pdf',
          isDirectory: false,
        );

        final copied = original.copyWith(size: 500);

        expect(copied, isA<NextcloudFile>());
        expect(copied.isPdf, true);
      });
    });

    group('inherits WebDavFile', () {
      test('extension getter works', () {
        const file = NextcloudFile(
          path: '/book.epub',
          name: 'book.EPUB',
          isDirectory: false,
        );
        expect(file.extension, 'epub');
      });

      test('parentPath getter works', () {
        const file = NextcloudFile(
          path: '/documents/books/novel.epub',
          name: 'novel.epub',
          isDirectory: false,
        );
        expect(file.parentPath, '/documents/books');
      });
    });
  });
}
