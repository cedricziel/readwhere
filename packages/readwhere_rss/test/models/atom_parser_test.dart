import 'package:readwhere_rss/readwhere_rss.dart';
import 'package:test/test.dart';

void main() {
  group('AtomParser', () {
    const feedUrl = 'https://example.com/feed.xml';

    test('parses minimal Atom feed', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Test Feed</title>
  <id>urn:uuid:test-feed</id>
</feed>''';

      final feed = AtomParser.parse(xml, feedUrl);

      expect(feed.title, equals('Test Feed'));
      expect(feed.format, equals(RssFeedFormat.atom));
      expect(feed.feedUrl, equals(feedUrl));
      expect(feed.id, equals('urn:uuid:test-feed'));
      expect(feed.items, isEmpty);
    });

    test('parses feed with metadata', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>My Ebook Feed</title>
  <subtitle>A feed for ebooks</subtitle>
  <id>urn:uuid:test</id>
  <link href="https://example.com" rel="alternate"/>
  <link href="https://example.com/feed.xml" rel="self"/>
  <icon>https://example.com/icon.png</icon>
  <rights>Copyright 2024</rights>
  <author>
    <name>John Doe</name>
  </author>
  <generator uri="https://example.com" version="1.0">Test Generator</generator>
</feed>''';

      final feed = AtomParser.parse(xml, feedUrl);

      expect(feed.title, equals('My Ebook Feed'));
      expect(feed.description, equals('A feed for ebooks'));
      expect(feed.link, equals('https://example.com'));
      expect(feed.imageUrl, equals('https://example.com/icon.png'));
      expect(feed.copyright, equals('Copyright 2024'));
      expect(feed.author, equals('John Doe'));
      expect(feed.generator, equals('Test Generator 1.0'));
    });

    test('parses entry with basic fields', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Test Feed</title>
  <id>urn:uuid:test</id>
  <entry>
    <title>Entry 1</title>
    <id>urn:uuid:entry-1</id>
    <summary>Summary of entry 1</summary>
    <link href="https://example.com/entry1" rel="alternate"/>
  </entry>
</feed>''';

      final feed = AtomParser.parse(xml, feedUrl);

      expect(feed.items.length, equals(1));
      expect(feed.items[0].title, equals('Entry 1'));
      expect(feed.items[0].id, equals('urn:uuid:entry-1'));
      expect(feed.items[0].description, equals('Summary of entry 1'));
      expect(feed.items[0].link, equals('https://example.com/entry1'));
    });

    test('parses entry with content', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Test Feed</title>
  <id>urn:uuid:test</id>
  <entry>
    <title>Entry</title>
    <id>urn:uuid:entry</id>
    <summary>Short summary</summary>
    <content type="html">Full HTML content here</content>
  </entry>
</feed>''';

      final feed = AtomParser.parse(xml, feedUrl);

      expect(feed.items[0].description, equals('Short summary'));
      expect(feed.items[0].content, equals('Full HTML content here'));
    });

    test('parses entry with enclosure link', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Test Feed</title>
  <id>urn:uuid:test</id>
  <entry>
    <title>Ebook Entry</title>
    <id>urn:uuid:entry</id>
    <link href="https://example.com/book.epub" rel="enclosure" type="application/epub+zip" length="1234567"/>
  </entry>
</feed>''';

      final feed = AtomParser.parse(xml, feedUrl);

      expect(feed.items[0].enclosures.length, equals(1));
      expect(
        feed.items[0].enclosures[0].url,
        equals('https://example.com/book.epub'),
      );
      expect(feed.items[0].enclosures[0].type, equals('application/epub+zip'));
      expect(feed.items[0].enclosures[0].length, equals(1234567));
      expect(feed.items[0].hasEbookEnclosures, isTrue);
    });

    test('parses multiple enclosures', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Test Feed</title>
  <id>urn:uuid:test</id>
  <entry>
    <title>Multi-format Entry</title>
    <id>urn:uuid:entry</id>
    <link href="https://example.com/book.epub" rel="enclosure" type="application/epub+zip"/>
    <link href="https://example.com/book.pdf" rel="enclosure" type="application/pdf"/>
  </entry>
</feed>''';

      final feed = AtomParser.parse(xml, feedUrl);

      expect(feed.items[0].enclosures.length, equals(2));
    });

    test('parses entry categories', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Test Feed</title>
  <id>urn:uuid:test</id>
  <entry>
    <title>Entry</title>
    <id>urn:uuid:entry</id>
    <category term="fiction" label="Fiction"/>
    <category term="scifi" label="Sci-Fi" scheme="https://example.com/categories"/>
  </entry>
</feed>''';

      final feed = AtomParser.parse(xml, feedUrl);

      expect(feed.items[0].categories.length, equals(2));
      expect(feed.items[0].categories[0].label, equals('Fiction'));
      expect(feed.items[0].categories[1].label, equals('Sci-Fi'));
      expect(
        feed.items[0].categories[1].domain,
        equals('https://example.com/categories'),
      );
    });

    test('parses published and updated dates', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Test Feed</title>
  <id>urn:uuid:test</id>
  <entry>
    <title>Entry</title>
    <id>urn:uuid:entry</id>
    <published>2024-09-07T12:30:00Z</published>
    <updated>2024-09-08T14:00:00Z</updated>
  </entry>
</feed>''';

      final feed = AtomParser.parse(xml, feedUrl);

      expect(feed.items[0].pubDate, isNotNull);
      expect(feed.items[0].pubDate!.year, equals(2024));
      expect(feed.items[0].pubDate!.month, equals(9));
      expect(feed.items[0].pubDate!.day, equals(7));

      expect(feed.items[0].updated, isNotNull);
      expect(feed.items[0].updated!.day, equals(8));
    });

    test('parses entry author', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Test Feed</title>
  <id>urn:uuid:test</id>
  <entry>
    <title>Entry</title>
    <id>urn:uuid:entry</id>
    <author>
      <name>Jane Doe</name>
      <email>jane@example.com</email>
    </author>
  </entry>
</feed>''';

      final feed = AtomParser.parse(xml, feedUrl);

      expect(feed.items[0].author, equals('Jane Doe'));
      expect(feed.items[0].authorEmail, equals('jane@example.com'));
    });

    test('throws FormatException for non-Atom XML', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel><title>Not Atom</title></channel>
</rss>''';

      expect(
        () => AtomParser.parse(xml, feedUrl),
        throwsA(isA<FormatException>()),
      );
    });

    test('parses multiple entries', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Test Feed</title>
  <id>urn:uuid:test</id>
  <entry><title>Entry 1</title><id>1</id></entry>
  <entry><title>Entry 2</title><id>2</id></entry>
  <entry><title>Entry 3</title><id>3</id></entry>
</feed>''';

      final feed = AtomParser.parse(xml, feedUrl);

      expect(feed.items.length, equals(3));
      expect(feed.itemCount, equals(3));
    });

    test('uses logo as imageUrl when icon not present', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Test Feed</title>
  <id>urn:uuid:test</id>
  <logo>https://example.com/logo.png</logo>
</feed>''';

      final feed = AtomParser.parse(xml, feedUrl);

      expect(feed.imageUrl, equals('https://example.com/logo.png'));
    });
  });
}
