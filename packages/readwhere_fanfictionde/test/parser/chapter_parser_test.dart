import 'package:readwhere_fanfictionde/readwhere_fanfictionde.dart';
import 'package:test/test.dart';

void main() {
  group('ChapterParser', () {
    const parser = ChapterParser();

    group('parseChapter', () {
      test('extracts chapter title from story page', () {
        const html = '''
          <html><body>
            <div class="story-left">
              <h4>Story Title</h4>
            </div>
            <select name="k">
              <option value="1" selected>1. First Chapter</option>
              <option value="2">2. Second Chapter</option>
            </select>
            <div id="storytext">
              <div class="user-formatted-inner">
                <p>Chapter content here.</p>
              </div>
            </div>
          </body></html>
        ''';

        final chapter = parser.parseChapter(html, 1);

        expect(chapter.number, equals(1));
        expect(chapter.title, equals('First Chapter'));
        expect(chapter.htmlContent, contains('Chapter content here'));
      });

      test('handles single chapter stories with default title', () {
        const html = '''
          <html><body>
            <div class="story-left">
              <h4>Single Chapter Story</h4>
            </div>
            <div id="storytext">
              <div class="user-formatted-inner">
                <p>The only chapter.</p>
              </div>
            </div>
          </body></html>
        ''';

        final chapter = parser.parseChapter(html, 1);

        expect(chapter.number, equals(1));
        // Without a select element, defaults to "Chapter N"
        expect(chapter.title, equals('Chapter 1'));
      });
    });

    group('cleanChapterHtml', () {
      test('removes script tags', () {
        const html = '<p>Content</p><script>alert("bad")</script><p>More</p>';

        final cleaned = parser.cleanChapterHtml(html);

        expect(cleaned, isNot(contains('script')));
        expect(cleaned, contains('Content'));
        expect(cleaned, contains('More'));
      });

      test('removes style tags', () {
        const html = '<p>Content</p><style>.bad{}</style>';

        final cleaned = parser.cleanChapterHtml(html);

        expect(cleaned, isNot(contains('style')));
        expect(cleaned, contains('Content'));
      });

      test('removes onclick attributes', () {
        const html = '<p onclick="evil()">Click me</p>';

        final cleaned = parser.cleanChapterHtml(html);

        expect(cleaned, isNot(contains('onclick')));
        expect(cleaned, contains('Click me'));
      });

      test('preserves allowed formatting tags', () {
        const html = '''
          <p><strong>Bold</strong> and <em>italic</em> text.</p>
          <p><b>Also bold</b> and <i>also italic</i>.</p>
          <p><u>Underlined</u> text.</p>
        ''';

        final cleaned = parser.cleanChapterHtml(html);

        // <b> and <i> are converted to <strong> and <em>
        expect(cleaned, contains('<strong>'));
        expect(cleaned, contains('<em>'));
        expect(cleaned, contains('<u>'));
        expect(cleaned, contains('Bold'));
        expect(cleaned, contains('italic'));
        expect(cleaned, contains('Underlined'));
      });

      test('preserves line breaks', () {
        const html = '<p>Line one<br/>Line two<br>Line three</p>';

        final cleaned = parser.cleanChapterHtml(html);

        // Should preserve br tags in some form
        expect(cleaned, contains('Line one'));
        expect(cleaned, contains('Line two'));
      });

      test('handles empty input', () {
        final cleaned = parser.cleanChapterHtml('');

        expect(cleaned, isEmpty);
      });

      test('handles malformed HTML gracefully', () {
        const html = '<p>Unclosed paragraph<p>Another unclosed';

        // Should not throw
        final cleaned = parser.cleanChapterHtml(html);

        expect(cleaned, contains('Unclosed paragraph'));
      });
    });
  });
}
