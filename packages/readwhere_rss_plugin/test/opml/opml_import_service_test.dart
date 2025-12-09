import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_rss_plugin/readwhere_rss_plugin.dart';

void main() {
  group('OpmlImportService', () {
    late OpmlImportService service;

    setUp(() {
      service = OpmlImportService();
    });

    test('imports single feed from OPML', () {
      const opml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="My Feed" type="rss" xmlUrl="https://example.com/feed.xml"/>
  </body>
</opml>''';

      final configs = service.importFromOpml(opml);

      expect(configs.length, equals(1));
      expect(configs[0].name, equals('My Feed'));
      expect(configs[0].feedUrl, equals('https://example.com/feed.xml'));
    });

    test('imports multiple feeds from OPML', () {
      const opml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="Feed 1" type="rss" xmlUrl="https://example.com/feed1.xml"/>
    <outline text="Feed 2" type="rss" xmlUrl="https://example.com/feed2.xml"/>
    <outline text="Feed 3" type="rss" xmlUrl="https://example.com/feed3.xml"/>
  </body>
</opml>''';

      final configs = service.importFromOpml(opml);

      expect(configs.length, equals(3));
    });

    test('imports feed with all attributes', () {
      const opml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline
      text="My Feed"
      type="rss"
      xmlUrl="https://example.com/feed.xml"
      htmlUrl="https://example.com"
      description="A great feed"/>
  </body>
</opml>''';

      final configs = service.importFromOpml(opml);

      expect(configs[0].name, equals('My Feed'));
      expect(configs[0].feedUrl, equals('https://example.com/feed.xml'));
      expect(configs[0].htmlUrl, equals('https://example.com'));
      expect(configs[0].description, equals('A great feed'));
    });

    test('flattens feeds from folders', () {
      const opml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="Tech">
      <outline text="Feed 1" type="rss" xmlUrl="https://example.com/feed1.xml"/>
      <outline text="Feed 2" type="rss" xmlUrl="https://example.com/feed2.xml"/>
    </outline>
    <outline text="Feed 3" type="rss" xmlUrl="https://example.com/feed3.xml"/>
  </body>
</opml>''';

      final configs = service.importFromOpml(opml);

      expect(configs.length, equals(3));
    });

    test('assigns category from parent folder', () {
      const opml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="Tech">
      <outline text="Tech Feed" type="rss" xmlUrl="https://example.com/tech.xml"/>
    </outline>
    <outline text="News" type="rss" xmlUrl="https://example.com/news.xml"/>
  </body>
</opml>''';

      final configs = service.importFromOpml(opml);

      final techFeed = configs.firstWhere((c) => c.name == 'Tech Feed');
      final newsFeed = configs.firstWhere((c) => c.name == 'News');

      expect(techFeed.category, equals('Tech'));
      expect(newsFeed.category, isNull);
    });

    test('handles deeply nested folders', () {
      const opml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="Level 1">
      <outline text="Level 2">
        <outline text="Level 3">
          <outline text="Deep Feed" type="rss" xmlUrl="https://example.com/deep.xml"/>
        </outline>
      </outline>
    </outline>
  </body>
</opml>''';

      final configs = service.importFromOpml(opml);

      expect(configs.length, equals(1));
      expect(configs[0].name, equals('Deep Feed'));
      // Category is from immediate parent
      expect(configs[0].category, equals('Level 3'));
    });

    test('ignores non-feed outlines', () {
      const opml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="A Folder"/>
    <outline text="A Link" type="link" htmlUrl="https://example.com"/>
    <outline text="A Feed" type="rss" xmlUrl="https://example.com/feed.xml"/>
  </body>
</opml>''';

      final configs = service.importFromOpml(opml);

      expect(configs.length, equals(1));
      expect(configs[0].name, equals('A Feed'));
    });

    test('handles empty OPML', () {
      const opml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
  </body>
</opml>''';

      final configs = service.importFromOpml(opml);

      expect(configs, isEmpty);
    });
  });

  group('OpmlImportService.getSummary', () {
    late OpmlImportService service;

    setUp(() {
      service = OpmlImportService();
    });

    test('returns summary with feed count', () {
      const opml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <head>
    <title>My Subscriptions</title>
    <ownerName>John Doe</ownerName>
  </head>
  <body>
    <outline text="Feed 1" type="rss" xmlUrl="https://example.com/feed1.xml"/>
    <outline text="Feed 2" type="rss" xmlUrl="https://example.com/feed2.xml"/>
  </body>
</opml>''';

      final summary = service.getSummary(opml);

      expect(summary.title, equals('My Subscriptions'));
      expect(summary.feedCount, equals(2));
      expect(summary.ownerName, equals('John Doe'));
    });

    test('returns categories from folders', () {
      const opml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="Tech">
      <outline text="Feed" type="rss" xmlUrl="https://example.com/feed.xml"/>
    </outline>
    <outline text="News">
      <outline text="Feed 2" type="rss" xmlUrl="https://example.com/feed2.xml"/>
    </outline>
  </body>
</opml>''';

      final summary = service.getSummary(opml);

      expect(summary.categories, containsAll(['Tech', 'News']));
      expect(summary.categories.length, equals(2));
    });

    test('categories are sorted', () {
      const opml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="Zebra">
      <outline text="Feed" type="rss" xmlUrl="url"/>
    </outline>
    <outline text="Apple">
      <outline text="Feed 2" type="rss" xmlUrl="url2"/>
    </outline>
  </body>
</opml>''';

      final summary = service.getSummary(opml);

      expect(summary.categories[0], equals('Apple'));
      expect(summary.categories[1], equals('Zebra'));
    });
  });

  group('RssCatalogConfig', () {
    test('creates config with required fields', () {
      const config = RssCatalogConfig(
        name: 'My Feed',
        feedUrl: 'https://example.com/feed.xml',
      );

      expect(config.name, equals('My Feed'));
      expect(config.feedUrl, equals('https://example.com/feed.xml'));
      expect(config.htmlUrl, isNull);
      expect(config.description, isNull);
      expect(config.category, isNull);
    });

    test('creates config with all fields', () {
      const config = RssCatalogConfig(
        name: 'My Feed',
        feedUrl: 'https://example.com/feed.xml',
        htmlUrl: 'https://example.com',
        description: 'A description',
        category: 'Tech',
      );

      expect(config.htmlUrl, equals('https://example.com'));
      expect(config.description, equals('A description'));
      expect(config.category, equals('Tech'));
    });

    test('toString includes name and feedUrl', () {
      const config = RssCatalogConfig(
        name: 'My Feed',
        feedUrl: 'https://example.com/feed.xml',
        category: 'Tech',
      );

      expect(config.toString(), contains('My Feed'));
      expect(config.toString(), contains('https://example.com/feed.xml'));
      expect(config.toString(), contains('Tech'));
    });
  });

  group('OpmlImportSummary', () {
    test('creates summary with all fields', () {
      const summary = OpmlImportSummary(
        title: 'My Feeds',
        feedCount: 10,
        categories: ['Tech', 'News'],
        ownerName: 'John',
      );

      expect(summary.title, equals('My Feeds'));
      expect(summary.feedCount, equals(10));
      expect(summary.categories.length, equals(2));
      expect(summary.ownerName, equals('John'));
    });

    test('toString includes summary info', () {
      const summary = OpmlImportSummary(
        title: 'My Feeds',
        feedCount: 10,
        categories: ['Tech', 'News'],
      );

      expect(summary.toString(), contains('My Feeds'));
      expect(summary.toString(), contains('10'));
    });
  });
}
