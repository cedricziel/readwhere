import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:test/test.dart';
import 'package:readwhere_epub/readwhere_epub.dart';

void main() {
  group('EpubValidator', () {
    late EpubValidator validator;
    late Directory tempDir;

    setUp(() async {
      validator = EpubValidator();
      tempDir = await Directory.systemTemp.createTemp('epub_validator_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    /// Creates a minimal valid EPUB file.
    Future<String> createValidEpub({
      String? mimetype,
      String? containerXml,
      String? opfContent,
      Map<String, String>? additionalFiles,
    }) async {
      final archive = Archive();

      // Mimetype (must be first, uncompressed)
      final mimetypeContent = mimetype ?? 'application/epub+zip';
      archive.addFile(ArchiveFile(
        'mimetype',
        mimetypeContent.length,
        Uint8List.fromList(mimetypeContent.codeUnits),
      ));

      // Container.xml
      final container = containerXml ??
          '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
      archive.addFile(ArchiveFile(
        'META-INF/container.xml',
        container.length,
        Uint8List.fromList(container.codeUnits),
      ));

      // OPF content
      final opf = opfContent ??
          '''<?xml version="1.0" encoding="UTF-8"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="uid">test-book-123</dc:identifier>
    <dc:title>Test Book</dc:title>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
  </manifest>
  <spine>
    <itemref idref="chapter1"/>
  </spine>
</package>''';
      archive.addFile(ArchiveFile(
        'OEBPS/content.opf',
        opf.length,
        Uint8List.fromList(opf.codeUnits),
      ));

      // Chapter content
      const chapter = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter 1</title></head>
<body><h1>Chapter 1</h1><p>Content here.</p></body>
</html>''';
      archive.addFile(ArchiveFile(
        'OEBPS/chapter1.xhtml',
        chapter.length,
        Uint8List.fromList(chapter.codeUnits),
      ));

      // Nav document
      const nav = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head><title>Navigation</title></head>
<body>
<nav epub:type="toc"><ol><li><a href="chapter1.xhtml">Chapter 1</a></li></ol></nav>
</body>
</html>''';
      archive.addFile(ArchiveFile(
        'OEBPS/nav.xhtml',
        nav.length,
        Uint8List.fromList(nav.codeUnits),
      ));

      // Additional files
      additionalFiles?.forEach((path, content) {
        archive.addFile(ArchiveFile(
          path,
          content.length,
          Uint8List.fromList(content.codeUnits),
        ));
      });

      // Write to temp file
      final encoder = ZipEncoder();
      final bytes = encoder.encode(archive);
      final filePath = '${tempDir.path}/test.epub';
      await File(filePath).writeAsBytes(bytes);

      return filePath;
    }

    group('valid EPUBs', () {
      test('validates a minimal valid EPUB 3', () async {
        final epubPath = await createValidEpub();
        final result = await validator.validate(epubPath);

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
        expect(result.detectedVersion, equals(EpubVersion.epub30));
      });

      test('detects EPUB 2', () async {
        final epubPath = await createValidEpub(
          opfContent: '''<?xml version="1.0" encoding="UTF-8"?>
<package version="2.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="uid">test-book-123</dc:identifier>
    <dc:title>Test Book</dc:title>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chapter1"/>
  </spine>
</package>''',
        );

        final result = await validator.validate(epubPath);
        expect(result.detectedVersion, equals(EpubVersion.epub2));
      });
    });

    group('structure validation', () {
      test('reports missing file', () async {
        final result = await validator.validate('/nonexistent/path.epub');

        expect(result.isValid, isFalse);
        expect(
            result.errors.any((e) => e.code == ValidationCodes.strInvalidZip),
            isTrue);
      });

      test('reports invalid ZIP', () async {
        final filePath = '${tempDir.path}/invalid.epub';
        await File(filePath).writeAsString('not a zip file');

        final result = await validator.validate(filePath);

        expect(result.isValid, isFalse);
        expect(
            result.errors.any((e) => e.code == ValidationCodes.strInvalidZip),
            isTrue);
      });

      test('reports invalid mimetype', () async {
        final epubPath = await createValidEpub(mimetype: 'text/plain');
        final result = await validator.validate(epubPath);

        expect(result.isValid, isFalse);
        expect(
            result.errors
                .any((e) => e.code == ValidationCodes.strInvalidMimetype),
            isTrue);
      });

      test('reports missing container.xml', () async {
        // Create archive without container.xml
        final archive = Archive();
        archive.addFile(ArchiveFile(
          'mimetype',
          'application/epub+zip'.length,
          Uint8List.fromList('application/epub+zip'.codeUnits),
        ));

        final encoder = ZipEncoder();
        final bytes = encoder.encode(archive);
        final filePath = '${tempDir.path}/no_container.epub';
        await File(filePath).writeAsBytes(bytes);

        final result = await validator.validate(filePath);

        expect(result.isValid, isFalse);
        expect(
            result.errors
                .any((e) => e.code == ValidationCodes.strMissingContainer),
            isTrue);
      });
    });

    group('package validation', () {
      test('reports missing metadata', () async {
        final epubPath = await createValidEpub(
          opfContent: '''<?xml version="1.0" encoding="UTF-8"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="uid">
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="chapter1"/>
  </spine>
</package>''',
        );

        final result = await validator.validate(epubPath);

        expect(result.isValid, isFalse);
        expect(
            result.errors
                .any((e) => e.code == ValidationCodes.pkgMissingMetadata),
            isTrue);
      });

      test('reports missing title', () async {
        final epubPath = await createValidEpub(
          opfContent: '''<?xml version="1.0" encoding="UTF-8"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="uid">test-book-123</dc:identifier>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="chapter1"/>
  </spine>
</package>''',
        );

        final result = await validator.validate(epubPath);

        expect(result.isValid, isFalse);
        expect(
            result.errors.any((e) => e.code == ValidationCodes.pkgMissingTitle),
            isTrue);
      });

      test('reports missing language', () async {
        final epubPath = await createValidEpub(
          opfContent: '''<?xml version="1.0" encoding="UTF-8"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="uid">test-book-123</dc:identifier>
    <dc:title>Test</dc:title>
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="chapter1"/>
  </spine>
</package>''',
        );

        final result = await validator.validate(epubPath);

        expect(result.isValid, isFalse);
        expect(
            result.errors
                .any((e) => e.code == ValidationCodes.pkgMissingLanguage),
            isTrue);
      });

      test('reports empty spine', () async {
        final epubPath = await createValidEpub(
          opfContent: '''<?xml version="1.0" encoding="UTF-8"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="uid">test-book-123</dc:identifier>
    <dc:title>Test</dc:title>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
  </spine>
</package>''',
        );

        final result = await validator.validate(epubPath);

        expect(result.isValid, isFalse);
        expect(
            result.errors.any((e) => e.code == ValidationCodes.pkgEmptySpine),
            isTrue);
      });
    });

    group('resource validation', () {
      test('reports missing resource', () async {
        final epubPath = await createValidEpub(
          opfContent: '''<?xml version="1.0" encoding="UTF-8"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="uid">test-book-123</dc:identifier>
    <dc:title>Test Book</dc:title>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="missing" href="missing.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="chapter1"/>
  </spine>
</package>''',
        );

        final result = await validator.validate(epubPath);

        expect(result.isValid, isFalse);
        expect(
            result.errors
                .any((e) => e.code == ValidationCodes.resMissingResource),
            isTrue);
      });

      test('reports invalid XHTML', () async {
        final epubPath = await createValidEpub(
          additionalFiles: {
            'OEBPS/chapter1.xhtml': '<html><body>Not valid XML <<broken',
          },
        );

        final result = await validator.validate(epubPath);

        expect(result.isValid, isFalse);
        expect(
            result.errors.any((e) => e.code == ValidationCodes.resInvalidXhtml),
            isTrue);
      });
    });

    group('warnings', () {
      test('warns about missing description', () async {
        final epubPath = await createValidEpub();
        final result = await validator.validate(epubPath);

        expect(
            result.warnings
                .any((e) => e.code == ValidationCodes.wrnMissingDescription),
            isTrue);
      });

      test('warns about missing cover', () async {
        final epubPath = await createValidEpub();
        final result = await validator.validate(epubPath);

        expect(
            result.warnings
                .any((e) => e.code == ValidationCodes.wrnMissingCover),
            isTrue);
      });

      test('warns about NCX in EPUB 3', () async {
        final epubPath = await createValidEpub(
          opfContent: '''<?xml version="1.0" encoding="UTF-8"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="uid">test-book-123</dc:identifier>
    <dc:title>Test Book</dc:title>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chapter1"/>
  </spine>
</package>''',
        );

        final result = await validator.validate(epubPath);

        expect(
            result.warnings
                .any((e) => e.code == ValidationCodes.wrnDeprecatedNcx),
            isTrue);
      });
    });

    group('validateStructure', () {
      test('skips resource validation', () async {
        // Create EPUB with missing resource in manifest
        final epubPath = await createValidEpub(
          opfContent: '''<?xml version="1.0" encoding="UTF-8"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="uid">test-book-123</dc:identifier>
    <dc:title>Test Book</dc:title>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="missing" href="missing.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="chapter1"/>
  </spine>
</package>''',
        );

        // Full validation should find missing resource
        final fullResult = await validator.validate(epubPath);
        expect(fullResult.isValid, isFalse);

        // Structure validation should pass
        final structureResult = await validator.validateStructure(epubPath);
        expect(
            structureResult.errors.any(
              (e) => e.code == ValidationCodes.resMissingResource,
            ),
            isFalse);
      });
    });

    group('EpubValidationResult', () {
      test('allIssues returns all issues', () {
        const result = EpubValidationResult(
          isValid: false,
          errors: [
            EpubValidationError(
              severity: EpubValidationSeverity.error,
              code: 'E1',
              message: 'Error 1',
            ),
          ],
          warnings: [
            EpubValidationError(
              severity: EpubValidationSeverity.warning,
              code: 'W1',
              message: 'Warning 1',
            ),
          ],
          info: [
            EpubValidationError(
              severity: EpubValidationSeverity.info,
              code: 'I1',
              message: 'Info 1',
            ),
          ],
        );

        expect(result.allIssues, hasLength(3));
        expect(result.totalIssues, equals(3));
      });
    });

    group('EpubValidationError', () {
      test('toString includes location when present', () {
        const error = EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: 'TEST-001',
          message: 'Test message',
          location: 'path/to/file.xml',
        );

        final str = error.toString();
        expect(str, contains('ERROR'));
        expect(str, contains('TEST-001'));
        expect(str, contains('Test message'));
        expect(str, contains('path/to/file.xml'));
      });

      test('toString excludes location when not present', () {
        const error = EpubValidationError(
          severity: EpubValidationSeverity.warning,
          code: 'TEST-002',
          message: 'Another message',
        );

        final str = error.toString();
        expect(str, contains('WARNING'));
        expect(str, contains('TEST-002'));
        expect(str, isNot(contains('at')));
      });
    });

    group('ValidationCodes', () {
      test('has all expected code categories', () {
        // Structure codes
        expect(ValidationCodes.strMissingMimetype, startsWith('STR-'));
        expect(ValidationCodes.strInvalidZip, startsWith('STR-'));

        // Package codes
        expect(ValidationCodes.pkgInvalidOpf, startsWith('PKG-'));
        expect(ValidationCodes.pkgMissingTitle, startsWith('PKG-'));

        // Resource codes
        expect(ValidationCodes.resMissingResource, startsWith('RES-'));

        // Warning codes
        expect(ValidationCodes.wrnDeprecatedNcx, startsWith('WRN-'));
      });
    });
  });
}
