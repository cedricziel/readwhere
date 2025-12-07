import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/plugins/epub/epub.dart';

void main() {
  group('EpubPlugin', () {
    late EpubPlugin plugin;

    setUp(() {
      plugin = EpubPlugin();
    });

    test('should have correct id', () {
      expect(plugin.id, equals('com.readwhere.epub'));
    });

    test('should have correct name', () {
      expect(plugin.name, equals('EPUB Reader'));
    });

    test('should support epub extensions', () {
      expect(plugin.supportedExtensions, contains('epub'));
      expect(plugin.supportedExtensions, contains('epub3'));
    });

    test('should support epub mime types', () {
      expect(plugin.supportedMimeTypes, contains('application/epub+zip'));
      expect(plugin.supportedMimeTypes, contains('application/epub'));
    });

    test('should not handle non-epub files', () async {
      final canHandle = await plugin.canHandle('/path/to/file.pdf');
      expect(canHandle, isFalse);
    });

    test('should not handle files with wrong extension', () async {
      final canHandle = await plugin.canHandle('/path/to/file.txt');
      expect(canHandle, isFalse);
    });

    test('should not handle non-existent files', () async {
      final canHandle = await plugin.canHandle('/nonexistent/file.epub');
      expect(canHandle, isFalse);
    });
  });

  group('EpubUtils', () {
    test('should generate valid CFI', () {
      final cfi = EpubUtils.generateCfi(
        chapterId: 'chapter1',
        spinePosition: 0,
      );

      expect(cfi, startsWith('epubcfi('));
      expect(cfi, contains('[chapter1]'));
      expect(cfi, endsWith(')'));
    });

    test('should generate CFI with character offset', () {
      final cfi = EpubUtils.generateCfi(
        chapterId: 'chapter1',
        spinePosition: 0,
        characterOffset: 100,
      );

      expect(cfi, contains(':100'));
    });

    test('should parse CFI correctly', () {
      final cfi = 'epubcfi(/6/4[chapter1]!/4:100)';
      final parsed = EpubUtils.parseCfi(cfi);

      expect(parsed['spinePosition'], equals(1));
      expect(parsed['chapterId'], equals('chapter1'));
      expect(parsed['characterOffset'], equals(100));
    });

    test('should strip HTML tags', () {
      final html = '<p>Hello <strong>world</strong>!</p>';
      final text = EpubUtils.stripHtmlTags(html);

      expect(text, equals('Hello world!'));
    });

    test('should handle empty HTML', () {
      final text = EpubUtils.stripHtmlTags('');
      expect(text, equals(''));
    });

    test('should clean HTML content', () {
      final html = '<div onclick="alert()">Content</div>';
      final cleaned = EpubUtils.cleanHtmlContent(html);

      expect(cleaned, isNot(contains('onclick')));
      expect(cleaned, contains('Content'));
    });
  });

  group('EpubParser', () {
    test('should have parseBook method', () {
      expect(EpubParser.parseBook, isNotNull);
    });

    test('should have extractMetadata method', () {
      expect(EpubParser.extractMetadata, isNotNull);
    });

    test('should have extractTableOfContents method', () {
      expect(EpubParser.extractTableOfContents, isNotNull);
    });

    test('should have extractCover method', () {
      expect(EpubParser.extractCover, isNotNull);
    });

    test('should have getChapterContent method', () {
      expect(EpubParser.getChapterContent, isNotNull);
    });
  });
}
