import 'package:readwhere_epub/src/utils/path_utils.dart';
import 'package:test/test.dart';

void main() {
  group('PathUtils', () {
    group('normalize', () {
      test('normalizes simple paths', () {
        expect(PathUtils.normalize('OEBPS/content.opf'), equals('OEBPS/content.opf'));
      });

      test('removes leading slash', () {
        expect(PathUtils.normalize('/OEBPS/content.opf'), equals('OEBPS/content.opf'));
      });

      test('resolves parent references', () {
        expect(PathUtils.normalize('OEBPS/Text/../Images/cover.jpg'),
            equals('OEBPS/Images/cover.jpg'));
      });

      test('resolves current directory references', () {
        expect(PathUtils.normalize('OEBPS/./Text/chapter1.xhtml'),
            equals('OEBPS/Text/chapter1.xhtml'));
      });

      test('handles multiple parent references', () {
        expect(PathUtils.normalize('OEBPS/Text/Sub/../../Images/cover.jpg'),
            equals('OEBPS/Images/cover.jpg'));
      });
    });

    group('resolve', () {
      test('resolves sibling path', () {
        expect(PathUtils.resolve('OEBPS/Text/chapter1.xhtml', 'chapter2.xhtml'),
            equals('OEBPS/Text/chapter2.xhtml'));
      });

      test('resolves parent reference', () {
        expect(PathUtils.resolve('OEBPS/Text/chapter1.xhtml', '../Images/cover.jpg'),
            equals('OEBPS/Images/cover.jpg'));
      });

      test('handles absolute path in EPUB', () {
        expect(PathUtils.resolve('OEBPS/Text/chapter1.xhtml', '/Images/cover.jpg'),
            equals('Images/cover.jpg'));
      });
    });

    group('dirname', () {
      test('returns directory for file path', () {
        expect(PathUtils.dirname('OEBPS/Text/chapter1.xhtml'), equals('OEBPS/Text'));
      });

      test('returns directory for nested path', () {
        expect(PathUtils.dirname('OEBPS/content.opf'), equals('OEBPS'));
      });

      test('returns dot for root-level file', () {
        expect(PathUtils.dirname('content.opf'), equals('.'));
      });
    });

    group('basename', () {
      test('returns filename from path', () {
        expect(PathUtils.basename('OEBPS/Text/chapter1.xhtml'), equals('chapter1.xhtml'));
      });

      test('returns filename for root-level file', () {
        expect(PathUtils.basename('content.opf'), equals('content.opf'));
      });
    });

    group('extension', () {
      test('returns extension with dot', () {
        expect(PathUtils.extension('chapter1.xhtml'), equals('.xhtml'));
      });

      test('returns extension for complex path', () {
        expect(PathUtils.extension('OEBPS/Images/cover.jpg'), equals('.jpg'));
      });

      test('returns empty for file without extension', () {
        expect(PathUtils.extension('mimetype'), equals(''));
      });
    });

    group('fragment handling', () {
      test('removeFragment removes fragment', () {
        expect(PathUtils.removeFragment('chapter1.xhtml#section1'),
            equals('chapter1.xhtml'));
      });

      test('removeFragment returns path if no fragment', () {
        expect(PathUtils.removeFragment('chapter1.xhtml'), equals('chapter1.xhtml'));
      });

      test('getFragment returns fragment', () {
        expect(PathUtils.getFragment('chapter1.xhtml#section1'), equals('section1'));
      });

      test('getFragment returns null if no fragment', () {
        expect(PathUtils.getFragment('chapter1.xhtml'), isNull);
      });
    });

    group('urlDecode', () {
      test('decodes URL-encoded characters', () {
        expect(PathUtils.urlDecode('chapter%201.xhtml'), equals('chapter 1.xhtml'));
      });

      test('preserves plus signs (not form encoding)', () {
        // Uri.decodeComponent doesn't convert + to space (that's form encoding)
        expect(PathUtils.urlDecode('chapter+1.xhtml'), equals('chapter+1.xhtml'));
      });
    });
  });
}
