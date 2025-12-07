import '../entities/reading_progress.dart';

/// Abstract repository interface for managing reading progress
///
/// This interface defines all operations for tracking reading progress
/// across different books. Each book should have at most one progress record.
abstract class ReadingProgressRepository {
  /// Retrieve the reading progress for a specific book
  ///
  /// Returns the progress record if it exists, null otherwise.
  /// [bookId] The unique identifier of the book
  Future<ReadingProgress?> getProgressForBook(String bookId);

  /// Save or update reading progress for a book
  ///
  /// If progress already exists for the book, it will be updated.
  /// Otherwise, a new progress record will be created.
  /// Returns the saved progress record.
  /// [progress] The reading progress to save
  Future<ReadingProgress> saveProgress(ReadingProgress progress);

  /// Delete all reading progress for a specific book
  ///
  /// Returns true if progress was deleted, false if none existed.
  /// [bookId] The unique identifier of the book
  Future<bool> deleteProgressForBook(String bookId);
}
