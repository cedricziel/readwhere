/// Bookmarks table schema for storing user bookmarks
class BookmarksTable {
  static const String tableName = 'bookmarks';

  // Column names
  static const String columnId = 'id';
  static const String columnBookId = 'book_id';
  static const String columnChapterId = 'chapter_id';
  static const String columnCfi = 'cfi';
  static const String columnTitle = 'title';
  static const String columnCreatedAt = 'created_at';

  /// Map of column names for easy reference
  static const Map<String, String> columns = {
    'id': columnId,
    'bookId': columnBookId,
    'chapterId': columnChapterId,
    'cfi': columnCfi,
    'title': columnTitle,
    'createdAt': columnCreatedAt,
  };

  /// Returns the SQL query to create the bookmarks table
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnBookId TEXT NOT NULL,
        $columnChapterId TEXT,
        $columnCfi TEXT,
        $columnTitle TEXT,
        $columnCreatedAt INTEGER NOT NULL,
        FOREIGN KEY ($columnBookId) REFERENCES books(id) ON DELETE CASCADE
      )
    ''';
  }

  /// Returns indices to improve query performance
  static List<String> createIndices() {
    return [
      'CREATE INDEX idx_bookmarks_book_id ON $tableName($columnBookId)',
      'CREATE INDEX idx_bookmarks_created_at ON $tableName($columnCreatedAt)',
    ];
  }
}
