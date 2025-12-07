import '../entities/bookmark.dart';

/// Abstract repository interface for managing bookmarks
///
/// This interface defines all operations for bookmark data access.
/// Bookmarks are associated with specific books and ordered by creation date.
abstract class BookmarkRepository {
  /// Retrieve all bookmarks for a specific book
  ///
  /// Returns bookmarks ordered by creation date (newest first).
  /// Returns an empty list if no bookmarks exist for the book.
  /// [bookId] The unique identifier of the book
  Future<List<Bookmark>> getBookmarksForBook(String bookId);

  /// Add a new bookmark
  ///
  /// Returns the created bookmark with all fields populated.
  /// [bookmark] The bookmark to add
  Future<Bookmark> addBookmark(Bookmark bookmark);

  /// Delete a bookmark by its ID
  ///
  /// Returns true if the bookmark was deleted, false if it didn't exist.
  /// [id] The unique identifier of the bookmark to delete
  Future<bool> deleteBookmark(String id);

  /// Update an existing bookmark
  ///
  /// Returns the updated bookmark.
  /// Throws an exception if the bookmark doesn't exist.
  /// [bookmark] The bookmark with updated fields
  Future<Bookmark> updateBookmark(Bookmark bookmark);
}
