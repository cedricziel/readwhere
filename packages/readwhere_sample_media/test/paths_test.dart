import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:readwhere_sample_media/readwhere_sample_media.dart';
import 'package:test/test.dart';

void main() {
  group('SampleMediaPaths', () {
    setUp(() {
      // Clear cache before each test
      SampleMediaPaths.clearCache();
    });

    test('rootDirectory finds workspace root', () {
      final rootDir = SampleMediaPaths.rootDirectory;
      expect(rootDir.path, contains('.dart_tool'));
      expect(rootDir.path, contains('sample_media'));
    });

    test('isDownloaded returns false when not downloaded', () {
      // Clear any existing cache
      SampleMediaPaths.clearCache();
      final rootDir = SampleMediaPaths.rootDirectory;

      // If version file doesn't exist, should return false
      final versionFile = File(
        p.join(rootDir.path, SampleMediaConfig.versionFileName),
      );
      if (!versionFile.existsSync()) {
        expect(SampleMediaPaths.isDownloaded, isFalse);
      }
    });

    test('getFilesByExtension handles extension with and without dot', () {
      // This test verifies the extension normalization logic
      // Actual file retrieval depends on whether files are downloaded
      final withDot = SampleMediaPaths.getFilesByExtension('.epub');
      final withoutDot = SampleMediaPaths.getFilesByExtension('epub');

      // Both should return same results
      expect(withDot.length, equals(withoutDot.length));
    });

    test('extension getters return lists', () {
      // These should return empty lists if not downloaded, not throw
      expect(SampleMediaPaths.epubFiles, isA<List<File>>());
      expect(SampleMediaPaths.cbzFiles, isA<List<File>>());
      expect(SampleMediaPaths.cbrFiles, isA<List<File>>());
      expect(SampleMediaPaths.pdfFiles, isA<List<File>>());
      expect(SampleMediaPaths.fb2Files, isA<List<File>>());
      expect(SampleMediaPaths.htmlFiles, isA<List<File>>());
      expect(SampleMediaPaths.txtFiles, isA<List<File>>());
      expect(SampleMediaPaths.mdFiles, isA<List<File>>());
      expect(SampleMediaPaths.allFiles, isA<List<File>>());
    });

    test('allFiles excludes hidden files', () {
      final allFiles = SampleMediaPaths.allFiles;
      for (final file in allFiles) {
        final basename = p.basename(file.path);
        expect(basename, isNot(startsWith('.')));
      }
    });

    test('clearCache allows re-detection of root', () {
      final first = SampleMediaPaths.rootDirectory;
      SampleMediaPaths.clearCache();
      final second = SampleMediaPaths.rootDirectory;

      // Should be equivalent paths
      expect(first.path, equals(second.path));
    });
  });
}
