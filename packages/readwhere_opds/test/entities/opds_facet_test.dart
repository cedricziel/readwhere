import 'package:readwhere_opds/src/entities/opds_facet.dart';
import 'package:readwhere_opds/src/entities/opds_feed.dart';
import 'package:readwhere_opds/src/entities/opds_link.dart';
import 'package:readwhere_opds/src/models/opds_feed_model.dart';
import 'package:test/test.dart';

void main() {
  group('OpdsFacet', () {
    test('creates facet with required fields', () {
      const facet = OpdsFacet(
        title: 'Science Fiction',
        href: '/catalog/genre/scifi',
      );

      expect(facet.title, 'Science Fiction');
      expect(facet.href, '/catalog/genre/scifi');
      expect(facet.count, isNull);
      expect(facet.isActive, isFalse);
    });

    test('creates facet with all fields', () {
      const facet = OpdsFacet(
        title: 'Fantasy',
        href: '/catalog/genre/fantasy',
        count: 42,
        isActive: true,
      );

      expect(facet.title, 'Fantasy');
      expect(facet.href, '/catalog/genre/fantasy');
      expect(facet.count, 42);
      expect(facet.isActive, isTrue);
    });

    test('equality works correctly', () {
      const facet1 = OpdsFacet(
        title: 'Horror',
        href: '/catalog/genre/horror',
        count: 10,
        isActive: false,
      );
      const facet2 = OpdsFacet(
        title: 'Horror',
        href: '/catalog/genre/horror',
        count: 10,
        isActive: false,
      );
      const facet3 = OpdsFacet(
        title: 'Horror',
        href: '/catalog/genre/horror',
        count: 11, // Different count
        isActive: false,
      );

      expect(facet1, equals(facet2));
      expect(facet1, isNot(equals(facet3)));
    });
  });

  group('OpdsFacetGroup', () {
    test('creates empty group', () {
      const group = OpdsFacetGroup(name: 'Genre', facets: []);

      expect(group.name, 'Genre');
      expect(group.facets, isEmpty);
      expect(group.activeFacet, isNull);
      expect(group.hasActiveFacet, isFalse);
    });

    test('creates group with facets', () {
      const group = OpdsFacetGroup(
        name: 'Genre',
        facets: [
          OpdsFacet(title: 'Sci-Fi', href: '/scifi'),
          OpdsFacet(title: 'Fantasy', href: '/fantasy'),
        ],
      );

      expect(group.facets.length, 2);
      expect(group.activeFacet, isNull);
      expect(group.hasActiveFacet, isFalse);
    });

    test('returns active facet when present', () {
      const group = OpdsFacetGroup(
        name: 'Genre',
        facets: [
          OpdsFacet(title: 'Sci-Fi', href: '/scifi', isActive: false),
          OpdsFacet(title: 'Fantasy', href: '/fantasy', isActive: true),
          OpdsFacet(title: 'Horror', href: '/horror', isActive: false),
        ],
      );

      expect(group.hasActiveFacet, isTrue);
      expect(group.activeFacet?.title, 'Fantasy');
    });

    test('equality works correctly', () {
      const group1 = OpdsFacetGroup(
        name: 'Author',
        facets: [OpdsFacet(title: 'Asimov', href: '/asimov')],
      );
      const group2 = OpdsFacetGroup(
        name: 'Author',
        facets: [OpdsFacet(title: 'Asimov', href: '/asimov')],
      );

      expect(group1, equals(group2));
    });
  });

  group('OpdsLink facet fields', () {
    test('creates link with facet fields', () {
      final link = OpdsLink(
        href: '/catalog/genre/scifi',
        rel: OpdsLinkRel.facet,
        type: 'application/atom+xml;profile=opds-catalog',
        title: 'Science Fiction',
        facetGroup: 'Genre',
        activeFacet: true,
        count: 150,
      );

      expect(link.isFacet, isTrue);
      expect(link.facetGroup, 'Genre');
      expect(link.activeFacet, isTrue);
      expect(link.count, 150);
    });

    test('isFacet returns false for non-facet links', () {
      final link = OpdsLink(
        href: '/catalog',
        rel: OpdsLinkRel.self,
        type: 'application/atom+xml',
      );

      expect(link.isFacet, isFalse);
    });
  });

  group('OpdsFeed facet extraction', () {
    test('facetLinks returns only facet links', () {
      final feed = OpdsFeed(
        id: 'test',
        title: 'Test Feed',
        updated: DateTime(2024, 1, 1),
        links: [
          OpdsLink(
            href: '/self',
            rel: OpdsLinkRel.self,
            type: 'application/atom+xml',
          ),
          OpdsLink(
            href: '/genre/scifi',
            rel: OpdsLinkRel.facet,
            type: 'application/atom+xml',
            title: 'Sci-Fi',
            facetGroup: 'Genre',
          ),
          OpdsLink(
            href: '/next',
            rel: OpdsLinkRel.next,
            type: 'application/atom+xml',
          ),
          OpdsLink(
            href: '/genre/fantasy',
            rel: OpdsLinkRel.facet,
            type: 'application/atom+xml',
            title: 'Fantasy',
            facetGroup: 'Genre',
          ),
        ],
        entries: [],
      );

      expect(feed.facetLinks.length, 2);
      expect(feed.hasFacets, isTrue);
    });

    test('facetGroups organizes facets by group', () {
      final feed = OpdsFeed(
        id: 'test',
        title: 'Test Feed',
        updated: DateTime(2024, 1, 1),
        links: [
          OpdsLink(
            href: '/genre/scifi',
            rel: OpdsLinkRel.facet,
            type: 'application/atom+xml',
            title: 'Sci-Fi',
            facetGroup: 'Genre',
            count: 50,
          ),
          OpdsLink(
            href: '/genre/fantasy',
            rel: OpdsLinkRel.facet,
            type: 'application/atom+xml',
            title: 'Fantasy',
            facetGroup: 'Genre',
            count: 30,
            activeFacet: true,
          ),
          OpdsLink(
            href: '/author/asimov',
            rel: OpdsLinkRel.facet,
            type: 'application/atom+xml',
            title: 'Isaac Asimov',
            facetGroup: 'Author',
            count: 15,
          ),
        ],
        entries: [],
      );

      final groups = feed.facetGroups;
      expect(groups.length, 2);

      final genreGroup = groups.firstWhere((g) => g.name == 'Genre');
      expect(genreGroup.facets.length, 2);
      expect(genreGroup.hasActiveFacet, isTrue);
      expect(genreGroup.activeFacet?.title, 'Fantasy');

      final authorGroup = groups.firstWhere((g) => g.name == 'Author');
      expect(authorGroup.facets.length, 1);
      expect(authorGroup.hasActiveFacet, isFalse);
    });

    test('facetGroups uses "Other" for facets without group', () {
      final feed = OpdsFeed(
        id: 'test',
        title: 'Test Feed',
        updated: DateTime(2024, 1, 1),
        links: [
          OpdsLink(
            href: '/filter/new',
            rel: OpdsLinkRel.facet,
            type: 'application/atom+xml',
            title: 'New Arrivals',
            // No facetGroup specified
          ),
        ],
        entries: [],
      );

      final groups = feed.facetGroups;
      expect(groups.length, 1);
      expect(groups.first.name, 'Other');
      expect(groups.first.facets.first.title, 'New Arrivals');
    });

    test('hasFacets returns false when no facets', () {
      final feed = OpdsFeed(
        id: 'test',
        title: 'Test Feed',
        updated: DateTime(2024, 1, 1),
        links: [
          OpdsLink(
            href: '/self',
            rel: OpdsLinkRel.self,
            type: 'application/atom+xml',
          ),
        ],
        entries: [],
      );

      expect(feed.hasFacets, isFalse);
      expect(feed.facetGroups, isEmpty);
    });
  });

  group('OpdsLinkModel facet parsing', () {
    test('parses facet attributes from XML', () {
      const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom"
      xmlns:opds="http://opds-spec.org/2010/catalog"
      xmlns:thr="http://purl.org/syndication/thread/1.0">
  <id>test</id>
  <title>Test Feed</title>
  <link href="/genre/scifi"
        rel="http://opds-spec.org/facet"
        type="application/atom+xml;profile=opds-catalog;kind=acquisition"
        title="Science Fiction"
        opds:facetGroup="Genre"
        opds:activeFacet="true"
        thr:count="42"/>
  <link href="/genre/fantasy"
        rel="http://opds-spec.org/facet"
        type="application/atom+xml;profile=opds-catalog;kind=acquisition"
        title="Fantasy"
        opds:facetGroup="Genre"
        thr:count="30"/>
</feed>
''';

      final feed = OpdsFeedModel.fromXmlString(xml);

      expect(feed.hasFacets, isTrue);
      expect(feed.facetLinks.length, 2);

      final scifiLink = feed.facetLinks.firstWhere(
        (l) => l.title == 'Science Fiction',
      );
      expect(scifiLink.facetGroup, 'Genre');
      expect(scifiLink.activeFacet, isTrue);
      expect(scifiLink.count, 42);

      final fantasyLink = feed.facetLinks.firstWhere(
        (l) => l.title == 'Fantasy',
      );
      expect(fantasyLink.facetGroup, 'Genre');
      expect(fantasyLink.activeFacet, isNull); // Not set in XML
      expect(fantasyLink.count, 30);
    });

    test('facetGroups correctly groups parsed facets', () {
      const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom"
      xmlns:opds="http://opds-spec.org/2010/catalog"
      xmlns:thr="http://purl.org/syndication/thread/1.0">
  <id>test</id>
  <title>Test Feed</title>
  <link href="/genre/scifi" rel="http://opds-spec.org/facet" title="Sci-Fi" opds:facetGroup="Genre" thr:count="50"/>
  <link href="/genre/fantasy" rel="http://opds-spec.org/facet" title="Fantasy" opds:facetGroup="Genre" thr:count="30"/>
  <link href="/lang/en" rel="http://opds-spec.org/facet" title="English" opds:facetGroup="Language" opds:activeFacet="true"/>
  <link href="/lang/de" rel="http://opds-spec.org/facet" title="German" opds:facetGroup="Language"/>
  <link href="/year/2024" rel="http://opds-spec.org/facet" title="2024" opds:facetGroup="Year"/>
</feed>
''';

      final feed = OpdsFeedModel.fromXmlString(xml);
      final groups = feed.facetGroups;

      expect(groups.length, 3);

      final genreGroup = groups.firstWhere((g) => g.name == 'Genre');
      expect(genreGroup.facets.length, 2);

      final langGroup = groups.firstWhere((g) => g.name == 'Language');
      expect(langGroup.facets.length, 2);
      expect(langGroup.hasActiveFacet, isTrue);
      expect(langGroup.activeFacet?.title, 'English');

      final yearGroup = groups.firstWhere((g) => g.name == 'Year');
      expect(yearGroup.facets.length, 1);
    });

    test('handles feed without facets', () {
      const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>test</id>
  <title>Test Feed</title>
  <link href="/self" rel="self" type="application/atom+xml"/>
  <link href="/next" rel="next" type="application/atom+xml"/>
</feed>
''';

      final feed = OpdsFeedModel.fromXmlString(xml);

      expect(feed.hasFacets, isFalse);
      expect(feed.facetLinks, isEmpty);
      expect(feed.facetGroups, isEmpty);
    });
  });
}
