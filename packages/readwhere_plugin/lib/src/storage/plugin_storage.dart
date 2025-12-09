/// Unified storage interface for plugins.
///
/// Provides access to settings, credentials, and cache storage
/// with the actual implementation handled by the system. All data
/// is automatically namespaced to the plugin's ID.
///
/// Storage is divided into three tiers:
/// - **Settings**: Non-sensitive configuration (e.g., preferences)
/// - **Credentials**: Sensitive data (e.g., tokens, passwords)
/// - **Cache**: Temporary data with optional TTL
///
/// Example usage:
/// ```dart
/// // Store a setting
/// await storage.setSetting('pageSize', 50);
///
/// // Store credentials for a catalog
/// await storage.saveCredential(
///   catalogId: 'my-server',
///   key: 'apiKey',
///   value: 'secret123',
/// );
///
/// // Cache some data
/// await storage.cacheData(
///   key: 'feed:root',
///   data: feedJson,
///   ttl: Duration(hours: 1),
/// );
/// ```
abstract class PluginStorage {
  /// The plugin ID this storage is scoped to.
  String get pluginId;

  // ===== Settings Storage =====
  // Uses SharedPreferences or similar non-secure storage.

  /// Get a setting value.
  ///
  /// Returns null if the setting doesn't exist.
  /// Supported types: `String`, `int`, `double`, `bool`, `List<String>`
  Future<T?> getSetting<T>(String key);

  /// Set a setting value.
  ///
  /// Supported types: `String`, `int`, `double`, `bool`, `List<String>`
  Future<void> setSetting<T>(String key, T value);

  /// Remove a setting.
  Future<void> removeSetting(String key);

  /// Get all settings for this plugin.
  ///
  /// Returns a map of all settings with their current values.
  Future<Map<String, dynamic>> getAllSettings();

  /// Clear all settings for this plugin.
  Future<void> clearSettings();

  // ===== Secure Credential Storage =====
  // Uses FlutterSecureStorage or platform keychain.

  /// Store a credential securely.
  ///
  /// [catalogId] Optional catalog ID to scope the credential.
  ///   Use this when storing credentials for a specific catalog/server.
  /// [key] The credential key (e.g., 'apiKey', 'accessToken').
  /// [value] The credential value.
  ///
  /// Example:
  /// ```dart
  /// // Plugin-level credential
  /// await storage.saveCredential(key: 'licenseKey', value: 'abc123');
  ///
  /// // Catalog-specific credential
  /// await storage.saveCredential(
  ///   catalogId: 'my-kavita-server',
  ///   key: 'apiKey',
  ///   value: 'xyz789',
  /// );
  /// ```
  Future<void> saveCredential({
    String? catalogId,
    required String key,
    required String value,
  });

  /// Retrieve a credential.
  ///
  /// Returns null if the credential doesn't exist.
  Future<String?> getCredential({String? catalogId, required String key});

  /// Delete a credential.
  Future<void> deleteCredential({String? catalogId, required String key});

  /// Delete all credentials for a catalog.
  ///
  /// Call this when a catalog is removed or the user logs out.
  Future<void> deleteCredentialsForCatalog(String catalogId);

  /// Check if credentials exist for a catalog.
  Future<bool> hasCredentials(String catalogId);

  /// Delete all credentials for this plugin.
  ///
  /// Use with caution - this removes all credentials for all catalogs
  /// managed by this plugin.
  Future<void> deleteAllCredentials();

  // ===== Cache Storage =====
  // Uses SQLite or file-based storage with TTL support.

  /// Cache data with an optional TTL.
  ///
  /// [key] Cache key (plugin-scoped).
  /// [data] Data to cache. Must be JSON-serializable.
  /// [ttl] Optional time-to-live. If not specified, data persists
  ///   until manually invalidated.
  ///
  /// Example:
  /// ```dart
  /// await storage.cacheData(
  ///   key: 'catalog:root:feed',
  ///   data: {'entries': [...], 'links': [...]},
  ///   ttl: Duration(hours: 1),
  /// );
  /// ```
  Future<void> cacheData({
    required String key,
    required dynamic data,
    Duration? ttl,
  });

  /// Retrieve cached data.
  ///
  /// Returns null if not found or expired.
  Future<T?> getCachedData<T>(String key);

  /// Check if cache entry exists and is valid (not expired).
  Future<bool> hasCachedData(String key);

  /// Invalidate a cache entry.
  Future<void> invalidateCache(String key);

  /// Invalidate cache entries matching a pattern.
  ///
  /// [pattern] Glob-like pattern (e.g., 'catalog:*' matches all
  /// keys starting with 'catalog:').
  Future<void> invalidateCachePattern(String pattern);

  /// Clear all cache for this plugin.
  Future<void> clearCache();

  /// Get cache statistics.
  Future<CacheStats> getCacheStats();
}

/// Cache statistics.
class CacheStats {
  /// Number of cached entries.
  final int entryCount;

