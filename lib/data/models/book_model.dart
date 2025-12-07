import '../../domain/entities/book.dart';
import '../database/tables/books_table.dart';

/// Data model for Book entity with database serialization support
///
/// This model extends the domain entity with methods for converting
/// to and from database representations (Map format for SQLite).
class BookModel extends Book {
  const BookModel({
    required super.id,
    required super.title,
    required super.author,
    required super.filePath,
    super.coverPath,
    required super.format,
    required super.fileSize,
    required super.addedAt,
    super.lastOpenedAt,
    super.isFavorite,
    super.readingProgress,
  });

  /// Create a BookModel from a Map (SQLite row)
  ///
  /// Converts database column types to Dart types:
  /// - INTEGER timestamps to DateTime
  /// - INTEGER boolean (0/1) to bool
  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map[BooksTable.columnId] as String,
      title: map[BooksTable.columnTitle] as String,
      author: map[BooksTable.columnAuthor] as String? ?? '',
      filePath: map[BooksTable.columnFilePath] as String,
      coverPath: map[BooksTable.columnCoverPath] as String?,
      format: map[BooksTable.columnFormat] as String,
      fileSize: map[BooksTable.columnFileSize] as int? ?? 0,
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        map[BooksTable.columnAddedAt] as int,
      ),
      lastOpenedAt: map[BooksTable.columnLastOpenedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[BooksTable.columnLastOpenedAt] as int,
            )
          : null,
      isFavorite: (map[BooksTable.columnIsFavorite] as int) == 1,
      readingProgress: null, // Reading progress is stored separately
    );
  }

  /// Create a BookModel from a domain entity
  factory BookModel.fromEntity(Book book) {
    return BookModel(
      id: book.id,
      title: book.title,
      author: book.author,
      filePath: book.filePath,
      coverPath: book.coverPath,
      format: book.format,
      fileSize: book.fileSize,
      addedAt: book.addedAt,
      lastOpenedAt: book.lastOpenedAt,
      isFavorite: book.isFavorite,
      readingProgress: book.readingProgress,
    );
  }

  /// Convert to a Map for SQLite storage
  ///
  /// Converts Dart types to database column types:
  /// - DateTime to INTEGER (milliseconds since epoch)
  /// - bool to INTEGER (0 or 1)
  Map<String, dynamic> toMap() {
    return {
      BooksTable.columnId: id,
      BooksTable.columnTitle: title,
      BooksTable.columnAuthor: author,
      BooksTable.columnFilePath: filePath,
      BooksTable.columnCoverPath: coverPath,
      BooksTable.columnFormat: format,
      BooksTable.columnFileSize: fileSize,
      BooksTable.columnAddedAt: addedAt.millisecondsSinceEpoch,
      BooksTable.columnLastOpenedAt: lastOpenedAt?.millisecondsSinceEpoch,
      BooksTable.columnIsFavorite: isFavorite ? 1 : 0,
    };
  }

  /// Convert to domain entity (Book)
  Book toEntity() {
    return Book(
      id: id,
      title: title,
      author: author,
      filePath: filePath,
      coverPath: coverPath,
      format: format,
      fileSize: fileSize,
      addedAt: addedAt,
      lastOpenedAt: lastOpenedAt,
      isFavorite: isFavorite,
      readingProgress: readingProgress,
    );
  }
}
