import 'package:readwhere_epub/src/navigation/toc.dart';
import 'package:test/test.dart';

void main() {
  group('TocEntry', () {
    test('creates basic entry', () {
      const entry = TocEntry(
        id: 'ch1',
        title: 'Chapter 1',
        href: 'chapter1.xhtml',
      );

      expect(entry.id, equals('ch1'));
      expect(entry.title, equals('Chapter 1'));
      expect(entry.href, equals('chapter1.xhtml'));
      expect(entry.level, equals(0));
      expect(entry.children, isEmpty);
      expect(entry.hidden, isFalse);
    });

    test('documentHref removes fragment', () {
      const entry = TocEntry(
        id: 'ch1',
        title: 'Section 1',
        href: 'chapter1.xhtml#section1',
      );

      expect(entry.documentHref, equals('chapter1.xhtml'));
    });

    test('fragment extracts fragment identifier', () {
      const entry = TocEntry(
        id: 'ch1',
        title: 'Section 1',
        href: 'chapter1.xhtml#section1',
      );

      expect(entry.fragment, equals('section1'));
    });

    test('fragment returns null when no fragment', () {
      const entry = TocEntry(
        id: 'ch1',
        title: 'Chapter 1',
        href: 'chapter1.xhtml',
      );

      expect(entry.fragment, isNull);
    });

    test('hasChildren returns correct value', () {
      const entryWithoutChildren = TocEntry(
        id: 'ch1',
        title: 'Chapter 1',
        href: 'chapter1.xhtml',
      );
      expect(entryWithoutChildren.hasChildren, isFalse);

      const entryWithChildren = TocEntry(
        id: 'ch1',
        title: 'Chapter 1',
        href: 'chapter1.xhtml',
        children: [
          TocEntry(id: 'ch1-1', title: 'Section 1', href: 'chapter1.xhtml#s1'),
        ],
      );
      expect(entryWithChildren.hasChildren, isTrue);
    });

    test('totalDescendants counts all descendants', () {
      const entry = TocEntry(
        id: 'ch1',
        title: 'Chapter 1',
        href: 'chapter1.xhtml',
        children: [
          TocEntry(
            id: 'ch1-1',
            title: 'Section 1',
            href: 'chapter1.xhtml#s1',
            level: 1,
            children: [
              TocEntry(
                  id: 'ch1-1-1',
                  title: 'Sub 1',
                  href: 'chapter1.xhtml#s1-1',
                  level: 2),
              TocEntry(
                  id: 'ch1-1-2',
                  title: 'Sub 2',
                  href: 'chapter1.xhtml#s1-2',
                  level: 2),
            ],
          ),
          TocEntry(
              id: 'ch1-2',
              title: 'Section 2',
              href: 'chapter1.xhtml#s2',
              level: 1),
        ],
      );

      expect(entry.totalDescendants, equals(4)); // 2 children + 2 grandchildren
    });

    test('flatten returns all entries including self', () {
      const entry = TocEntry(
        id: 'ch1',
        title: 'Chapter 1',
        href: 'chapter1.xhtml',
        children: [
          TocEntry(
              id: 'ch1-1',
              title: 'Section 1',
              href: 'chapter1.xhtml#s1',
              level: 1),
          TocEntry(
              id: 'ch1-2',
              title: 'Section 2',
              href: 'chapter1.xhtml#s2',
              level: 1),
        ],
      );

      final flattened = entry.flatten();
      expect(flattened.length, equals(3));
      expect(flattened[0].id, equals('ch1'));
      expect(flattened[1].id, equals('ch1-1'));
      expect(flattened[2].id, equals('ch1-2'));
    });

    test('copyWith creates modified copy', () {
      const original = TocEntry(
        id: 'ch1',
        title: 'Chapter 1',
        href: 'chapter1.xhtml',
      );

      final copy = original.copyWith(title: 'Updated Title');
      expect(copy.id, equals('ch1'));
      expect(copy.title, equals('Updated Title'));
      expect(copy.href, equals('chapter1.xhtml'));
    });
  });

  group('PageEntry', () {
    test('creates page entry', () {
      const page = PageEntry(
        href: 'chapter1.xhtml#page42',
        label: '42',
        pageNumber: 42,
      );

      expect(page.href, equals('chapter1.xhtml#page42'));
      expect(page.label, equals('42'));
      expect(page.pageNumber, equals(42));
    });
  });

  group('LandmarkType', () {
    test('parses standard types', () {
      expect(LandmarkType.fromEpubType('cover'), equals(LandmarkType.cover));
      expect(LandmarkType.fromEpubType('toc'), equals(LandmarkType.toc));
      expect(LandmarkType.fromEpubType('bodymatter'),
          equals(LandmarkType.bodymatter));
    });

    test('parses with hyphens removed', () {
      expect(LandmarkType.fromEpubType('title-page'),
          equals(LandmarkType.titlePage));
    });

    test('parses case insensitively', () {
      expect(LandmarkType.fromEpubType('COVER'), equals(LandmarkType.cover));
      expect(LandmarkType.fromEpubType('ToC'), equals(LandmarkType.toc));
    });

    test('returns other for unknown types', () {
      expect(LandmarkType.fromEpubType('unknown'), equals(LandmarkType.other));
    });
  });

  group('EpubNavigation', () {
    test('isEmpty returns true for empty TOC', () {
      const nav = EpubNavigation(
        tableOfContents: [],
        source: NavigationSource.spine,
      );

      expect(nav.isEmpty, isTrue);
      expect(nav.isNotEmpty, isFalse);
    });

    test('flattenedToc flattens all entries', () {
      const nav = EpubNavigation(
        tableOfContents: [
          TocEntry(
            id: 'ch1',
            title: 'Chapter 1',
            href: 'chapter1.xhtml',
            children: [
              TocEntry(
                  id: 'ch1-1',
                  title: 'Section 1',
                  href: 'chapter1.xhtml#s1',
                  level: 1),
            ],
          ),
          TocEntry(id: 'ch2', title: 'Chapter 2', href: 'chapter2.xhtml'),
        ],
        source: NavigationSource.navDocument,
      );

      final flattened = nav.flattenedToc;
      expect(flattened.length, equals(3));
    });

    test('maxDepth calculates correctly', () {
      const nav = EpubNavigation(
        tableOfContents: [
          TocEntry(
            id: 'ch1',
            title: 'Chapter 1',
            href: 'chapter1.xhtml',
            children: [
              TocEntry(
                id: 'ch1-1',
                title: 'Section 1',
                href: 'chapter1.xhtml#s1',
                level: 1,
                children: [
                  TocEntry(
                      id: 'ch1-1-1',
                      title: 'Sub 1',
                      href: 'chapter1.xhtml#s1-1',
                      level: 2),
                ],
              ),
            ],
          ),
        ],
        source: NavigationSource.navDocument,
      );

      expect(nav.maxDepth, equals(3));
    });

    test('findByHref locates entry', () {
      const nav = EpubNavigation(
        tableOfContents: [
          TocEntry(id: 'ch1', title: 'Chapter 1', href: 'chapter1.xhtml'),
          TocEntry(id: 'ch2', title: 'Chapter 2', href: 'chapter2.xhtml'),
        ],
        source: NavigationSource.navDocument,
      );

      final found = nav.findByHref('chapter2.xhtml');
      expect(found?.title, equals('Chapter 2'));
    });

    test('getLandmark retrieves by type', () {
      const nav = EpubNavigation(
        tableOfContents: [],
        landmarks: [
          Landmark(
              href: 'cover.xhtml', title: 'Cover', type: LandmarkType.cover),
          Landmark(
              href: 'toc.xhtml',
              title: 'Table of Contents',
              type: LandmarkType.toc),
        ],
        source: NavigationSource.navDocument,
      );

      expect(nav.cover?.href, equals('cover.xhtml'));
      expect(nav.tocLandmark?.href, equals('toc.xhtml'));
    });
  });
}
