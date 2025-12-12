/// Cached OPDS links table schema for offline catalog browsing
class CachedOpdsLinksTable {
  static const String tableName = 'cached_opds_links';

  // Column names
  static const String columnId = 'id';
  static const String columnFeedId = 'feed_id';
  static const String columnEntryId = 'entry_id';
  static const String columnEntryFeedId = 'entry_feed_id';
  static const String columnHref = 'href';
  static const String columnRel = 'rel';
  static const String columnType = 'type';
  static const String columnTitle = 'title';
  static const String columnLength = 'length';
  static const String columnPrice = 'price';
  static const String columnCurrency = 'currency';
  static const String columnLinkOrder = 'link_order';

  /// Map of column names for easy reference
  static const Map<String, String> columns = {
    'id': columnId,
    'feedId': columnFeedId,
    'entryId': columnEntryId,
    'entryFeedId': columnEntryFeedId,
    'href': columnHref,
    'rel': columnRel,
    'type': columnType,
    'title': columnTitle,
    'length': columnLength,
    'price': columnPrice,
    'currency': columnCurrency,
    'linkOrder': columnLinkOrder,
  };

  /// Returns the SQL query to create the cached_opds_links table
  /// Links can belong to either a feed (feed-level links) or an entry.
  /// Entry links use the composite FK (entry_feed_id, entry_id) since
  /// cached_opds_entries uses a composite primary key.
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnFeedId TEXT,
        $columnEntryId TEXT,
        $columnEntryFeedId TEXT,
        $columnHref TEXT NOT NULL,
        $columnRel TEXT NOT NULL,
        $columnType TEXT NOT NULL,
        $columnTitle TEXT,
        $columnLength INTEGER,
        $columnPrice TEXT,
        $columnCurrency TEXT,
        $columnLinkOrder INTEGER NOT NULL,
        FOREIGN KEY ($columnFeedId) REFERENCES cached_opds_feeds(id) ON DELETE CASCADE,
        FOREIGN KEY ($columnEntryFeedId, $columnEntryId) REFERENCES cached_opds_entries(feed_id, id) ON DELETE CASCADE
      )
    ''';
  }

  /// Returns indices to improve query performance
  static List<String> createIndices() {
    return [
      'CREATE INDEX idx_cached_links_feed_id ON $tableName($columnFeedId)',
      'CREATE INDEX idx_cached_links_entry ON $tableName($columnEntryFeedId, $columnEntryId)',
    ];
  }

  /// Migration for V10: Recreate table with composite FK for entries
  static List<String> migrationV10() {
    return [
      'DROP TABLE IF EXISTS $tableName',
      createTableQuery(),
      ...createIndices(),
    ];
  }
}
