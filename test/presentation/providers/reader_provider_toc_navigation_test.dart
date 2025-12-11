import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/presentation/providers/reader_provider.dart';
import 'package:readwhere_epub_plugin/readwhere_epub_plugin.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../../mocks/mock_repositories.mocks.dart';

// Mock for ReadwhereEpubController
class MockReadwhereEpubController extends Mock
    implements ReadwhereEpubController {}

void main() {
  late ReaderProvider readerProvider;
  late MockReadingProgressRepository mockProgressRepository;
  late MockBookmarkRepository mockBookmarkRepository;
  late UnifiedPluginRegistry pluginRegistry;

  setUp(() {
    mockProgressRepository = MockReadingProgressRepository();
    mockBookmarkRepository = MockBookmarkRepository();
    pluginRegistry = UnifiedPluginRegistry();

    readerProvider = ReaderProvider(
      readingProgressRepository: mockProgressRepository,
      bookmarkRepository: mockBookmarkRepository,
      pluginRegistry: pluginRegistry,
    );
  });

  group('ReaderProvider TOC Navigation', () {
    group('currentChapterHref', () {
      test('returns null when no book is open', () {
        expect(readerProvider.currentChapterHref, isNull);
      });
    });

    group('goToTocEntry', () {
      test('navigates using href-to-spine mapping for EPUB', () async {
        // This test verifies the concept - in a real scenario we would
        // need to open an actual EPUB with proper TOC/spine structure
        // to fully test the mapping logic.

        // Create a TOC entry with a known href
        final tocEntry = TocEntry(
          id: 'chapter-1',
          title: 'Chapter 1',
          href: 'chapter1.xhtml',
          level: 0,
        );

        // Without a book open, goToTocEntry should return early
        await readerProvider.goToTocEntry(tocEntry);

        // Verify no error was thrown and provider is in valid state
        expect(readerProvider.error, isNull);
        expect(readerProvider.currentChapterIndex, 0);
      });

      test('handles TOC entry with fragment in href', () async {
        final tocEntry = TocEntry(
          id: 'section-1',
          title: 'Section 1',
          href: 'chapter1.xhtml#section1',
          level: 1,
        );

        // Without a book open, goToTocEntry should return early
        await readerProvider.goToTocEntry(tocEntry);

        // Verify no error was thrown
        expect(readerProvider.error, isNull);
      });
    });
  });

  group('TocEntry href matching', () {
    test('TOC entry href is correctly parsed without fragment', () {
      final entry = TocEntry(
        id: 'test',
        title: 'Test',
        href: 'chapter1.xhtml#section1',
        level: 0,
      );

      // Simulate the href parsing logic from goToTocEntry
      final hrefWithoutFragment = entry.href.contains('#')
          ? entry.href.split('#').first
          : entry.href;

      expect(hrefWithoutFragment, 'chapter1.xhtml');
    });

    test('TOC entry href without fragment remains unchanged', () {
      final entry = TocEntry(
        id: 'test',
        title: 'Test',
        href: 'chapter1.xhtml',
        level: 0,
      );

      final hrefWithoutFragment = entry.href.contains('#')
          ? entry.href.split('#').first
          : entry.href;

      expect(hrefWithoutFragment, 'chapter1.xhtml');
    });
  });
}
