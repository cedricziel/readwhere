import 'package:readwhere_webdav/readwhere_webdav.dart';
import 'package:test/test.dart';

void main() {
  group('WebDavFile', () {
    group('constructor', () {
      test('creates file with required parameters', () {
        final file = WebDavFile(
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
        final file = WebDavFile(
          path: '/documents/test.pdf',
          name: 'test.pdf',
          isDirectory: false,
          size: 1024,
          lastModified: lastModified,
          mimeType: 'application/pdf',
          etag: '"abc123"',
        );

        expect(file.path, '/documents/test.pdf');
        expect(file.name, 'test.pdf');
        expect(file.isDirectory, false);
        expect(file.size, 1024);
        expect(file.lastModified, lastModified);
        expect(file.mimeType, 'application/pdf');
        expect(file.etag, '"abc123"');
      });

      test('creates directory', () {
        final dir = WebDavFile(
          path: '/documents/folder/',
          name: 'folder',
          isDirectory: true,
        );

        expect(dir.path, '/documents/folder/');
        expect(dir.name, 'folder');
        expect(dir.isDirectory, true);
      });
    });

    group('extension', () {
      test('returns lowercase extension without dot', () {
        final file = WebDavFile(
          path: '/test.PDF',
          name: 'test.PDF',
          isDirectory: false,
        );
        expect(file.extension, 'pdf');
      });

      test('returns null for no extension', () {
        final file = WebDavFile(
          path: '/README',
          name: 'README',
          isDirectory: false,
        );
        expect(file.extension, isNull);
      });

      test('handles multiple dots correctly', () {
        final file = WebDavFile(
          path: '/archive.tar.gz',
          name: 'archive.tar.gz',
          isDirectory: false,
        );
        expect(file.extension, 'gz');
      });

      test('returns null for directories', () {
        final dir = WebDavFile(
          path: '/folder/',
          name: 'folder',
          isDirectory: true,
        );
        expect(dir.extension, isNull);
      });

      test('handles hidden files with extension', () {
        final file = WebDavFile(
          path: '/.gitignore',
          name: '.gitignore',
          isDirectory: false,
        );
        expect(file.extension, 'gitignore');
      });
    });

    group('parentPath', () {
      test('returns parent directory path', () {
        final file = WebDavFile(
          path: '/documents/folder/test.txt',
          name: 'test.txt',
          isDirectory: false,
        );
        expect(file.parentPath, '/documents/folder');
      });

      test('returns root for top-level file', () {
        final file = WebDavFile(
          path: '/test.txt',
          name: 'test.txt',
          isDirectory: false,
        );
        expect(file.parentPath, '/');
      });

      test('handles trailing slash in path', () {
        // Note: parentPath doesn't strip trailing slashes - it finds the last /
        // For '/documents/folder/', the last slash is at the end, so parent is '/documents/folder'
        final dir = WebDavFile(
          path: '/documents/folder/',
          name: 'folder',
          isDirectory: true,
        );
        expect(dir.parentPath, '/documents/folder');
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final original = WebDavFile(
          path: '/test.txt',
          name: 'test.txt',
          isDirectory: false,
          size: 100,
        );

        final copied = original.copyWith(
          size: 200,
          etag: '"new-etag"',
        );

        expect(copied.path, '/test.txt');
        expect(copied.name, 'test.txt');
        expect(copied.isDirectory, false);
        expect(copied.size, 200);
        expect(copied.etag, '"new-etag"');
      });

      test('preserves original values when not specified', () {
        final lastModified = DateTime(2024, 1, 15);
        final original = WebDavFile(
          path: '/test.txt',
          name: 'test.txt',
          isDirectory: false,
          size: 100,
          lastModified: lastModified,
          mimeType: 'text/plain',
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
    });

    group('equality', () {
      test('equal files have same props', () {
        final file1 = WebDavFile(
          path: '/test.txt',
          name: 'test.txt',
          isDirectory: false,
          size: 100,
        );
        final file2 = WebDavFile(
          path: '/test.txt',
          name: 'test.txt',
          isDirectory: false,
          size: 100,
        );

        expect(file1, equals(file2));
        expect(file1.hashCode, file2.hashCode);
      });

      test('different files are not equal', () {
        final file1 = WebDavFile(
          path: '/test1.txt',
          name: 'test1.txt',
          isDirectory: false,
        );
        final file2 = WebDavFile(
          path: '/test2.txt',
          name: 'test2.txt',
          isDirectory: false,
        );

        expect(file1, isNot(equals(file2)));
      });
    });
  });
}
