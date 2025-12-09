/// Plugin cache table schema for plugin data with TTL support.
///
/// This table stores cached data for plugins with optional expiration.
/// Each plugin's data is isolated by the plugin_id column.
class PluginCacheTable {
  static const String tableName = 'plugin_cache';

  // Column names
  static const String columnId = 'id';
  static const String columnPluginId = 'plugin_id';
  static const String columnCacheKey = 'cache_key';
  static const String columnData = 'data';
  static const String columnCreatedAt = 'created_at';
  static const String columnExpiresAt = 'expires_at';

  /// Map of column names for easy reference
  static const Map<String, String> columns = {
    'id': columnId,
    'pluginId': columnPluginId,
    'cacheKey': columnCacheKey,
    'data': columnData,
    'createdAt': columnCreatedAt,
    'expiresAt': columnExpiresAt,
  };

  /// Returns the SQL query to create the plugin_cache table
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnPluginId TEXT NOT NULL,
        $columnCacheKey TEXT NOT NULL,
        $columnData TEXT NOT NULL,
        $columnCreatedAt INTEGER NOT NULL,
        $columnExpiresAt INTEGER,
        UNIQUE($columnPluginId, $columnCacheKey)
      )
    ''';
  }

  /// Returns indices to improve query performance
  static List<String> createIndices() {
    return [
      'CREATE INDEX idx_plugin_cache_lookup ON $tableName($columnPluginId, $columnCacheKey)',
      'CREATE INDEX idx_plugin_cache_expiry ON $tableName($columnExpiresAt)',
    ];
  }

  /// Returns migration queries for version 6
  static List<String> migrationV6() {
    return [createTableQuery(), ...createIndices()];
  }
}
