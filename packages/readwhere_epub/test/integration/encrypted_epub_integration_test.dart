@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:readwhere_epub/readwhere_epub.dart';
import 'package:test/test.dart';

import '../fixtures/encrypted_epub_builder.dart';

/// Integration tests for encrypted EPUB reading.
///
/// These tests verify the complete decryption pipeline using
/// programmatically built encrypted EPUBs.
///
/// For testing with real encrypted EPUBs from EDRLab:
/// - Passphrase: "edrlab rocks"
/// - Download from: https://edrlab.org/public/feed/opds-lcp.json
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('epub_encryption_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('IDPF Font Obfuscation Integration', () {
    test('reads EPUB with IDPF obfuscated fonts', () async {
      // Create a fake font (OpenType header bytes)
      final originalFont = Uint8List.fromList([
        // OTF magic number
        0x4F, 0x54, 0x54, 0x4F,
        // Padding to exceed 1040 bytes for proper obfuscation test
        ...List.generate(2000, (i) => (i * 17 + 31) % 256),
      ]);

      // Build EPUB with obfuscated font
      final builder = EncryptedEpubBuilder(
        uniqueIdentifier: 'urn:uuid:12345678-1234-5678-1234-567812345678',
        title: 'Font Obfuscation Test',
      );

      builder.addChapter(
        id: 'chapter1',
        filename: 'chapter1.xhtml',
        title: 'Chapter 1',
        content: '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter 1</title></head>
<body><h1>Chapter 1</h1><p>Test content with embedded font.</p></body>
</html>''',
      );

      builder.addIdpfObfuscatedFont(
        id: 'font1',
        filename: 'test-font.otf',
        fontBytes: originalFont,
      );

      final epubPath = '${tempDir.path}/font-test.epub';
      await builder.buildToFile(epubPath);

      // Open and read the EPUB
      final reader = await EpubReader.open(epubPath);

      // Verify basic parsing works
      expect(reader.title, equals('Font Obfuscation Test'));
      expect(reader.chapterCount, equals(1));

      // Verify font obfuscation is detected
      expect(reader.hasEncryption, isTrue);
      expect(reader.encryptionInfo.type, equals(EncryptionType.fontObfuscation));
      expect(reader.canDecrypt, isTrue);
      expect(reader.requiresCredentials, isFalse);

      // Read and verify the font can be accessed
      final fontResource = reader.getResource('fonts/test-font.otf');
      expect(fontResource.bytes, isNotNull);
      expect(fontResource.bytes.length, equals(originalFont.length));

      // Verify the font was deobfuscated correctly
      // (XOR is symmetric, so original bytes should match)
      expect(fontResource.bytes, equals(originalFont));
    });

    test('reads EPUB with Adobe obfuscated fonts', () async {
      final originalFont = Uint8List.fromList([
        0x00, 0x01, 0x00, 0x00, // TTF magic
        ...List.generate(2000, (i) => (i * 13 + 7) % 256),
      ]);

      final builder = EncryptedEpubBuilder(
        uniqueIdentifier: 'urn:uuid:abcd1234-abcd-1234-abcd-1234abcd5678',
        title: 'Adobe Font Test',
      );

      builder.addChapter(
        id: 'chapter1',
        filename: 'chapter1.xhtml',
        title: 'Chapter 1',
        content: '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter 1</title></head>
<body><p>Content with Adobe obfuscated font.</p></body>
</html>''',
      );

      builder.addAdobeObfuscatedFont(
        id: 'font1',
        filename: 'adobe-font.ttf',
        fontBytes: originalFont,
      );

      final epubPath = '${tempDir.path}/adobe-font-test.epub';
      await builder.buildToFile(epubPath);

      final reader = await EpubReader.open(epubPath);

      expect(reader.hasEncryption, isTrue);
      expect(reader.canDecrypt, isTrue);

      final fontResource = reader.getResource('fonts/adobe-font.ttf');
      expect(fontResource.bytes, equals(originalFont));
    });

    test('correctly identifies font obfuscation as non-DRM', () async {
      final builder = EncryptedEpubBuilder(
        uniqueIdentifier: 'test-id-12345',
        title: 'Non-DRM Test',
      );

      builder.addChapter(
        id: 'ch1',
        filename: 'ch1.xhtml',
        title: 'Content',
        content: '<html><body><p>Hello</p></body></html>',
      );

      builder.addIdpfObfuscatedFont(
        id: 'f1',
        filename: 'font.otf',
        fontBytes: Uint8List.fromList(List.generate(100, (i) => i)),
      );

      final epubPath = '${tempDir.path}/non-drm.epub';
      await builder.buildToFile(epubPath);

      final reader = await EpubReader.open(epubPath);

      expect(reader.encryptionInfo.hasDrm, isFalse);
      expect(reader.encryptionInfo.isOnlyFontObfuscation, isTrue);
      expect(reader.encryptionDescription, contains('font'));
    });
  });

  group('Unencrypted EPUB', () {
    test('reads unencrypted EPUB without issues', () async {
      final builder = EncryptedEpubBuilder(
        uniqueIdentifier: 'simple-test-id',
        title: 'Simple Unencrypted Book',
        author: 'Test Author',
      );

      builder.addChapter(
        id: 'chapter1',
        filename: 'chapter1.xhtml',
        title: 'First Chapter',
        content: '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>First Chapter</title></head>
<body>
  <h1>First Chapter</h1>
  <p>This is the content of the first chapter.</p>
</body>
</html>''',
      );

      builder.addChapter(
        id: 'chapter2',
        filename: 'chapter2.xhtml',
        title: 'Second Chapter',
        content: '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Second Chapter</title></head>
<body>
  <h1>Second Chapter</h1>
  <p>This is the content of the second chapter.</p>
</body>
</html>''',
      );

      final epubPath = '${tempDir.path}/unencrypted.epub';
      await builder.buildToFile(epubPath);

      final reader = await EpubReader.open(epubPath);

      expect(reader.title, equals('Simple Unencrypted Book'));
      expect(reader.author, equals('Test Author'));
      expect(reader.chapterCount, equals(2));
      expect(reader.hasEncryption, isFalse);
      expect(reader.canDecrypt, isTrue);
      expect(reader.requiresCredentials, isFalse);

      // Verify chapter content is readable
      final chapter1 = reader.getChapter(0);
      expect(chapter1.content, contains('First Chapter'));
      expect(chapter1.content, contains('content of the first chapter'));

      final chapter2 = reader.getChapter(1);
      expect(chapter2.content, contains('Second Chapter'));
    });
  });

  group('Encryption status reporting', () {
    test('reports correct encryption type for font obfuscation', () async {
      final builder = EncryptedEpubBuilder(uniqueIdentifier: 'id-123');

      builder.addChapter(
        id: 'ch1',
        filename: 'ch1.xhtml',
        title: 'Chapter',
        content: '<html><body>Content</body></html>',
      );

      builder.addIdpfObfuscatedFont(
        id: 'f1',
        filename: 'font.otf',
        fontBytes: Uint8List(100),
      );

      final epubPath = '${tempDir.path}/font-enc.epub';
      await builder.buildToFile(epubPath);

      final reader = await EpubReader.open(epubPath);

      expect(reader.encryptionInfo.type, equals(EncryptionType.fontObfuscation));
      expect(reader.encryptionInfo.encryptedResourceCount, equals(1));
      expect(reader.encryptionInfo.fontObfuscatedResources.length, equals(1));
      expect(reader.encryptionInfo.drmEncryptedResources.length, equals(0));
    });
  });

  group('DecryptionContext edge cases', () {
    test('handles missing unique identifier gracefully', () async {
      // Build EPUB but the context should handle empty identifier
      final builder = EncryptedEpubBuilder(
        uniqueIdentifier: '', // Empty identifier
        title: 'No ID Book',
      );

      builder.addChapter(
        id: 'ch1',
        filename: 'ch1.xhtml',
        title: 'Chapter',
        content: '<html><body>Content</body></html>',
      );

      final epubPath = '${tempDir.path}/no-id.epub';
      await builder.buildToFile(epubPath);

      // Should open without throwing
      final reader = await EpubReader.open(epubPath);
      expect(reader.title, equals('No ID Book'));
      expect(reader.canDecrypt, isTrue);
    });

    test('handles multiple fonts with different obfuscation', () async {
      final font1 = Uint8List.fromList(List.generate(1500, (i) => i % 256));
      final font2 = Uint8List.fromList(List.generate(1500, (i) => (i * 2) % 256));

      final builder = EncryptedEpubBuilder(
        uniqueIdentifier: 'urn:uuid:multi-font-test-1234',
      );

      builder.addChapter(
        id: 'ch1',
        filename: 'ch1.xhtml',
        title: 'Chapter',
        content: '<html><body>Multi-font content</body></html>',
      );

      builder.addIdpfObfuscatedFont(
        id: 'font1',
        filename: 'regular.otf',
        fontBytes: font1,
      );

      builder.addIdpfObfuscatedFont(
        id: 'font2',
        filename: 'bold.otf',
        fontBytes: font2,
      );

      final epubPath = '${tempDir.path}/multi-font.epub';
      await builder.buildToFile(epubPath);

      final reader = await EpubReader.open(epubPath);

      expect(reader.encryptionInfo.fontObfuscatedResources.length, equals(2));

      final readFont1 = reader.getResource('fonts/regular.otf');
      final readFont2 = reader.getResource('fonts/bold.otf');

      expect(readFont1.bytes, equals(font1));
      expect(readFont2.bytes, equals(font2));
    });
  });
}

