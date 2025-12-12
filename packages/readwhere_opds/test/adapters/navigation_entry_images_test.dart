import 'package:readwhere_opds/readwhere_opds.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:test/test.dart';

void main() {
  group('Navigation entry image links', () {
    test('parses image and thumbnail links for navigation entries', () {
      // Sample from Kavita on-deck feed - navigation entry with images
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <id>3</id>
    <title>Volume 01</title>
    <updated>2025-12-12T19:31:48</updated>
    <author><name>Greg Pak</name></author>
    <link rel="subsection" type="application/atom+xml;profile=opds-catalog;kind=navigation" href="/api/opds/key/series/3" />
    <link rel="http://opds-spec.org/image" type="image/jpeg" href="/api/image/series-cover?seriesId=3&amp;apiKey=key" />
    <link rel="http://opds-spec.org/image/thumbnail" type="image/jpeg" href="/api/image/series-cover?seriesId=3&amp;apiKey=key" />
  </entry>
</feed>''';

      final feed = OpdsFeedModel.fromXmlString(
        xml,
        baseUrl: 'https://kavita.58lab.org',
      );
      final entry = feed.entries.first;

      expect(entry.isNavigation, isTrue);
      expect(entry.links.length, equals(3));

      // Verify image links are parsed
      expect(
        entry.coverUrl,
        equals(
          'https://kavita.58lab.org/api/image/series-cover?seriesId=3&apiKey=key',
        ),
      );
      expect(
        entry.thumbnailUrl,
        equals(
          'https://kavita.58lab.org/api/image/series-cover?seriesId=3&apiKey=key',
        ),
      );
    });

    test('adapter exposes thumbnail and cover URLs for navigation entries', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <id>comics-1</id>
    <title>Comics Library</title>
    <updated>2025-12-12T19:31:48</updated>
    <link rel="subsection" type="application/atom+xml;profile=opds-catalog;kind=navigation" href="/api/opds/key/libraries/1" />
    <link rel="http://opds-spec.org/image" type="image/jpeg" href="/api/image/library-cover?libraryId=1" />
    <link rel="http://opds-spec.org/image/thumbnail" type="image/jpeg" href="/api/image/library-cover?libraryId=1&amp;thumbnail=true" />
  </entry>
</feed>''';

      final feed = OpdsFeedModel.fromXmlString(
        xml,
        baseUrl: 'https://kavita.58lab.org',
      );
      final entry = feed.entries.first;
      final adapter = OpdsEntryAdapter(entry);

      // Verify adapter exposes the URLs
      expect(adapter.type, equals(CatalogEntryType.navigation));
      expect(adapter.thumbnailUrl, isNotNull);
      expect(adapter.thumbnailUrl, contains('library-cover'));
      expect(adapter.coverUrl, isNotNull);
      expect(adapter.coverUrl, contains('library-cover'));
    });

    test('toBrowseResult preserves image URLs on navigation entries', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>libraries</id>
  <title>All Libraries</title>
  <updated>2025-12-12T19:31:48</updated>
  <entry>
    <id>1</id>
    <title>Comics</title>
    <updated>2025-12-12T19:31:48</updated>
    <link rel="subsection" type="application/atom+xml;profile=opds-catalog;kind=navigation" href="/api/opds/key/libraries/1" />
    <link rel="http://opds-spec.org/image" type="image/jpeg" href="/api/image/library-cover?libraryId=1" />
    <link rel="http://opds-spec.org/image/thumbnail" type="image/jpeg" href="/api/image/library-cover?libraryId=1" />
  </entry>
  <entry>
    <id>2</id>
    <title>Books</title>
    <updated>2025-12-12T19:31:48</updated>
    <link rel="subsection" type="application/atom+xml;profile=opds-catalog;kind=navigation" href="/api/opds/key/libraries/2" />
    <link rel="http://opds-spec.org/image" type="image/jpeg" href="/api/image/library-cover?libraryId=2" />
    <link rel="http://opds-spec.org/image/thumbnail" type="image/jpeg" href="/api/image/library-cover?libraryId=2" />
  </entry>
</feed>''';

      final feed = OpdsFeedModel.fromXmlString(
        xml,
        baseUrl: 'https://kavita.58lab.org',
      );
      final browseResult = feed.toBrowseResult();

      expect(browseResult.entries.length, equals(2));

      for (final entry in browseResult.entries) {
        expect(entry.type, equals(CatalogEntryType.navigation));
        expect(entry.thumbnailUrl, isNotNull);
        expect(entry.thumbnailUrl, contains('library-cover'));
      }
    });
  });
}
