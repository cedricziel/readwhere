import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'tables/books_table.dart';
import 'tables/reading_progress_table.dart';
import 'tables/bookmarks_table.dart';
import 'tables/annotations_table.dart';
import 'tables/catalogs_table.dart';
import 'tables/feeds_table.dart';

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
  static const int _databaseVersion = 1;

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
    ];

    for (final index in indices) {
      await db.execute(index);
    }
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic will be added here as the schema evolves
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE books ADD COLUMN new_column TEXT');
    // }
    // if (oldVersion < 3) {
    //   await db.execute('CREATE TABLE new_table (...)');
    // }
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