  /// Total size of cached data in bytes.
  final int totalSizeBytes;

  /// Timestamp of the oldest cache entry.
  final DateTime? oldestEntry;

  /// Timestamp of the newest cache entry.
  final DateTime? newestEntry;

  /// Number of expired entries waiting to be cleaned up.
  final int expiredCount;

  /// Creates cache statistics.
  const CacheStats({
    required this.entryCount,
    required this.totalSizeBytes,
    this.oldestEntry,
    this.newestEntry,
    this.expiredCount = 0,
  });

  /// Whether the cache is empty.
  bool get isEmpty => entryCount == 0;

  /// Human-readable size string.
  String get formattedSize {
    if (totalSizeBytes < 1024) {
      return '$totalSizeBytes B';
    } else if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  String toString() =>
      'CacheStats('
      'entries: $entryCount, '
      'size: $formattedSize, '
      'expired: $expiredCount'
      ')';
}

/// Factory for creating plugin storage instances.
///
/// Implementations provide the actual storage creation logic,
/// which involves setting up database tables, secure storage
/// namespaces, and preferences.
abstract class PluginStorageFactory {
  /// Create storage for the given plugin.
  ///
  /// [pluginId] is used to namespace all stored data.
  Future<PluginStorage> create(String pluginId);
}

/// An in-memory implementation of [PluginStorage] for testing.
///
/// This implementation stores data in memory and is not persistent.
/// Do not use in production.
class InMemoryPluginStorage implements PluginStorage {
  @override
  final String pluginId;

  final Map<String, dynamic> _settings = {};
  final Map<String, String> _credentials = {};
  final Map<String, _CacheEntry> _cache = {};

  /// Creates an in-memory storage for testing.
  InMemoryPluginStorage(this.pluginId);

  // Settings

  @override
  Future<T?> getSetting<T>(String key) async => _settings[key] as T?;

  @override
  Future<void> setSetting<T>(String key, T value) async {
    _settings[key] = value;
  }

  @override
  Future<void> removeSetting(String key) async {
    _settings.remove(key);
  }

  @override
  Future<Map<String, dynamic>> getAllSettings() async =>
      Map.unmodifiable(_settings);

  @override
  Future<void> clearSettings() async {
    _settings.clear();
  }

  // Credentials

  String _credKey(String? catalogId, String key) =>
      catalogId != null ? '$catalogId:$key' : key;

  @override
  Future<void> saveCredential({
    String? catalogId,
    required String key,
    required String value,
  }) async {
    _credentials[_credKey(catalogId, key)] = value;
  }

  @override
  Future<String?> getCredential({
    String? catalogId,
    required String key,
  }) async {
    return _credentials[_credKey(catalogId, key)];
  }

  @override
  Future<void> deleteCredential({
    String? catalogId,
    required String key,
  }) async {
    _credentials.remove(_credKey(catalogId, key));
  }

  @override
  Future<void> deleteCredentialsForCatalog(String catalogId) async {
    _credentials.removeWhere((key, _) => key.startsWith('$catalogId:'));
  }

  @override
  Future<bool> hasCredentials(String catalogId) async {
    return _credentials.keys.any((key) => key.startsWith('$catalogId:'));
  }

  @override
  Future<void> deleteAllCredentials() async {
    _credentials.clear();
  }

  // Cache

  @override
  Future<void> cacheData({
    required String key,
    required dynamic data,
    Duration? ttl,
  }) async {
    final expiresAt = ttl != null ? DateTime.now().add(ttl) : null;
    _cache[key] = _CacheEntry(data: data, expiresAt: expiresAt);
  }

  @override
  Future<T?> getCachedData<T>(String key) async {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T?;
  }

  @override
  Future<bool> hasCachedData(String key) async {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  @override
  Future<void> invalidateCache(String key) async {
    _cache.remove(key);
  }

  @override
  Future<void> invalidateCachePattern(String pattern) async {
    final regex = RegExp('^${pattern.replaceAll('*', '.*')}\$');
    _cache.removeWhere((key, _) => regex.hasMatch(key));
  }

  @override
  Future<void> clearCache() async {
    _cache.clear();
  }

  @override
  Future<CacheStats> getCacheStats() async {
    var expired = 0;
    var totalSize = 0;
    DateTime? oldest;
    DateTime? newest;

    for (final entry in _cache.values) {
      if (entry.isExpired) {
        expired++;
      }
      totalSize += entry.data.toString().length;
      if (oldest == null || entry.createdAt.isBefore(oldest)) {
        oldest = entry.createdAt;
      }
      if (newest == null || entry.createdAt.isAfter(newest)) {
        newest = entry.createdAt;
      }
    }

    return CacheStats(
      entryCount: _cache.length,
      totalSizeBytes: totalSize,
      oldestEntry: oldest,
      newestEntry: newest,
      expiredCount: expired,
    );
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime createdAt;
  final DateTime? expiresAt;

  _CacheEntry({required this.data, this.expiresAt})
    : createdAt = DateTime.now();

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
