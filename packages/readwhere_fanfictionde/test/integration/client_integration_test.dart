@Tags(['integration'])
library;

import 'package:readwhere_fanfictionde/readwhere_fanfictionde.dart';
import 'package:test/test.dart';

/// Integration tests for FanfictionClient.
///
/// These tests run against the live fanfiction.de website.
/// Run with: dart test --tags=integration
///
/// Note: These tests depend on external website availability and content.
/// They may need updates if the website structure changes.
void main() {
  late FanfictionClient client;

  setUpAll(() {
    client = FanfictionClient(
      userAgent: 'ReadWhere/1.0 (Integration Tests)',
      timeout: const Duration(seconds: 60),
    );
  });

  tearDownAll(() {
    client.close();
  });

  group('FanfictionClient Integration', () {
    group('fetchCategories', () {
      test('fetches main categories from homepage', () async {
        final categories = await client.fetchCategories();

        expect(categories, isNotEmpty);
        // fanfiction.de has several main categories
        expect(categories.length, greaterThanOrEqualTo(5));

        // Check structure of first category
        final firstCategory = categories.first;
        expect(firstCategory.id, isNotEmpty);
        expect(firstCategory.name, isNotEmpty);
        expect(firstCategory.url, contains('/c/'));

        // Print categories for debugging
        for (final cat in categories) {
          // ignore: avoid_print
          print('Category: ${cat.name} (${cat.id}) - ${cat.url}');
        }
      });

      test('category IDs are numeric strings', () async {
        final categories = await client.fetchCategories();

        for (final category in categories) {
          expect(
            int.tryParse(category.id),
            isNotNull,
            reason: 'Category ID "${category.id}" should be numeric',
          );
        }
      });
    });

    group('fetchFandoms', () {
      test('fetches fandoms for first category', () async {
        // Get categories dynamically
        final categories = await client.fetchCategories();
        expect(categories, isNotEmpty);

        final firstCategory = categories.first;
        // ignore: avoid_print
        print('Testing with category: ${firstCategory.name}');

        final fandoms = await client.fetchFandoms(
          firstCategory.url,
          firstCategory.id,
        );

        // Some categories may not have fandoms (direct story listings)
        // So we just check structure if results exist
        if (fandoms.isNotEmpty) {
          final firstFandom = fandoms.first;
          expect(firstFandom.id, isNotEmpty);
          expect(firstFandom.name, isNotEmpty);

          // Print a few fandoms
          for (final fandom in fandoms.take(5)) {
            // ignore: avoid_print
            print('Fandom: ${fandom.name} (${fandom.storyCount} stories)');
          }
        } else {
          // ignore: avoid_print
          print('Category has no fandoms (direct story listing)');
        }
      });
    });

    group('fetchStories', () {
      test('fetches latest stories', () async {
        // Use fetchLatestStories which is more reliable than category pages
        final stories = await client.fetchLatestStories();

        expect(stories.stories, isNotEmpty);

        // Check story structure
        final firstStory = stories.stories.first;
        expect(firstStory.id, isNotEmpty);
        expect(firstStory.title, isNotEmpty);
        expect(firstStory.author.username, isNotEmpty);

        // Print first few stories
        for (final story in stories.stories.take(3)) {
          // ignore: avoid_print
          print('Story: ${story.title} by ${story.author.username}');
          // ignore: avoid_print
          print(
            '  - ${story.chapterCount} chapters, ${story.wordCount} words',
          );
        }
      });

      test('fetches stories via search', () async {
        // Search is more reliable for getting story listings
        // Note: Search may return empty results depending on site state
        final stories = await client.search('Geschichte');

        // We can't guarantee search results, so just verify no error
        // and if results exist, verify structure
        if (stories.stories.isNotEmpty) {
          final firstStory = stories.stories.first;
          expect(firstStory.id, isNotEmpty);
          expect(firstStory.title, isNotEmpty);
          // ignore: avoid_print
          print('Search returned ${stories.stories.length} results');
        } else {
          // ignore: avoid_print
          print('Search returned no results (may be site-specific)');
        }
      });

      test('returns pagination info from latest', () async {
        final result = await client.fetchLatestStories();

        expect(result.currentPage, equals(1));
        // Print pagination info
        // ignore: avoid_print
        print('Current page: ${result.currentPage}');
        // ignore: avoid_print
        print('Has next: ${result.hasNextPage}');
        // ignore: avoid_print
        print('Story count: ${result.stories.length}');
      });
    });

    group('fetchStoryDetails', () {
      test('fetches full story details', () async {
        // Use latest stories which is reliable
        final stories = await client.fetchLatestStories();
        expect(stories.stories, isNotEmpty);

        final storyId = stories.stories.first.id;
        final details = await client.fetchStoryDetails(storyId);

        expect(details.id, equals(storyId));
        expect(details.title, isNotEmpty);
        expect(details.author.username, isNotEmpty);
        expect(details.chapterCount, greaterThan(0));

        // ignore: avoid_print
        print('Story Details:');
        // ignore: avoid_print
        print('  Title: ${details.title}');
        // ignore: avoid_print
        print('  Author: ${details.author.username}');
        // ignore: avoid_print
        print('  Chapters: ${details.chapterCount}');
        // ignore: avoid_print
        print('  Words: ${details.wordCount}');
        // ignore: avoid_print
        print('  Rating: ${details.rating}');
        // ignore: avoid_print
        print('  Complete: ${details.isComplete}');
        final summaryPreview = details.summary.length > 100
            ? '${details.summary.substring(0, 100)}...'
            : details.summary;
        // ignore: avoid_print
        print('  Summary: $summaryPreview');
      });
    });

    group('fetchChapter', () {
      test('fetches chapter content', () async {
        // Get a story from latest
        final stories = await client.fetchLatestStories();
        final storyId = stories.stories.first.id;

        final chapter = await client.fetchChapter(storyId, 1);

        expect(chapter.number, equals(1));
        expect(chapter.title, isNotEmpty);
        expect(chapter.htmlContent, isNotNull);
        expect(chapter.htmlContent, isNotEmpty);

        // ignore: avoid_print
        print('Chapter: ${chapter.title}');
        // ignore: avoid_print
        print('Content length: ${chapter.htmlContent?.length ?? 0} chars');
      });

      test('chapter content is valid HTML', () async {
        final stories = await client.fetchLatestStories();
        final storyId = stories.stories.first.id;

        final chapter = await client.fetchChapter(storyId, 1);

        expect(chapter.htmlContent, isNotNull);
        // Should not contain script tags (sanitized)
        expect(chapter.htmlContent, isNot(contains('<script')));
      });
    });

    group('search', () {
      test('search does not throw', () async {
        // Search functionality may return empty results depending on site state
        // Just verify it doesn't throw an error
        final results = await client.search('Geschichte');

        // Verify we get a result object (even if empty)
        expect(results, isNotNull);
        expect(results.stories, isA<List>());

        if (results.stories.isNotEmpty) {
          // ignore: avoid_print
          print('Search results: ${results.stories.length} stories');
          for (final story in results.stories.take(3)) {
            // ignore: avoid_print
            print('  - ${story.title}');
          }
        } else {
          // ignore: avoid_print
          print('Search returned no results (may be site-specific)');
        }
      });

      test('search handles unlikely terms gracefully', () async {
        // Use a very unlikely search term
        final results = await client.search(
          'xyznonexistentstory12345abcdef',
        );

        // Should return result object without throwing
        expect(results, isNotNull);
      });
    });

    group('fetchLatestStories', () {
      test('fetches recently updated stories', () async {
        final latest = await client.fetchLatestStories();

        expect(latest.stories, isNotEmpty);

        // ignore: avoid_print
        print('Latest stories: ${latest.stories.length}');
        for (final story in latest.stories.take(3)) {
          // ignore: avoid_print
          print('  - ${story.title} (${story.updatedAt})');
        }
      });
    });

    group('error handling', () {
      test('throws FanfictionNotFoundException for invalid story', () async {
        expect(
          () => client.fetchStoryDetails('000000000000000000000000'),
          throwsA(isA<FanfictionNotFoundException>()),
        );
      });

      test('throws for completely invalid path', () async {
        expect(
          () => client.fetchStories('/this-path-does-not-exist-xyz-123'),
          throwsA(isA<FanfictionException>()),
        );
      });
    });
  });
}
