import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_pdf/readwhere_pdf.dart';

void main() {
  group('TextBlock', () {
    test('creates block with required fields', () {
      const block = TextBlock(
        text: 'Hello, world!',
        bounds: Rect.fromLTWH(10, 20, 100, 30),
        pageIndex: 0,
        startOffset: 0,
        endOffset: 13,
      );

      expect(block.text, 'Hello, world!');
      expect(block.bounds, const Rect.fromLTWH(10, 20, 100, 30));
      expect(block.pageIndex, 0);
      expect(block.startOffset, 0);
      expect(block.endOffset, 13);
    });

    test('width returns bounds width', () {
      const block = TextBlock(
        text: 'Test',
        bounds: Rect.fromLTWH(0, 0, 150, 25),
        pageIndex: 0,
        startOffset: 0,
        endOffset: 4,
      );

      expect(block.width, 150);
    });

    test('height returns bounds height', () {
      const block = TextBlock(
        text: 'Test',
        bounds: Rect.fromLTWH(0, 0, 150, 25),
        pageIndex: 0,
        startOffset: 0,
        endOffset: 4,
      );

      expect(block.height, 25);
    });

    test('length returns text length', () {
      const block = TextBlock(
        text: 'Hello',
        bounds: Rect.fromLTWH(0, 0, 50, 20),
        pageIndex: 0,
        startOffset: 0,
        endOffset: 5,
      );

      expect(block.length, 5);
    });

    test('isEmpty returns true for empty text', () {
      const block = TextBlock(
        text: '',
        bounds: Rect.fromLTWH(0, 0, 50, 20),
        pageIndex: 0,
        startOffset: 0,
        endOffset: 0,
      );

      expect(block.isEmpty, isTrue);
      expect(block.isNotEmpty, isFalse);
    });

    test('isNotEmpty returns true for non-empty text', () {
      const block = TextBlock(
        text: 'Hello',
        bounds: Rect.fromLTWH(0, 0, 50, 20),
        pageIndex: 0,
        startOffset: 0,
        endOffset: 5,
      );

      expect(block.isEmpty, isFalse);
      expect(block.isNotEmpty, isTrue);
    });

    group('equality', () {
      test('equal blocks are equal', () {
        const block1 = TextBlock(
          text: 'Hello',
          bounds: Rect.fromLTWH(10, 20, 100, 30),
          pageIndex: 0,
          startOffset: 0,
          endOffset: 5,
        );
        const block2 = TextBlock(
          text: 'Hello',
          bounds: Rect.fromLTWH(10, 20, 100, 30),
          pageIndex: 0,
          startOffset: 0,
          endOffset: 5,
        );

        expect(block1, equals(block2));
        expect(block1.hashCode, equals(block2.hashCode));
      });

      test('different blocks are not equal', () {
        const block1 = TextBlock(
          text: 'Hello',
          bounds: Rect.fromLTWH(10, 20, 100, 30),
          pageIndex: 0,
          startOffset: 0,
          endOffset: 5,
        );
        const block2 = TextBlock(
          text: 'World',
          bounds: Rect.fromLTWH(10, 20, 100, 30),
          pageIndex: 0,
          startOffset: 0,
          endOffset: 5,
        );

        expect(block1, isNot(equals(block2)));
      });
    });

    group('toString', () {
      test('shows short text', () {
        const block = TextBlock(
          text: 'Hello',
          bounds: Rect.fromLTWH(10, 20, 100, 30),
          pageIndex: 0,
          startOffset: 0,
          endOffset: 5,
        );

        final str = block.toString();
        expect(str, contains('TextBlock'));
        expect(str, contains('Hello'));
        expect(str, contains('pageIndex: 0'));
      });

      test('truncates long text', () {
        final longText = 'A' * 100;
        final block = TextBlock(
          text: longText,
          bounds: const Rect.fromLTWH(10, 20, 100, 30),
          pageIndex: 0,
          startOffset: 0,
          endOffset: 100,
        );

        final str = block.toString();
        expect(str, contains('...'));
        expect(str.length, lessThan(150)); // Truncated
      });
    });
  });

  group('TextLine', () {
    test('creates line with required fields', () {
      const line = TextLine(
        text: 'Line of text',
        bounds: Rect.fromLTWH(0, 0, 200, 20),
      );

      expect(line.text, 'Line of text');
      expect(line.bounds, const Rect.fromLTWH(0, 0, 200, 20));
      expect(line.fragments, isEmpty);
    });

    test('creates line with fragments', () {
      const fragments = [
        TextFragment(text: 'Hello', bounds: Rect.fromLTWH(0, 0, 50, 20)),
        TextFragment(text: ' world', bounds: Rect.fromLTWH(50, 0, 60, 20)),
      ];
      const line = TextLine(
        text: 'Hello world',
        bounds: Rect.fromLTWH(0, 0, 110, 20),
        fragments: fragments,
      );

      expect(line.fragments, hasLength(2));
      expect(line.fragments[0].text, 'Hello');
      expect(line.fragments[1].text, ' world');
    });

    group('equality', () {
      test('equal lines are equal', () {
        const line1 = TextLine(
          text: 'Test',
          bounds: Rect.fromLTWH(0, 0, 100, 20),
        );
        const line2 = TextLine(
          text: 'Test',
          bounds: Rect.fromLTWH(0, 0, 100, 20),
        );

        expect(line1, equals(line2));
        expect(line1.hashCode, equals(line2.hashCode));
      });

      test('different lines are not equal', () {
        const line1 = TextLine(
          text: 'Test1',
          bounds: Rect.fromLTWH(0, 0, 100, 20),
        );
        const line2 = TextLine(
          text: 'Test2',
          bounds: Rect.fromLTWH(0, 0, 100, 20),
        );

        expect(line1, isNot(equals(line2)));
      });
    });
  });

  group('TextFragment', () {
    test('creates fragment with required fields', () {
      const fragment = TextFragment(
        text: 'Hello',
        bounds: Rect.fromLTWH(0, 0, 50, 20),
      );

      expect(fragment.text, 'Hello');
      expect(fragment.bounds, const Rect.fromLTWH(0, 0, 50, 20));
      expect(fragment.fontSize, isNull);
    });

    test('creates fragment with fontSize', () {
      const fragment = TextFragment(
        text: 'Hello',
        bounds: Rect.fromLTWH(0, 0, 50, 20),
        fontSize: 12.0,
      );

      expect(fragment.fontSize, 12.0);
    });

    group('equality', () {
      test('equal fragments are equal', () {
        const frag1 = TextFragment(
          text: 'Test',
          bounds: Rect.fromLTWH(0, 0, 50, 20),
          fontSize: 12.0,
        );
        const frag2 = TextFragment(
          text: 'Test',
          bounds: Rect.fromLTWH(0, 0, 50, 20),
          fontSize: 12.0,
        );

        expect(frag1, equals(frag2));
        expect(frag1.hashCode, equals(frag2.hashCode));
      });

      test('different fragments are not equal', () {
        const frag1 = TextFragment(
          text: 'Test',
          bounds: Rect.fromLTWH(0, 0, 50, 20),
          fontSize: 12.0,
        );
        const frag2 = TextFragment(
          text: 'Test',
          bounds: Rect.fromLTWH(0, 0, 50, 20),
          fontSize: 14.0,
        );

        expect(frag1, isNot(equals(frag2)));
      });
    });
  });
}
