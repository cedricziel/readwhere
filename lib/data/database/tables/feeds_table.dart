/// Feeds table schema for storing RSS feed sources
class FeedsTable {
  static const String tableName = 'feeds';

  // Column names
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnUrl = 'url';
  static const String columnIconUrl = 'icon_url';
  static const String columnAddedAt = 'added_at';
  static const String columnLastRefreshedAt = 'last_refreshed_at';

  /// Map of column names for easy reference
  static const Map<String, String> columns = {
    'id': columnId,
    'name': columnName,
    'url': columnUrl,
    'iconUrl': columnIconUrl,
    'addedAt': columnAddedAt,
    'lastRefreshedAt': columnLastRefreshedAt,
  };

  /// Returns the SQL query to create the feeds table
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnUrl TEXT NOT NULL,
        $columnIconUrl TEXT,
        $columnAddedAt INTEGER NOT NULL,
        $columnLastRefreshedAt INTEGER,
        UNIQUE($columnUrl)
      )
    ''';
  }

  /// Returns indices to improve query performance
  static List<String> createIndices() {
    return [
      'CREATE INDEX idx_feeds_added_at ON $tableName($columnAddedAt)',
      'CREATE INDEX idx_feeds_last_refreshed_at ON $tableName($columnLastRefreshedAt)',
    ];
  }
}
