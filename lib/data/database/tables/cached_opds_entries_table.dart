/// Cached OPDS entries table schema for offline catalog browsing
class CachedOpdsEntriesTable {
  static const String tableName = 'cached_opds_entries';

  // Column names
  static const String columnId = 'id';
  static const String columnFeedId = 'feed_id';
  static const String columnTitle = 'title';
  static const String columnAuthor = 'author';
  static const String columnSummary = 'summary';
  static const String columnPublisher = 'publisher';
  static const String columnLanguage = 'language';
  static const String columnSeriesName = 'series_name';
  static const String columnSeriesPosition = 'series_position';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnPublishedAt = 'published_at';
  static const String columnCategories = 'categories';
  static const String columnEntryOrder = 'entry_order';

  /// Map of column names for easy reference
  static const Map<String, String> columns = {
    'id': columnId,
    'feedId': columnFeedId,
    'title': columnTitle,
    'author': columnAuthor,
    'summary': columnSummary,
    'publisher': columnPublisher,
    'language': columnLanguage,
    'seriesName': columnSeriesName,
    'seriesPosition': columnSeriesPosition,
    'updatedAt': columnUpdatedAt,
    'publishedAt': columnPublishedAt,
    'categories': columnCategories,
    'entryOrder': columnEntryOrder,
  };

  /// Returns the SQL query to create the cached_opds_entries table
  /// Uses composite primary key of (feed_id, id) since the same entry
  /// can appear in multiple feeds (e.g., "All Books" and a category feed).
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        $columnId TEXT NOT NULL,
        $columnFeedId TEXT NOT NULL,
        $columnTitle TEXT NOT NULL,
        $columnAuthor TEXT,
        $columnSummary TEXT,
        $columnPublisher TEXT,
        $columnLanguage TEXT,
        $columnSeriesName TEXT,
        $columnSeriesPosition INTEGER,
        $columnUpdatedAt INTEGER NOT NULL,
        $columnPublishedAt INTEGER,
        $columnCategories TEXT,
        $columnEntryOrder INTEGER NOT NULL,
        PRIMARY KEY ($columnFeedId, $columnId),
        FOREIGN KEY ($columnFeedId) REFERENCES cached_opds_feeds(id) ON DELETE CASCADE
      )
    ''';
  }

  /// Returns indices to improve query performance
  static List<String> createIndices() {
    return [
      'CREATE INDEX idx_cached_entries_feed_id ON $tableName($columnFeedId)',
      'CREATE INDEX idx_cached_entries_order ON $tableName($columnFeedId, $columnEntryOrder)',
    ];
  }

  /// Migration from V9 to V10: Change primary key from (id) to (feed_id, id)
  /// SQLite doesn't support ALTER TABLE to change primary key, so we need to:
  /// 1. Rename the old table
  /// 2. Create the new table with composite key
  /// 3. Copy data (but since we're changing the constraint, just drop old data)
  /// 4. Drop the old table
  static List<String> migrationV10() {
    return [
      // Drop the old table and its indices - cached data can be refreshed
      'DROP TABLE IF EXISTS $tableName',
      // Recreate with the new schema (composite primary key)
      createTableQuery(),
      // Recreate indices
      ...createIndices(),
    ];
  }
}
