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

  // Nextcloud-specific columns
  static const String columnUsername = 'username';
  static const String columnBooksFolder = 'books_folder';
  static const String columnUserId = 'user_id';

  // Nextcloud News sync columns
  static const String columnNewsSyncEnabled = 'news_sync_enabled';
  static const String columnNewsAppAvailable = 'news_app_available';

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
    'username': columnUsername,
    'booksFolder': columnBooksFolder,
    'userId': columnUserId,
    'newsSyncEnabled': columnNewsSyncEnabled,
    'newsAppAvailable': columnNewsAppAvailable,
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
        $columnUsername TEXT,
        $columnBooksFolder TEXT DEFAULT '/Books',
        $columnUserId TEXT,
        $columnNewsSyncEnabled INTEGER DEFAULT 0,
        $columnNewsAppAvailable INTEGER,
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

  /// Returns SQL statements for migrating from v3 to v4 (Nextcloud support)
  static List<String> migrateFromV3() {
    return [
      'ALTER TABLE $tableName ADD COLUMN $columnUsername TEXT',
      "ALTER TABLE $tableName ADD COLUMN $columnBooksFolder TEXT DEFAULT '/Books'",
      'ALTER TABLE $tableName ADD COLUMN $columnUserId TEXT',
    ];
  }

  /// Returns SQL statements for migrating to v13 (Nextcloud News sync)
  static List<String> migrateToV13() {
    return [
      'ALTER TABLE $tableName ADD COLUMN $columnNewsSyncEnabled INTEGER DEFAULT 0',
      'ALTER TABLE $tableName ADD COLUMN $columnNewsAppAvailable INTEGER',
    ];
  }
}
