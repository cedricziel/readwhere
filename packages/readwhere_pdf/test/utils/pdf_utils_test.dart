import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_pdf/src/utils/pdf_utils.dart';

void main() {
  group('PdfUtils', () {
    group('isPdfSignature', () {
      test('returns true for valid PDF signature', () {
        // %PDF-
        final bytes = [0x25, 0x50, 0x44, 0x46, 0x2D];
        expect(PdfUtils.isPdfSignature(bytes), isTrue);
      });

      test('returns true for PDF signature with version', () {
        // %PDF-1.7
        final bytes = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37];
        expect(PdfUtils.isPdfSignature(bytes), isTrue);
      });

      test('returns false for non-PDF signature', () {
        // PK (ZIP signature)
        final bytes = [0x50, 0x4B, 0x03, 0x04, 0x00];
        expect(PdfUtils.isPdfSignature(bytes), isFalse);
      });

      test('returns false for JPEG signature', () {
        final bytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00];
        expect(PdfUtils.isPdfSignature(bytes), isFalse);
      });

      test('returns false for empty bytes', () {
        final bytes = <int>[];
        expect(PdfUtils.isPdfSignature(bytes), isFalse);
      });

      test('returns false for bytes shorter than signature', () {
        final bytes = [0x25, 0x50, 0x44]; // Only first 3 bytes
        expect(PdfUtils.isPdfSignature(bytes), isFalse);
      });

      test('returns false for partial match', () {
        final bytes = [0x25, 0x50, 0x44, 0x46, 0x00]; // %PDF but not -
        expect(PdfUtils.isPdfSignature(bytes), isFalse);
      });
    });

    group('isPdfBytes', () {
      test('returns true for valid PDF bytes', () {
        final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]);
        expect(PdfUtils.isPdfBytes(bytes), isTrue);
      });

      test('returns false for non-PDF bytes', () {
        final bytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03, 0x04]);
        expect(PdfUtils.isPdfBytes(bytes), isFalse);
      });

      test('returns false for empty Uint8List', () {
        final bytes = Uint8List(0);
        expect(PdfUtils.isPdfBytes(bytes), isFalse);
      });
    });

    group('isPdfFile', () {
      late Directory tempDir;

      setUpAll(() async {
        tempDir = await Directory.systemTemp.createTemp('pdf_utils_test');
      });

      tearDownAll(() async {
        await tempDir.delete(recursive: true);
      });

      test('returns true for file with PDF signature', () async {
        final file = File('${tempDir.path}/test.pdf');
        // Write PDF signature + some content
        await file.writeAsBytes([
          0x25,
          0x50,
          0x44,
          0x46,
          0x2D,
          0x31,
          0x2E,
          0x37,
        ]);

        expect(await PdfUtils.isPdfFile(file.path), isTrue);
      });

      test('returns false for non-PDF file', () async {
        final file = File('${tempDir.path}/test.txt');
        await file.writeAsString('Hello, world!');

        expect(await PdfUtils.isPdfFile(file.path), isFalse);
      });

      test('returns false for non-existent file', () async {
        expect(
          await PdfUtils.isPdfFile('${tempDir.path}/nonexistent.pdf'),
          isFalse,
        );
      });

      test('returns false for empty file', () async {
        final file = File('${tempDir.path}/empty.pdf');
        await file.writeAsBytes([]);

        expect(await PdfUtils.isPdfFile(file.path), isFalse);
      });
    });

    group('extractFilename', () {
      test('extracts filename from path', () {
        expect(PdfUtils.extractFilename('/path/to/document.pdf'), 'document');
      });

      test('extracts filename from path with multiple dots', () {
        expect(
          PdfUtils.extractFilename('/path/to/my.document.pdf'),
          'my.document',
        );
      });

      test('handles filename without extension', () {
        expect(PdfUtils.extractFilename('/path/to/document'), 'document');
      });

      test('handles Windows-style path', () {
        // Note: This depends on platform behavior
        if (Platform.isWindows) {
          expect(
            PdfUtils.extractFilename(r'C:\path\to\document.pdf'),
            'document',
          );
        }
      });

      test('handles filename only', () {
        expect(PdfUtils.extractFilename('document.pdf'), 'document');
      });
    });

    group('getExtension', () {
      test('returns extension in lowercase', () {
        expect(PdfUtils.getExtension('/path/to/document.PDF'), 'pdf');
      });

      test('returns extension without dot', () {
        expect(PdfUtils.getExtension('/path/to/document.pdf'), 'pdf');
      });

      test('returns last extension for multiple dots', () {
        expect(PdfUtils.getExtension('/path/to/archive.tar.gz'), 'gz');
      });

      test('returns empty string for no extension', () {
        expect(PdfUtils.getExtension('/path/to/document'), '');
      });

      test('returns empty string for path ending with dot', () {
        expect(PdfUtils.getExtension('/path/to/document.'), '');
      });

      test('handles hidden files', () {
        expect(PdfUtils.getExtension('/path/to/.hidden'), 'hidden');
      });
    });

    group('hasPdfExtension', () {
      test('returns true for .pdf extension', () {
        expect(PdfUtils.hasPdfExtension('/path/to/document.pdf'), isTrue);
      });

      test('returns true for .PDF extension (case insensitive)', () {
        expect(PdfUtils.hasPdfExtension('/path/to/document.PDF'), isTrue);
      });

      test('returns true for .Pdf extension', () {
        expect(PdfUtils.hasPdfExtension('/path/to/document.Pdf'), isTrue);
      });

      test('returns false for non-pdf extension', () {
        expect(PdfUtils.hasPdfExtension('/path/to/document.epub'), isFalse);
      });

      test('returns false for no extension', () {
        expect(PdfUtils.hasPdfExtension('/path/to/document'), isFalse);
      });
    });

    group('pointsToPixels', () {
      test('converts at 72 DPI (1:1)', () {
        expect(PdfUtils.pointsToPixels(72, 72), 72);
      });

      test('converts at 144 DPI (2:1)', () {
        expect(PdfUtils.pointsToPixels(72, 144), 144);
      });

      test('converts at 96 DPI', () {
        // 72 points * 96 / 72 = 96 pixels
        expect(PdfUtils.pointsToPixels(72, 96), 96);
      });

      test('converts letter width (8.5 inches = 612 points) at 300 DPI', () {
        // 612 points * 300 / 72 = 2550 pixels
        expect(PdfUtils.pointsToPixels(612, 300), 2550);
      });

      test('handles fractional values', () {
        expect(PdfUtils.pointsToPixels(36, 72), 36);
        expect(PdfUtils.pointsToPixels(36, 144), 72);
      });
    });

    group('pixelsToPoints', () {
      test('converts at 72 DPI (1:1)', () {
        expect(PdfUtils.pixelsToPoints(72, 72), 72);
      });

      test('converts at 144 DPI', () {
        expect(PdfUtils.pixelsToPoints(144, 144), 72);
      });

      test('converts at 96 DPI', () {
        expect(PdfUtils.pixelsToPoints(96, 96), 72);
      });

      test('converts 2550 pixels at 300 DPI to 612 points', () {
        expect(PdfUtils.pixelsToPoints(2550, 300), 612);
      });

      test('round-trips correctly', () {
        const points = 612.0;
        const dpi = 300.0;
        final pixels = PdfUtils.pointsToPixels(points, dpi);
        final backToPoints = PdfUtils.pixelsToPoints(pixels, dpi);
        expect(backToPoints, closeTo(points, 0.001));
      });
    });

    group('pdfSignature constant', () {
      test('contains correct bytes', () {
        // %PDF- in ASCII
        expect(PdfUtils.pdfSignature, [0x25, 0x50, 0x44, 0x46, 0x2D]);
      });

      test('has length 5', () {
        expect(PdfUtils.pdfSignature.length, 5);
      });
    });
  });
}
