import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_epub/src/errors/epub_exception.dart';
import 'package:readwhere_epub/src/navigation/ncx_parser.dart';
import 'package:readwhere_epub/src/navigation/toc.dart';

void main() {
  group('NcxParser', () {
    group('parse', () {
      test('parses valid NCX document', () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="urn:uuid:12345"/>
  </head>
  <docTitle><text>Test Book</text></docTitle>
  <navMap>
    <navPoint id="ch1" playOrder="1">
      <navLabel><text>Chapter 1</text></navLabel>
      <content src="chapter1.xhtml"/>
    </navPoint>
    <navPoint id="ch2" playOrder="2">
      <navLabel><text>Chapter 2</text></navLabel>
      <content src="chapter2.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''';

        final result = NcxParser.parse(xml);

        expect(result.tableOfContents, hasLength(2));
        expect(result.tableOfContents[0].id, equals('ch1'));
        expect(result.tableOfContents[0].title, equals('Chapter 1'));
        expect(result.tableOfContents[0].href, equals('chapter1.xhtml'));
        expect(result.tableOfContents[1].title, equals('Chapter 2'));
        expect(result.source, equals(NavigationSource.ncx));
      });

      test('parses nested navPoints', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="part1" playOrder="1">
      <navLabel><text>Part 1</text></navLabel>
      <content src="part1.xhtml"/>
      <navPoint id="ch1" playOrder="2">
        <navLabel><text>Chapter 1</text></navLabel>
        <content src="chapter1.xhtml"/>
      </navPoint>
      <navPoint id="ch2" playOrder="3">
        <navLabel><text>Chapter 2</text></navLabel>
        <content src="chapter2.xhtml"/>
      </navPoint>
    </navPoint>
  </navMap>
</ncx>''';

        final result = NcxParser.parse(xml);

        expect(result.tableOfContents, hasLength(1));
        expect(result.tableOfContents[0].id, equals('part1'));
        expect(result.tableOfContents[0].children, hasLength(2));
        expect(
            result.tableOfContents[0].children[0].title, equals('Chapter 1'));
        expect(result.tableOfContents[0].children[0].level, equals(1));
      });

      test('parses pageList', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="ch1" playOrder="1">
      <navLabel><text>Chapter 1</text></navLabel>
      <content src="chapter1.xhtml"/>
    </navPoint>
  </navMap>
  <pageList>
    <pageTarget type="normal" value="1" playOrder="10">
      <navLabel><text>1</text></navLabel>
      <content src="chapter1.xhtml#page1"/>
    </pageTarget>
    <pageTarget type="normal" value="2" playOrder="11">
      <navLabel><text>2</text></navLabel>
      <content src="chapter1.xhtml#page2"/>
    </pageTarget>
    <pageTarget type="front" playOrder="12">
      <navLabel><text>iii</text></navLabel>
      <content src="front.xhtml#page3"/>
    </pageTarget>
  </pageList>
</ncx>''';

        final result = NcxParser.parse(xml);

        expect(result.pageList, hasLength(3));
        expect(result.pageList[0].label, equals('1'));
        expect(result.pageList[0].pageNumber, equals(1));
        expect(result.pageList[0].href, equals('chapter1.xhtml#page1'));
        expect(result.pageList[2].label, equals('iii'));
        expect(result.pageList[2].pageNumber, isNull);
      });

      test('page number falls back to label parsing', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap/>
  <pageList>
    <pageTarget type="normal" playOrder="1">
      <navLabel><text>42</text></navLabel>
      <content src="chapter1.xhtml#p42"/>
    </pageTarget>
  </pageList>
</ncx>''';

        final result = NcxParser.parse(xml);

        expect(result.pageList[0].label, equals('42'));
        expect(result.pageList[0].pageNumber, equals(42));
      });

      test('returns empty TOC when navMap missing', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
</ncx>''';

        final result = NcxParser.parse(xml);

        expect(result.tableOfContents, isEmpty);
      });

      test('returns empty pageList when pageList missing', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="ch1">
      <navLabel><text>Chapter 1</text></navLabel>
      <content src="chapter1.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''';

        final result = NcxParser.parse(xml);

        expect(result.pageList, isEmpty);
      });

      test('landmarks is always empty for NCX', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="ch1">
      <navLabel><text>Chapter 1</text></navLabel>
      <content src="chapter1.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''';

        final result = NcxParser.parse(xml);

        expect(result.landmarks, isEmpty);
      });

      test('throws EpubParseException on invalid XML', () {
        const invalidXml = 'not valid xml <>';

        expect(
          () => NcxParser.parse(invalidXml),
          throwsA(isA<EpubParseException>()),
        );
      });

      test('includes documentPath in exception', () {
        const invalidXml = 'invalid';

        try {
          NcxParser.parse(invalidXml, documentPath: 'toc.ncx');
          fail('Expected EpubParseException');
        } on EpubParseException catch (e) {
          expect(e.documentPath, equals('toc.ncx'));
        }
      });

      test('throws EpubParseException for wrong root element', () {
        const xml = '''<?xml version="1.0"?>
<wrong-element>
  <navMap/>
</wrong-element>''';

        expect(
          () => NcxParser.parse(xml),
          throwsA(
            isA<EpubParseException>().having(
              (e) => e.message,
              'message',
              contains('expected <ncx> root element'),
            ),
          ),
        );
      });

      test('skips navPoints with empty titles', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="ch1">
      <navLabel><text></text></navLabel>
      <content src="chapter1.xhtml"/>
    </navPoint>
    <navPoint id="ch2">
      <navLabel><text>Valid Chapter</text></navLabel>
      <content src="chapter2.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''';

        final result = NcxParser.parse(xml);

        expect(result.tableOfContents, hasLength(1));
        expect(result.tableOfContents[0].title, equals('Valid Chapter'));
      });

      test('skips navPoints without navLabel', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="ch1">
      <content src="chapter1.xhtml"/>
    </navPoint>
    <navPoint id="ch2">
      <navLabel><text>Valid Chapter</text></navLabel>
      <content src="chapter2.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''';

        final result = NcxParser.parse(xml);

        expect(result.tableOfContents, hasLength(1));
      });

      test('handles missing content src', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="ch1">
      <navLabel><text>Chapter 1</text></navLabel>
    </navPoint>
  </navMap>
</ncx>''';

        final result = NcxParser.parse(xml);

        expect(result.tableOfContents[0].href, equals(''));
      });

      test('generates ID when missing', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint>
      <navLabel><text>Chapter 1</text></navLabel>
      <content src="chapter1.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''';

        final result = NcxParser.parse(xml);

        expect(result.tableOfContents[0].id, startsWith('nav-'));
      });

      test('parses deeply nested navigation', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="l1">
      <navLabel><text>Level 1</text></navLabel>
      <content src="l1.xhtml"/>
      <navPoint id="l2">
        <navLabel><text>Level 2</text></navLabel>
        <content src="l2.xhtml"/>
        <navPoint id="l3">
          <navLabel><text>Level 3</text></navLabel>
          <content src="l3.xhtml"/>
        </navPoint>
      </navPoint>
    </navPoint>
  </navMap>
</ncx>''';

        final result = NcxParser.parse(xml);

        expect(result.tableOfContents[0].level, equals(0));
        expect(result.tableOfContents[0].children[0].level, equals(1));
        expect(
            result.tableOfContents[0].children[0].children[0].level, equals(2));
      });

      test('skips pageTargets without href', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap/>
  <pageList>
    <pageTarget type="normal">
      <navLabel><text>1</text></navLabel>
    </pageTarget>
    <pageTarget type="normal">
      <navLabel><text>2</text></navLabel>
      <content src="ch1.xhtml#p2"/>
    </pageTarget>
  </pageList>
</ncx>''';

        final result = NcxParser.parse(xml);

        expect(result.pageList, hasLength(1));
        expect(result.pageList[0].label, equals('2'));
      });

      test('skips pageTargets without label', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap/>
  <pageList>
    <pageTarget type="normal">
      <content src="ch1.xhtml#p1"/>
    </pageTarget>
    <pageTarget type="normal">
      <navLabel><text>2</text></navLabel>
      <content src="ch1.xhtml#p2"/>
    </pageTarget>
  </pageList>
</ncx>''';

        final result = NcxParser.parse(xml);

        expect(result.pageList, hasLength(1));
        expect(result.pageList[0].label, equals('2'));
      });

      test('handles hrefs with fragments', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="sec1">
      <navLabel><text>Section 1</text></navLabel>
      <content src="chapter1.xhtml#section-1"/>
    </navPoint>
  </navMap>
</ncx>''';

        final result = NcxParser.parse(xml);

        expect(
            result.tableOfContents[0].href, equals('chapter1.xhtml#section-1'));
        expect(
            result.tableOfContents[0].documentHref, equals('chapter1.xhtml'));
        expect(result.tableOfContents[0].fragment, equals('section-1'));
      });
    });

    group('extractTitle', () {
      test('extracts title from docTitle', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <docTitle><text>My Book Title</text></docTitle>
  <navMap/>
</ncx>''';

        final title = NcxParser.extractTitle(xml);

        expect(title, equals('My Book Title'));
      });

      test('returns null when docTitle missing', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap/>
</ncx>''';

        final title = NcxParser.extractTitle(xml);

        expect(title, isNull);
      });

      test('returns null when text element missing', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <docTitle></docTitle>
  <navMap/>
</ncx>''';

        final title = NcxParser.extractTitle(xml);

        expect(title, isNull);
      });

      test('returns null on invalid XML', () {
        const invalidXml = 'not valid xml';

        final title = NcxParser.extractTitle(invalidXml);

        expect(title, isNull);
      });

      test('trims whitespace from title', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <docTitle><text>  My Book Title  </text></docTitle>
  <navMap/>
</ncx>''';

        final title = NcxParser.extractTitle(xml);

        expect(title, equals('My Book Title'));
      });
    });

    group('extractAuthors', () {
      test('extracts single author', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <docAuthor><text>John Doe</text></docAuthor>
  <navMap/>
</ncx>''';

        final authors = NcxParser.extractAuthors(xml);

        expect(authors, hasLength(1));
        expect(authors[0], equals('John Doe'));
      });

      test('extracts multiple authors', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <docAuthor><text>John Doe</text></docAuthor>
  <docAuthor><text>Jane Smith</text></docAuthor>
  <navMap/>
</ncx>''';

        final authors = NcxParser.extractAuthors(xml);

        expect(authors, hasLength(2));
        expect(authors[0], equals('John Doe'));
        expect(authors[1], equals('Jane Smith'));
      });

      test('returns empty list when no docAuthor', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap/>
</ncx>''';

        final authors = NcxParser.extractAuthors(xml);

        expect(authors, isEmpty);
      });

      test('skips empty author names', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <docAuthor><text></text></docAuthor>
  <docAuthor><text>John Doe</text></docAuthor>
  <navMap/>
</ncx>''';

        final authors = NcxParser.extractAuthors(xml);

        expect(authors, hasLength(1));
        expect(authors[0], equals('John Doe'));
      });

      test('skips authors without text element', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <docAuthor></docAuthor>
  <docAuthor><text>John Doe</text></docAuthor>
  <navMap/>
</ncx>''';

        final authors = NcxParser.extractAuthors(xml);

        expect(authors, hasLength(1));
      });

      test('returns empty list on invalid XML', () {
        const invalidXml = 'not valid xml';

        final authors = NcxParser.extractAuthors(invalidXml);

        expect(authors, isEmpty);
      });

      test('trims whitespace from author names', () {
        const xml = '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <docAuthor><text>  John Doe  </text></docAuthor>
  <navMap/>
</ncx>''';

        final authors = NcxParser.extractAuthors(xml);

        expect(authors[0], equals('John Doe'));
      });
    });
  });
}
