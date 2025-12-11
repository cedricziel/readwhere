import 'package:readwhere_fanfictionde/readwhere_fanfictionde.dart';
import 'package:test/test.dart';

void main() {
  group('StoryParser', () {
    const parser = StoryParser();

    group('parseStoryList', () {
      test('parses empty HTML without throwing', () {
        final result = parser.parseStoryList('<html><body></body></html>');

        expect(result.stories, isEmpty);
        expect(result.currentPage, equals(1));
      });

      test('parses latest stories item format', () {
        const html = '''
          <html><body>
            <div class="lateststories-item">
              <a href="/s/abc123def456/1/test-story" aria-label="This is the summary">
                Test Story Title
              </a>
              <a href="/u/testuser">Test Author</a>
              <div class="tiny-font">
                <a href="/Anime-Manga/c/102000000">Anime &amp; Manga</a>
                <a href="/Anime-Manga/Naruto/c/102001000">Naruto</a>
              </div>
              <div class="tiny-font">
                Geschichte / Abenteuer, Drama / P16 / Abgeschlossen
              </div>
            </div>
          </body></html>
        ''';

        final result = parser.parseStoryList(html);

        expect(result.stories, hasLength(1));
        expect(result.stories.first.id, equals('abc123def456'));
        expect(result.stories.first.title, equals('Test Story Title'));
        expect(result.stories.first.author.username, equals('testuser'));
        expect(result.stories.first.author.displayName, equals('Test Author'));
        expect(result.stories.first.summary, equals('This is the summary'));
      });

      test('extracts story ID from various URL formats', () {
        const html = '''
          <html><body>
            <div class="lateststories-item">
              <a href="/s/692ad8140010153d10b9ea34/1/some-slug">Story</a>
              <a href="/u/author">Author</a>
            </div>
          </body></html>
        ''';

        final result = parser.parseStoryList(html);

        expect(result.stories.first.id, equals('692ad8140010153d10b9ea34'));
      });
    });

    group('parseStoryDetails', () {
      test('extracts story ID from canonical URL', () {
        const html = '''
          <html>
            <head>
              <link rel="canonical" href="https://www.fanfiktion.de/s/abc123/1/test"/>
            </head>
            <body>
              <div class="story-left">
                <h4>Story Title</h4>
                <a href="/u/testauthor">Author Name</a>
              </div>
            </body>
          </html>
        ''';

        final story = parser.parseStoryDetails(html);

        expect(story.id, equals('abc123'));
        expect(story.title, equals('Story Title'));
        expect(story.author.username, equals('testauthor'));
      });

      test('parses chapter dropdown for chapter count', () {
        const html = '''
          <html>
            <head>
              <link rel="canonical" href="https://www.fanfiktion.de/s/abc123/1/test"/>
            </head>
            <body>
              <div class="story-left">
                <h4>Multi Chapter Story</h4>
                <a href="/u/author">Author</a>
              </div>
              <select name="k">
                <option value="1">1. Chapter One</option>
                <option value="2">2. Chapter Two</option>
                <option value="3">3. Chapter Three</option>
              </select>
            </body>
          </html>
        ''';

        final story = parser.parseStoryDetails(html);

        expect(story.chapterCount, equals(3));
        expect(story.chapters, hasLength(3));
        expect(story.chapters[0].title, equals('Chapter One'));
        expect(story.chapters[1].number, equals(2));
      });
    });
  });
}
