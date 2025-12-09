import 'package:readwhere_opml/readwhere_opml.dart';
import 'package:test/test.dart';

void main() {
  group('OpmlParser', () {
    test('parses minimal OPML 1.0 document', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0">
  <body>
  </body>
</opml>''';

      final doc = OpmlParser.parse(xml);

      expect(doc.version, equals('1.0'));
      expect(doc.head, isNull);
      expect(doc.outlines, isEmpty);
    });

    test('parses OPML 2.0 document', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <head>
    <title>My Subscriptions</title>
  </head>
  <body>
  </body>
</opml>''';

      final doc = OpmlParser.parse(xml);

      expect(doc.version, equals('2.0'));
      expect(doc.title, equals('My Subscriptions'));
    });

    test('parses head with metadata', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <head>
    <title>My Feeds</title>
    <ownerName>John Doe</ownerName>
    <ownerEmail>john@example.com</ownerEmail>
  </head>
  <body>
  </body>
</opml>''';

      final doc = OpmlParser.parse(xml);

      expect(doc.head?.title, equals('My Feeds'));
      expect(doc.head?.ownerName, equals('John Doe'));
      expect(doc.head?.ownerEmail, equals('john@example.com'));
    });

    test('parses feed outline', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="My Feed" type="rss" xmlUrl="https://example.com/feed.xml" htmlUrl="https://example.com"/>
  </body>
</opml>''';

      final doc = OpmlParser.parse(xml);

      expect(doc.outlines.length, equals(1));
      expect(doc.outlines[0].text, equals('My Feed'));
      expect(doc.outlines[0].type, equals('rss'));
      expect(doc.outlines[0].xmlUrl, equals('https://example.com/feed.xml'));
      expect(doc.outlines[0].htmlUrl, equals('https://example.com'));
      expect(doc.outlines[0].isFeed, isTrue);
    });

    test('parses folder with feeds', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="Tech">
      <outline text="Feed 1" type="rss" xmlUrl="https://example.com/feed1.xml"/>
      <outline text="Feed 2" type="rss" xmlUrl="https://example.com/feed2.xml"/>
    </outline>
  </body>
</opml>''';

      final doc = OpmlParser.parse(xml);

      expect(doc.outlines.length, equals(1));
      expect(doc.outlines[0].text, equals('Tech'));
      expect(doc.outlines[0].isFolder, isTrue);
      expect(doc.outlines[0].children.length, equals(2));
    });

    test('parses nested folders', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="Level 1">
      <outline text="Level 2">
        <outline text="Feed" type="rss" xmlUrl="https://example.com/feed.xml"/>
      </outline>
    </outline>
  </body>
</opml>''';

      final doc = OpmlParser.parse(xml);

      expect(doc.outlines[0].text, equals('Level 1'));
      expect(doc.outlines[0].children[0].text, equals('Level 2'));
      expect(doc.outlines[0].children[0].children[0].text, equals('Feed'));
    });

    test('extracts all feeds flattened', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="Feed 1" type="rss" xmlUrl="https://example.com/feed1.xml"/>
    <outline text="Folder">
      <outline text="Feed 2" type="rss" xmlUrl="https://example.com/feed2.xml"/>
      <outline text="Nested">
        <outline text="Feed 3" type="rss" xmlUrl="https://example.com/feed3.xml"/>
      </outline>
    </outline>
  </body>
</opml>''';

      final doc = OpmlParser.parse(xml);
      final feeds = doc.allFeeds;

      expect(feeds.length, equals(3));
      expect(feeds[0].text, equals('Feed 1'));
      expect(feeds[1].text, equals('Feed 2'));
      expect(feeds[2].text, equals('Feed 3'));
    });

    test('parses outline with all attributes', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline
      text="Full Feed"
      title="Full Title"
      type="rss"
      xmlUrl="https://example.com/feed.xml"
      htmlUrl="https://example.com"
      description="A description"
      language="en-us"
      version="RSS2"
      category="Tech/News"/>
  </body>
</opml>''';

      final doc = OpmlParser.parse(xml);

      expect(doc.outlines[0].text, equals('Full Feed'));
      expect(doc.outlines[0].title, equals('Full Title'));
      expect(doc.outlines[0].description, equals('A description'));
      expect(doc.outlines[0].language, equals('en-us'));
      expect(doc.outlines[0].version, equals('RSS2'));
      expect(doc.outlines[0].category, equals('Tech/News'));
    });

    test('parses custom attributes', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="Feed" myCustomAttr="customValue"/>
  </body>
</opml>''';

      final doc = OpmlParser.parse(xml);

      expect(
        doc.outlines[0].customAttributes['myCustomAttr'],
        equals('customValue'),
      );
    });

    test('throws OpmlParseException for invalid XML', () {
      const xml = 'This is not valid XML';

      expect(() => OpmlParser.parse(xml), throwsA(isA<OpmlParseException>()));
    });

    test('throws OpmlFormatException for non-OPML XML', () {
      const xml = '''<?xml version="1.0"?>
<html><body>Not OPML</body></html>''';

      expect(() => OpmlParser.parse(xml), throwsA(isA<OpmlFormatException>()));
    });

    test('throws OpmlFormatException when body is missing', () {
      const xml = '''<?xml version="1.0"?>
<opml version="2.0">
  <head><title>Test</title></head>
</opml>''';

      expect(() => OpmlParser.parse(xml), throwsA(isA<OpmlFormatException>()));
    });

    test('tryParse returns document for valid OPML', () {
      const xml = '''<?xml version="1.0"?>
<opml version="2.0"><body></body></opml>''';

      final doc = OpmlParser.tryParse(xml);

      expect(doc, isNotNull);
    });

    test('tryParse returns null for invalid content', () {
      const xml = 'Not XML at all';

      final doc = OpmlParser.tryParse(xml);

      expect(doc, isNull);
    });

    test('extractFeeds static method works', () {
      const xml = '''<?xml version="1.0"?>
<opml version="2.0">
  <body>
    <outline text="Feed" type="rss" xmlUrl="https://example.com/feed.xml"/>
  </body>
</opml>''';

      final doc = OpmlParser.parse(xml);
      final feeds = OpmlParser.extractFeeds(doc);

      expect(feeds.length, equals(1));
    });

    test('handles case-insensitive root element', () {
      const xml = '''<?xml version="1.0"?>
<OPML version="2.0">
  <body></body>
</OPML>''';

      final doc = OpmlParser.parse(xml);

      expect(doc.version, equals('2.0'));
    });

    test('defaults version to 1.0 when not specified', () {
      const xml = '''<?xml version="1.0"?>
<opml>
  <body></body>
</opml>''';

      final doc = OpmlParser.parse(xml);

      expect(doc.version, equals('1.0'));
    });
  });
}
