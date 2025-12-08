/// Catalogs table schema for storing OPDS catalog sources
class CatalogsTable {
  static const String tableName = 'catalogs';

  // Column names
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnUrl = 'url';
  static const String columnIconUrl = 'icon_url';
  static const String columnAddedAt = 'added_at';
  static const String columnLastAccessedAt = 'last_accessed_at';
  static const String columnApiKey = 'api_key';
  static const String columnType = 'type';
  static const String columnServerVersion = 'server_version';

  /// Map of column names for easy reference
  static const Map<String, String> columns = {
    'id': columnId,
    'name': columnName,
    'url': columnUrl,
    'iconUrl': columnIconUrl,
    'addedAt': columnAddedAt,
    'lastAccessedAt': columnLastAccessedAt,
    'apiKey': columnApiKey,
    'type': columnType,
    'serverVersion': columnServerVersion,
  };

  /// Returns the SQL query to create the catalogs table
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnUrl TEXT NOT NULL,
        $columnIconUrl TEXT,
        $columnAddedAt INTEGER NOT NULL,
        $columnLastAccessedAt INTEGER,
        $columnApiKey TEXT,
        $columnType TEXT NOT NULL DEFAULT 'opds',
        $columnServerVersion TEXT,
        UNIQUE($columnUrl)
      )
    ''';
  }

  /// Returns indices to improve query performance
  static List<String> createIndices() {
    return [
      'CREATE INDEX idx_catalogs_added_at ON $tableName($columnAddedAt)',
      'CREATE INDEX idx_catalogs_last_accessed_at ON $tableName($columnLastAccessedAt)',
    ];
  }

  /// Returns SQL statements for migrating from v2 to v3
  static List<String> migrateFromV2() {
    return [
      'ALTER TABLE $tableName ADD COLUMN $columnApiKey TEXT',
      "ALTER TABLE $tableName ADD COLUMN $columnType TEXT NOT NULL DEFAULT 'opds'",
      'ALTER TABLE $tableName ADD COLUMN $columnServerVersion TEXT',
    ];
  }
}
