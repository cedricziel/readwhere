/// Annotations table schema for storing highlights and notes
class AnnotationsTable {
  static const String tableName = 'annotations';

  // Column names
  static const String columnId = 'id';
  static const String columnBookId = 'book_id';
  static const String columnChapterId = 'chapter_id';
  static const String columnCfiStart = 'cfi_start';
  static const String columnCfiEnd = 'cfi_end';
  static const String columnText = 'text';
  static const String columnNote = 'note';
  static const String columnColor = 'color';
  static const String columnCreatedAt = 'created_at';

  /// Map of column names for easy reference
  static const Map<String, String> columns = {
    'id': columnId,
    'bookId': columnBookId,
    'chapterId': columnChapterId,
    'cfiStart': columnCfiStart,
    'cfiEnd': columnCfiEnd,
    'text': columnText,
    'note': columnNote,
    'color': columnColor,
    'createdAt': columnCreatedAt,
  };

  /// Returns the SQL query to create the annotations table
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnBookId TEXT NOT NULL,
        $columnChapterId TEXT,
        $columnCfiStart TEXT,
        $columnCfiEnd TEXT,
        $columnText TEXT,
        $columnNote TEXT,
        $columnColor TEXT,
        $columnCreatedAt INTEGER NOT NULL,
        FOREIGN KEY ($columnBookId) REFERENCES books(id) ON DELETE CASCADE
      )
    ''';
  }

  /// Returns indices to improve query performance
  static List<String> createIndices() {
    return [
      'CREATE INDEX idx_annotations_book_id ON $tableName($columnBookId)',
      'CREATE INDEX idx_annotations_created_at ON $tableName($columnCreatedAt)',
      'CREATE INDEX idx_annotations_color ON $tableName($columnColor)',
    ];
  }
}
