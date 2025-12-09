/// Database table schema for feed items (RSS/Atom article entries)
class FeedItemsTable {
  FeedItemsTable._();

  static const String tableName = 'feed_items';

  // Column names
  static const String columnId = 'id';
  static const String columnFeedId = 'feed_id';
  static const String columnTitle = 'title';
  static const String columnContent = 'content';
  static const String columnDescription = 'description';
  static const String columnLink = 'link';
  static const String columnAuthor = 'author';
  static const String columnPubDate = 'pub_date';
  static const String columnThumbnailUrl = 'thumbnail_url';
  static const String columnIsRead = 'is_read';
  static const String columnIsStarred = 'is_starred';
  static const String columnFetchedAt = 'fetched_at';

  /// SQL query to create the feed_items table
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnFeedId TEXT NOT NULL,
        $columnTitle TEXT NOT NULL,
        $columnContent TEXT,
        $columnDescription TEXT,
        $columnLink TEXT,
        $columnAuthor TEXT,
        $columnPubDate INTEGER,
        $columnThumbnailUrl TEXT,
        $columnIsRead INTEGER DEFAULT 0,
        $columnIsStarred INTEGER DEFAULT 0,
        $columnFetchedAt INTEGER NOT NULL,
        FOREIGN KEY ($columnFeedId) REFERENCES catalogs(id) ON DELETE CASCADE
      )
    ''';
  }

  /// SQL queries to create indices for the feed_items table
  static List<String> createIndices() {
    return [
      'CREATE INDEX idx_feed_items_feed_id ON $tableName($columnFeedId)',
      'CREATE INDEX idx_feed_items_pub_date ON $tableName($columnPubDate DESC)',
      'CREATE INDEX idx_feed_items_is_read ON $tableName($columnIsRead)',
    ];
  }

  /// Migration query to add this table (for database version upgrades)
  static String migrationQuery() {
    return createTableQuery();
  }

  /// Get all migration queries including indices
  static List<String> allMigrationQueries() {
    return [createTableQuery(), ...createIndices()];
  }
}
