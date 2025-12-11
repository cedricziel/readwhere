import 'package:readwhere_fanfictionde/readwhere_fanfictionde.dart';
import 'package:test/test.dart';

void main() {
  group('CategoryParser', () {
    const parser = CategoryParser();

    group('parseCategories', () {
      test('parses empty HTML without throwing', () {
        final result = parser.parseCategories('<html><body></body></html>');

        expect(result, isEmpty);
      });

      test('parses category links with correct format', () {
        const html = '''
          <html><body>
            <div class="ffcbox">
              <a href="/Anime-Manga/c/102000000">Anime &amp; Manga</a>
              <span class="badge">15000</span>
            </div>
            <div class="ffcbox">
              <a href="/Buecher/c/103000000">Bücher</a>
              <span class="badge">8500</span>
            </div>
          </body></html>
        ''';

        final result = parser.parseCategories(html);

        expect(result, hasLength(2));
        expect(result[0].id, equals('102000000'));
        expect(result[0].name, equals('Anime & Manga'));
        expect(result[0].url, contains('/Anime-Manga/c/102000000'));

        expect(result[1].id, equals('103000000'));
        expect(result[1].name, equals('Bücher'));
      });

      test('avoids duplicate categories', () {
        const html = '''
          <html><body>
            <a href="/Category/c/12345">Category</a>
            <a href="/Category/c/12345">Category</a>
          </body></html>
        ''';

        final result = parser.parseCategories(html);

        expect(result, hasLength(1));
      });
    });

    group('parseFandoms', () {
      test('parses fandom links from category page', () {
        const html = '''
          <html><body>
            <a href="/Anime-Manga/Naruto/c/102001000">Naruto</a>
            <a href="/Anime-Manga/OnePiece/c/102002000">One Piece</a>
            <a href="/Anime-Manga/c/102000000">Anime &amp; Manga</a>
          </body></html>
        ''';

        final result = parser.parseFandoms(html, '102000000');

        // Should exclude the parent category itself
        expect(result, hasLength(2));
        expect(result[0].id, equals('102001000'));
        expect(result[0].name, equals('Naruto'));
        expect(result[0].categoryId, equals('102000000'));

        expect(result[1].id, equals('102002000'));
        expect(result[1].name, equals('One Piece'));
      });

      test('extracts story count from badge', () {
        const html = '''
          <html><body>
            <span>
              <a href="/Category/Fandom/c/12345">Test Fandom</a>
              <span class="badge">5000</span>
            </span>
          </body></html>
        ''';

        final result = parser.parseFandoms(html, '99999');

        expect(result, hasLength(1));
        expect(result.first.storyCount, equals(5000));
      });
    });

    group('parsePagination', () {
      test('returns defaults for empty HTML', () {
        final result = parser.parsePagination('<html><body></body></html>');

        expect(result.currentPage, equals(1));
        expect(result.totalPages, isNull);
        expect(result.hasNext, isFalse);
      });

      test('detects next page link', () {
        const html = '''
          <html><body>
            <div class="pager">
              <a href="/cat/1/updatedate">1</a>
              <a href="/cat/2/updatedate">»</a>
            </div>
          </body></html>
        ''';

        final result = parser.parsePagination(html);

        expect(result.hasNext, isTrue);
      });
    });
  });
}
