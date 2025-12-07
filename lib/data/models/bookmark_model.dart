import '../../domain/entities/bookmark.dart';
import '../database/tables/bookmarks_table.dart';

/// Data model for Bookmark entity with database serialization support
///
/// This model extends the domain entity with methods for converting
/// to and from database representations (Map format for SQLite).
class BookmarkModel extends Bookmark {
  const BookmarkModel({
    required super.id,
    required super.bookId,
    super.chapterId,
    required super.cfi,
    required super.title,
    required super.createdAt,
  });

  /// Create a BookmarkModel from a Map (SQLite row)
  ///
  /// Converts database column types to Dart types:
  /// - INTEGER timestamps to DateTime
  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map[BookmarksTable.columnId] as String,
      bookId: map[BookmarksTable.columnBookId] as String,
      chapterId: map[BookmarksTable.columnChapterId] as String?,
      cfi: map[BookmarksTable.columnCfi] as String? ?? '',
      title: map[BookmarksTable.columnTitle] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[BookmarksTable.columnCreatedAt] as int,
      ),
    );
  }

  /// Create a BookmarkModel from a domain entity
  factory BookmarkModel.fromEntity(Bookmark bookmark) {
    return BookmarkModel(
      id: bookmark.id,
      bookId: bookmark.bookId,
      chapterId: bookmark.chapterId,
      cfi: bookmark.cfi,
      title: bookmark.title,
      createdAt: bookmark.createdAt,
    );
  }

  /// Convert to a Map for SQLite storage
  ///
  /// Converts Dart types to database column types:
  /// - DateTime to INTEGER (milliseconds since epoch)
  Map<String, dynamic> toMap() {
    return {
      BookmarksTable.columnId: id,
      BookmarksTable.columnBookId: bookId,
      BookmarksTable.columnChapterId: chapterId,
      BookmarksTable.columnCfi: cfi,
      BookmarksTable.columnTitle: title,
      BookmarksTable.columnCreatedAt: createdAt.millisecondsSinceEpoch,
    };
  }

  /// Convert to domain entity (Bookmark)
  Bookmark toEntity() {
    return Bookmark(
      id: id,
      bookId: bookId,
      chapterId: chapterId,
      cfi: cfi,
      title: title,
      createdAt: createdAt,
    );
  }
}
