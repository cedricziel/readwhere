import '../domain/entities/toc_entry.dart';
import 'reader_content.dart';
import 'search_result.dart';

/// Abstract controller for reading a book
///
/// Implementations of this class handle navigation, content retrieval,
/// and search functionality for specific book formats.
abstract class ReaderController {
  /// Unique identifier for the book being read
  String get bookId;

  /// Table of contents for the book
  List<TocEntry> get tableOfContents;

  /// Total number of chapters in the book
  int get totalChapters;

  /// Current chapter index (0-based)
  int get currentChapterIndex;

  /// Reading progress as a value between 0.0 and 1.0
  double get progress;

  /// Stream of content updates as the reader navigates through the book
  Stream<ReaderContent> get contentStream;

  /// Navigate to a specific chapter by index
  ///
  /// Throws [ArgumentError] if [index] is out of bounds
  Future<void> goToChapter(int index);

  /// Navigate to a specific location using CFI (Canonical Fragment Identifier)
  ///
  /// CFI is a standard way to reference locations in EPUB and other formats
  Future<void> goToLocation(String cfi);

  /// Navigate to the next chapter
  ///
  /// Does nothing if already at the last chapter
  Future<void> nextChapter();

  /// Navigate to the previous chapter
  ///
  /// Does nothing if already at the first chapter
  Future<void> previousChapter();

  /// Search for text within the book
  ///
  /// Returns a list of [SearchResult] objects representing matches
  Future<List<SearchResult>> search(String query);

  /// Get the current reading position as a CFI string
  ///
  /// Returns null if CFI is not supported or cannot be determined
  String? getCurrentCfi();

  /// Clean up resources when the controller is no longer needed
  Future<void> dispose();

  /// Whether this content should use fixed-layout rendering (InteractiveViewer)
  ///
  /// Fixed-layout content (comics, image-heavy books) benefits from zoom/pan
  /// rather than reflowable text rendering.
  /// Defaults to false for text-based content.
  bool get isFixedLayout => false;
}
