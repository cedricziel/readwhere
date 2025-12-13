import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:readwhere_pdf/readwhere_pdf.dart';
import 'package:readwhere_sample_media/readwhere_sample_media.dart';

/// Integration tests for PdfReader that run on actual devices/simulators.
///
/// These tests require:
/// 1. Sample media: `dart run readwhere_sample_media:download`
/// 2. Run with:
///    - Set SAMPLE_MEDIA_PATH env var, or
///    - `flutter test integration_test/ -d macos --dart-define=SAMPLE_MEDIA_PATH=/path/to/sample_media`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialize pdfrx library for Flutter
  pdfrx.pdfrxFlutterInitialize();

  // Try to find sample media directory
  _configureSampleMediaPath();

  final bool mediaAvailable = SampleMediaPaths.isDownloaded;

  group('PdfReader Integration', () {
    late List<File> pdfFiles;

    setUpAll(() {
      if (!mediaAvailable) return;
      pdfFiles = SampleMediaPaths.pdfFiles;
    });

    testWidgets('opens valid PDF file', (tester) async {
      if (!mediaAvailable || pdfFiles.isEmpty) {
        markTestSkipped('Sample media not available');
        return;
      }

      final file = pdfFiles.first;
      final reader = await PdfReader.open(file.path);

      try {
        expect(reader.pageCount, greaterThan(0));
        expect(reader.book, isNotNull);
        expect(reader.book.pages, isNotEmpty);
      } finally {
        await reader.dispose();
      }
    });

    testWidgets('renders page image', (tester) async {
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

    testWidgets('extracts page text', (tester) async {
      if (!mediaAvailable || pdfFiles.isEmpty) {
        markTestSkipped('Sample media not available');
        return;
      }

      final file = pdfFiles.first;
      final reader = await PdfReader.open(file.path);

      try {
        final text = await reader.getPageText(0);
        expect(text, isA<String>());
      } finally {
        await reader.dispose();
      }
    });

    testWidgets('gets page dimensions', (tester) async {
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

    testWidgets('generates cover image', (tester) async {
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
}

/// Configures the sample media path for integration tests.
///
/// Tries multiple strategies to find the sample media directory:
/// 1. SAMPLE_MEDIA_PATH environment variable
/// 2. Compile-time define via --dart-define
/// 3. Common workspace locations
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
    // Running from workspace root
    Directory.current.path,
    // Running from package directory
    p.join(Directory.current.path, '..', '..'),
    // macOS app bundle - check for typical development paths
    Platform.environment['HOME'] ?? '',
  ];

  for (final root in possibleRoots) {
    if (root.isEmpty) continue;

    // Check if this looks like the workspace root
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

  // If we still haven't found it, try searching from executable path
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
