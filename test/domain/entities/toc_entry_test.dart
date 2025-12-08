import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/domain/entities/toc_entry.dart';

void main() {
  group('TocEntry', () {
    TocEntry createTestEntry({
      String id = 'toc-1',
      String title = 'Chapter 1',
      String href = 'chapter1.html',
      int level = 0,
      List<TocEntry> children = const [],
    }) {
      return TocEntry(
        id: id,
        title: title,
        href: href,
        level: level,
        children: children,
      );
    }

    group('constructor', () {
      test('creates entry with required fields', () {
        final entry = createTestEntry();

        expect(entry.id, equals('toc-1'));
        expect(entry.title, equals('Chapter 1'));
        expect(entry.href, equals('chapter1.html'));
        expect(entry.level, equals(0));
      });

      test('children default to empty list', () {
        final entry = createTestEntry();

        expect(entry.children, isEmpty);
      });

      test('creates entry with children', () {
        final child1 = createTestEntry(id: 'child-1', title: 'Section 1.1');
        final child2 = createTestEntry(id: 'child-2', title: 'Section 1.2');

        final entry = TocEntry(
          id: 'parent',
          title: 'Chapter 1',
          href: 'chapter1.html',
          level: 0,
          children: [child1, child2],
        );

        expect(entry.children.length, equals(2));
        expect(entry.children[0].title, equals('Section 1.1'));
        expect(entry.children[1].title, equals('Section 1.2'));
      });

      test('supports nested hierarchy', () {
        final grandChild = createTestEntry(
          id: 'grandchild',
          title: 'Section 1.1.1',
          level: 2,
        );
        final child = TocEntry(
          id: 'child',
          title: 'Section 1.1',
          href: 'section1.1.html',
          level: 1,
          children: [grandChild],
        );
        final entry = TocEntry(
          id: 'parent',
          title: 'Chapter 1',
          href: 'chapter1.html',
          level: 0,
          children: [child],
        );

        expect(entry.children[0].children[0].title, equals('Section 1.1.1'));
        expect(entry.children[0].children[0].level, equals(2));
      });
    });

    group('copyWith', () {
      test('creates new instance with changed fields', () {
        final entry = createTestEntry();

        final updated = entry.copyWith(title: 'New Title', level: 1);

        expect(updated.title, equals('New Title'));
        expect(updated.level, equals(1));
      });

      test('preserves unchanged fields', () {
        final entry = createTestEntry();

        final updated = entry.copyWith(title: 'New Title');

        expect(updated.id, equals(entry.id));
        expect(updated.href, equals(entry.href));
        expect(updated.level, equals(entry.level));
        expect(updated.children, equals(entry.children));
      });

      test('can update all fields', () {
        final entry = createTestEntry();
        final newChildren = [
          createTestEntry(id: 'new-child', title: 'New Section'),
        ];

        final updated = entry.copyWith(
          id: 'toc-2',
          title: 'Chapter 2',
          href: 'chapter2.html',
          level: 1,
          children: newChildren,
        );

        expect(updated.id, equals('toc-2'));
        expect(updated.title, equals('Chapter 2'));
        expect(updated.href, equals('chapter2.html'));
        expect(updated.level, equals(1));
        expect(updated.children, equals(newChildren));
      });
    });

    group('equality', () {
      test('equals same entry with identical properties', () {
        final entry1 = createTestEntry();
        final entry2 = createTestEntry();

        expect(entry1, equals(entry2));
      });

      test('not equals entry with different id', () {
        final entry1 = createTestEntry(id: 'toc-1');
        final entry2 = createTestEntry(id: 'toc-2');

        expect(entry1, isNot(equals(entry2)));
      });

      test('not equals entry with different href', () {
        final entry1 = createTestEntry(href: 'ch1.html');
        final entry2 = createTestEntry(href: 'ch2.html');

        expect(entry1, isNot(equals(entry2)));
      });

      test('equals entries with identical children', () {
        final children = [createTestEntry(id: 'child')];
        final entry1 = createTestEntry(children: children);
        final entry2 = createTestEntry(children: children);

        expect(entry1, equals(entry2));
      });

      test('not equals entries with different children', () {
        final entry1 = createTestEntry(
          children: [createTestEntry(id: 'child-1')],
        );
        final entry2 = createTestEntry(
          children: [createTestEntry(id: 'child-2')],
        );

        expect(entry1, isNot(equals(entry2)));
      });

      test('hashCode is equal for equal entries', () {
        final entry1 = createTestEntry();
        final entry2 = createTestEntry();

        expect(entry1.hashCode, equals(entry2.hashCode));
      });
    });

    group('toString', () {
      test('includes title and level', () {
        final entry = createTestEntry(title: 'Test Chapter', level: 1);
        final str = entry.toString();

        expect(str, contains('title: Test Chapter'));
        expect(str, contains('level: 1'));
      });

      test('shows children count when has children', () {
        final entry = createTestEntry(
          children: [
            createTestEntry(id: 'child-1'),
            createTestEntry(id: 'child-2'),
          ],
        );
        final str = entry.toString();

        expect(str, contains('children: 2'));
      });

      test('does not show children when empty', () {
        final entry = createTestEntry(children: const []);
        final str = entry.toString();

        expect(str, isNot(contains('children:')));
      });

      test('indents based on level', () {
        final level0 = createTestEntry(level: 0);
        final level1 = createTestEntry(level: 1);
        final level2 = createTestEntry(level: 2);

        final str0 = level0.toString();
        final str1 = level1.toString();
        final str2 = level2.toString();

        // Level 0 should have no leading spaces before TocEntry
        expect(str0.trim(), startsWith('TocEntry'));
        // Level 1 should have 2 spaces
        expect(str1, startsWith('  '));
        // Level 2 should have 4 spaces
        expect(str2, startsWith('    '));
      });
    });

    group('href handling', () {
      test('handles plain file reference', () {
        final entry = createTestEntry(href: 'chapter1.html');
        expect(entry.href, equals('chapter1.html'));
      });

      test('handles href with fragment identifier', () {
        final entry = createTestEntry(href: 'chapter1.html#section1');
        expect(entry.href, equals('chapter1.html#section1'));
      });

      test('handles path-based href', () {
        final entry = createTestEntry(href: 'OEBPS/text/chapter1.xhtml');
        expect(entry.href, equals('OEBPS/text/chapter1.xhtml'));
      });
    });
  });
}
