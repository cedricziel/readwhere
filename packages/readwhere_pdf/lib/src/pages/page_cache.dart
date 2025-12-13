import 'dart:typed_data';
import 'dart:collection';

/// A simple LRU cache for rendered page images.
class PageCache {
  final int _maxEntries;
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();

  /// Creates a new page cache with the specified maximum number of entries.
  PageCache({int maxEntries = 10}) : _maxEntries = maxEntries;

  /// The current number of entries in the cache.
  int get length => _cache.length;

  /// The maximum number of entries this cache can hold.
  int get maxEntries => _maxEntries;

  /// Whether the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Whether the cache is not empty.
  bool get isNotEmpty => _cache.isNotEmpty;

  /// Gets a cached image by key, or null if not found.
  ///
  /// Accessing an entry moves it to the end of the LRU list.
  Uint8List? get(String key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }

  /// Checks if a key exists in the cache.
  bool containsKey(String key) => _cache.containsKey(key);

  /// Stores an image in the cache.
  ///
  /// If the cache is full, the least recently used entry is removed.
  void put(String key, Uint8List value) {
    _cache.remove(key);
    _cache[key] = value;

    while (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Removes an entry from the cache.
  Uint8List? remove(String key) => _cache.remove(key);

  /// Clears all entries from the cache.
  void clear() => _cache.clear();

  /// Returns an estimate of the total memory usage of cached images in bytes.
  int get estimatedMemoryUsage =>
      _cache.values.fold(0, (sum, bytes) => sum + bytes.length);

  /// Creates a cache key for a page at a given scale.
  static String pageKey(int pageIndex, double scale) =>
      'page_${pageIndex}_scale_$scale';

  /// Creates a cache key for a page thumbnail.
  static String thumbnailKey(int pageIndex, int maxWidth) =>
      'thumb_${pageIndex}_w$maxWidth';
}
