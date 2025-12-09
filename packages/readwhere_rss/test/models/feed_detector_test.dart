import 'package:readwhere_rss/readwhere_rss.dart';
import 'package:test/test.dart';

void main() {
  group('FeedDetector', () {
    const feedUrl = 'https://example.com/feed.xml';

    group('detect', () {
      test('detects RSS 2.0 format', () {
        const xml = '''<?xml version="1.0"?>
<rss version="2.0">
  <channel><title>Test</title></channel>
</rss>''';

        expect(FeedDetector.detect(xml), equals(RssFeedFormat.rss2));
      });

      test('detects Atom format', () {
        const xml = '''<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Test</title>
</feed>''';

        expect(FeedDetector.detect(xml), equals(RssFeedFormat.atom));
      });

      test('detects RSS 1.0 (RDF) format', () {
        const xml = '''<?xml version="1.0"?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <channel><title>Test</title></channel>
</rdf:RDF>''';

        expect(FeedDetector.detect(xml), equals(RssFeedFormat.rss1));
      });

      test('returns unknown for non-feed XML', () {
        const xml = '''<?xml version="1.0"?>
<html><body>Not a feed</body></html>''';

        expect(FeedDetector.detect(xml), equals(RssFeedFormat.unknown));
      });

      test('returns unknown for invalid XML', () {
        const xml = 'This is not valid XML at all';

        expect(FeedDetector.detect(xml), equals(RssFeedFormat.unknown));
      });

      test('handles case-insensitive root element names', () {
        const xmlUpper = '''<?xml version="1.0"?>
<RSS version="2.0">
  <channel><title>Test</title></channel>
</RSS>''';

        const xmlLower = '''<?xml version="1.0"?>
<rss version="2.0">
  <channel><title>Test</title></channel>
</rss>''';

        expect(FeedDetector.detect(xmlUpper), equals(RssFeedFormat.rss2));
        expect(FeedDetector.detect(xmlLower), equals(RssFeedFormat.rss2));
      });
    });

    group('parse', () {
      test('parses RSS 2.0 feed', () {
        const xml = '''<?xml version="1.0"?>
<rss version="2.0">
  <channel><title>RSS 2.0 Feed</title></channel>
</rss>''';

        final feed = FeedDetector.parse(xml, feedUrl);

        expect(feed.format, equals(RssFeedFormat.rss2));
        expect(feed.title, equals('RSS 2.0 Feed'));
      });

      test('parses Atom feed', () {
        const xml = '''<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Atom Feed</title>
  <id>urn:uuid:test</id>
</feed>''';

        final feed = FeedDetector.parse(xml, feedUrl);

        expect(feed.format, equals(RssFeedFormat.atom));
        expect(feed.title, equals('Atom Feed'));
      });

      test('parses RSS 1.0 feed', () {
        const xml = '''<?xml version="1.0"?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns="http://purl.org/rss/1.0/">
  <channel>
    <title>RSS 1.0 Feed</title>
  </channel>
</rdf:RDF>''';

        final feed = FeedDetector.parse(xml, feedUrl);

        expect(feed.format, equals(RssFeedFormat.rss1));
        expect(feed.title, equals('RSS 1.0 Feed'));
      });

      test('throws FormatException for unknown format', () {
        const xml = '''<?xml version="1.0"?>
<html><body>Not a feed</body></html>''';

        expect(
          () => FeedDetector.parse(xml, feedUrl),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('isValidFeed', () {
      test('returns true for valid RSS 2.0', () {
        const xml = '''<?xml version="1.0"?>
<rss version="2.0"><channel><title>Test</title></channel></rss>''';

        expect(FeedDetector.isValidFeed(xml), isTrue);
      });

      test('returns true for valid Atom', () {
        const xml = '''<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom"><title>Test</title></feed>''';

        expect(FeedDetector.isValidFeed(xml), isTrue);
      });

      test('returns false for non-feed content', () {
        const xml = '<html><body>Not a feed</body></html>';

        expect(FeedDetector.isValidFeed(xml), isFalse);
      });

      test('returns false for invalid XML', () {
        const content = 'Just plain text, not XML';

        expect(FeedDetector.isValidFeed(content), isFalse);
      });
    });

    group('tryParse', () {
      test('returns feed for valid content', () {
        const xml = '''<?xml version="1.0"?>
<rss version="2.0"><channel><title>Test</title></channel></rss>''';

        final feed = FeedDetector.tryParse(xml, feedUrl);

        expect(feed, isNotNull);
        expect(feed!.title, equals('Test'));
      });

      test('returns null for invalid content', () {
        const xml = '<html><body>Not a feed</body></html>';

        final feed = FeedDetector.tryParse(xml, feedUrl);

        expect(feed, isNull);
      });

      test('returns null for malformed XML', () {
        const content = 'Not even XML';

        final feed = FeedDetector.tryParse(content, feedUrl);

        expect(feed, isNull);
      });
    });
  });
}
