@Tags(['integration'])
library;

import 'package:readwhere_sample_media/readwhere_sample_media.dart';
import 'package:test/test.dart';

/// Integration tests that require sample media to be downloaded.
///
/// Run these after downloading sample media:
///   dart run readwhere_sample_media:download
///   dart test --tags=integration
void main() {
  group('SampleMediaPaths integration', () {
    setUpAll(() {
      if (!SampleMediaPaths.isDownloaded) {
        fail(
          'Sample media not downloaded. Run: dart run readwhere_sample_media:download',
        );
      }
    });

    test('isDownloaded is true after download', () {
      expect(SampleMediaPaths.isDownloaded, isTrue);
    });

    test('downloadedVersion matches expected', () {
      expect(SampleMediaPaths.downloadedVersion,
          equals(SampleMediaConfig.version));
    });

    test('epubFiles returns EPUB files', () {
      final epubs = SampleMediaPaths.epubFiles;
      expect(epubs, isNotEmpty, reason: 'Expected EPUB files');
      for (final file in epubs) {
        expect(file.path.toLowerCase(), endsWith('.epub'));
        expect(file.existsSync(), isTrue);
      }
    });

    test('cbzFiles returns CBZ files', () {
      final files = SampleMediaPaths.cbzFiles;
      expect(files, isNotEmpty, reason: 'Expected CBZ files');
      for (final file in files) {
        expect(file.path.toLowerCase(), endsWith('.cbz'));
        expect(file.existsSync(), isTrue);
      }
    });

    test('cbrFiles returns CBR files', () {
      final files = SampleMediaPaths.cbrFiles;
      expect(files, isNotEmpty, reason: 'Expected CBR files');
      for (final file in files) {
        expect(file.path.toLowerCase(), endsWith('.cbr'));
        expect(file.existsSync(), isTrue);
      }
    });

    test('pdfFiles returns PDF files', () {
      final files = SampleMediaPaths.pdfFiles;
      expect(files, isNotEmpty, reason: 'Expected PDF files');
      for (final file in files) {
        expect(file.path.toLowerCase(), endsWith('.pdf'));
        expect(file.existsSync(), isTrue);
      }
    });

    test('fb2Files returns FB2 files', () {
      final files = SampleMediaPaths.fb2Files;
      expect(files, isNotEmpty, reason: 'Expected FB2 files');
      for (final file in files) {
        expect(file.path.toLowerCase(), endsWith('.fb2'));
        expect(file.existsSync(), isTrue);
      }
    });

    test('htmlFiles returns HTML files', () {
      final files = SampleMediaPaths.htmlFiles;
      expect(files, isNotEmpty, reason: 'Expected HTML files');
      for (final file in files) {
        expect(file.path.toLowerCase(), endsWith('.html'));
        expect(file.existsSync(), isTrue);
      }
    });

    test('txtFiles returns TXT files', () {
      final files = SampleMediaPaths.txtFiles;
      expect(files, isNotEmpty, reason: 'Expected TXT files');
      for (final file in files) {
        expect(file.path.toLowerCase(), endsWith('.txt'));
        expect(file.existsSync(), isTrue);
      }
    });

    test('allFiles returns multiple files', () {
      final files = SampleMediaPaths.allFiles;
      expect(files.length, greaterThan(10),
          reason: 'Expected many sample files');
    });

    test('getFirstFileByExtension returns a file', () {
      final epub = SampleMediaPaths.getFirstFileByExtension('epub');
      expect(epub, isNotNull);
      expect(epub!.existsSync(), isTrue);
    });

    test('getFirstFileByExtension returns null for unknown extension', () {
      final file = SampleMediaPaths.getFirstFileByExtension('xyz123');
      expect(file, isNull);
    });
  });
}