/// Helper to check if test can run with real EDRLab samples.
///
/// Set environment variable EDRLAB_LCP_SAMPLES_PATH to the directory
/// containing downloaded LCP-protected EPUBs from EDRLab.
///
/// Test passphrase: "edrlab rocks"
String? get edrlabSamplesPath => Platform.environment['EDRLAB_LCP_SAMPLES_PATH'];

/// Tests using real EDRLab LCP samples (skipped if not available).
@TestOn('vm')
void realLcpTests() {
  group('Real EDRLab LCP Samples', () {
    test(
      'reads LCP-protected EPUB with correct passphrase',
      () async {
        final samplesPath = edrlabSamplesPath;
        if (samplesPath == null) {
          markTestSkipped('EDRLAB_LCP_SAMPLES_PATH not set');
          return;
        }

        final sampleDir = Directory(samplesPath);
        if (!await sampleDir.exists()) {
          markTestSkipped('EDRLab samples directory not found');
          return;
        }

        final epubFiles = await sampleDir
            .list()
            .where((e) => e.path.endsWith('.epub'))
            .toList();

        if (epubFiles.isEmpty) {
          markTestSkipped('No EPUB files found in samples directory');
          return;
        }

        final epubPath = epubFiles.first.path;
        const passphrase = 'edrlab rocks';

        final reader = await EpubReader.open(epubPath, passphrase: passphrase);

        expect(reader.canDecrypt, isTrue);
        expect(reader.encryptionInfo.type, equals(EncryptionType.lcp));

        // Should be able to read chapter content
        if (reader.chapterCount > 0) {
          final chapter = reader.getChapter(0);
          expect(chapter.content, isNotEmpty);
        }
      },
      skip: edrlabSamplesPath == null
          ? 'Set EDRLAB_LCP_SAMPLES_PATH to run real LCP tests'
          : null,
    );
  });
}
