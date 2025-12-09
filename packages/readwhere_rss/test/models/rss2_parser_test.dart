import 'package:readwhere_rss/readwhere_rss.dart';
import 'package:test/test.dart';

void main() {
  group('Rss2Parser', () {
    const feedUrl = 'https://example.com/feed.xml';

    test('parses minimal RSS 2.0 feed', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
  </channel>
</rss>''';

      final feed = Rss2Parser.parse(xml, feedUrl);

      expect(feed.title, equals('Test Feed'));
      expect(feed.format, equals(RssFeedFormat.rss2));
      expect(feed.feedUrl, equals(feedUrl));
      expect(feed.items, isEmpty);
    });

    test('parses feed with channel metadata', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>My Ebook Feed</title>
    <description>A feed for ebooks</description>
    <link>https://example.com</link>
    <language>en-us</language>
    <copyright>Copyright 2024</copyright>
    <generator>Test Generator</generator>
  </channel>
</rss>''';

      final feed = Rss2Parser.parse(xml, feedUrl);

      expect(feed.title, equals('My Ebook Feed'));
      expect(feed.description, equals('A feed for ebooks'));
      expect(feed.link, equals('https://example.com'));
      expect(feed.language, equals('en-us'));
      expect(feed.copyright, equals('Copyright 2024'));
      expect(feed.generator, equals('Test Generator'));
    });

    test('parses feed with image element', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <image>
      <url>https://example.com/image.png</url>
      <title>Feed Image</title>
      <link>https://example.com</link>
    </image>
  </channel>
</rss>''';

      final feed = Rss2Parser.parse(xml, feedUrl);

      expect(feed.imageUrl, equals('https://example.com/image.png'));
    });

    test('parses items with basic fields', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <item>
      <title>Item 1</title>
      <description>Description of item 1</description>
      <link>https://example.com/item1</link>
      <guid>item-guid-1</guid>
    </item>
  </channel>
</rss>''';

      final feed = Rss2Parser.parse(xml, feedUrl);

      expect(feed.items.length, equals(1));
      expect(feed.items[0].title, equals('Item 1'));
      expect(feed.items[0].description, equals('Description of item 1'));
      expect(feed.items[0].link, equals('https://example.com/item1'));
      expect(feed.items[0].id, equals('item-guid-1'));
    });

    test('parses item with enclosure', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <item>
      <title>Ebook Item</title>
      <enclosure url="https://example.com/book.epub" type="application/epub+zip" length="1234567"/>
    </item>
  </channel>
</rss>''';

      final feed = Rss2Parser.parse(xml, feedUrl);

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
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <item>
      <title>Multi-format Item</title>
      <enclosure url="https://example.com/book.epub" type="application/epub+zip"/>
      <enclosure url="https://example.com/book.pdf" type="application/pdf"/>
    </item>
  </channel>
</rss>''';

      final feed = Rss2Parser.parse(xml, feedUrl);

      expect(feed.items[0].enclosures.length, equals(2));
    });

    test('parses item categories', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <item>
      <title>Item</title>
      <category>Fiction</category>
      <category domain="https://example.com/cats">Sci-Fi</category>
    </item>
  </channel>
</rss>''';

      final feed = Rss2Parser.parse(xml, feedUrl);

      expect(feed.items[0].categories.length, equals(2));
      expect(feed.items[0].categories[0].label, equals('Fiction'));
      expect(feed.items[0].categories[1].label, equals('Sci-Fi'));
      expect(
        feed.items[0].categories[1].domain,
        equals('https://example.com/cats'),
      );
    });

    test('parses pubDate in RFC 2822 format', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <item>
      <title>Item</title>
      <pubDate>Sat, 07 Sep 2024 12:30:00 GMT</pubDate>
    </item>
  </channel>
</rss>''';

      final feed = Rss2Parser.parse(xml, feedUrl);

      expect(feed.items[0].pubDate, isNotNull);
      expect(feed.items[0].pubDate!.year, equals(2024));
      expect(feed.items[0].pubDate!.month, equals(9));
      expect(feed.items[0].pubDate!.day, equals(7));
    });

    test('uses link as id when guid not present', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <item>
      <title>Item</title>
      <link>https://example.com/unique-item</link>
    </item>
  </channel>
</rss>''';

      final feed = Rss2Parser.parse(xml, feedUrl);

      expect(feed.items[0].id, equals('https://example.com/unique-item'));
    });

    test('throws FormatException for non-RSS XML', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<html>
  <body>Not a feed</body>
</html>''';

      expect(
        () => Rss2Parser.parse(xml, feedUrl),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for RSS without channel', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
</rss>''';

      expect(
        () => Rss2Parser.parse(xml, feedUrl),
        throwsA(isA<FormatException>()),
      );
    });

    test('parses content:encoded extension', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <channel>
    <title>Test Feed</title>
    <item>
      <title>Item</title>
      <description>Short description</description>
      <content:encoded><![CDATA[<p>Full HTML content here</p>]]></content:encoded>
    </item>
  </channel>
</rss>''';

      final feed = Rss2Parser.parse(xml, feedUrl);

      expect(feed.items[0].description, equals('Short description'));
      expect(feed.items[0].content, contains('Full HTML content'));
    });

    test('parses dc:creator extension', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Test Feed</title>
    <item>
      <title>Item</title>
      <dc:creator>John Doe</dc:creator>
    </item>
  </channel>
</rss>''';

      final feed = Rss2Parser.parse(xml, feedUrl);

      expect(feed.items[0].author, equals('John Doe'));
    });

    test('parses multiple items', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <item><title>Item 1</title><guid>1</guid></item>
    <item><title>Item 2</title><guid>2</guid></item>
    <item><title>Item 3</title><guid>3</guid></item>
  </channel>
</rss>''';

      final feed = Rss2Parser.parse(xml, feedUrl);

      expect(feed.items.length, equals(3));
      expect(feed.itemCount, equals(3));
    });
  });
}
