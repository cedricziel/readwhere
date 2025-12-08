import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_epub/src/container/container_parser.dart';
import 'package:readwhere_epub/src/errors/epub_exception.dart';

void main() {
  group('ContainerParser', () {
    group('containerPath', () {
      test('has correct value', () {
        expect(ContainerParser.containerPath, equals('META-INF/container.xml'));
      });
    });

    group('parse', () {
      test('parses valid container.xml', () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

        final result = ContainerParser.parse(xml);

        expect(result.version, equals('1.0'));
        expect(result.rootfiles, hasLength(1));
        expect(result.rootfiles.first.fullPath, equals('OEBPS/content.opf'));
        expect(
          result.rootfiles.first.mediaType,
          equals('application/oebps-package+xml'),
        );
      });

      test('parses container with multiple rootfiles', () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
    <rootfile full-path="OEBPS/fixed-layout.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

        final result = ContainerParser.parse(xml);

        expect(result.rootfiles, hasLength(2));
        expect(result.rootfiles[0].fullPath, equals('OEBPS/content.opf'));
        expect(result.rootfiles[1].fullPath, equals('OEBPS/fixed-layout.opf'));
      });

      test('defaults version to 1.0 when not specified', () {
        const xml = '''<?xml version="1.0"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

        final result = ContainerParser.parse(xml);

        expect(result.version, equals('1.0'));
      });

      test('defaults media-type when not specified', () {
        const xml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="content.opf"/>
  </rootfiles>
</container>''';

        final result = ContainerParser.parse(xml);

        expect(
          result.rootfiles.first.mediaType,
          equals('application/oebps-package+xml'),
        );
      });

      test('throws EpubParseException on invalid XML', () {
        const invalidXml = 'not valid xml <>';

        expect(
          () => ContainerParser.parse(invalidXml),
          throwsA(isA<EpubParseException>()),
        );
      });

      test('exception message includes container path on invalid XML', () {
        const invalidXml = 'not valid xml';

        try {
          ContainerParser.parse(invalidXml);
          fail('Expected EpubParseException');
        } on EpubParseException catch (e) {
          expect(e.documentPath, equals(ContainerParser.containerPath));
        }
      });

      test('throws EpubParseException for wrong root element', () {
        const xml = '''<?xml version="1.0"?>
<wrong-element>
  <rootfiles>
    <rootfile full-path="content.opf"/>
  </rootfiles>
</wrong-element>''';

        expect(
          () => ContainerParser.parse(xml),
          throwsA(
            isA<EpubParseException>().having(
              (e) => e.message,
              'message',
              contains('expected <container> root element'),
            ),
          ),
        );
      });

      test('throws EpubParseException when rootfiles element missing', () {
        const xml = '''<?xml version="1.0"?>
<container version="1.0">
</container>''';

        expect(
          () => ContainerParser.parse(xml),
          throwsA(
            isA<EpubParseException>().having(
              (e) => e.message,
              'message',
              contains('missing <rootfiles> element'),
            ),
          ),
        );
      });

      test('throws EpubParseException when no rootfile elements', () {
        const xml = '''<?xml version="1.0"?>
<container version="1.0">
  <rootfiles>
  </rootfiles>
</container>''';

        expect(
          () => ContainerParser.parse(xml),
          throwsA(
            isA<EpubParseException>().having(
              (e) => e.message,
              'message',
              contains('no <rootfile> elements found'),
            ),
          ),
        );
      });

      test('throws EpubParseException when full-path missing', () {
        const xml = '''<?xml version="1.0"?>
<container version="1.0">
  <rootfiles>
    <rootfile media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

        expect(
          () => ContainerParser.parse(xml),
          throwsA(
            isA<EpubParseException>().having(
              (e) => e.message,
              'message',
              contains('missing full-path attribute'),
            ),
          ),
        );
      });

      test('throws EpubParseException when full-path is empty', () {
        const xml = '''<?xml version="1.0"?>
<container version="1.0">
  <rootfiles>
    <rootfile full-path=""/>
  </rootfiles>
</container>''';

        expect(
          () => ContainerParser.parse(xml),
          throwsA(
            isA<EpubParseException>().having(
              (e) => e.message,
              'message',
              contains('missing full-path attribute'),
            ),
          ),
        );
      });

      test('parses different container versions', () {
        const xml = '''<?xml version="1.0"?>
<container version="2.0">
  <rootfiles>
    <rootfile full-path="content.opf"/>
  </rootfiles>
</container>''';

        final result = ContainerParser.parse(xml);

        expect(result.version, equals('2.0'));
      });

      test('handles paths with special characters', () {
        const xml = '''<?xml version="1.0"?>
<container version="1.0">
  <rootfiles>
    <rootfile full-path="OPS/content%20file.opf"/>
  </rootfiles>
</container>''';

        final result = ContainerParser.parse(xml);

        expect(
            result.rootfiles.first.fullPath, equals('OPS/content%20file.opf'));
      });

      test('handles nested directory paths', () {
        const xml = '''<?xml version="1.0"?>
<container version="1.0">
  <rootfiles>
    <rootfile full-path="deep/nested/path/content.opf"/>
  </rootfiles>
</container>''';

        final result = ContainerParser.parse(xml);

        expect(
          result.rootfiles.first.fullPath,
          equals('deep/nested/path/content.opf'),
        );
      });

      test('handles custom media types', () {
        const xml = '''<?xml version="1.0"?>
<container version="1.0">
  <rootfiles>
    <rootfile full-path="content.opf" media-type="custom/type"/>
  </rootfiles>
</container>''';

        final result = ContainerParser.parse(xml);

        expect(result.rootfiles.first.mediaType, equals('custom/type'));
      });
    });
  });

  group('ContainerDocument', () {
    group('constructor', () {
      test('creates with required fields', () {
        const doc = ContainerDocument(
          version: '1.0',
          rootfiles: [
            Rootfile(
              fullPath: 'content.opf',
              mediaType: 'application/oebps-package+xml',
            ),
          ],
        );

        expect(doc.version, equals('1.0'));
        expect(doc.rootfiles, hasLength(1));
      });

      test('creates with multiple rootfiles', () {
        const doc = ContainerDocument(
          version: '1.0',
          rootfiles: [
            Rootfile(
                fullPath: 'a.opf', mediaType: 'application/oebps-package+xml'),
            Rootfile(
                fullPath: 'b.opf', mediaType: 'application/oebps-package+xml'),
          ],
        );

        expect(doc.rootfiles, hasLength(2));
      });
    });

    group('primaryRootfile', () {
      test('returns first rootfile', () {
        const doc = ContainerDocument(
          version: '1.0',
          rootfiles: [
            Rootfile(
                fullPath: 'first.opf',
                mediaType: 'application/oebps-package+xml'),
            Rootfile(
                fullPath: 'second.opf',
                mediaType: 'application/oebps-package+xml'),
          ],
        );

        expect(doc.primaryRootfile.fullPath, equals('first.opf'));
      });
    });

    group('primaryOpfPath', () {
      test('returns full-path of first rootfile', () {
        const doc = ContainerDocument(
          version: '1.0',
          rootfiles: [
            Rootfile(
                fullPath: 'OEBPS/content.opf',
                mediaType: 'application/oebps-package+xml'),
          ],
        );

        expect(doc.primaryOpfPath, equals('OEBPS/content.opf'));
      });
    });

    group('hasMultipleRenditions', () {
      test('returns false for single rootfile', () {
        const doc = ContainerDocument(
          version: '1.0',
          rootfiles: [
            Rootfile(
                fullPath: 'content.opf',
                mediaType: 'application/oebps-package+xml'),
          ],
        );

        expect(doc.hasMultipleRenditions, isFalse);
      });

      test('returns true for multiple rootfiles', () {
        const doc = ContainerDocument(
          version: '1.0',
          rootfiles: [
            Rootfile(
                fullPath: 'a.opf', mediaType: 'application/oebps-package+xml'),
            Rootfile(
                fullPath: 'b.opf', mediaType: 'application/oebps-package+xml'),
          ],
        );

        expect(doc.hasMultipleRenditions, isTrue);
      });
    });

    group('Equatable', () {
      test('equal documents are equal', () {
        const doc1 = ContainerDocument(
          version: '1.0',
          rootfiles: [
            Rootfile(
                fullPath: 'content.opf',
                mediaType: 'application/oebps-package+xml'),
          ],
        );
        const doc2 = ContainerDocument(
          version: '1.0',
          rootfiles: [
            Rootfile(
                fullPath: 'content.opf',
                mediaType: 'application/oebps-package+xml'),
          ],
        );

        expect(doc1, equals(doc2));
        expect(doc1.hashCode, equals(doc2.hashCode));
      });

      test('different versions are not equal', () {
        const doc1 = ContainerDocument(
          version: '1.0',
          rootfiles: [
            Rootfile(
                fullPath: 'content.opf',
                mediaType: 'application/oebps-package+xml'),
          ],
        );
        const doc2 = ContainerDocument(
          version: '2.0',
          rootfiles: [
            Rootfile(
                fullPath: 'content.opf',
                mediaType: 'application/oebps-package+xml'),
          ],
        );

        expect(doc1, isNot(equals(doc2)));
      });

      test('different rootfiles are not equal', () {
        const doc1 = ContainerDocument(
          version: '1.0',
          rootfiles: [
            Rootfile(
                fullPath: 'a.opf', mediaType: 'application/oebps-package+xml'),
          ],
        );
        const doc2 = ContainerDocument(
          version: '1.0',
          rootfiles: [
            Rootfile(
                fullPath: 'b.opf', mediaType: 'application/oebps-package+xml'),
          ],
        );

        expect(doc1, isNot(equals(doc2)));
      });
    });
  });

  group('Rootfile', () {
    group('constructor', () {
      test('creates with required fields', () {
        const rootfile = Rootfile(
          fullPath: 'OEBPS/content.opf',
          mediaType: 'application/oebps-package+xml',
        );

        expect(rootfile.fullPath, equals('OEBPS/content.opf'));
        expect(rootfile.mediaType, equals('application/oebps-package+xml'));
      });
    });

    group('isOpf', () {
      test('returns true for OPF media type', () {
        const rootfile = Rootfile(
          fullPath: 'content.opf',
          mediaType: 'application/oebps-package+xml',
        );

        expect(rootfile.isOpf, isTrue);
      });

      test('returns false for non-OPF media type', () {
        const rootfile = Rootfile(
          fullPath: 'content.opf',
          mediaType: 'text/html',
        );

        expect(rootfile.isOpf, isFalse);
      });

      test('returns false for empty media type', () {
        const rootfile = Rootfile(
          fullPath: 'content.opf',
          mediaType: '',
        );

        expect(rootfile.isOpf, isFalse);
      });

      test('is case sensitive', () {
        const rootfile = Rootfile(
          fullPath: 'content.opf',
          mediaType: 'Application/OEBPS-package+xml',
        );

        expect(rootfile.isOpf, isFalse);
      });
    });

    group('Equatable', () {
      test('equal rootfiles are equal', () {
        const rf1 = Rootfile(
          fullPath: 'content.opf',
          mediaType: 'application/oebps-package+xml',
        );
        const rf2 = Rootfile(
          fullPath: 'content.opf',
          mediaType: 'application/oebps-package+xml',
        );

        expect(rf1, equals(rf2));
        expect(rf1.hashCode, equals(rf2.hashCode));
      });

      test('different fullPaths are not equal', () {
        const rf1 = Rootfile(
          fullPath: 'a.opf',
          mediaType: 'application/oebps-package+xml',
        );
        const rf2 = Rootfile(
          fullPath: 'b.opf',
          mediaType: 'application/oebps-package+xml',
        );

        expect(rf1, isNot(equals(rf2)));
      });

      test('different mediaTypes are not equal', () {
        const rf1 = Rootfile(
          fullPath: 'content.opf',
          mediaType: 'application/oebps-package+xml',
        );
        const rf2 = Rootfile(
          fullPath: 'content.opf',
          mediaType: 'text/html',
        );

        expect(rf1, isNot(equals(rf2)));
      });
    });
  });
}
