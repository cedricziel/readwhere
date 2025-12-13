import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_pdf/readwhere_pdf.dart';

void main() {
  group('PdfOutlineEntry', () {
    test('creates entry with required fields', () {
      const entry = PdfOutlineEntry(title: 'Chapter 1');

      expect(entry.title, 'Chapter 1');
      expect(entry.pageIndex, isNull);
      expect(entry.children, isEmpty);
      expect(entry.depth, 0);
    });

    test('creates entry with all fields', () {
      const children = [
        PdfOutlineEntry(title: 'Section 1.1', pageIndex: 5, depth: 1),
        PdfOutlineEntry(title: 'Section 1.2', pageIndex: 10, depth: 1),
      ];
      const entry = PdfOutlineEntry(
        title: 'Chapter 1',
        pageIndex: 0,
        children: children,
        depth: 0,
      );

      expect(entry.title, 'Chapter 1');
      expect(entry.pageIndex, 0);
      expect(entry.children, hasLength(2));
      expect(entry.depth, 0);
    });

    group('hasChildren', () {
      test('returns false when children is empty', () {
        const entry = PdfOutlineEntry(title: 'Leaf');

        expect(entry.hasChildren, isFalse);
      });

      test('returns true when children is not empty', () {
        const entry = PdfOutlineEntry(
          title: 'Parent',
          children: [PdfOutlineEntry(title: 'Child')],
        );

        expect(entry.hasChildren, isTrue);
      });
    });

    group('copyWith', () {
      test('creates copy with modified title', () {
        const original = PdfOutlineEntry(
          title: 'Original',
          pageIndex: 5,
          depth: 1,
        );

        final copy = original.copyWith(title: 'Modified');

        expect(copy.title, 'Modified');
        expect(copy.pageIndex, 5);
        expect(copy.depth, 1);
      });

      test('creates copy with modified pageIndex', () {
        const original = PdfOutlineEntry(title: 'Chapter', pageIndex: 0);

        final copy = original.copyWith(pageIndex: 10);

        expect(copy.title, 'Chapter');
        expect(copy.pageIndex, 10);
      });

      test('creates copy with modified children', () {
        const original = PdfOutlineEntry(
          title: 'Parent',
          children: [PdfOutlineEntry(title: 'Child 1')],
        );

        final copy = original.copyWith(
          children: [
            const PdfOutlineEntry(title: 'Child 1'),
            const PdfOutlineEntry(title: 'Child 2'),
          ],
        );

        expect(copy.title, 'Parent');
        expect(copy.children, hasLength(2));
        expect(copy.children[1].title, 'Child 2');
      });

      test('creates copy with modified depth', () {
        const original = PdfOutlineEntry(title: 'Entry', depth: 0);

        final copy = original.copyWith(depth: 2);

        expect(copy.title, 'Entry');
        expect(copy.depth, 2);
      });

      test('creates copy without modifications', () {
        const original = PdfOutlineEntry(
          title: 'Entry',
          pageIndex: 5,
          depth: 1,
        );

        final copy = original.copyWith();

        expect(copy.title, 'Entry');
        expect(copy.pageIndex, 5);
        expect(copy.depth, 1);
        expect(copy, equals(original));
      });
    });

    group('nested structure', () {
      test('supports deeply nested hierarchy', () {
        const entry = PdfOutlineEntry(
          title: 'Part 1',
          pageIndex: 0,
          depth: 0,
          children: [
            PdfOutlineEntry(
              title: 'Chapter 1',
              pageIndex: 1,
              depth: 1,
              children: [
                PdfOutlineEntry(
                  title: 'Section 1.1',
                  pageIndex: 2,
                  depth: 2,
                  children: [
                    PdfOutlineEntry(
                      title: 'Subsection 1.1.1',
                      pageIndex: 3,
                      depth: 3,
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        expect(entry.depth, 0);
        expect(entry.children[0].depth, 1);
        expect(entry.children[0].children[0].depth, 2);
        expect(entry.children[0].children[0].children[0].depth, 3);

        expect(
          entry.children[0].children[0].children[0].title,
          'Subsection 1.1.1',
        );
      });
    });

    group('equality', () {
      test('equal entries are equal', () {
        const entry1 = PdfOutlineEntry(
          title: 'Chapter 1',
          pageIndex: 0,
          depth: 0,
          children: [PdfOutlineEntry(title: 'Section 1', depth: 1)],
        );
        const entry2 = PdfOutlineEntry(
          title: 'Chapter 1',
          pageIndex: 0,
          depth: 0,
          children: [PdfOutlineEntry(title: 'Section 1', depth: 1)],
        );

        expect(entry1, equals(entry2));
        expect(entry1.hashCode, equals(entry2.hashCode));
      });

      test('entries with different titles are not equal', () {
        const entry1 = PdfOutlineEntry(title: 'Chapter 1');
        const entry2 = PdfOutlineEntry(title: 'Chapter 2');

        expect(entry1, isNot(equals(entry2)));
      });

      test('entries with different pageIndex are not equal', () {
        const entry1 = PdfOutlineEntry(title: 'Chapter', pageIndex: 0);
        const entry2 = PdfOutlineEntry(title: 'Chapter', pageIndex: 1);

        expect(entry1, isNot(equals(entry2)));
      });

      test('entries with different children are not equal', () {
        const entry1 = PdfOutlineEntry(
          title: 'Chapter',
          children: [PdfOutlineEntry(title: 'Section 1')],
        );
        const entry2 = PdfOutlineEntry(
          title: 'Chapter',
          children: [PdfOutlineEntry(title: 'Section 2')],
        );

        expect(entry1, isNot(equals(entry2)));
      });

      test('entries with different depth are not equal', () {
        const entry1 = PdfOutlineEntry(title: 'Entry', depth: 0);
        const entry2 = PdfOutlineEntry(title: 'Entry', depth: 1);

        expect(entry1, isNot(equals(entry2)));
      });
    });

    test('toString returns meaningful representation', () {
      const entry = PdfOutlineEntry(
        title: 'Chapter 1',
        pageIndex: 5,
        children: [
          PdfOutlineEntry(title: 'Section 1'),
          PdfOutlineEntry(title: 'Section 2'),
        ],
        depth: 0,
      );

      final str = entry.toString();
      expect(str, contains('PdfOutlineEntry'));
      expect(str, contains('title: Chapter 1'));
      expect(str, contains('pageIndex: 5'));
      expect(str, contains('children: 2'));
      expect(str, contains('depth: 0'));
    });
  });
}
