/// Reading progress table schema for tracking user reading position
class ReadingProgressTable {
  static const String tableName = 'reading_progress';

  // Column names
  static const String columnId = 'id';
  static const String columnBookId = 'book_id';
  static const String columnChapterId = 'chapter_id';
  static const String columnCfi = 'cfi';
  static const String columnProgress = 'progress';
  static const String columnUpdatedAt = 'updated_at';

  /// Map of column names for easy reference
  static const Map<String, String> columns = {
    'id': columnId,
    'bookId': columnBookId,
    'chapterId': columnChapterId,
    'cfi': columnCfi,
    'progress': columnProgress,
    'updatedAt': columnUpdatedAt,
  };

  /// Returns the SQL query to create the reading_progress table
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnBookId TEXT NOT NULL,
        $columnChapterId TEXT,
        $columnCfi TEXT,
        $columnProgress REAL NOT NULL DEFAULT 0.0,
        $columnUpdatedAt INTEGER NOT NULL,
        FOREIGN KEY ($columnBookId) REFERENCES books(id) ON DELETE CASCADE
      )
    ''';
  }

  /// Returns indices to improve query performance
  static List<String> createIndices() {
    return [
      'CREATE INDEX idx_reading_progress_book_id ON $tableName($columnBookId)',
      'CREATE INDEX idx_reading_progress_updated_at ON $tableName($columnUpdatedAt)',
    ];
  }
}
