@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:readwhere_pdf/readwhere_pdf.dart';
import 'package:readwhere_pdf_plugin/readwhere_pdf_plugin.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:readwhere_sample_media/readwhere_sample_media.dart';

/// Mock plugin context for testing.
class MockPluginContext implements PluginContext {
  @override
  final Logger logger = Logger('TestPlugin');

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  // Skip all tests if sample media is not downloaded
  final bool mediaAvailable = SampleMediaPaths.isDownloaded;

  group('PdfReaderPlugin', () {
    late PdfReaderPlugin plugin;

    setUp(() async {
      plugin = PdfReaderPlugin();
      await plugin.initialize(MockPluginContext());
    });

    tearDown(() async {
      await plugin.dispose();
    });

    group('metadata', () {
      test('id returns com.readwhere.pdf', () {
        expect(plugin.id, 'com.readwhere.pdf');
      });

      test('name returns PDF Reader', () {
        expect(plugin.name, 'PDF Reader');
      });

      test('description is meaningful', () {
        expect(plugin.description, isNotEmpty);
        expect(plugin.description.toLowerCase(), contains('pdf'));
      });

      test('version is valid', () {
        expect(plugin.version, isNotEmpty);
      });

      test('supportedExtensions contains pdf', () {
        expect(plugin.supportedExtensions, contains('pdf'));
      });

      test('supportedMimeTypes contains application/pdf', () {
        expect(plugin.supportedMimeTypes, contains('application/pdf'));
      });

      test('capabilityNames contains ReaderCapability', () {
        expect(plugin.capabilityNames, contains('ReaderCapability'));
      });
    });

    group('canHandleFile', () {
      test('returns true for valid PDF file', () async {
        if (!mediaAvailable) {
          markTestSkipped('Sample media not available');
          return;
        }

        final pdfFiles = SampleMediaPaths.pdfFiles;
        if (pdfFiles.isEmpty) {
          markTestSkipped('No PDF files in sample media');
          return;
        }

        final result = await plugin.canHandleFile(pdfFiles.first.path);
        expect(result, isTrue);
      });

      test('returns false for non-existent file', () async {
        final result = await plugin.canHandleFile('/nonexistent/path/file.pdf');
        expect(result, isFalse);
      });

      test('returns false for non-PDF extension', () async {
        // Create a temp file with wrong extension
        final tempDir = await Directory.systemTemp.createTemp('plugin_test');
        final tempFile = File('${tempDir.path}/test.epub');
        await tempFile.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x2D]);

        try {
          final result = await plugin.canHandleFile(tempFile.path);
          expect(result, isFalse);
        } finally {
          await tempDir.delete(recursive: true);
        }
      });

      test('returns false for .pdf file without PDF signature', () async {
        final tempDir = await Directory.systemTemp.createTemp('plugin_test');
        final tempFile = File('${tempDir.path}/fake.pdf');
        await tempFile.writeAsString('This is not a PDF');

        try {
          final result = await plugin.canHandleFile(tempFile.path);
          expect(result, isFalse);
        } finally {
          await tempDir.delete(recursive: true);
        }
      });
    });

    group('parseMetadata', () {
      test('returns BookMetadata for valid PDF', () async {
        if (!mediaAvailable) {
          markTestSkipped('Sample media not available');
          return;
        }

        final pdfFiles = SampleMediaPaths.pdfFiles;
        if (pdfFiles.isEmpty) {
          markTestSkipped('No PDF files in sample media');
          return;
        }

        final metadata = await plugin.parseMetadata(pdfFiles.first.path);

        expect(metadata, isA<BookMetadata>());
        expect(metadata.title, isNotEmpty);
        expect(metadata.isFixedLayout, isTrue);
      });

      test('throws for non-existent file', () async {
        expect(
          () => plugin.parseMetadata('/nonexistent/path/file.pdf'),
          throwsA(isA<PdfException>()),
        );
      });
    });

    group('extractCover', () {
      test('returns cover image for valid PDF', () async {
        if (!mediaAvailable) {
          markTestSkipped('Sample media not available');
          return;
        }

        final pdfFiles = SampleMediaPaths.pdfFiles;
        if (pdfFiles.isEmpty) {
          markTestSkipped('No PDF files in sample media');
          return;
        }

        final cover = await plugin.extractCover(pdfFiles.first.path);

        expect(cover, isNotNull);
        expect(cover, isNotEmpty);
        // Check PNG header
        expect(cover![0], 0x89);
        expect(cover[1], 0x50); // P
      });

      test('returns null for non-existent file', () async {
        final cover = await plugin.extractCover('/nonexistent/path/file.pdf');
        expect(cover, isNull);
      });
    });

    group('openBook', () {
      test('returns ReaderController for valid PDF', () async {
        if (!mediaAvailable) {
          markTestSkipped('Sample media not available');
          return;
        }

        final pdfFiles = SampleMediaPaths.pdfFiles;
        if (pdfFiles.isEmpty) {
          markTestSkipped('No PDF files in sample media');
          return;
        }

        final controller = await plugin.openBook(pdfFiles.first.path);

        try {
          expect(controller, isA<ReaderController>());
          expect(controller.totalChapters, greaterThan(0));
        } finally {
          await controller.dispose();
        }
      });

      test('throws for non-existent file', () async {
        expect(
          () => plugin.openBook('/nonexistent/path/file.pdf'),
          throwsA(anything),
        );
      });
    });

    group('ReaderCapability mixin', () {
      test('plugin has ReaderCapability', () {
        expect(plugin, isA<ReaderCapability>());
      });
    });
  });
}
