import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/database/database_helper.dart';

/// Implementation of [PluginStorage] using platform services.
///
/// Uses:
/// - [SharedPreferences] for settings (non-sensitive key-value storage)
/// - [FlutterSecureStorage] for credentials (encrypted storage)
/// - SQLite via [DatabaseHelper] for cache with TTL support
///
/// All keys are prefixed with the plugin ID to ensure isolation between plugins.
class PluginStorageImpl implements PluginStorage {
  @override
  final String pluginId;

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  final DatabaseHelper _dbHelper;

  /// Creates a plugin storage implementation.
  PluginStorageImpl({
    required this.pluginId,
    required SharedPreferences prefs,
    required FlutterSecureStorage secureStorage,
    required DatabaseHelper dbHelper,
  }) : _prefs = prefs,
       _secureStorage = secureStorage,
       _dbHelper = dbHelper;

  // ===== Key Generation =====

  /// Generates a settings key with plugin prefix.
  String _settingsKey(String key) => 'plugin:$pluginId:setting:$key';

  /// Generates a credential key with plugin and optional catalog prefix.
  String _credentialKey(String? catalogId, String key) => catalogId != null
      ? 'plugin:$pluginId:cred:$catalogId:$key'
      : 'plugin:$pluginId:cred:$key';

  /// Prefix for scanning all credentials of this plugin.
  String get _credentialPrefix => 'plugin:$pluginId:cred:';

  /// Prefix for scanning credentials of a specific catalog.
  String _catalogCredentialPrefix(String catalogId) =>
      'plugin:$pluginId:cred:$catalogId:';

  // ===== Settings Storage =====

  @override
  Future<T?> getSetting<T>(String key) async {
    final prefKey = _settingsKey(key);

    if (T == String) {
      return _prefs.getString(prefKey) as T?;
    } else if (T == int) {
      return _prefs.getInt(prefKey) as T?;
    } else if (T == double) {
      return _prefs.getDouble(prefKey) as T?;
    } else if (T == bool) {
      return _prefs.getBool(prefKey) as T?;
    } else if (T == List<String>) {
      return _prefs.getStringList(prefKey) as T?;
    }

    // For unsupported types, return null
    return null;
  }

