/// Cached OPDS feeds table schema for offline catalog browsing
class CachedOpdsFeedsTable {
  static const String tableName = 'cached_opds_feeds';

  // Column names
  static const String columnId = 'id';
  static const String columnCatalogId = 'catalog_id';
  static const String columnUrl = 'url';
  static const String columnTitle = 'title';
  static const String columnSubtitle = 'subtitle';
  static const String columnAuthor = 'author';
  static const String columnIconUrl = 'icon_url';
  static const String columnKind = 'kind';
  static const String columnTotalResults = 'total_results';
  static const String columnItemsPerPage = 'items_per_page';
  static const String columnStartIndex = 'start_index';
  static const String columnFeedUpdatedAt = 'feed_updated_at';
  static const String columnCachedAt = 'cached_at';
  static const String columnExpiresAt = 'expires_at';

  /// Map of column names for easy reference
  static const Map<String, String> columns = {
    'id': columnId,
    'catalogId': columnCatalogId,
    'url': columnUrl,
    'title': columnTitle,
    'subtitle': columnSubtitle,
    'author': columnAuthor,
    'iconUrl': columnIconUrl,
    'kind': columnKind,
    'totalResults': columnTotalResults,
    'itemsPerPage': columnItemsPerPage,
    'startIndex': columnStartIndex,
    'feedUpdatedAt': columnFeedUpdatedAt,
    'cachedAt': columnCachedAt,
    'expiresAt': columnExpiresAt,
  };

  /// Returns the SQL query to create the cached_opds_feeds table
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnCatalogId TEXT NOT NULL,
        $columnUrl TEXT NOT NULL,
        $columnTitle TEXT NOT NULL,
        $columnSubtitle TEXT,
        $columnAuthor TEXT,
        $columnIconUrl TEXT,
        $columnKind TEXT NOT NULL,
        $columnTotalResults INTEGER,
        $columnItemsPerPage INTEGER,
        $columnStartIndex INTEGER,
        $columnFeedUpdatedAt INTEGER,
        $columnCachedAt INTEGER NOT NULL,
        $columnExpiresAt INTEGER NOT NULL,
        UNIQUE($columnCatalogId, $columnUrl),
        FOREIGN KEY ($columnCatalogId) REFERENCES catalogs(id) ON DELETE CASCADE
      )
    ''';
  }

  /// Returns indices to improve query performance
  static List<String> createIndices() {
    return [
      'CREATE INDEX idx_cached_feeds_catalog_id ON $tableName($columnCatalogId)',
      'CREATE INDEX idx_cached_feeds_url ON $tableName($columnUrl)',
      'CREATE INDEX idx_cached_feeds_expires_at ON $tableName($columnExpiresAt)',
    ];
  }
}
