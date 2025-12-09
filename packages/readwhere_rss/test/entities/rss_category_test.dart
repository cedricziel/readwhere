import 'package:readwhere_rss/readwhere_rss.dart';
import 'package:test/test.dart';

void main() {
  group('RssCategory', () {
    test('creates category with label only', () {
      const category = RssCategory(label: 'Fiction');

      expect(category.label, equals('Fiction'));
      expect(category.domain, isNull);
    });

    test('creates category with all fields', () {
      const category = RssCategory(
        label: 'Fiction',
        domain: 'https://example.com/categories',
      );

      expect(category.label, equals('Fiction'));
      expect(category.domain, equals('https://example.com/categories'));
    });

    test('equality works correctly', () {
      const cat1 = RssCategory(label: 'Fiction');
      const cat2 = RssCategory(label: 'Fiction');
      const cat3 = RssCategory(label: 'Non-Fiction');

      expect(cat1, equals(cat2));
      expect(cat1, isNot(equals(cat3)));
    });

    test('equality includes domain', () {
      const cat1 = RssCategory(
        label: 'Fiction',
        domain: 'https://example.com/categories',
      );
      const cat2 = RssCategory(
        label: 'Fiction',
        domain: 'https://other.com/categories',
      );

      expect(cat1, isNot(equals(cat2)));
    });

    test('toString includes label and domain', () {
      const category = RssCategory(
        label: 'Fiction',
        domain: 'https://example.com/categories',
      );

      expect(category.toString(), contains('Fiction'));
      expect(category.toString(), contains('https://example.com/categories'));
    });
  });
}
