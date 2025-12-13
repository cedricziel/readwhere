import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_pdf/src/pages/page_cache.dart';

void main() {
  group('PageCache', () {
    late PageCache cache;

    setUp(() {
      cache = PageCache(maxEntries: 3);
    });

    test('stores and retrieves entries', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      cache.put('key1', bytes);

      expect(cache.get('key1'), equals(bytes));
    });

    test('returns null for missing key', () {
      expect(cache.get('nonexistent'), isNull);
    });

    test('reports correct length', () {
      expect(cache.length, 0);

      cache.put('key1', Uint8List.fromList([1]));
      expect(cache.length, 1);

      cache.put('key2', Uint8List.fromList([2]));
      expect(cache.length, 2);
    });

    test('reports isEmpty and isNotEmpty correctly', () {
      expect(cache.isEmpty, isTrue);
      expect(cache.isNotEmpty, isFalse);

      cache.put('key1', Uint8List.fromList([1]));

      expect(cache.isEmpty, isFalse);
      expect(cache.isNotEmpty, isTrue);
    });

    test('reports maxEntries', () {
      expect(cache.maxEntries, 3);
    });

    group('LRU eviction', () {
      test('evicts oldest entry when full', () {
        cache.put('key1', Uint8List.fromList([1]));
        cache.put('key2', Uint8List.fromList([2]));
        cache.put('key3', Uint8List.fromList([3]));

        // Cache is now full
        expect(cache.length, 3);

        // Add fourth entry, should evict key1
        cache.put('key4', Uint8List.fromList([4]));

        expect(cache.length, 3);
        expect(cache.get('key1'), isNull); // Evicted
        expect(cache.get('key2'), isNotNull);
        expect(cache.get('key3'), isNotNull);
        expect(cache.get('key4'), isNotNull);
      });

      test('get() moves entry to end of LRU list', () {
        cache.put('key1', Uint8List.fromList([1]));
        cache.put('key2', Uint8List.fromList([2]));
        cache.put('key3', Uint8List.fromList([3]));

        // Access key1, moving it to end
        cache.get('key1');

        // Add fourth entry, should evict key2 (now oldest)
        cache.put('key4', Uint8List.fromList([4]));

        expect(cache.get('key1'), isNotNull); // Not evicted
        expect(cache.get('key2'), isNull); // Evicted
        expect(cache.get('key3'), isNotNull);
        expect(cache.get('key4'), isNotNull);
      });

      test('put() with existing key updates and moves to end', () {
        cache.put('key1', Uint8List.fromList([1]));
        cache.put('key2', Uint8List.fromList([2]));
        cache.put('key3', Uint8List.fromList([3]));

        // Update key1
        cache.put('key1', Uint8List.fromList([100]));

        // Add fourth entry, should evict key2 (now oldest)
        cache.put('key4', Uint8List.fromList([4]));

        final result = cache.get('key1');
        expect(result, isNotNull);
        expect(result![0], 100); // Updated value
        expect(cache.get('key2'), isNull); // Evicted
      });
    });

    test('containsKey returns correct value', () {
      cache.put('key1', Uint8List.fromList([1]));

      expect(cache.containsKey('key1'), isTrue);
      expect(cache.containsKey('key2'), isFalse);
    });

    test('remove removes entry and returns it', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      cache.put('key1', bytes);

      final removed = cache.remove('key1');

      expect(removed, equals(bytes));
      expect(cache.containsKey('key1'), isFalse);
      expect(cache.length, 0);
    });

    test('remove returns null for missing key', () {
      expect(cache.remove('nonexistent'), isNull);
    });

    test('clear removes all entries', () {
      cache.put('key1', Uint8List.fromList([1]));
      cache.put('key2', Uint8List.fromList([2]));

      cache.clear();

      expect(cache.isEmpty, isTrue);
      expect(cache.length, 0);
    });

    test('estimatedMemoryUsage calculates total bytes', () {
      cache.put('key1', Uint8List.fromList([1, 2, 3])); // 3 bytes
      cache.put('key2', Uint8List.fromList([4, 5, 6, 7, 8])); // 5 bytes

      expect(cache.estimatedMemoryUsage, 8);
    });

    test('estimatedMemoryUsage is 0 for empty cache', () {
      expect(cache.estimatedMemoryUsage, 0);
    });
  });

  group('PageCache static methods', () {
    test('pageKey generates correct key', () {
      expect(PageCache.pageKey(0, 1.0), 'page_0_scale_1.0');
      expect(PageCache.pageKey(5, 2.0), 'page_5_scale_2.0');
      expect(PageCache.pageKey(10, 0.5), 'page_10_scale_0.5');
    });

    test('thumbnailKey generates correct key', () {
      expect(PageCache.thumbnailKey(0, 200), 'thumb_0_w200');
      expect(PageCache.thumbnailKey(5, 100), 'thumb_5_w100');
      expect(PageCache.thumbnailKey(10, 300), 'thumb_10_w300');
    });
  });

  group('PageCache default maxEntries', () {
    test('default maxEntries is 10', () {
      final defaultCache = PageCache();
      expect(defaultCache.maxEntries, 10);
    });
  });
}
