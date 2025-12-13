@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_pdf_plugin/readwhere_pdf_plugin.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:readwhere_sample_media/readwhere_sample_media.dart';

void main() {
  // Skip all tests if sample media is not downloaded
  final bool mediaAvailable = SampleMediaPaths.isDownloaded;

  group('PdfReaderController', () {
    late List<File> pdfFiles;

    setUpAll(() {
      if (!mediaAvailable) return;
      pdfFiles = SampleMediaPaths.pdfFiles;
    });

    group('create', () {
      test('creates controller for valid PDF', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          expect(controller, isA<PdfReaderController>());
          expect(controller, isA<ReaderController>());
        } finally {
          await controller.dispose();
        }
      });

      test('throws for non-existent file', () async {
        expect(
          () => PdfReaderController.create('/nonexistent/path/file.pdf'),
          throwsA(anything),
        );
      });
    });

    group('bookId', () {
      test('returns hash of file path', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          expect(controller.bookId, isNotEmpty);
          expect(controller.bookId, pdfFiles.first.path.hashCode.toString());
        } finally {
          await controller.dispose();
        }
      });
    });

    group('totalChapters', () {
      test('returns page count', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          expect(controller.totalChapters, greaterThan(0));
        } finally {
          await controller.dispose();
        }
      });
    });

    group('isFixedLayout', () {
      test('returns true for PDF', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          expect(controller.isFixedLayout, isTrue);
        } finally {
          await controller.dispose();
        }
      });
    });

    group('tableOfContents', () {
      test('returns list of TocEntry', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          final toc = controller.tableOfContents;
          expect(toc, isA<List<TocEntry>>());
          expect(toc, isNotEmpty);
        } finally {
          await controller.dispose();
        }
      });
    });

    group('currentChapterIndex', () {
      test('starts at 0', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          expect(controller.currentChapterIndex, 0);
        } finally {
          await controller.dispose();
        }
      });
    });

    group('progress', () {
      test('starts at initial value', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          expect(controller.progress, greaterThanOrEqualTo(0.0));
          expect(controller.progress, lessThanOrEqualTo(1.0));
        } finally {
          await controller.dispose();
        }
      });
    });

    group('goToChapter', () {
      test('updates currentChapterIndex', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          if (controller.totalChapters > 1) {
            await controller.goToChapter(1);
            expect(controller.currentChapterIndex, 1);
          }
        } finally {
          await controller.dispose();
        }
      });

      test('throws for out-of-bounds index', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          expect(
            () => controller.goToChapter(-1),
            throwsA(isA<ArgumentError>()),
          );
          expect(
            () => controller.goToChapter(99999),
            throwsA(isA<ArgumentError>()),
          );
        } finally {
          await controller.dispose();
        }
      });
    });

    group('goToLocation', () {
      test('parses page-N format', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          if (controller.totalChapters > 1) {
            await controller.goToLocation('page-1');
            expect(controller.currentChapterIndex, 1);
          }
        } finally {
          await controller.dispose();
        }
      });
    });

    group('nextChapter / previousChapter', () {
      test('navigates forward and backward', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          if (controller.totalChapters > 1) {
            expect(controller.currentChapterIndex, 0);

            await controller.nextChapter();
            expect(controller.currentChapterIndex, 1);

            await controller.previousChapter();
            expect(controller.currentChapterIndex, 0);
          }
        } finally {
          await controller.dispose();
        }
      });

      test('previousChapter does nothing at first page', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          expect(controller.currentChapterIndex, 0);
          await controller.previousChapter();
          expect(controller.currentChapterIndex, 0);
        } finally {
          await controller.dispose();
        }
      });
    });

    group('getCurrentCfi', () {
      test('returns page-N format', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          final cfi = controller.getCurrentCfi();
          expect(cfi, startsWith('page-'));
        } finally {
          await controller.dispose();
        }
      });
    });

    group('search', () {
      test('returns empty list for empty query', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          final results = await controller.search('');
          expect(results, isEmpty);
        } finally {
          await controller.dispose();
        }
      });

      test('returns SearchResult list', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          // Search for a common word
          final results = await controller.search('the');
          expect(results, isA<List<SearchResult>>());
        } finally {
          await controller.dispose();
        }
      });
    });

    group('contentStream', () {
      test('emits content when navigating', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          // Listen for content
          final contentFuture = controller.contentStream.first;

          // Navigate to trigger content emission
          await controller.goToChapter(0);

          final content = await contentFuture;
          expect(content, isA<ReaderContent>());
          expect(content.chapterId, startsWith('page-'));
          expect(content.htmlContent, isNotEmpty);
        } finally {
          await controller.dispose();
        }
      });
    });

    group('dispose', () {
      test('prevents further operations', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );
        await controller.dispose();

        expect(() => controller.totalChapters, throwsA(isA<StateError>()));
        expect(() => controller.bookId, throwsA(isA<StateError>()));
      });

      test('can be called multiple times safely', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        await controller.dispose();
        await controller.dispose(); // Should not throw
      });
    });

    group('getPageBytes', () {
      test('returns page image bytes', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          final bytes = await controller.getPageBytes(0);

          expect(bytes, isNotNull);
          expect(bytes, isNotEmpty);
          // Check PNG header
          expect(bytes![0], 0x89);
        } finally {
          await controller.dispose();
        }
      });

      test('returns null for invalid index', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          final bytes = await controller.getPageBytes(-1);
          expect(bytes, isNull);
        } finally {
          await controller.dispose();
        }
      });
    });

    group('getPageThumbnail', () {
      test('returns thumbnail image', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          final bytes = await controller.getPageThumbnail(0, maxWidth: 100);

          expect(bytes, isNotNull);
          expect(bytes, isNotEmpty);
        } finally {
          await controller.dispose();
        }
      });
    });

    group('getPageText', () {
      test('returns text content', () async {
        if (!mediaAvailable || pdfFiles.isEmpty) {
          markTestSkipped('Sample media not available');
          return;
        }

        final controller = await PdfReaderController.create(
          pdfFiles.first.path,
        );

        try {
          final text = await controller.getPageText(0);
          expect(text, isA<String>());
        } finally {
          await controller.dispose();
        }
      });
    });
  });
}
