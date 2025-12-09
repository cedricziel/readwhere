import 'dart:io';

import 'package:readwhere_rar/readwhere_rar.dart';
import 'package:test/test.dart';

/// Integration tests using real RAR files from ssokolow/rar-test-files repository.
///
/// These tests verify parsing against real archives created by the official
/// RAR toolchain. The test files use compression (not STORE method), and
/// we now support decompression via the Rar29 algorithm.
void main() {
  final fixturesPath =
      '${Directory.current.path}/test/fixtures/rar-test-files-master/build';
  final sourcesPath =
      '${Directory.current.path}/test/fixtures/rar-test-files-master/sources';

  group('RAR 4.x (RAR3) archives', () {
    group('testfile.rar3.rar - single file archive', () {
      late RarArchive archive;

      setUpAll(() async {
        final file = File('$fixturesPath/testfile.rar3.rar');
        if (!file.existsSync()) {
          fail('Test fixture not found: ${file.path}');
        }
        archive = await RarArchive.fromFile(file.path);
      });

      test('parses without error', () {
        expect(archive.files, isNotEmpty);
      });

      test('detects single file', () {
        expect(archive.fileCount, equals(1));
        expect(archive.files.first.path, equals('testfile.txt'));
      });

      test('reports correct file properties', () {
        final file = archive.files.first;
        expect(file.path, equals('testfile.txt'));
        expect(file.fileName, equals('testfile.txt'));
        expect(file.extension, equals('.txt'));
        expect(file.size, equals(12)); // "Testing 123\n"
        expect(file.isDirectory, isFalse);
        expect(file.isEncrypted, isFalse);
      });

      test('detects compression (not STORE) but supports extraction', () {
        final file = archive.files.first;
        expect(file.hasUnsupportedCompression, isFalse);
        expect(file.canExtract, isTrue);
        expect(file.needsDecompression, isTrue);
      });

      test(
          'allFilesExtractable is true for compressed archives (decompression supported)',
          () {
        expect(archive.allFilesExtractable, isTrue);
        expect(archive.unsupportedFiles, isEmpty);
        expect(archive.extractableFiles, hasLength(1));
      });

      test('hasFile works correctly', () {
        expect(archive.hasFile('testfile.txt'), isTrue);
        expect(archive.hasFile('nonexistent.txt'), isFalse);
      });

      test('getFile returns file entry', () {
        final file = archive.getFile('testfile.txt');
        expect(file, isNotNull);
        expect(file!.path, equals('testfile.txt'));
      });
    });

    group('testfile.rar3.cbr - multi-file archive (as CBR)', () {
      late RarArchive archive;

      setUpAll(() async {
        final file = File('$fixturesPath/testfile.rar3.cbr');
        if (!file.existsSync()) {
          fail('Test fixture not found: ${file.path}');
        }
        archive = await RarArchive.fromFile(file.path);
      });

      test('parses multiple files', () {
        // CBR contains only image files (jpg and png)
        expect(archive.fileCount, equals(2));
      });

      test('lists all expected files', () {
        final paths = archive.filePaths.toList()..sort();
        expect(paths, containsAll(['testfile.jpg', 'testfile.png']));
      });

      test('reports correct file sizes', () {
        final jpg = archive.getFile('testfile.jpg')!;
        final png = archive.getFile('testfile.png')!;

        expect(jpg.size, equals(220));
        expect(png.size, equals(87));
      });

      test('getFilesByExtensions filters correctly', () {
        final images = archive.getFilesByExtensions({'.jpg', '.png'});
        expect(images, hasLength(2));
        expect(images.map((f) => f.fileName).toSet(),
            equals({'testfile.jpg', 'testfile.png'}));
      });

      test('all compressed files can be extracted (decompression supported)',
          () {
        for (final file in archive.files) {
          expect(file.hasUnsupportedCompression, isFalse,
              reason: '${file.path} compression should be supported');
          expect(file.canExtract, isTrue,
              reason: '${file.path} should be extractable');
        }
      });
    });

    group('testfile.rar3.solid.rar - solid archive', () {
      late RarArchive archive;

      setUpAll(() async {
        final file = File('$fixturesPath/testfile.rar3.solid.rar');
        if (!file.existsSync()) {
          fail('Test fixture not found: ${file.path}');
        }
        archive = await RarArchive.fromFile(file.path);
      });

      test('parses solid archive', () {
        expect(archive.files, isNotEmpty);
      });
    });

    group('testfile.rar3.locked.rar - locked archive', () {
      late RarArchive archive;

      setUpAll(() async {
        final file = File('$fixturesPath/testfile.rar3.locked.rar');
        if (!file.existsSync()) {
          fail('Test fixture not found: ${file.path}');
        }
        archive = await RarArchive.fromFile(file.path);
      });

      test('parses locked archive', () {
        expect(archive.files, isNotEmpty);
      });
    });

    group('testfile.rar3.rr.rar - archive with recovery record', () {
      late RarArchive archive;

      setUpAll(() async {
        final file = File('$fixturesPath/testfile.rar3.rr.rar');
        if (!file.existsSync()) {
          fail('Test fixture not found: ${file.path}');
        }
        archive = await RarArchive.fromFile(file.path);
      });

      test('parses archive with recovery record', () {
        expect(archive.files, isNotEmpty);
      });
    });
  });

  group('RAR 5.x archives - version detection', () {
    test('rejects testfile.rar5.rar with RarVersionException', () async {
      final file = File('$fixturesPath/testfile.rar5.rar');
      if (!file.existsSync()) {
        fail('Test fixture not found: ${file.path}');
      }

      expect(
        () => RarArchive.fromFile(file.path),
        throwsA(isA<RarVersionException>()),
      );
    });

    test('rejects testfile.rar5.cbr with RarVersionException', () async {
      final file = File('$fixturesPath/testfile.rar5.cbr');
      if (!file.existsSync()) {
        fail('Test fixture not found: ${file.path}');
      }

      expect(
        () => RarArchive.fromFile(file.path),
        throwsA(isA<RarVersionException>()),
      );
    });

    test('isRarArchive returns true for RAR5 (magic matches)', () async {
      final file = File('$fixturesPath/testfile.rar5.rar');
      final bytes = await file.readAsBytes();
      // isRarArchive returns true for any RAR magic (4.x or 5.x)
      expect(RarArchive.isRarArchive(bytes), isTrue);
    });
  });

  group('Source file verification', () {
    test('testfile.txt contains expected content', () async {
      final file = File('$sourcesPath/testfile.txt');
      if (!file.existsSync()) {
        fail('Source file not found: ${file.path}');
      }
      final content = await file.readAsString();
      expect(content, equals('Testing 123\n'));
      expect(content.length, equals(12));
    });

    test('testfile.png has expected size', () async {
      final file = File('$sourcesPath/testfile.png');
      if (!file.existsSync()) {
        fail('Source file not found: ${file.path}');
      }
      expect(file.lengthSync(), equals(87));
    });

    test('testfile.jpg has expected size', () async {
      final file = File('$sourcesPath/testfile.jpg');
      if (!file.existsSync()) {
        fail('Source file not found: ${file.path}');
      }
      expect(file.lengthSync(), equals(220));
    });
  });

  group('Static utility methods', () {
    test('isRarArchive returns true for RAR4', () async {
      final file = File('$fixturesPath/testfile.rar3.rar');
      final bytes = await file.readAsBytes();
      expect(RarArchive.isRarArchive(bytes), isTrue);
    });

    test('isRarArchive returns false for non-RAR data', () async {
      // Use the source PNG file as non-RAR data
      final file = File('$sourcesPath/testfile.png');
      final bytes = await file.readAsBytes();
      expect(RarArchive.isRarArchive(bytes), isFalse);
    });
  });
}
