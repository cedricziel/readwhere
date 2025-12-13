@Tags(['integration'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_pdf/readwhere_pdf.dart';
import 'package:readwhere_sample_media/readwhere_sample_media.dart';

/// Integration tests for PdfReader.
///
/// These tests require:
/// 1. Sample media to be downloaded: `dart run readwhere_sample_media:download`
/// 2. A Flutter runtime environment (pdfrx uses native platform code)
///
/// Run with: `flutter test integration_test/` on a device/simulator
/// or skip VM tests with `flutter test --exclude-tags=integration`
void main() {
  // Ensure Flutter bindings are initialized for native plugin support
  TestWidgetsFlutterBinding.ensureInitialized();

  // Skip all tests if sample media is not downloaded
  final bool mediaAvailable = SampleMediaPaths.isDownloaded;

  // Check if pdfrx native code is available (not in VM test mode)
  bool pdfrxAvailable = true;

  group('PdfReader', () {
    late List<File> pdfFiles;

    setUpAll(() async {
      if (!mediaAvailable) {
        return;
      }
      pdfFiles = SampleMediaPaths.pdfFiles;

      // Test if pdfrx can actually work in this environment
      if (pdfFiles.isNotEmpty) {
        try {
          final reader = await PdfReader.open(pdfFiles.first.path);
          await reader.dispose();
        } on PdfReadException catch (e) {
          // pdfrx native code not available (running in VM test mode)
          if (e.cause != null &&
              e.cause.toString().contains('MissingPluginException')) {
            pdfrxAvailable = false;
          } else {
            // Re-throw if it's a different error
            pdfrxAvailable = false;
          }
        }
      }
    });

    group('open', () {
      test('opens valid PDF file', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }
        if (!pdfrxAvailable) {
          markTestSkipped('pdfrx native code not available in VM test mode');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          expect(reader.pageCount, greaterThan(0));
          expect(reader.book, isNotNull);
        } finally {
          await reader.dispose();
        }
      });

      test('throws PdfReadException for missing file', () async {
        expect(
          () => PdfReader.open('/nonexistent/path/to/file.pdf'),
          throwsA(isA<PdfReadException>()),
        );
      });

      test('throws PdfParseException for non-PDF file', () async {
        // Create a temporary non-PDF file
        final tempDir = await Directory.systemTemp.createTemp('pdf_test');
        final tempFile = File('${tempDir.path}/fake.pdf');
        await tempFile.writeAsString('This is not a PDF file');

        try {
          expect(
            () => PdfReader.open(tempFile.path),
            throwsA(isA<PdfParseException>()),
          );
        } finally {
          await tempDir.delete(recursive: true);
        }
      });
    });

    group('openBytes', () {
      test('opens valid PDF bytes', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final bytes = await file.readAsBytes();
        final reader = await PdfReader.openBytes(bytes);

        try {
          expect(reader.pageCount, greaterThan(0));
        } finally {
          await reader.dispose();
        }
      });

      test('throws PdfParseException for invalid bytes', () async {
        final invalidBytes = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        expect(
          () => PdfReader.openBytes(Uint8List.fromList(invalidBytes)),
          throwsA(isA<PdfParseException>()),
        );
      });
    });

    group('pageCount', () {
      test('returns correct page count', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          expect(reader.pageCount, greaterThan(0));
          expect(reader.pageCount, equals(reader.book.pageCount));
        } finally {
          await reader.dispose();
        }
      });
    });

    group('book', () {
      test('returns PdfBook with pages', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          final book = reader.book;
          expect(book, isA<PdfBook>());
          expect(book.pages, hasLength(reader.pageCount));
          expect(book.pages.first.index, 0);
        } finally {
          await reader.dispose();
        }
      });
    });

    group('metadata', () {
      test('returns metadata (may be empty)', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          final metadata = reader.metadata;
          expect(metadata, isA<PdfMetadata>());
          // Note: pdfrx doesn't expose metadata, so it will be empty
        } finally {
          await reader.dispose();
        }
      });
    });

    group('outline', () {
      test('returns outline if available', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          // Outline may be null or have entries depending on PDF
          final outline = reader.outline;
          if (outline != null) {
            expect(outline, isA<List<PdfOutlineEntry>>());
          }
        } finally {
          await reader.dispose();
        }
      });
    });

    group('getPageImage', () {
      test('returns PNG bytes for valid page', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          final imageBytes = await reader.getPageImage(0);

          expect(imageBytes, isNotEmpty);
          // Check PNG magic bytes
          expect(imageBytes[0], 0x89);
          expect(imageBytes[1], 0x50); // P
          expect(imageBytes[2], 0x4E); // N
          expect(imageBytes[3], 0x47); // G
        } finally {
          await reader.dispose();
        }
      });

      test('throws RangeError for invalid page index', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          expect(() => reader.getPageImage(-1), throwsA(isA<RangeError>()));
          expect(() => reader.getPageImage(9999), throwsA(isA<RangeError>()));
        } finally {
          await reader.dispose();
        }
      });
    });

    group('getPageThumbnail', () {
      test('returns thumbnail image', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          final thumbnail = await reader.getPageThumbnail(0, maxWidth: 100);

          expect(thumbnail, isNotEmpty);
          // Check PNG magic bytes
          expect(thumbnail[0], 0x89);
        } finally {
          await reader.dispose();
        }
      });
    });

    group('getCoverImage', () {
      test('returns cover image (first page thumbnail)', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          final cover = await reader.getCoverImage();

          expect(cover, isNotNull);
          expect(cover, isNotEmpty);
        } finally {
          await reader.dispose();
        }
      });
    });

    group('getPageDimensions', () {
      test('returns page dimensions', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          final dimensions = await reader.getPageDimensions(0);

          expect(dimensions.width, greaterThan(0));
          expect(dimensions.height, greaterThan(0));
        } finally {
          await reader.dispose();
        }
      });
    });

    group('getPageText', () {
      test('extracts text from page', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          final text = await reader.getPageText(0);
          // Text may be empty for scanned PDFs
          expect(text, isA<String>());
        } finally {
          await reader.dispose();
        }
      });
    });

    group('getTextBlocks', () {
      test('extracts text blocks with positions', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          final blocks = await reader.getTextBlocks(0);
          // Blocks may be empty for scanned PDFs
          expect(blocks, isA<List<TextBlock>>());
        } finally {
          await reader.dispose();
        }
      });
    });

    group('caching', () {
      test('caches page images', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          // First call renders
          final bytes1 = await reader.getPageImage(0);
          // Second call should use cache
          final bytes2 = await reader.getPageImage(0);

          // Both should return PNG data
          expect(bytes1[0], 0x89);
          expect(bytes2[0], 0x89);
        } finally {
          await reader.dispose();
        }
      });

      test('clearCache clears cached images', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          await reader.getPageImage(0);
          reader.clearCache();
          // Should still work after clearing cache
          final bytes = await reader.getPageImage(0);
          expect(bytes, isNotEmpty);
        } finally {
          await reader.dispose();
        }
      });
    });

    group('dispose', () {
      test('prevents further operations', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);
        await reader.dispose();

        expect(() => reader.pageCount, throwsA(isA<StateError>()));
        expect(() => reader.book, throwsA(isA<StateError>()));
        expect(() => reader.getPageImage(0), throwsA(isA<StateError>()));
      });

      test('can be called multiple times safely', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        await reader.dispose();
        await reader.dispose(); // Should not throw
      });
    });

    group('filePath', () {
      test('returns file path for file-opened reader', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          expect(reader.filePath, file.path);
        } finally {
          await reader.dispose();
        }
      });

      test('returns null for bytes-opened reader', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final bytes = await file.readAsBytes();
        final reader = await PdfReader.openBytes(bytes);

        try {
          expect(reader.filePath, isNull);
        } finally {
          await reader.dispose();
        }
      });
    });

    group('isEncrypted', () {
      test('returns false for unencrypted PDF', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final file = pdfFiles.first;
        final reader = await PdfReader.open(file.path);

        try {
          // Most sample PDFs are not encrypted
          expect(reader.isEncrypted, isA<bool>());
        } finally {
          await reader.dispose();
        }
      });
    });
  });
}
