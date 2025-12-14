// Database table definitions for Nextcloud News ID mappings
//
// These tables track the relationship between Nextcloud News IDs
// and local app IDs for feeds and items, enabling sync operations.

/// Table for mapping Nextcloud News feed IDs to local RSS catalog IDs
class NextcloudNewsFeedMappingsTable {
  static const String tableName = 'nextcloud_news_feed_mappings';

  // Column names
  static const String columnId = 'id';
  static const String columnCatalogId = 'catalog_id';
  static const String columnNcFeedId = 'nc_feed_id';
  static const String columnLocalFeedId = 'local_feed_id';
  static const String columnFeedUrl = 'feed_url';
  static const String columnCreatedAt = 'created_at';

  /// Returns the SQL query to create the feed mappings table
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnCatalogId TEXT NOT NULL,
        $columnNcFeedId INTEGER NOT NULL,
        $columnLocalFeedId TEXT NOT NULL,
        $columnFeedUrl TEXT NOT NULL,
        $columnCreatedAt INTEGER NOT NULL,
        UNIQUE($columnCatalogId, $columnNcFeedId),
        UNIQUE($columnCatalogId, $columnLocalFeedId),
        FOREIGN KEY ($columnCatalogId) REFERENCES catalogs(id) ON DELETE CASCADE,
        FOREIGN KEY ($columnLocalFeedId) REFERENCES catalogs(id) ON DELETE CASCADE
      )
    ''';
  }

  /// Returns indices for query performance
  static List<String> createIndices() {
    return [
      'CREATE INDEX idx_nc_feed_mappings_catalog ON $tableName($columnCatalogId)',
      'CREATE INDEX idx_nc_feed_mappings_nc_feed ON $tableName($columnNcFeedId)',
      'CREATE INDEX idx_nc_feed_mappings_local_feed ON $tableName($columnLocalFeedId)',
      'CREATE INDEX idx_nc_feed_mappings_url ON $tableName($columnFeedUrl)',
    ];
  }

  /// Returns all migration queries for v13
  static List<String> migrationV13() {
    return [createTableQuery(), ...createIndices()];
  }
}

/// Table for mapping Nextcloud News item IDs to local feed item IDs
class NextcloudNewsItemMappingsTable {
  static const String tableName = 'nextcloud_news_item_mappings';

  // Column names
  static const String columnId = 'id';
  static const String columnCatalogId = 'catalog_id';
  static const String columnNcItemId = 'nc_item_id';
  static const String columnLocalItemId = 'local_item_id';
  static const String columnNcFeedId = 'nc_feed_id';
  static const String columnLocalFeedId = 'local_feed_id';
  static const String columnCreatedAt = 'created_at';

  /// Returns the SQL query to create the item mappings table
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnCatalogId TEXT NOT NULL,
        $columnNcItemId INTEGER NOT NULL,
        $columnLocalItemId TEXT NOT NULL,
        $columnNcFeedId INTEGER NOT NULL,
        $columnLocalFeedId TEXT NOT NULL,
        $columnCreatedAt INTEGER NOT NULL,
        UNIQUE($columnCatalogId, $columnNcItemId),
        FOREIGN KEY ($columnCatalogId) REFERENCES catalogs(id) ON DELETE CASCADE,
        FOREIGN KEY ($columnLocalItemId) REFERENCES feed_items(id) ON DELETE CASCADE,
        FOREIGN KEY ($columnLocalFeedId) REFERENCES catalogs(id) ON DELETE CASCADE
      )
    ''';
  }

  /// Returns indices for query performance
  static List<String> createIndices() {
    return [
      'CREATE INDEX idx_nc_item_mappings_catalog ON $tableName($columnCatalogId)',
      'CREATE INDEX idx_nc_item_mappings_nc_item ON $tableName($columnNcItemId)',
      'CREATE INDEX idx_nc_item_mappings_local_item ON $tableName($columnLocalItemId)',
      'CREATE INDEX idx_nc_item_mappings_nc_feed ON $tableName($columnNcFeedId)',
    ];
  }

  /// Returns all migration queries for v13
  static List<String> migrationV13() {
    return [createTableQuery(), ...createIndices()];
  }
}
