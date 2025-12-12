import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_opds/readwhere_opds.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

void main() {
  group('OpdsEntryAdapter', () {
    group('basic properties', () {
      test('maps id from entry', () {
        final entry = _createEntry(id: 'test-id-123');
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.id, equals('test-id-123'));
      });

      test('maps title from entry', () {
        final entry = _createEntry(title: 'Test Book Title');
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.title, equals('Test Book Title'));
      });

      test('maps summary from entry', () {
        final entry = _createEntry(summary: 'A great book about testing');
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.summary, equals('A great book about testing'));
      });

      test('maps thumbnailUrl from entry', () {
        final entry = _createEntry(
          links: [
            const OpdsLink(
              href: 'https://example.com/thumb.jpg',
              rel: OpdsLinkRel.thumbnail,
              type: 'image/jpeg',
            ),
          ],
        );
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.thumbnailUrl, equals('https://example.com/thumb.jpg'));
      });
    });

    group('entry type detection', () {
      test('returns book type when entry has acquisition links', () {
        final entry = _createEntry(
          links: [
            const OpdsLink(
              href: 'https://example.com/book.epub',
              rel: OpdsLinkRel.acquisitionOpenAccess,
              type: 'application/epub+zip',
            ),
          ],
        );
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.type, equals(CatalogEntryType.book));
      });

      test('returns navigation type for navigation entries', () {
        final entry = _createEntry(
          links: [
            const OpdsLink(
              href: 'https://example.com/feed',
              rel: OpdsLinkRel.subsection,
              type: 'application/atom+xml;profile=opds-catalog',
            ),
          ],
        );
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.type, equals(CatalogEntryType.navigation));
      });
    });

    group('extended metadata getters', () {
      test('maps author from entry', () {
        final entry = _createEntry(author: 'Jane Doe');
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.author, equals('Jane Doe'));
        expect(adapter.subtitle, equals('Jane Doe'));
      });

      test('maps publisher from entry', () {
        final entry = _createEntry(publisher: 'Acme Publishing');
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.publisher, equals('Acme Publishing'));
      });

      test('maps seriesName from entry', () {
        final entry = _createEntry(seriesName: 'The Great Series');
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.seriesName, equals('The Great Series'));
      });

      test('maps seriesPosition from entry', () {
        final entry = _createEntry(seriesPosition: 3);
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.seriesPosition, equals(3));
      });

      test('maps language from entry', () {
        final entry = _createEntry(language: 'en');
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.language, equals('en'));
      });

      test('maps categories from entry', () {
        final entry = _createEntry(
          categories: ['Fiction', 'Sci-Fi', 'Adventure'],
        );
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.categories, equals(['Fiction', 'Sci-Fi', 'Adventure']));
      });

      test('maps published date from entry', () {
        final publishDate = DateTime(2024, 1, 15);
        final entry = _createEntry(published: publishDate);
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.published, equals(publishDate));
      });

      test('maps coverUrl from entry', () {
        final entry = _createEntry(
          links: [
            const OpdsLink(
              href: 'https://example.com/cover.jpg',
              rel: OpdsLinkRel.image,
              type: 'image/jpeg',
            ),
          ],
        );
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.coverUrl, equals('https://example.com/cover.jpg'));
      });

      test('returns null for missing optional metadata', () {
        final entry = _createEntry();
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.author, isNull);
        expect(adapter.publisher, isNull);
        expect(adapter.seriesName, isNull);
        expect(adapter.seriesPosition, isNull);
        expect(adapter.language, isNull);
        expect(adapter.published, isNull);
        expect(adapter.coverUrl, isNull);
      });

      test('returns empty list for missing categories', () {
        final entry = _createEntry();
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.categories, isEmpty);
      });
    });

    group('file mapping', () {
      test('maps acquisition links to files', () {
        final entry = _createEntry(
          links: [
            const OpdsLink(
              href: 'https://example.com/book.epub',
              rel: OpdsLinkRel.acquisitionOpenAccess,
              type: 'application/epub+zip',
              length: 1024000,
              title: 'EPUB Download',
            ),
          ],
        );
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.files.length, equals(1));
        expect(
          adapter.files.first.href,
          equals('https://example.com/book.epub'),
        );
        expect(adapter.files.first.mimeType, equals('application/epub+zip'));
        expect(adapter.files.first.size, equals(1024000));
        expect(adapter.files.first.title, equals('EPUB Download'));
      });

      test('marks best acquisition link as primary', () {
        final entry = _createEntry(
          links: [
            const OpdsLink(
              href: 'https://example.com/book.pdf',
              rel: OpdsLinkRel.acquisitionOpenAccess,
              type: 'application/pdf',
            ),
            const OpdsLink(
              href: 'https://example.com/book.epub',
              rel: OpdsLinkRel.acquisitionOpenAccess,
              type: 'application/epub+zip',
            ),
          ],
        );
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.files.length, equals(2));
        // EPUB should be primary since it's the preferred format
        final epubFile = adapter.files.firstWhere(
          (f) => f.mimeType == 'application/epub+zip',
        );
        expect(epubFile.isPrimary, isTrue);
      });
    });

    group('link mapping', () {
      test('maps navigation link to links', () {
        final entry = _createEntry(
          links: [
            const OpdsLink(
              href: 'https://example.com/related-feed',
              rel: OpdsLinkRel.subsection,
              type: 'application/atom+xml;profile=opds-catalog',
              title: 'Related Books',
            ),
          ],
        );
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.links.length, equals(1));
        expect(
          adapter.links.first.href,
          equals('https://example.com/related-feed'),
        );
        expect(adapter.links.first.title, equals('Related Books'));
      });

      test('includes related links', () {
        final entry = _createEntry(
          links: [
            const OpdsLink(
              href: 'https://example.com/related',
              rel: OpdsLinkRel.related,
              type: 'text/html',
            ),
          ],
        );
        final adapter = OpdsEntryAdapter(entry);

        expect(adapter.links.length, equals(1));
        expect(adapter.links.first.href, equals('https://example.com/related'));
      });
    });
  });

  group('opdsFeedToBrowseResult', () {
    test('converts feed entries to CatalogEntry adapters', () {
      final feed = OpdsFeed(
        id: 'feed-123',
        title: 'Test Feed',
        updated: DateTime.now(),
        links: const [],
        entries: [
          _createEntry(id: 'entry-1', title: 'Book 1'),
          _createEntry(id: 'entry-2', title: 'Book 2'),
        ],
      );

      final result = opdsFeedToBrowseResult(feed);

      expect(result.entries.length, equals(2));
      expect(result.entries[0].id, equals('entry-1'));
      expect(result.entries[1].id, equals('entry-2'));
    });

    test('maps pagination info from feed', () {
      final feed = OpdsFeed(
        id: 'feed-123',
        title: 'Test Feed',
        updated: DateTime.now(),
        links: const [
          OpdsLink(
            href: 'https://example.com/next',
            rel: OpdsLinkRel.next,
            type: 'application/atom+xml',
          ),
        ],
        entries: const [],
        totalResults: 100,
        itemsPerPage: 20,
        startIndex: 21,
      );

      final result = opdsFeedToBrowseResult(feed);

      expect(result.hasNextPage, isTrue);
      expect(result.nextPageUrl, equals('https://example.com/next'));
      expect(result.totalEntries, equals(100));
    });
  });
}

/// Helper to create test OpdsEntry instances
OpdsEntry _createEntry({
  String id = 'test-entry',
  String title = 'Test Entry',
  String? author,
  String? summary,
  List<OpdsLink> links = const [],
  List<String> categories = const [],
  String? publisher,
  String? language,
  DateTime? published,
  String? seriesName,
  int? seriesPosition,
}) {
  return OpdsEntry(
    id: id,
    title: title,
    author: author,
    summary: summary,
    updated: DateTime.now(),
    links: links,
    categories: categories,
    publisher: publisher,
    language: language,
    published: published,
    seriesName: seriesName,
    seriesPosition: seriesPosition,
  );
}
