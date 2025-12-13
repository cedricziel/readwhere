import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:pdfrx/pdfrx.dart' as pdfrx;
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

/// Integration tests for PdfReaderPlugin that run on actual devices/simulators.
///
/// These tests require:
/// 1. Sample media: `dart run readwhere_sample_media:download`
/// 2. Run with: `flutter test integration_test/ -d macos`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialize pdfrx library for Flutter
  pdfrx.pdfrxFlutterInitialize();

  // Try to find sample media directory
  _configureSampleMediaPath();

  final bool mediaAvailable = SampleMediaPaths.isDownloaded;

  group('PdfReaderPlugin Integration', () {
    late PdfReaderPlugin plugin;
    late List<File> pdfFiles;

    setUpAll(() async {
      plugin = PdfReaderPlugin();
      await plugin.initialize(MockPluginContext());

      if (!mediaAvailable) return;
      pdfFiles = SampleMediaPaths.pdfFiles;
    });

    tearDownAll(() async {
      await plugin.dispose();
    });

    testWidgets('canHandleFile returns true for valid PDF', (tester) async {
      if (!mediaAvailable || pdfFiles.isEmpty) {
        markTestSkipped('Sample media not available');
        return;
      }

      final result = await plugin.canHandleFile(pdfFiles.first.path);
      expect(result, isTrue);
    });

    testWidgets('parseMetadata returns BookMetadata', (tester) async {
      if (!mediaAvailable || pdfFiles.isEmpty) {
        markTestSkipped('Sample media not available');
        return;
      }

      final metadata = await plugin.parseMetadata(pdfFiles.first.path);

      expect(metadata, isA<BookMetadata>());
      expect(metadata.title, isNotEmpty);
      expect(metadata.isFixedLayout, isTrue);
    });

    testWidgets('extractCover returns cover image', (tester) async {
      if (!mediaAvailable || pdfFiles.isEmpty) {
        markTestSkipped('Sample media not available');
        return;
      }

      final cover = await plugin.extractCover(pdfFiles.first.path);

      expect(cover, isNotNull);
      expect(cover, isNotEmpty);
      // Check PNG header
      expect(cover![0], 0x89);
      expect(cover[1], 0x50); // P
    });

    testWidgets('openBook returns ReaderController', (tester) async {
      if (!mediaAvailable || pdfFiles.isEmpty) {
        markTestSkipped('Sample media not available');
        return;
      }

      final controller = await plugin.openBook(pdfFiles.first.path);

      try {
        expect(controller, isA<ReaderController>());
        expect(controller.totalChapters, greaterThan(0));
        expect(controller.isFixedLayout, isTrue);
      } finally {
        await controller.dispose();
      }
    });
  });

  group('PdfReaderController Integration', () {
    late List<File> pdfFiles;

    setUpAll(() {
      if (!mediaAvailable) return;
      pdfFiles = SampleMediaPaths.pdfFiles;
    });

    testWidgets('navigation works correctly', (tester) async {
      if (!mediaAvailable || pdfFiles.isEmpty) {
        markTestSkipped('Sample media not available');
        return;
      }

      final controller = await PdfReaderController.create(pdfFiles.first.path);

      try {
        expect(controller.currentChapterIndex, 0);

        if (controller.totalChapters > 1) {
          await controller.goToChapter(1);
          expect(controller.currentChapterIndex, 1);

          await controller.previousChapter();
          expect(controller.currentChapterIndex, 0);
        }
      } finally {
        await controller.dispose();
      }
    });

    testWidgets('getPageBytes returns image data', (tester) async {
      if (!mediaAvailable || pdfFiles.isEmpty) {
        markTestSkipped('Sample media not available');
        return;
      }

      final controller = await PdfReaderController.create(pdfFiles.first.path);

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

    testWidgets('search returns results', (tester) async {
      if (!mediaAvailable || pdfFiles.isEmpty) {
        markTestSkipped('Sample media not available');
        return;
      }

      final controller = await PdfReaderController.create(pdfFiles.first.path);

      try {
        // Search for a common word that might be in the PDF
        final results = await controller.search('the');
        expect(results, isA<List<SearchResult>>());
      } finally {
        await controller.dispose();
      }
    });

    testWidgets('contentStream emits content', (tester) async {
      if (!mediaAvailable || pdfFiles.isEmpty) {
        markTestSkipped('Sample media not available');
        return;
      }

      final controller = await PdfReaderController.create(pdfFiles.first.path);

      try {
        // Listen for content
        final contentFuture = controller.contentStream.first;

        // Navigate to trigger content emission
        await controller.goToChapter(0);

        final content = await contentFuture;
        expect(content, isA<ReaderContent>());
        expect(content.chapterId, startsWith('page-'));
      } finally {
        await controller.dispose();
      }
    });
  });
}

/// Configures the sample media path for integration tests.
void _configureSampleMediaPath() {
  // Clear any cached values
  SampleMediaPaths.clearCache();

  // Check for compile-time define
  const definedPath = String.fromEnvironment('SAMPLE_MEDIA_PATH');
  if (definedPath.isNotEmpty) {
    SampleMediaPaths.rootDirectory = Directory(definedPath);
    return;
  }

  // Check for environment variable (handled by SampleMediaPaths itself)
  final envPath = Platform.environment['SAMPLE_MEDIA_PATH'];
  if (envPath != null && envPath.isNotEmpty) {
    return; // SampleMediaPaths will use this
  }

  // Try common workspace locations
  final possibleRoots = [
    Directory.current.path,
    p.join(Directory.current.path, '..', '..'),
    Platform.environment['HOME'] ?? '',
  ];

  for (final root in possibleRoots) {
    if (root.isEmpty) continue;

    final pubspec = File(p.join(root, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final content = pubspec.readAsStringSync();
      if (content.contains('workspace:')) {
        final sampleMediaDir = Directory(
          p.join(root, '.dart_tool', 'sample_media'),
        );
        if (sampleMediaDir.existsSync()) {
          SampleMediaPaths.rootDirectory = sampleMediaDir;
          return;
        }
      }
    }
  }

  // Search from executable path
  final executablePath = Platform.resolvedExecutable;
  var searchDir = Directory(p.dirname(executablePath));
  for (var i = 0; i < 10 && searchDir.path != searchDir.parent.path; i++) {
    final pubspec = File(p.join(searchDir.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      try {
        final content = pubspec.readAsStringSync();
        if (content.contains('workspace:')) {
          final sampleMediaDir = Directory(
            p.join(searchDir.path, '.dart_tool', 'sample_media'),
          );
          if (sampleMediaDir.existsSync()) {
            SampleMediaPaths.rootDirectory = sampleMediaDir;
            return;
          }
        }
      } catch (_) {
        // Ignore read errors
      }
    }
    searchDir = searchDir.parent;
  }
}
