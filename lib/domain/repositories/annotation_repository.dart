import '../entities/annotation.dart';

/// Abstract repository interface for managing annotations
///
/// This interface defines all operations for annotation data access.
/// Annotations are associated with specific books and can be filtered by chapter.
abstract class AnnotationRepository {
  /// Retrieve all annotations for a specific book
  ///
  /// Returns annotations ordered by creation date (newest first).
  /// Returns an empty list if no annotations exist for the book.
  /// [bookId] The unique identifier of the book
  Future<List<Annotation>> getAnnotationsForBook(String bookId);

  /// Retrieve all annotations for a specific chapter within a book
  ///
  /// Returns annotations ordered by CFI position for proper display order.
  /// Returns an empty list if no annotations exist for the chapter.
  /// [bookId] The unique identifier of the book
  /// [chapterId] The identifier of the chapter
  Future<List<Annotation>> getAnnotationsForChapter(
    String bookId,
    String chapterId,
  );

  /// Add a new annotation
  ///
  /// Returns the created annotation with all fields populated.
  /// [annotation] The annotation to add
  Future<Annotation> addAnnotation(Annotation annotation);

  /// Delete an annotation by its ID
  ///
  /// Returns true if the annotation was deleted, false if it didn't exist.
  /// [id] The unique identifier of the annotation to delete
  Future<bool> deleteAnnotation(String id);

  /// Update an existing annotation
  ///
  /// Returns the updated annotation.
  /// Throws an exception if the annotation doesn't exist.
  /// [annotation] The annotation with updated fields
  Future<Annotation> updateAnnotation(Annotation annotation);

  /// Delete all annotations for a specific book
  ///
  /// Returns the number of annotations deleted.
  /// Useful for cleanup when a book is removed from the library.
  /// [bookId] The unique identifier of the book
  Future<int> deleteAnnotationsForBook(String bookId);
}
