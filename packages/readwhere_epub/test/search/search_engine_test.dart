import 'package:test/test.dart';
import 'package:readwhere_epub/readwhere_epub.dart';

void main() {
  late List<EpubChapter> testChapters;
  late EpubSearchEngine searchEngine;

  setUp(() {
    testChapters = [
      const EpubChapter(
        id: 'ch1',
        href: 'chapter1.xhtml',
        title: 'Introduction',
        spineIndex: 0,
        content: '''
          <html><body>
            <p>Welcome to this adventure book. This is the beginning of a great journey.</p>
            <p>The hero starts their adventure in a small village.</p>
          </body></html>
        ''',
      ),
      const EpubChapter(
        id: 'ch2',
        href: 'chapter2.xhtml',
        title: 'The Journey',
        spineIndex: 1,
        content: '''
          <html><body>
            <p>The adventure continues as the hero travels across the land.</p>
            <p>Many adventures await in the forest ahead.</p>
          </body></html>
        ''',
      ),
      const EpubChapter(
        id: 'ch3',
        href: 'chapter3.xhtml',
        title: 'The End',
        spineIndex: 2,
        content: '''
          <html><body>
            <p>The adventure concludes with the hero returning home.</p>
            <p>All's well that ends well.</p>
          </body></html>
        ''',
      ),
    ];
    searchEngine = EpubSearchEngine(testChapters);
  });

  group('EpubSearchEngine', () {
    group('search', () {
      test('finds matches across all chapters', () async {
        final results = await searchEngine.search('adventure').toList();

        expect(results, hasLength(5)); // adventure appears 5 times
      });

      test('returns empty for empty query', () async {
        final results = await searchEngine.search('').toList();

        expect(results, isEmpty);
      });

      test('returns empty for no matches', () async {
        final results = await searchEngine.search('dragon').toList();

        expect(results, isEmpty);
      });

      test('respects case sensitivity option', () async {
        final insensitiveResults = await searchEngine
            .search('ADVENTURE',
                options: const SearchOptions(caseSensitive: false))
            .toList();

        final sensitiveResults = await searchEngine
            .search('ADVENTURE',
                options: const SearchOptions(caseSensitive: true))
            .toList();

        expect(insensitiveResults, hasLength(5));
        expect(sensitiveResults, isEmpty);
      });

      test('respects maxResults limit', () async {
        final results = await searchEngine
            .search('adventure', options: const SearchOptions(maxResults: 2))
            .toList();

        expect(results, hasLength(2));
      });

      test('respects chaptersToSearch filter', () async {
        final results = await searchEngine
            .search('adventure', options: SearchOptions(chaptersToSearch: {0}))
            .toList();

        expect(results, hasLength(2)); // Only chapter 0 has 2 matches
        expect(results.every((r) => r.chapterIndex == 0), isTrue);
      });

      test('includes context in results', () async {
        final results = await searchEngine
            .search('hero', options: const SearchOptions(contextChars: 20))
            .toList();

        expect(results.first.contextBefore, isNotEmpty);
        expect(results.first.contextAfter, isNotEmpty);
      });
    });

    group('searchChapter', () {
      test('finds matches in specific chapter', () {
        final results = searchEngine.searchChapter(0, 'adventure');

        expect(results, hasLength(2));
        expect(results.every((r) => r.chapterIndex == 0), isTrue);
      });

      test('returns empty for invalid chapter index', () {
        final results = searchEngine.searchChapter(-1, 'test');
        expect(results, isEmpty);

        final results2 = searchEngine.searchChapter(100, 'test');
        expect(results2, isEmpty);
      });

      test('includes chapter metadata in results', () {
        final results = searchEngine.searchChapter(0, 'adventure');

        expect(results.first.chapterId, equals('ch1'));
        expect(results.first.chapterTitle, equals('Introduction'));
      });
    });

    group('countMatches', () {
      test('counts total matches across all chapters', () {
        final count = searchEngine.countMatches('adventure');

        expect(count, equals(5));
      });

      test('returns zero for empty query', () {
        final count = searchEngine.countMatches('');

        expect(count, equals(0));
      });

      test('returns zero for no matches', () {
        final count = searchEngine.countMatches('dragon');

        expect(count, equals(0));
      });

      test('respects chaptersToSearch filter', () {
        final count = searchEngine.countMatches(
          'adventure',
          options: SearchOptions(chaptersToSearch: {0}),
        );

        expect(count, equals(2));
      });
    });

    group('whole word matching', () {
      test('matches whole words only', () async {
        final wholeWordResults = await searchEngine
            .search('book', options: SearchOptions.wholeWord())
            .toList();

        expect(wholeWordResults, hasLength(1)); // Only "book" not "books"
      });

      test('does not match partial words', () async {
        final results = await searchEngine
            .search('advent', options: SearchOptions.wholeWord())
            .toList();

        expect(results, isEmpty); // "adventure" doesn't match "advent"
      });
    });

    group('regex search', () {
      test('supports custom regex patterns', () async {
        final results = await searchEngine
            .search('', options: SearchOptions.regex(r'hero\b'))
            .toList();

        expect(results, hasLength(3)); // "hero" appears 3 times
      });
    });
  });

  group('EpubSearchResult', () {
    test('calculates matchEnd correctly', () {
      const result = EpubSearchResult(
        chapterIndex: 0,
        chapterId: 'ch1',
        matchText: 'adventure',
        contextBefore: 'this ',
        contextAfter: ' book',
        matchStart: 10,
        matchLength: 9,
      );

      expect(result.matchEnd, equals(19));
    });

    test('generates fullContext correctly', () {
      const result = EpubSearchResult(
        chapterIndex: 0,
        chapterId: 'ch1',
        matchText: 'adventure',
        contextBefore: 'this ',
        contextAfter: ' book',
        matchStart: 10,
        matchLength: 9,
      );

      expect(result.fullContext, equals('this adventure book'));
    });

    test('copyWith creates modified copy', () {
      const original = EpubSearchResult(
        chapterIndex: 0,
        chapterId: 'ch1',
        matchText: 'test',
        contextBefore: '',
        contextAfter: '',
        matchStart: 0,
        matchLength: 4,
      );

      final modified = original.copyWith(chapterIndex: 1);

      expect(modified.chapterIndex, equals(1));
      expect(modified.chapterId, equals('ch1')); // Unchanged
    });
  });

  group('SearchOptions', () {
    test('has sensible defaults', () {
      const options = SearchOptions();

      expect(options.caseSensitive, isFalse);
      expect(options.wholeWord, isFalse);
      expect(options.contextChars, equals(50));
      expect(options.maxResults, equals(0));
    });

    test('caseSensitive factory works', () {
      final options = SearchOptions.caseSensitive();

      expect(options.caseSensitive, isTrue);
    });

    test('wholeWord factory works', () {
      final options = SearchOptions.wholeWord();

      expect(options.wholeWord, isTrue);
    });

    test('regex factory creates pattern', () {
      final options = SearchOptions.regex(r'\d+');

      expect(options.pattern, isNotNull);
      expect(options.pattern!.hasMatch('123'), isTrue);
    });

    test('hasLimit returns correct value', () {
      const unlimited = SearchOptions();
      const limited = SearchOptions(maxResults: 10);

      expect(unlimited.hasLimit, isFalse);
      expect(limited.hasLimit, isTrue);
    });

    test('searchAllChapters returns correct value', () {
      const allChapters = SearchOptions();
      final specificChapters = SearchOptions(chaptersToSearch: {0, 1});

      expect(allChapters.searchAllChapters, isTrue);
      expect(specificChapters.searchAllChapters, isFalse);
    });
  });

  group('SearchableChapters extension', () {
    test('creates search engine', () {
      expect(testChapters.searchEngine, isA<EpubSearchEngine>());
    });

    test('search method works', () async {
      final results = await testChapters.search('adventure').toList();

      expect(results, hasLength(5));
    });
  });
}
