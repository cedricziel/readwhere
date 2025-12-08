import 'package:readwhere_cbz/src/utils/natural_sort.dart';
import 'package:test/test.dart';

void main() {
  group('naturalCompare', () {
    test('compares simple strings lexicographically', () {
      expect(naturalCompare('a', 'b'), lessThan(0));
      expect(naturalCompare('b', 'a'), greaterThan(0));
      expect(naturalCompare('a', 'a'), equals(0));
    });

    test('compares numbers numerically', () {
      expect(naturalCompare('1', '2'), lessThan(0));
      expect(naturalCompare('2', '10'), lessThan(0));
      expect(naturalCompare('10', '2'), greaterThan(0));
      expect(naturalCompare('10', '10'), equals(0));
    });

    test('handles mixed alphanumeric strings', () {
      expect(naturalCompare('page1', 'page2'), lessThan(0));
      expect(naturalCompare('page2', 'page10'), lessThan(0));
      expect(naturalCompare('page10', 'page2'), greaterThan(0));
      expect(naturalCompare('page10', 'page10'), equals(0));
    });

    test('handles strings with multiple number sequences', () {
      expect(naturalCompare('file1page1', 'file1page2'), lessThan(0));
      expect(naturalCompare('file1page10', 'file1page2'), greaterThan(0));
      expect(naturalCompare('file2page1', 'file1page10'), greaterThan(0));
    });

    test('handles leading zeros', () {
      expect(naturalCompare('001', '002'), lessThan(0));
      expect(naturalCompare('002', '010'), lessThan(0));
      expect(naturalCompare('010', '002'), greaterThan(0));
    });

    test('shorter strings come first when prefix matches', () {
      expect(naturalCompare('page', 'page1'), lessThan(0));
      expect(naturalCompare('page1', 'page'), greaterThan(0));
    });

    test('is case-insensitive for non-numeric parts', () {
      expect(naturalCompare('Page1', 'page2'), lessThan(0));
      expect(naturalCompare('PAGE10', 'page2'), greaterThan(0));
    });

    test('handles empty strings', () {
      expect(naturalCompare('', ''), equals(0));
      expect(naturalCompare('', 'a'), lessThan(0));
      expect(naturalCompare('a', ''), greaterThan(0));
    });

    test('handles file extensions correctly', () {
      expect(naturalCompare('page1.jpg', 'page2.jpg'), lessThan(0));
      expect(naturalCompare('page2.jpg', 'page10.jpg'), lessThan(0));
      expect(naturalCompare('page10.jpg', 'page2.jpg'), greaterThan(0));
    });
  });

  group('naturalSort', () {
    test('sorts simple numbers', () {
      final list = ['10', '1', '2', '20', '3'];
      naturalSort(list);
      expect(list, equals(['1', '2', '3', '10', '20']));
    });

    test('sorts comic book page names', () {
      final list = [
        'page10.jpg',
        'page1.jpg',
        'page2.jpg',
        'page20.jpg',
        'page3.jpg',
      ];
      naturalSort(list);
      expect(
          list,
          equals([
            'page1.jpg',
            'page2.jpg',
            'page3.jpg',
            'page10.jpg',
            'page20.jpg',
          ]));
    });

    test('sorts zero-padded numbers', () {
      final list = ['100.jpg', '001.jpg', '010.jpg', '002.jpg'];
      naturalSort(list);
      expect(list, equals(['001.jpg', '002.jpg', '010.jpg', '100.jpg']));
    });

    test('sorts mixed naming conventions', () {
      final list = [
        'cover.jpg',
        '001.jpg',
        '002.jpg',
        'back.jpg',
        '010.jpg',
      ];
      naturalSort(list);
      // Numbers come before letters in natural sort
      expect(
          list,
          equals([
            '001.jpg',
            '002.jpg',
            '010.jpg',
            'back.jpg',
            'cover.jpg',
          ]));
    });

    test('handles realistic CBZ page names', () {
      final list = [
        'Batman_001_page_010.jpg',
        'Batman_001_page_001.jpg',
        'Batman_001_page_002.jpg',
        'Batman_001_cover.jpg',
      ];
      naturalSort(list);
      expect(
          list,
          equals([
            'Batman_001_cover.jpg',
            'Batman_001_page_001.jpg',
            'Batman_001_page_002.jpg',
            'Batman_001_page_010.jpg',
          ]));
    });
  });

  group('naturalSorted', () {
    test('returns a new sorted list without modifying original', () {
      final original = ['page10', 'page1', 'page2'];
      final sorted = naturalSorted(original);

      expect(sorted, equals(['page1', 'page2', 'page10']));
      expect(original, equals(['page10', 'page1', 'page2']));
    });

    test('works with iterables', () {
      final set = {'page10', 'page1', 'page2'};
      final sorted = naturalSorted(set);

      expect(sorted, equals(['page1', 'page2', 'page10']));
    });
  });

  group('NaturalSortExtension', () {
    test('toNaturalSortedList returns sorted list', () {
      final list = ['page10', 'page1', 'page2'];
      final sorted = list.toNaturalSortedList();

      expect(sorted, equals(['page1', 'page2', 'page10']));
      // Original should be unchanged
      expect(list, equals(['page10', 'page1', 'page2']));
    });
  });

  group('NaturalSortListExtension', () {
    test('sortNatural sorts in place', () {
      final list = ['page10', 'page1', 'page2'];
      list.sortNatural();

      expect(list, equals(['page1', 'page2', 'page10']));
    });
  });

  group('edge cases', () {
    test('handles very large numbers', () {
      final list = ['999999999999', '1', '100'];
      naturalSort(list);
      expect(list, equals(['1', '100', '999999999999']));
    });

    test('handles unicode characters', () {
      // Japanese manga naming
      final list = ['漫画10', '漫画1', '漫画2'];
      naturalSort(list);
      expect(list, equals(['漫画1', '漫画2', '漫画10']));
    });

    test('handles paths with directories', () {
      final list = [
        'chapter1/page10.jpg',
        'chapter1/page1.jpg',
        'chapter1/page2.jpg',
      ];
      naturalSort(list);
      expect(
          list,
          equals([
            'chapter1/page1.jpg',
            'chapter1/page2.jpg',
            'chapter1/page10.jpg',
          ]));
    });
  });
}
