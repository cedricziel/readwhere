/// Books table schema for storing book metadata
class BooksTable {
  static const String tableName = 'books';

  // Column names
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnAuthor = 'author';
  static const String columnFilePath = 'file_path';
  static const String columnCoverPath = 'cover_path';
  static const String columnFormat = 'format';
  static const String columnFileSize = 'file_size';
  static const String columnAddedAt = 'added_at';
  static const String columnLastOpenedAt = 'last_opened_at';
  static const String columnIsFavorite = 'is_favorite';

  /// Map of column names for easy reference
  static const Map<String, String> columns = {
    'id': columnId,
    'title': columnTitle,
    'author': columnAuthor,
    'filePath': columnFilePath,
    'coverPath': columnCoverPath,
    'format': columnFormat,
    'fileSize': columnFileSize,
    'addedAt': columnAddedAt,
    'lastOpenedAt': columnLastOpenedAt,
    'isFavorite': columnIsFavorite,
  };

  /// Returns the SQL query to create the books table
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnTitle TEXT NOT NULL,
        $columnAuthor TEXT,
        $columnFilePath TEXT NOT NULL,
        $columnCoverPath TEXT,
        $columnFormat TEXT NOT NULL,
        $columnFileSize INTEGER,
        $columnAddedAt INTEGER NOT NULL,
        $columnLastOpenedAt INTEGER,
        $columnIsFavorite INTEGER NOT NULL DEFAULT 0
      )
    ''';
  }

  /// Returns indices to improve query performance
  static List<String> createIndices() {
    return [
      'CREATE INDEX idx_books_added_at ON $tableName($columnAddedAt)',
      'CREATE INDEX idx_books_last_opened_at ON $tableName($columnLastOpenedAt)',
      'CREATE INDEX idx_books_is_favorite ON $tableName($columnIsFavorite)',
      'CREATE INDEX idx_books_format ON $tableName($columnFormat)',
    ];
  }
}