  @override
  Future<void> setSetting<T>(String key, T value) async {
    final prefKey = _settingsKey(key);

    if (value is String) {
      await _prefs.setString(prefKey, value);
    } else if (value is int) {
      await _prefs.setInt(prefKey, value);
    } else if (value is double) {
      await _prefs.setDouble(prefKey, value);
    } else if (value is bool) {
      await _prefs.setBool(prefKey, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(prefKey, value);
    } else {
      throw ArgumentError('Unsupported setting type: ${value.runtimeType}');
    }
  }

  @override
  Future<void> removeSetting(String key) async {
    await _prefs.remove(_settingsKey(key));
  }

  @override
  Future<Map<String, dynamic>> getAllSettings() async {
    final prefix = 'plugin:$pluginId:setting:';
    final allKeys = _prefs.getKeys().where((k) => k.startsWith(prefix));

    final settings = <String, dynamic>{};
    for (final fullKey in allKeys) {
      final key = fullKey.substring(prefix.length);
      settings[key] = _prefs.get(fullKey);
    }

    return settings;
  }

  @override
  Future<void> clearSettings() async {
    final prefix = 'plugin:$pluginId:setting:';
    final keysToRemove = _prefs.getKeys().where((k) => k.startsWith(prefix));

    for (final key in keysToRemove.toList()) {
      await _prefs.remove(key);
    }
  }

  // ===== Credential Storage =====

  @override
  Future<void> saveCredential({
    String? catalogId,
    required String key,
    required String value,
  }) async {
    await _secureStorage.write(
      key: _credentialKey(catalogId, key),
      value: value,
    );
  }

  @override
  Future<String?> getCredential({
    String? catalogId,
    required String key,
  }) async {
    return await _secureStorage.read(key: _credentialKey(catalogId, key));
  }

  @override
  Future<void> deleteCredential({
    String? catalogId,
    required String key,
  }) async {
    await _secureStorage.delete(key: _credentialKey(catalogId, key));
  }

  @override
  Future<void> deleteCredentialsForCatalog(String catalogId) async {
    final prefix = _catalogCredentialPrefix(catalogId);
    final allCredentials = await _secureStorage.readAll();

    for (final key in allCredentials.keys) {
      if (key.startsWith(prefix)) {
        await _secureStorage.delete(key: key);
      }
    }
  }

  @override
  Future<bool> hasCredentials(String catalogId) async {
    final prefix = _catalogCredentialPrefix(catalogId);
    final allCredentials = await _secureStorage.readAll();

    return allCredentials.keys.any((k) => k.startsWith(prefix));
  }

  @override
  Future<void> deleteAllCredentials() async {
    final allCredentials = await _secureStorage.readAll();

    for (final key in allCredentials.keys) {
      if (key.startsWith(_credentialPrefix)) {
        await _secureStorage.delete(key: key);
      }
    }
  }

  // ===== Cache Storage =====

  @override
  Future<void> cacheData({
    required String key,
    required dynamic data,
    Duration? ttl,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = ttl != null ? now + ttl.inMilliseconds : null;

    final jsonData = jsonEncode(data);

    await db.insert('plugin_cache', {
      'plugin_id': pluginId,
      'cache_key': key,
      'data': jsonData,
      'created_at': now,
      'expires_at': expiresAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<T?> getCachedData<T>(String key) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final results = await db.query(
      'plugin_cache',
      where:
          'plugin_id = ? AND cache_key = ? AND (expires_at IS NULL OR expires_at > ?)',
      whereArgs: [pluginId, key, now],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    final jsonData = results.first['data'] as String;
    return jsonDecode(jsonData) as T?;
  }

  @override
  Future<bool> hasCachedData(String key) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final results = await db.query(
      'plugin_cache',
      columns: ['id'],
      where:
          'plugin_id = ? AND cache_key = ? AND (expires_at IS NULL OR expires_at > ?)',
      whereArgs: [pluginId, key, now],
      limit: 1,
    );

    return results.isNotEmpty;
  }

  @override
  Future<void> invalidateCache(String key) async {
    final db = await _dbHelper.database;

    await db.delete(
      'plugin_cache',
      where: 'plugin_id = ? AND cache_key = ?',
      whereArgs: [pluginId, key],
    );
  }

  @override
  Future<void> invalidateCachePattern(String pattern) async {
    final db = await _dbHelper.database;

    // Convert glob pattern to SQL LIKE pattern
    // * -> % (match any characters)
    // ? -> _ (match single character)
    final likePattern = pattern.replaceAll('*', '%').replaceAll('?', '_');

    await db.delete(
      'plugin_cache',
      where: 'plugin_id = ? AND cache_key LIKE ?',
      whereArgs: [pluginId, likePattern],
    );
  }

  @override
  Future<void> clearCache() async {
    final db = await _dbHelper.database;

    await db.delete(
      'plugin_cache',
      where: 'plugin_id = ?',
      whereArgs: [pluginId],
    );
  }

  @override
  Future<CacheStats> getCacheStats() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Get total count and size
    final countResult = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as count,
        COALESCE(SUM(LENGTH(data)), 0) as total_size,
        MIN(created_at) as oldest,
        MAX(created_at) as newest
      FROM plugin_cache
      WHERE plugin_id = ?
      ''',
      [pluginId],
    );

    // Get expired count
    final expiredResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as expired_count
      FROM plugin_cache
      WHERE plugin_id = ? AND expires_at IS NOT NULL AND expires_at <= ?
      ''',
      [pluginId, now],
    );

    final row = countResult.first;
    final entryCount = (row['count'] as int?) ?? 0;
    final totalSize = (row['total_size'] as int?) ?? 0;
    final oldestTs = row['oldest'] as int?;
    final newestTs = row['newest'] as int?;
    final expiredCount = (expiredResult.first['expired_count'] as int?) ?? 0;

    return CacheStats(
      entryCount: entryCount,
      totalSizeBytes: totalSize,
      oldestEntry: oldestTs != null
          ? DateTime.fromMillisecondsSinceEpoch(oldestTs)
          : null,
      newestEntry: newestTs != null
          ? DateTime.fromMillisecondsSinceEpoch(newestTs)
          : null,
      expiredCount: expiredCount,
    );
  }

  /// Cleans up expired cache entries.
  ///
  /// Call this periodically to remove stale cache entries and free up space.
  Future<int> cleanupExpiredCache() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    return await db.delete(
      'plugin_cache',
      where: 'plugin_id = ? AND expires_at IS NOT NULL AND expires_at <= ?',
      whereArgs: [pluginId, now],
    );
  }
}

/// Factory for creating [PluginStorageImpl] instances.
///
/// Wraps the required dependencies and creates storage instances
/// scoped to individual plugins.
class PluginStorageFactoryImpl implements PluginStorageFactory {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  final DatabaseHelper _dbHelper;

  /// Creates a plugin storage factory.
  PluginStorageFactoryImpl({
    required SharedPreferences prefs,
    required FlutterSecureStorage secureStorage,
    required DatabaseHelper dbHelper,
  }) : _prefs = prefs,
       _secureStorage = secureStorage,
       _dbHelper = dbHelper;

  @override
  Future<PluginStorage> create(String pluginId) async {
    return PluginStorageImpl(
      pluginId: pluginId,
      prefs: _prefs,
      secureStorage: _secureStorage,
      dbHelper: _dbHelper,
    );
  }
}
