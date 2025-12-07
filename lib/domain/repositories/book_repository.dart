import '../entities/book.dart';

/// Abstract repository interface for managing books
///
/// This interface defines all operations for book data access.
/// Implementations should handle database operations and provide
/// proper error handling.
abstract class BookRepository {
  /// Retrieve all books from the library
  ///
  /// Returns a list of all books, ordered by most recently added first.
  /// Returns an empty list if no books exist.
  Future<List<Book>> getAll();

  /// Retrieve a specific book by its ID
  ///
  /// Returns the book if found, null otherwise.
  /// [id] The unique identifier of the book
  Future<Book?> getById(String id);

  /// Insert a new book into the library
  ///
  /// Returns the inserted book with all fields populated.
  /// Throws an exception if a book with the same ID already exists.
  /// [book] The book to insert
  Future<Book> insert(Book book);

  /// Update an existing book
  ///
  /// Returns the updated book.
  /// Throws an exception if the book doesn't exist.
  /// [book] The book with updated fields
  Future<Book> update(Book book);

  /// Delete a book by its ID
  ///
  /// Returns true if the book was deleted, false if it didn't exist.
  /// Also deletes all associated reading progress and bookmarks.
  /// [id] The unique identifier of the book to delete
  Future<bool> delete(String id);

  /// Retrieve recently opened books
  ///
  /// Returns books ordered by last opened date (most recent first).
  /// [limit] Maximum number of books to return (default: 10)
  Future<List<Book>> getRecent({int limit = 10});

  /// Retrieve all favorite books
  ///
  /// Returns books marked as favorites, ordered by title.
  Future<List<Book>> getFavorites();

  /// Search for books by title or author
  ///
  /// Returns books where title or author contains the query string (case-insensitive).
  /// [query] The search term to match against title and author
  Future<List<Book>> search(String query);

  /// Update the last opened timestamp for a book
  ///
  /// Sets the lastOpenedAt field to the current time.
  /// [id] The unique identifier of the book
  Future<void> updateLastOpened(String id);

  /// Toggle the favorite status of a book
  ///
  /// If the book is currently a favorite, it will be unmarked.
  /// If it's not a favorite, it will be marked as one.
  /// Returns the updated book.
  /// [id] The unique identifier of the book
  Future<Book> toggleFavorite(String id);
}
