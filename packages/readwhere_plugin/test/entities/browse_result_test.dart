import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:test/test.dart';

void main() {
  group('BrowseResult', () {
    group('constructor', () {
      test('creates result with entries', () {
        final entries = [
          const DefaultCatalogEntry(
            id: '1',
            title: 'Test Book',
            type: CatalogEntryType.book,
          ),
        ];
        final result = BrowseResult(entries: entries);

        expect(result.entries.length, 1);
        expect(result.entries.first.title, 'Test Book');
        expect(result.title, isNull);
        expect(result.page, isNull);
        expect(result.hasNextPage, false);
      });

      test('creates result with all parameters', () {
        final searchLinks = [const CatalogLink(href: '/search', rel: 'search')];
        final result = BrowseResult(
          entries: const [],
          title: 'My Library',
          page: 2,
          totalPages: 5,
          totalEntries: 100,
          hasNextPage: true,
          hasPreviousPage: true,
          nextPageUrl: '/page/3',
          previousPageUrl: '/page/1',
          searchLinks: searchLinks,
        );

        expect(result.title, 'My Library');
        expect(result.page, 2);
        expect(result.totalPages, 5);
        expect(result.totalEntries, 100);
        expect(result.hasNextPage, true);
        expect(result.hasPreviousPage, true);
        expect(result.nextPageUrl, '/page/3');
        expect(result.previousPageUrl, '/page/1');
        expect(result.searchLinks.length, 1);
      });
    });

    group('BrowseResult.empty', () {
      test('creates empty result', () {
        const result = BrowseResult.empty();

        expect(result.isEmpty, true);
        expect(result.isNotEmpty, false);
        expect(result.length, 0);
        expect(result.entries, isEmpty);
        expect(result.hasNextPage, false);
        expect(result.hasPreviousPage, false);
        expect(result.searchLinks, isEmpty);
      });
    });

    group('isEmpty/isNotEmpty', () {
      test('isEmpty is true for empty entries', () {
        const result = BrowseResult(entries: []);
        expect(result.isEmpty, true);
        expect(result.isNotEmpty, false);
      });

      test('isNotEmpty is true when entries exist', () {
        const result = BrowseResult(
          entries: [
            DefaultCatalogEntry(
              id: '1',
              title: 'Book',
              type: CatalogEntryType.book,
            ),
          ],
        );
        expect(result.isEmpty, false);
        expect(result.isNotEmpty, true);
      });
    });

    group('isPaginated', () {
      test('returns true when hasNextPage', () {
        const result = BrowseResult(entries: [], hasNextPage: true);
        expect(result.isPaginated, true);
      });

      test('returns true when hasPreviousPage', () {
        const result = BrowseResult(entries: [], hasPreviousPage: true);
        expect(result.isPaginated, true);
      });

      test('returns true when page is set', () {
        const result = BrowseResult(entries: [], page: 1);
        expect(result.isPaginated, true);
      });

      test('returns false when not paginated', () {
        const result = BrowseResult(entries: []);
        expect(result.isPaginated, false);
      });
    });

    group('hasSearch', () {
      test('returns true when search links exist', () {
        const result = BrowseResult(
          entries: [],
          searchLinks: [CatalogLink(href: '/search', rel: 'search')],
        );
        expect(result.hasSearch, true);
      });

      test('returns false when no search links', () {
        const result = BrowseResult(entries: []);
        expect(result.hasSearch, false);
      });
    });

    group('copyWith', () {
      test('copies with new entries', () {
        const original = BrowseResult(entries: [], title: 'Original', page: 1);

        final copied = original.copyWith(
          entries: const [
            DefaultCatalogEntry(
              id: '1',
              title: 'New',
              type: CatalogEntryType.book,
            ),
          ],
        );

        expect(copied.entries.length, 1);
        expect(copied.title, 'Original'); // preserved
        expect(copied.page, 1); // preserved
      });

      test('preserves all values when no changes', () {
        final searchLinks = [const CatalogLink(href: '/search', rel: 'search')];
        final original = BrowseResult(
          entries: const [],
          title: 'Library',
          page: 2,
          totalPages: 10,
          totalEntries: 200,
          hasNextPage: true,
          hasPreviousPage: true,
          nextPageUrl: '/next',
          previousPageUrl: '/prev',
          searchLinks: searchLinks,
        );

        final copied = original.copyWith();

        expect(copied.title, original.title);
        expect(copied.page, original.page);
        expect(copied.totalPages, original.totalPages);
        expect(copied.totalEntries, original.totalEntries);
        expect(copied.hasNextPage, original.hasNextPage);
        expect(copied.hasPreviousPage, original.hasPreviousPage);
        expect(copied.nextPageUrl, original.nextPageUrl);
        expect(copied.previousPageUrl, original.previousPageUrl);
        expect(copied.searchLinks, original.searchLinks);
      });
    });

    group('equality', () {
      test('equal results are equal', () {
        const result1 = BrowseResult(
          entries: [
            DefaultCatalogEntry(
              id: '1',
              title: 'Book',
              type: CatalogEntryType.book,
            ),
          ],
          page: 1,
        );
        const result2 = BrowseResult(
          entries: [
            DefaultCatalogEntry(
              id: '1',
              title: 'Book',
              type: CatalogEntryType.book,
            ),
          ],
          page: 1,
        );

        expect(result1, equals(result2));
        expect(result1.hashCode, result2.hashCode);
      });

      test('different results are not equal', () {
        const result1 = BrowseResult(entries: [], page: 1);
        const result2 = BrowseResult(entries: [], page: 2);

        expect(result1, isNot(equals(result2)));
      });
    });
  });

  group('CatalogFile', () {
    group('constructor', () {
      test('creates file with required parameters', () {
        const file = CatalogFile(
          href: 'https://example.com/book.epub',
          mimeType: 'application/epub+zip',
        );

        expect(file.href, 'https://example.com/book.epub');
        expect(file.mimeType, 'application/epub+zip');
        expect(file.size, isNull);
        expect(file.title, isNull);
        expect(file.isPrimary, false);
      });

      test('creates file with all parameters', () {
        const file = CatalogFile(
          href: 'https://example.com/book.epub',
          mimeType: 'application/epub+zip',
          size: 1024000,
          title: 'EPUB Version',
          isPrimary: true,
        );

        expect(file.size, 1024000);
        expect(file.title, 'EPUB Version');
        expect(file.isPrimary, true);
      });
    });

    group('extension', () {
      test('returns extension from MIME type', () {
        const file = CatalogFile(
          href: '/file',
          mimeType: 'application/epub+zip',
        );
        expect(file.extension, 'epub');
      });

      test('returns extension from href when MIME unknown', () {
        const file = CatalogFile(
          href: 'https://example.com/book.epub',
          mimeType: 'application/octet-stream',
        );
        expect(file.extension, 'epub');
      });

      test('returns null for unknown extension', () {
        const file = CatalogFile(
          href: '/file',
          mimeType: 'application/octet-stream',
        );
        expect(file.extension, isNull);
      });
    });

    group('isEpub', () {
      test('returns true for EPUB MIME type', () {
        const file = CatalogFile(
          href: '/book',
          mimeType: 'application/epub+zip',
        );
        expect(file.isEpub, true);
      });

      test('returns true for .epub extension', () {
        const file = CatalogFile(
          href: '/book.epub',
          mimeType: 'application/octet-stream',
        );
        expect(file.isEpub, true);
      });

      test('returns false for non-EPUB', () {
        const file = CatalogFile(href: '/doc.pdf', mimeType: 'application/pdf');
        expect(file.isEpub, false);
      });
    });

    group('isPdf', () {
      test('returns true for PDF MIME type', () {
        const file = CatalogFile(href: '/doc', mimeType: 'application/pdf');
        expect(file.isPdf, true);
      });

      test('returns true for .pdf extension', () {
        const file = CatalogFile(
          href: '/doc.pdf',
          mimeType: 'application/octet-stream',
        );
        expect(file.isPdf, true);
      });
    });

    group('isComic', () {
      test('returns true for .cbz', () {
        const file = CatalogFile(
          href: '/comic.cbz',
          mimeType: 'application/octet-stream',
        );
        expect(file.isComic, true);
      });

      test('returns true for .cbr', () {
        const file = CatalogFile(
          href: '/comic.cbr',
          mimeType: 'application/octet-stream',
        );
        expect(file.isComic, true);
      });

      test('returns false for non-comic', () {
        const file = CatalogFile(
          href: '/book.epub',
          mimeType: 'application/epub+zip',
        );
        expect(file.isComic, false);
      });
    });

    group('equality', () {
      test('equal files are equal', () {
        const file1 = CatalogFile(
          href: '/book.epub',
          mimeType: 'application/epub+zip',
          size: 1024,
        );
        const file2 = CatalogFile(
          href: '/book.epub',
          mimeType: 'application/epub+zip',
          size: 1024,
        );

        expect(file1, equals(file2));
        expect(file1.hashCode, file2.hashCode);
      });
    });
  });

  group('CatalogLink', () {
    test('creates link with required parameters', () {
      const link = CatalogLink(href: '/browse');

      expect(link.href, '/browse');
      expect(link.title, isNull);
      expect(link.rel, isNull);
      expect(link.type, isNull);
    });

    test('creates link with all parameters', () {
      const link = CatalogLink(
        href: '/search',
        title: 'Search',
        rel: 'search',
        type: 'application/opensearchdescription+xml',
      );

      expect(link.href, '/search');
      expect(link.title, 'Search');
      expect(link.rel, 'search');
      expect(link.type, 'application/opensearchdescription+xml');
    });

    group('isNavigation', () {
      test('returns true when rel is null', () {
        const link = CatalogLink(href: '/browse');
        expect(link.isNavigation, true);
      });

      test('returns false for acquisition link', () {
        const link = CatalogLink(
          href: '/download',
          rel: 'http://opds-spec.org/acquisition',
        );
        expect(link.isNavigation, false);
      });
    });

    group('isSearch', () {
      test('returns true for search rel', () {
        const link = CatalogLink(href: '/search', rel: 'search');
        expect(link.isSearch, true);
      });

      test('returns false for other rel', () {
        const link = CatalogLink(href: '/browse', rel: 'subsection');
        expect(link.isSearch, false);
      });
    });

    group('isPagination', () {
      test('returns true for next', () {
        const link = CatalogLink(href: '/page/2', rel: 'next');
        expect(link.isPagination, true);
        expect(link.isNext, true);
        expect(link.isPrevious, false);
      });

      test('returns true for previous', () {
        const link = CatalogLink(href: '/page/1', rel: 'previous');
        expect(link.isPagination, true);
        expect(link.isNext, false);
        expect(link.isPrevious, true);
      });
    });

    group('equality', () {
      test('equal links are equal', () {
        const link1 = CatalogLink(href: '/search', rel: 'search');
        const link2 = CatalogLink(href: '/search', rel: 'search');

        expect(link1, equals(link2));
        expect(link1.hashCode, link2.hashCode);
      });
    });
  });

  group('DefaultCatalogEntry', () {
    test('creates entry with required parameters', () {
      const entry = DefaultCatalogEntry(
        id: '1',
        title: 'Test Book',
        type: CatalogEntryType.book,
      );

      expect(entry.id, '1');
      expect(entry.title, 'Test Book');
      expect(entry.type, CatalogEntryType.book);
      expect(entry.subtitle, isNull);
      expect(entry.summary, isNull);
      expect(entry.thumbnailUrl, isNull);
      expect(entry.files, isEmpty);
      expect(entry.links, isEmpty);
    });

    test('creates entry with all parameters', () {
      const entry = DefaultCatalogEntry(
        id: '1',
        title: 'Test Book',
        type: CatalogEntryType.book,
        subtitle: 'By Author',
        summary: 'A great book',
        thumbnailUrl: '/cover.jpg',
        files: [
          CatalogFile(href: '/book.epub', mimeType: 'application/epub+zip'),
        ],
        links: [CatalogLink(href: '/more', rel: 'related')],
      );

      expect(entry.subtitle, 'By Author');
      expect(entry.summary, 'A great book');
      expect(entry.thumbnailUrl, '/cover.jpg');
      expect(entry.files.length, 1);
      expect(entry.links.length, 1);
    });

    group('primaryFile', () {
      test('returns primary file when marked', () {
        const entry = DefaultCatalogEntry(
          id: '1',
          title: 'Book',
          type: CatalogEntryType.book,
          files: [
            CatalogFile(href: '/book.pdf', mimeType: 'application/pdf'),
            CatalogFile(
              href: '/book.epub',
              mimeType: 'application/epub+zip',
              isPrimary: true,
            ),
          ],
        );

        expect(entry.primaryFile?.mimeType, 'application/epub+zip');
      });

      test('returns first file when none marked primary', () {
        const entry = DefaultCatalogEntry(
          id: '1',
          title: 'Book',
          type: CatalogEntryType.book,
          files: [
            CatalogFile(href: '/book.pdf', mimeType: 'application/pdf'),
            CatalogFile(href: '/book.epub', mimeType: 'application/epub+zip'),
          ],
        );

        expect(entry.primaryFile?.mimeType, 'application/pdf');
      });

      test('returns null when no files', () {
        const entry = DefaultCatalogEntry(
          id: '1',
          title: 'Book',
          type: CatalogEntryType.book,
        );

        expect(entry.primaryFile, isNull);
      });
    });

    group('hasFiles', () {
      test('returns true when files exist', () {
        const entry = DefaultCatalogEntry(
          id: '1',
          title: 'Book',
          type: CatalogEntryType.book,
          files: [
            CatalogFile(href: '/book.epub', mimeType: 'application/epub+zip'),
          ],
        );

        expect(entry.hasFiles, true);
      });

      test('returns false when no files', () {
        const entry = DefaultCatalogEntry(
          id: '1',
          title: 'Book',
          type: CatalogEntryType.book,
        );

        expect(entry.hasFiles, false);
      });
    });

    group('isBrowsable', () {
      test('returns true for collection', () {
        const entry = DefaultCatalogEntry(
          id: '1',
          title: 'Collection',
          type: CatalogEntryType.collection,
        );

        expect(entry.isBrowsable, true);
      });

      test('returns true for navigation', () {
        const entry = DefaultCatalogEntry(
          id: '1',
          title: 'Nav',
          type: CatalogEntryType.navigation,
        );

        expect(entry.isBrowsable, true);
      });

      test('returns false for book', () {
        const entry = DefaultCatalogEntry(
          id: '1',
          title: 'Book',
          type: CatalogEntryType.book,
        );

        expect(entry.isBrowsable, false);
      });
    });
  });

  group('ValidationResult', () {
    test('success creates valid result', () {
      const result = ValidationResult.success(
        serverName: 'Test Server',
        serverVersion: '1.0.0',
      );

      expect(result.isValid, true);
      expect(result.isInvalid, false);
      expect(result.serverName, 'Test Server');
      expect(result.serverVersion, '1.0.0');
      expect(result.error, isNull);
      expect(result.errorCode, isNull);
    });

    test('failure creates invalid result', () {
      const result = ValidationResult.failure(
        error: 'Connection failed',
        errorCode: 'connection_failed',
      );

      expect(result.isValid, false);
      expect(result.isInvalid, true);
      expect(result.error, 'Connection failed');
      expect(result.errorCode, 'connection_failed');
      expect(result.serverName, isNull);
    });

    test('isAuthError returns true for auth errors', () {
      const authRequired = ValidationResult.failure(
        error: 'Auth required',
        errorCode: 'auth_required',
      );
      const authFailed = ValidationResult.failure(
        error: 'Auth failed',
        errorCode: 'auth_failed',
      );
      const connectionFailed = ValidationResult.failure(
        error: 'Connection failed',
        errorCode: 'connection_failed',
      );

      expect(authRequired.isAuthError, true);
      expect(authFailed.isAuthError, true);
      expect(connectionFailed.isAuthError, false);
    });

    test('isConnectionError returns true for connection errors', () {
      const result = ValidationResult.failure(
        error: 'Connection failed',
        errorCode: 'connection_failed',
      );

      expect(result.isConnectionError, true);
    });
  });
}
