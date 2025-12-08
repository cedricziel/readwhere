import 'package:test/test.dart';
import 'package:readwhere_epub/src/errors/epub_exception.dart';
import 'package:readwhere_epub/src/navigation/nav_document.dart';
import 'package:readwhere_epub/src/navigation/toc.dart';

void main() {
  group('NavDocumentParser', () {
    group('parse', () {
      test('parses valid navigation document', () {
        const xhtml = '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head><title>Navigation</title></head>
<body>
  <nav epub:type="toc">
    <ol>
      <li><a href="chapter1.xhtml">Chapter 1</a></li>
      <li><a href="chapter2.xhtml">Chapter 2</a></li>
    </ol>
  </nav>
</body>
</html>''';

        final result = NavDocumentParser.parse(xhtml);

        expect(result.tableOfContents, hasLength(2));
        expect(result.tableOfContents[0].title, equals('Chapter 1'));
        expect(result.tableOfContents[0].href, equals('chapter1.xhtml'));
        expect(result.tableOfContents[1].title, equals('Chapter 2'));
        expect(result.source, equals(NavigationSource.navDocument));
      });

      test('parses nested TOC entries', () {
        const xhtml = '''<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<body>
  <nav epub:type="toc">
    <ol>
      <li>
        <a href="part1.xhtml">Part 1</a>
        <ol>
          <li><a href="ch1.xhtml">Chapter 1</a></li>
          <li><a href="ch2.xhtml">Chapter 2</a></li>
        </ol>
      </li>
    </ol>
  </nav>
</body>
</html>''';

        final result = NavDocumentParser.parse(xhtml);

        expect(result.tableOfContents, hasLength(1));
        expect(result.tableOfContents[0].children, hasLength(2));
        expect(
            result.tableOfContents[0].children[0].title, equals('Chapter 1'));
        expect(result.tableOfContents[0].children[0].level, equals(1));
      });

      test('parses page list', () {
        const xhtml = '''<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<body>
  <nav epub:type="page-list">
    <ol>
      <li><a href="ch1.xhtml#page1">1</a></li>
      <li><a href="ch1.xhtml#page2">2</a></li>
      <li><a href="ch2.xhtml#page3">iii</a></li>
    </ol>
  </nav>
</body>
</html>''';

        final result = NavDocumentParser.parse(xhtml);

        expect(result.pageList, hasLength(3));
        expect(result.pageList[0].label, equals('1'));
        expect(result.pageList[0].pageNumber, equals(1));
        expect(result.pageList[2].label, equals('iii'));
        expect(result.pageList[2].pageNumber, isNull);
      });

      test('parses landmarks', () {
        const xhtml = '''<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<body>
  <nav epub:type="landmarks">
    <ol>
      <li><a epub:type="cover" href="cover.xhtml">Cover</a></li>
      <li><a epub:type="bodymatter" href="chapter1.xhtml">Start Reading</a></li>
      <li><a epub:type="toc" href="toc.xhtml">Table of Contents</a></li>
    </ol>
  </nav>
</body>
</html>''';

        final result = NavDocumentParser.parse(xhtml);

        expect(result.landmarks, hasLength(3));
        expect(result.landmarks[0].type, equals(LandmarkType.cover));
        expect(result.landmarks[0].title, equals('Cover'));
        expect(result.landmarks[1].type, equals(LandmarkType.bodymatter));
        expect(result.landmarks[2].type, equals(LandmarkType.toc));
      });

      test('handles multiple nav sections', () {
        const xhtml = '''<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<body>
  <nav epub:type="toc">
    <ol><li><a href="ch1.xhtml">Chapter 1</a></li></ol>
  </nav>
  <nav epub:type="page-list">
    <ol><li><a href="ch1.xhtml#p1">1</a></li></ol>
  </nav>
  <nav epub:type="landmarks">
    <ol><li><a epub:type="cover" href="cover.xhtml">Cover</a></li></ol>
  </nav>
</body>
</html>''';

        final result = NavDocumentParser.parse(xhtml);

        expect(result.tableOfContents, hasLength(1));
        expect(result.pageList, hasLength(1));
        expect(result.landmarks, hasLength(1));
      });

      test('handles empty nav document', () {
        const xhtml = '''<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<body>
</body>
</html>''';

        final result = NavDocumentParser.parse(xhtml);

        expect(result.tableOfContents, isEmpty);
        expect(result.pageList, isEmpty);
        expect(result.landmarks, isEmpty);
      });

      test('handles TOC entries without href (span)', () {
        const xhtml = '''<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<body>
  <nav epub:type="toc">
    <ol>
      <li>
        <span>Part 1</span>
        <ol>
          <li><a href="ch1.xhtml">Chapter 1</a></li>
        </ol>
      </li>
    </ol>
  </nav>
</body>
</html>''';

        final result = NavDocumentParser.parse(xhtml);

        expect(result.tableOfContents, hasLength(1));
        expect(result.tableOfContents[0].title, equals('Part 1'));
        expect(result.tableOfContents[0].href, equals(''));
      });

      test('handles hidden TOC entries', () {
        const xhtml = '''<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<body>
  <nav epub:type="toc">
    <ol>
      <li><a href="ch1.xhtml">Visible</a></li>
      <li hidden=""><a href="hidden.xhtml">Hidden</a></li>
    </ol>
  </nav>
</body>
</html>''';

        final result = NavDocumentParser.parse(xhtml);

        expect(result.tableOfContents[0].hidden, isFalse);
        expect(result.tableOfContents[1].hidden, isTrue);
      });

      test('throws EpubParseException on invalid XML', () {
        const invalidXhtml = 'not valid xml <>';

        expect(
          () => NavDocumentParser.parse(invalidXhtml),
          throwsA(isA<EpubParseException>()),
        );
      });

      test('throws EpubParseException for wrong root element', () {
        const xhtml = '''<?xml version="1.0"?>
<wrong-element>
  <body></body>
</wrong-element>''';

        expect(
          () => NavDocumentParser.parse(xhtml),
          throwsA(
            isA<EpubParseException>().having(
              (e) => e.message,
              'message',
              contains('expected <html> root element'),
            ),
          ),
        );
      });

      test('throws EpubParseException when body is missing', () {
        const xhtml = '''<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head></head>
</html>''';

        expect(
          () => NavDocumentParser.parse(xhtml),
          throwsA(
            isA<EpubParseException>().having(
              (e) => e.message,
              'message',
              contains('missing <body> element'),
            ),
          ),
        );
      });

      test('includes documentPath in exception', () {
        const invalidXhtml = 'invalid';

        try {
          NavDocumentParser.parse(invalidXhtml, documentPath: 'nav.xhtml');
          fail('Expected EpubParseException');
        } on EpubParseException catch (e) {
          expect(e.documentPath, equals('nav.xhtml'));
        }
      });

      test('skips empty titles', () {
        const xhtml = '''<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<body>
  <nav epub:type="toc">
    <ol>
      <li><a href="ch1.xhtml"></a></li>
      <li><a href="ch2.xhtml">Valid Title</a></li>
    </ol>
  </nav>
</body>
</html>''';

        final result = NavDocumentParser.parse(xhtml);

        expect(result.tableOfContents, hasLength(1));
        expect(result.tableOfContents[0].title, equals('Valid Title'));
      });

      test('handles space-separated epub:type values', () {
        const xhtml = '''<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<body>
  <nav epub:type="toc nav">
    <ol>
      <li><a href="ch1.xhtml">Chapter 1</a></li>
    </ol>
  </nav>
</body>
</html>''';

        final result = NavDocumentParser.parse(xhtml);

        expect(result.tableOfContents, hasLength(1));
      });

      test('handles deeply nested TOC', () {
        const xhtml = '''<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<body>
  <nav epub:type="toc">
    <ol>
      <li>
        <a href="l1.xhtml">Level 1</a>
        <ol>
          <li>
            <a href="l2.xhtml">Level 2</a>
            <ol>
              <li><a href="l3.xhtml">Level 3</a></li>
            </ol>
          </li>
        </ol>
      </li>
    </ol>
  </nav>
</body>
</html>''';

        final result = NavDocumentParser.parse(xhtml);

        expect(result.tableOfContents[0].level, equals(0));
        expect(result.tableOfContents[0].children[0].level, equals(1));
        expect(
            result.tableOfContents[0].children[0].children[0].level, equals(2));
      });
    });
  });

  group('TocEntry', () {
    group('constructor', () {
      test('creates with required fields', () {
        const entry = TocEntry(
          id: 'toc-1',
          title: 'Chapter 1',
          href: 'chapter1.xhtml',
        );

        expect(entry.id, equals('toc-1'));
        expect(entry.title, equals('Chapter 1'));
        expect(entry.href, equals('chapter1.xhtml'));
        expect(entry.level, equals(0));
        expect(entry.children, isEmpty);
        expect(entry.hidden, isFalse);
      });

      test('creates with all fields', () {
        const child = TocEntry(
          id: 'child-1',
          title: 'Section 1',
          href: 'section1.xhtml',
        );
        const entry = TocEntry(
          id: 'toc-1',
          title: 'Chapter 1',
          href: 'chapter1.xhtml',
          level: 1,
          children: [child],
          hidden: true,
        );

        expect(entry.level, equals(1));
        expect(entry.children, hasLength(1));
        expect(entry.hidden, isTrue);
      });
    });

    group('documentHref', () {
      test('returns href without fragment', () {
        const entry = TocEntry(
          id: 'toc-1',
          title: 'Chapter 1',
          href: 'chapter1.xhtml#section-1',
        );

        expect(entry.documentHref, equals('chapter1.xhtml'));
      });

      test('returns full href when no fragment', () {
        const entry = TocEntry(
          id: 'toc-1',
          title: 'Chapter 1',
          href: 'chapter1.xhtml',
        );

        expect(entry.documentHref, equals('chapter1.xhtml'));
      });
    });

    group('fragment', () {
      test('returns fragment identifier', () {
        const entry = TocEntry(
          id: 'toc-1',
          title: 'Chapter 1',
          href: 'chapter1.xhtml#section-1',
        );

        expect(entry.fragment, equals('section-1'));
      });

      test('returns null when no fragment', () {
        const entry = TocEntry(
          id: 'toc-1',
          title: 'Chapter 1',
          href: 'chapter1.xhtml',
        );

        expect(entry.fragment, isNull);
      });
    });

    group('hasChildren', () {
      test('returns true when has children', () {
        const entry = TocEntry(
          id: 'toc-1',
          title: 'Part 1',
          href: 'part1.xhtml',
          children: [
            TocEntry(id: 'ch-1', title: 'Chapter 1', href: 'ch1.xhtml'),
          ],
        );

        expect(entry.hasChildren, isTrue);
      });

      test('returns false when no children', () {
        const entry = TocEntry(
          id: 'toc-1',
          title: 'Chapter 1',
          href: 'ch1.xhtml',
        );

        expect(entry.hasChildren, isFalse);
      });
    });

    group('totalDescendants', () {
      test('returns 0 for no children', () {
        const entry = TocEntry(
          id: 'toc-1',
          title: 'Chapter 1',
          href: 'ch1.xhtml',
        );

        expect(entry.totalDescendants, equals(0));
      });

      test('counts all descendants', () {
        const entry = TocEntry(
          id: 'toc-1',
          title: 'Part 1',
          href: 'part1.xhtml',
          children: [
            TocEntry(
              id: 'ch-1',
              title: 'Chapter 1',
              href: 'ch1.xhtml',
              children: [
                TocEntry(id: 'sec-1', title: 'Section 1', href: 'sec1.xhtml'),
                TocEntry(id: 'sec-2', title: 'Section 2', href: 'sec2.xhtml'),
              ],
            ),
            TocEntry(id: 'ch-2', title: 'Chapter 2', href: 'ch2.xhtml'),
          ],
        );

        expect(entry.totalDescendants, equals(4));
      });
    });

    group('flatten', () {
      test('returns list with self for leaf entry', () {
        const entry = TocEntry(
          id: 'toc-1',
          title: 'Chapter 1',
          href: 'ch1.xhtml',
        );

        final flat = entry.flatten();

        expect(flat, hasLength(1));
        expect(flat[0], equals(entry));
      });

      test('flattens nested entries', () {
        const entry = TocEntry(
          id: 'part',
          title: 'Part 1',
          href: 'part1.xhtml',
          children: [
            TocEntry(id: 'ch1', title: 'Chapter 1', href: 'ch1.xhtml'),
            TocEntry(id: 'ch2', title: 'Chapter 2', href: 'ch2.xhtml'),
          ],
        );

        final flat = entry.flatten();

        expect(flat, hasLength(3));
        expect(flat[0].id, equals('part'));
        expect(flat[1].id, equals('ch1'));
        expect(flat[2].id, equals('ch2'));
      });
    });

    group('copyWith', () {
      test('copies with modified fields', () {
        const original = TocEntry(
          id: 'toc-1',
          title: 'Chapter 1',
          href: 'ch1.xhtml',
        );

        final copy = original.copyWith(title: 'New Title', hidden: true);

        expect(copy.id, equals('toc-1'));
        expect(copy.title, equals('New Title'));
        expect(copy.href, equals('ch1.xhtml'));
        expect(copy.hidden, isTrue);
      });
    });

    group('toString', () {
      test('includes title and href', () {
        const entry = TocEntry(
          id: 'toc-1',
          title: 'Chapter 1',
          href: 'ch1.xhtml',
        );

        expect(entry.toString(), equals('TocEntry(Chapter 1 -> ch1.xhtml)'));
      });
    });

    group('Equatable', () {
      test('equal entries are equal', () {
        const entry1 = TocEntry(id: 'toc-1', title: 'Ch1', href: 'ch1.xhtml');
        const entry2 = TocEntry(id: 'toc-1', title: 'Ch1', href: 'ch1.xhtml');

        expect(entry1, equals(entry2));
        expect(entry1.hashCode, equals(entry2.hashCode));
      });

      test('different entries are not equal', () {
        const entry1 = TocEntry(id: 'toc-1', title: 'Ch1', href: 'ch1.xhtml');
        const entry2 = TocEntry(id: 'toc-2', title: 'Ch2', href: 'ch2.xhtml');

        expect(entry1, isNot(equals(entry2)));
      });
    });
  });

  group('PageEntry', () {
    group('constructor', () {
      test('creates with required fields', () {
        const entry = PageEntry(href: 'ch1.xhtml#p1', label: '1');

        expect(entry.href, equals('ch1.xhtml#p1'));
        expect(entry.label, equals('1'));
        expect(entry.pageNumber, isNull);
      });

      test('creates with page number', () {
        const entry = PageEntry(
          href: 'ch1.xhtml#p1',
          label: '42',
          pageNumber: 42,
        );

        expect(entry.pageNumber, equals(42));
      });
    });

    group('Equatable', () {
      test('equal entries are equal', () {
        const entry1 = PageEntry(href: 'ch1.xhtml', label: '1', pageNumber: 1);
        const entry2 = PageEntry(href: 'ch1.xhtml', label: '1', pageNumber: 1);

        expect(entry1, equals(entry2));
        expect(entry1.hashCode, equals(entry2.hashCode));
      });

      test('different entries are not equal', () {
        const entry1 = PageEntry(href: 'ch1.xhtml', label: '1');
        const entry2 = PageEntry(href: 'ch2.xhtml', label: '2');

        expect(entry1, isNot(equals(entry2)));
      });
    });
  });

  group('Landmark', () {
    group('constructor', () {
      test('creates with required fields', () {
        const landmark = Landmark(
          href: 'cover.xhtml',
          title: 'Cover',
          type: LandmarkType.cover,
        );

        expect(landmark.href, equals('cover.xhtml'));
        expect(landmark.title, equals('Cover'));
        expect(landmark.type, equals(LandmarkType.cover));
      });
    });

    group('Equatable', () {
      test('equal landmarks are equal', () {
        const lm1 = Landmark(
          href: 'cover.xhtml',
          title: 'Cover',
          type: LandmarkType.cover,
        );
        const lm2 = Landmark(
          href: 'cover.xhtml',
          title: 'Cover',
          type: LandmarkType.cover,
        );

        expect(lm1, equals(lm2));
        expect(lm1.hashCode, equals(lm2.hashCode));
      });

      test('different landmarks are not equal', () {
        const lm1 = Landmark(
          href: 'cover.xhtml',
          title: 'Cover',
          type: LandmarkType.cover,
        );
        const lm2 = Landmark(
          href: 'toc.xhtml',
          title: 'TOC',
          type: LandmarkType.toc,
        );

        expect(lm1, isNot(equals(lm2)));
      });
    });
  });

  group('LandmarkType', () {
    test('has all expected values', () {
      expect(LandmarkType.values, contains(LandmarkType.cover));
      expect(LandmarkType.values, contains(LandmarkType.titlePage));
      expect(LandmarkType.values, contains(LandmarkType.toc));
      expect(LandmarkType.values, contains(LandmarkType.bodymatter));
      expect(LandmarkType.values, contains(LandmarkType.frontmatter));
      expect(LandmarkType.values, contains(LandmarkType.backmatter));
      expect(LandmarkType.values, contains(LandmarkType.loi));
      expect(LandmarkType.values, contains(LandmarkType.lot));
      expect(LandmarkType.values, contains(LandmarkType.preface));
      expect(LandmarkType.values, contains(LandmarkType.bibliography));
      expect(LandmarkType.values, contains(LandmarkType.bookIndex));
      expect(LandmarkType.values, contains(LandmarkType.glossary));
      expect(LandmarkType.values, contains(LandmarkType.acknowledgments));
      expect(LandmarkType.values, contains(LandmarkType.copyright));
      expect(LandmarkType.values, contains(LandmarkType.dedication));
      expect(LandmarkType.values, contains(LandmarkType.epigraph));
      expect(LandmarkType.values, contains(LandmarkType.foreword));
      expect(LandmarkType.values, contains(LandmarkType.other));
    });

    group('fromEpubType', () {
      test('parses cover', () {
        expect(LandmarkType.fromEpubType('cover'), equals(LandmarkType.cover));
      });

      test('parses title-page', () {
        expect(
          LandmarkType.fromEpubType('title-page'),
          equals(LandmarkType.titlePage),
        );
      });

      test('parses titlepage (without hyphen)', () {
        expect(
          LandmarkType.fromEpubType('titlepage'),
          equals(LandmarkType.titlePage),
        );
      });

      test('parses toc', () {
        expect(LandmarkType.fromEpubType('toc'), equals(LandmarkType.toc));
      });

      test('parses bodymatter', () {
        expect(
          LandmarkType.fromEpubType('bodymatter'),
          equals(LandmarkType.bodymatter),
        );
      });

      test('parses frontmatter', () {
        expect(
          LandmarkType.fromEpubType('frontmatter'),
          equals(LandmarkType.frontmatter),
        );
      });

      test('parses backmatter', () {
        expect(
          LandmarkType.fromEpubType('backmatter'),
          equals(LandmarkType.backmatter),
        );
      });

      test('parses index to bookIndex', () {
        expect(
          LandmarkType.fromEpubType('index'),
          equals(LandmarkType.bookIndex),
        );
      });

      test('parses acknowledgments', () {
        expect(
          LandmarkType.fromEpubType('acknowledgments'),
          equals(LandmarkType.acknowledgments),
        );
      });

      test('parses acknowledgements (British spelling)', () {
        expect(
          LandmarkType.fromEpubType('acknowledgements'),
          equals(LandmarkType.acknowledgments),
        );
      });

      test('parses copyright', () {
        expect(
          LandmarkType.fromEpubType('copyright'),
          equals(LandmarkType.copyright),
        );
      });

      test('parses copyright-page', () {
        expect(
          LandmarkType.fromEpubType('copyright-page'),
          equals(LandmarkType.copyright),
        );
      });

      test('is case insensitive', () {
        expect(LandmarkType.fromEpubType('COVER'), equals(LandmarkType.cover));
        expect(LandmarkType.fromEpubType('Cover'), equals(LandmarkType.cover));
      });

      test('returns other for unknown type', () {
        expect(
          LandmarkType.fromEpubType('unknown-type'),
          equals(LandmarkType.other),
        );
      });
    });
  });

  group('NavigationSource', () {
    test('has navDocument value', () {
      expect(NavigationSource.navDocument, isNotNull);
    });

    test('has ncx value', () {
      expect(NavigationSource.ncx, isNotNull);
    });

    test('has spine value', () {
      expect(NavigationSource.spine, isNotNull);
    });

    test('has exactly 3 values', () {
      expect(NavigationSource.values, hasLength(3));
    });
  });

  group('EpubNavigation', () {
    group('constructor', () {
      test('creates with required source', () {
        const nav = EpubNavigation(source: NavigationSource.navDocument);

        expect(nav.tableOfContents, isEmpty);
        expect(nav.pageList, isEmpty);
        expect(nav.landmarks, isEmpty);
        expect(nav.source, equals(NavigationSource.navDocument));
      });

      test('creates with all fields', () {
        const nav = EpubNavigation(
          tableOfContents: [
            TocEntry(id: 'ch1', title: 'Chapter 1', href: 'ch1.xhtml'),
          ],
          pageList: [PageEntry(href: 'ch1.xhtml#p1', label: '1')],
          landmarks: [
            Landmark(
                href: 'cover.xhtml', title: 'Cover', type: LandmarkType.cover),
          ],
          source: NavigationSource.navDocument,
        );

        expect(nav.tableOfContents, hasLength(1));
        expect(nav.pageList, hasLength(1));
        expect(nav.landmarks, hasLength(1));
      });
    });

    group('isEmpty', () {
      test('returns true when no TOC entries', () {
        const nav = EpubNavigation(source: NavigationSource.spine);
        expect(nav.isEmpty, isTrue);
      });

      test('returns false when has TOC entries', () {
        const nav = EpubNavigation(
          tableOfContents: [
            TocEntry(id: 'ch1', title: 'Chapter 1', href: 'ch1.xhtml'),
          ],
          source: NavigationSource.navDocument,
        );
        expect(nav.isEmpty, isFalse);
      });
    });

    group('isNotEmpty', () {
      test('returns true when has TOC entries', () {
        const nav = EpubNavigation(
          tableOfContents: [
            TocEntry(id: 'ch1', title: 'Chapter 1', href: 'ch1.xhtml'),
          ],
          source: NavigationSource.navDocument,
        );
        expect(nav.isNotEmpty, isTrue);
      });

      test('returns false when no TOC entries', () {
        const nav = EpubNavigation(source: NavigationSource.spine);
        expect(nav.isNotEmpty, isFalse);
      });
    });

    group('length', () {
      test('returns number of top-level TOC entries', () {
        const nav = EpubNavigation(
          tableOfContents: [
            TocEntry(id: 'ch1', title: 'Chapter 1', href: 'ch1.xhtml'),
            TocEntry(id: 'ch2', title: 'Chapter 2', href: 'ch2.xhtml'),
          ],
          source: NavigationSource.navDocument,
        );
        expect(nav.length, equals(2));
      });
    });

    group('flattenedToc', () {
      test('flattens nested TOC', () {
        const nav = EpubNavigation(
          tableOfContents: [
            TocEntry(
              id: 'part1',
              title: 'Part 1',
              href: 'part1.xhtml',
              children: [
                TocEntry(id: 'ch1', title: 'Chapter 1', href: 'ch1.xhtml'),
              ],
            ),
            TocEntry(id: 'part2', title: 'Part 2', href: 'part2.xhtml'),
          ],
          source: NavigationSource.navDocument,
        );

        expect(nav.flattenedToc, hasLength(3));
      });

      test('returns empty list for empty TOC', () {
        const nav = EpubNavigation(source: NavigationSource.spine);
        expect(nav.flattenedToc, isEmpty);
      });
    });

    group('maxDepth', () {
      test('returns 0 for empty TOC', () {
        const nav = EpubNavigation(source: NavigationSource.spine);
        expect(nav.maxDepth, equals(0));
      });

      test('returns 1 for flat TOC', () {
        const nav = EpubNavigation(
          tableOfContents: [
            TocEntry(id: 'ch1', title: 'Chapter 1', href: 'ch1.xhtml'),
          ],
          source: NavigationSource.navDocument,
        );
        expect(nav.maxDepth, equals(1));
      });

      test('returns correct depth for nested TOC', () {
        const nav = EpubNavigation(
          tableOfContents: [
            TocEntry(
              id: 'part1',
              title: 'Part 1',
              href: 'part1.xhtml',
              children: [
                TocEntry(
                  id: 'ch1',
                  title: 'Chapter 1',
                  href: 'ch1.xhtml',
                  children: [
                    TocEntry(
                        id: 'sec1', title: 'Section 1', href: 'sec1.xhtml'),
                  ],
                ),
              ],
            ),
          ],
          source: NavigationSource.navDocument,
        );
        expect(nav.maxDepth, equals(3));
      });
    });

    group('findByHref', () {
      test('finds entry by exact href', () {
        const nav = EpubNavigation(
          tableOfContents: [
            TocEntry(id: 'ch1', title: 'Chapter 1', href: 'ch1.xhtml'),
            TocEntry(id: 'ch2', title: 'Chapter 2', href: 'ch2.xhtml'),
          ],
          source: NavigationSource.navDocument,
        );

        final found = nav.findByHref('ch2.xhtml');
        expect(found?.title, equals('Chapter 2'));
      });

      test('finds entry by document href', () {
        const nav = EpubNavigation(
          tableOfContents: [
            TocEntry(
              id: 'ch1',
              title: 'Chapter 1',
              href: 'ch1.xhtml#section',
            ),
          ],
          source: NavigationSource.navDocument,
        );

        final found = nav.findByHref('ch1.xhtml');
        expect(found?.title, equals('Chapter 1'));
      });

      test('finds nested entry', () {
        const nav = EpubNavigation(
          tableOfContents: [
            TocEntry(
              id: 'part1',
              title: 'Part 1',
              href: 'part1.xhtml',
              children: [
                TocEntry(id: 'ch1', title: 'Chapter 1', href: 'ch1.xhtml'),
              ],
            ),
          ],
          source: NavigationSource.navDocument,
        );

        final found = nav.findByHref('ch1.xhtml');
        expect(found?.title, equals('Chapter 1'));
      });

      test('returns null when not found', () {
        const nav = EpubNavigation(
          tableOfContents: [
            TocEntry(id: 'ch1', title: 'Chapter 1', href: 'ch1.xhtml'),
          ],
          source: NavigationSource.navDocument,
        );

        expect(nav.findByHref('unknown.xhtml'), isNull);
      });

      test('is case insensitive', () {
        const nav = EpubNavigation(
          tableOfContents: [
            TocEntry(id: 'ch1', title: 'Chapter 1', href: 'Chapter1.xhtml'),
          ],
          source: NavigationSource.navDocument,
        );

        final found = nav.findByHref('chapter1.xhtml');
        expect(found?.title, equals('Chapter 1'));
      });
    });

    group('getLandmark', () {
      test('returns landmark by type', () {
        const nav = EpubNavigation(
          landmarks: [
            Landmark(
                href: 'cover.xhtml', title: 'Cover', type: LandmarkType.cover),
            Landmark(
                href: 'ch1.xhtml',
                title: 'Start',
                type: LandmarkType.bodymatter),
          ],
          source: NavigationSource.navDocument,
        );

        expect(
            nav.getLandmark(LandmarkType.cover)?.href, equals('cover.xhtml'));
      });

      test('returns null when type not found', () {
        const nav = EpubNavigation(
          landmarks: [
            Landmark(
                href: 'cover.xhtml', title: 'Cover', type: LandmarkType.cover),
          ],
          source: NavigationSource.navDocument,
        );

        expect(nav.getLandmark(LandmarkType.toc), isNull);
      });
    });

    group('convenience getters', () {
      test('cover returns cover landmark', () {
        const nav = EpubNavigation(
          landmarks: [
            Landmark(
                href: 'cover.xhtml', title: 'Cover', type: LandmarkType.cover),
          ],
          source: NavigationSource.navDocument,
        );

        expect(nav.cover?.href, equals('cover.xhtml'));
      });

      test('bodymatter returns bodymatter landmark', () {
        const nav = EpubNavigation(
          landmarks: [
            Landmark(
                href: 'ch1.xhtml',
                title: 'Start',
                type: LandmarkType.bodymatter),
          ],
          source: NavigationSource.navDocument,
        );

        expect(nav.bodymatter?.href, equals('ch1.xhtml'));
      });

      test('tocLandmark returns toc landmark', () {
        const nav = EpubNavigation(
          landmarks: [
            Landmark(href: 'toc.xhtml', title: 'TOC', type: LandmarkType.toc),
          ],
          source: NavigationSource.navDocument,
        );

        expect(nav.tocLandmark?.href, equals('toc.xhtml'));
      });
    });

    group('hasPageList', () {
      test('returns true when page list is not empty', () {
        const nav = EpubNavigation(
          pageList: [PageEntry(href: 'ch1.xhtml', label: '1')],
          source: NavigationSource.navDocument,
        );

        expect(nav.hasPageList, isTrue);
      });

      test('returns false when page list is empty', () {
        const nav = EpubNavigation(source: NavigationSource.navDocument);

        expect(nav.hasPageList, isFalse);
      });
    });

    group('getPage', () {
      test('returns page by number', () {
        const nav = EpubNavigation(
          pageList: [
            PageEntry(href: 'ch1.xhtml#p1', label: '1', pageNumber: 1),
            PageEntry(href: 'ch1.xhtml#p2', label: '2', pageNumber: 2),
          ],
          source: NavigationSource.navDocument,
        );

        expect(nav.getPage(2)?.label, equals('2'));
      });

      test('returns null when page not found', () {
        const nav = EpubNavigation(
          pageList: [PageEntry(href: 'ch1.xhtml', label: '1', pageNumber: 1)],
          source: NavigationSource.navDocument,
        );

        expect(nav.getPage(99), isNull);
      });
    });

    group('Equatable', () {
      test('equal navigations are equal', () {
        const nav1 = EpubNavigation(
          tableOfContents: [
            TocEntry(id: 'ch1', title: 'Chapter 1', href: 'ch1.xhtml'),
          ],
          source: NavigationSource.navDocument,
        );
        const nav2 = EpubNavigation(
          tableOfContents: [
            TocEntry(id: 'ch1', title: 'Chapter 1', href: 'ch1.xhtml'),
          ],
          source: NavigationSource.navDocument,
        );

        expect(nav1, equals(nav2));
        expect(nav1.hashCode, equals(nav2.hashCode));
      });

      test('different navigations are not equal', () {
        const nav1 = EpubNavigation(source: NavigationSource.navDocument);
        const nav2 = EpubNavigation(source: NavigationSource.ncx);

        expect(nav1, isNot(equals(nav2)));
      });
    });
  });
}
