import 'dart:io';

import 'package:readwhere_sample_media/src/downloader/media_downloader.dart';
import 'package:test/test.dart';

void main() {
  group('MediaDownloader', () {
    test('isAlreadyDownloaded returns false for missing directory', () async {
      final nonExistent = Directory(
          '/tmp/non_existent_${DateTime.now().millisecondsSinceEpoch}');

      final result = await MediaDownloader.isAlreadyDownloaded(
        nonExistent,
        'v0.2',
      );

      expect(result, isFalse);
    });

    test('isAlreadyDownloaded returns false for missing version file',
        () async {
      final tempDir =
          await Directory.systemTemp.createTemp('sample_media_test_');

      try {
        final result = await MediaDownloader.isAlreadyDownloaded(
          tempDir,
          'v0.2',
        );

        expect(result, isFalse);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('isAlreadyDownloaded returns false for version mismatch', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('sample_media_test_');

      try {
        // Write a different version
        final versionFile = File('${tempDir.path}/.version');
        await versionFile.writeAsString('v0.1');

        final result = await MediaDownloader.isAlreadyDownloaded(
          tempDir,
          'v0.2',
        );

        expect(result, isFalse);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('isAlreadyDownloaded returns true for matching version', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('sample_media_test_');

      try {
        // Write matching version
        final versionFile = File('${tempDir.path}/.version');
        await versionFile.writeAsString('v0.2');

        final result = await MediaDownloader.isAlreadyDownloaded(
          tempDir,
          'v0.2',
        );

        expect(result, isTrue);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('isAlreadyDownloaded handles version with whitespace', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('sample_media_test_');

      try {
        // Write version with trailing newline
        final versionFile = File('${tempDir.path}/.version');
        await versionFile.writeAsString('v0.2\n');

        final result = await MediaDownloader.isAlreadyDownloaded(
          tempDir,
          'v0.2',
        );

        expect(result, isTrue);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });

  group('MediaDownloadException', () {
    test('toString includes message', () {
      final exception = MediaDownloadException('Test error');
      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), contains('MediaDownloadException'));
    });

    test('message is accessible', () {
      final exception = MediaDownloadException('Another error');
      expect(exception.message, equals('Another error'));
    });
  });
}
