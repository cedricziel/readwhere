import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'tables/books_table.dart';
import 'tables/reading_progress_table.dart';
import 'tables/bookmarks_table.dart';
import 'tables/annotations_table.dart';
import 'tables/catalogs_table.dart';
import 'tables/feeds_table.dart';
import 'tables/cached_opds_feeds_table.dart';
import 'tables/cached_opds_entries_table.dart';
import 'tables/cached_opds_links_table.dart';
import 'tables/plugin_cache_table.dart';
import 'tables/feed_items_table.dart';

/// SQLite database helper for the readwhere e-reader app
///
/// Manages database lifecycle, schema creation, and migrations.
/// Uses singleton pattern to ensure only one database connection exists.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Current database version
  /// Version 2: Added encryption_type, is_fixed_layout, has_media_overlays
  /// Version 3: Added source_catalog_id, source_entry_id for remote book tracking
  ///            Added api_key, type, server_version to catalogs table
  /// Version 4: Added cached_opds_feeds, cached_opds_entries, cached_opds_links
  ///            for offline catalog browsing
  /// Version 5: Added username, books_folder, user_id to catalogs table
  ///            for Nextcloud integration
  /// Version 6: Added plugin_cache table for unified plugin storage
  /// Version 7: Added feed_items table for RSS feed reader functionality
  /// Version 8: Added full_content and content_scraped_at columns to feed_items
  ///            for article content scraping
  /// Version 9: Added extended metadata columns to books table
  ///            (publisher, description, language, published_date, subjects)
  /// Version 10: Fixed cached_opds_entries primary key to use composite key
  ///             (feed_id, id) instead of just id
  /// Version 11: Re-run V10 migration with correct drop order for FK constraints
  static const int _databaseVersion = 11;

  /// Database filename
  static const String _databaseName = 'readwhere.db';

  /// Get the database instance, initializing if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configure database settings
  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create all tables and indices
  Future<void> _onCreate(Database db, int version) async {
    // Create tables in dependency order (parent tables first)
    await db.execute(BooksTable.createTableQuery());
    await db.execute(ReadingProgressTable.createTableQuery());
    await db.execute(BookmarksTable.createTableQuery());
    await db.execute(AnnotationsTable.createTableQuery());
    await db.execute(CatalogsTable.createTableQuery());
    await db.execute(FeedsTable.createTableQuery());
    // Cache tables for offline catalog browsing
    await db.execute(CachedOpdsFeedsTable.createTableQuery());
    await db.execute(CachedOpdsEntriesTable.createTableQuery());
    await db.execute(CachedOpdsLinksTable.createTableQuery());
    // Plugin cache table for unified plugin storage
    await db.execute(PluginCacheTable.createTableQuery());
    // Feed items table for RSS feed reader
    await db.execute(FeedItemsTable.createTableQuery());

    // Create indices for better query performance
    await _createIndices(db);
  }

  /// Create all indices across tables
  Future<void> _createIndices(Database db) async {
    final indices = [
      ...BooksTable.createIndices(),
      ...ReadingProgressTable.createIndices(),
      ...BookmarksTable.createIndices(),
      ...AnnotationsTable.createIndices(),
      ...CatalogsTable.createIndices(),
      ...FeedsTable.createIndices(),
      ...CachedOpdsFeedsTable.createIndices(),
      ...CachedOpdsEntriesTable.createIndices(),
      ...CachedOpdsLinksTable.createIndices(),
      ...PluginCacheTable.createIndices(),
      ...FeedItemsTable.createIndices(),
    ];

    for (final index in indices) {
      await db.execute(index);
    }
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Version 2: Add encryption, fixed-layout, and media overlay columns
    if (oldVersion < 2) {
      for (final query in BooksTable.migrationV2()) {
        await db.execute(query);
      }
    }
    // Version 3: Add source tracking for remote books and catalog enhancements
    if (oldVersion < 3) {
      for (final query in BooksTable.migrationV3()) {
        await db.execute(query);
      }
      for (final query in CatalogsTable.migrateFromV2()) {
        await db.execute(query);
      }
    }
    // Version 4: Add cache tables for offline catalog browsing
    if (oldVersion < 4) {
      await db.execute(CachedOpdsFeedsTable.createTableQuery());
      await db.execute(CachedOpdsEntriesTable.createTableQuery());
      await db.execute(CachedOpdsLinksTable.createTableQuery());
      for (final index in CachedOpdsFeedsTable.createIndices()) {
        await db.execute(index);
      }
      for (final index in CachedOpdsEntriesTable.createIndices()) {
        await db.execute(index);
      }
      for (final index in CachedOpdsLinksTable.createIndices()) {
        await db.execute(index);
      }
    }
    // Version 5: Add Nextcloud-specific columns to catalogs table
    if (oldVersion < 5) {
      for (final query in CatalogsTable.migrateFromV3()) {
        await db.execute(query);
      }
    }
    // Version 6: Add plugin_cache table for unified plugin storage
    if (oldVersion < 6) {
      for (final query in PluginCacheTable.migrationV6()) {
        await db.execute(query);
      }
    }
    // Version 7: Add feed_items table for RSS feed reader
    if (oldVersion < 7) {
      for (final query in FeedItemsTable.allMigrationQueries()) {
        await db.execute(query);
      }
    }
    // Version 8: Add full_content and content_scraped_at columns to feed_items
    if (oldVersion < 8) {
      await db.execute(FeedItemsTable.addFullContentColumnQuery());
      await db.execute(FeedItemsTable.addContentScrapedAtColumnQuery());
    }
    // Version 9: Add extended metadata columns to books table
    if (oldVersion < 9) {
      for (final query in BooksTable.migrationV9()) {
        await db.execute(query);
      }
    }
    // Version 10/11: Fix cached_opds_entries primary key to use composite key
    // Also recreate cached_opds_links to use composite FK for entries
    // V11 re-runs this with correct drop order for FK constraints
    if (oldVersion < 11) {
      // Drop both tables first (links references entries, so drop links first)
      await db.execute(
        'DROP TABLE IF EXISTS ${CachedOpdsLinksTable.tableName}',
      );
      await db.execute(
        'DROP TABLE IF EXISTS ${CachedOpdsEntriesTable.tableName}',
      );
      // Recreate entries with new composite primary key
      await db.execute(CachedOpdsEntriesTable.createTableQuery());
      for (final index in CachedOpdsEntriesTable.createIndices()) {
        await db.execute(index);
      }
      // Recreate links with new composite FK
      await db.execute(CachedOpdsLinksTable.createTableQuery());
      for (final index in CachedOpdsLinksTable.createIndices()) {
        await db.execute(index);
      }
    }
  }

  /// Close the database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete the database (useful for testing or reset functionality)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  /// Execute a raw query (use with caution)
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Execute a raw SQL statement (use with caution)
  Future<int> rawExecute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  /// Get database file path (useful for debugging)
  Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, _databaseName);
  }

  /// Check if database exists
  Future<bool> exists() async {
    final path = await getDatabasePath();
    return await databaseFactory.databaseExists(path);
  }
}
