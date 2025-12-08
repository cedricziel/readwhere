import 'package:flutter/foundation.dart';
import '../../data/services/book_import_service.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';

/// Sort order options for the library
enum LibrarySortOrder {
  /// Recently added books first
  recentlyAdded,

  /// Recently opened books first
  recentlyOpened,

  /// Alphabetical by title
  title,

  /// Alphabetical by author
  author,
}

/// View mode options for the library
enum LibraryViewMode {
  /// Grid view with book covers
  grid,

  /// List view with book details
  list,
}

/// Provider for managing library state and operations
///
/// This provider handles:
/// - Loading and displaying books from the library
/// - Importing new books
/// - Deleting books
/// - Managing favorites
/// - Sorting and filtering
/// - Search functionality
class LibraryProvider extends ChangeNotifier {
  final BookRepository _bookRepository;
  final BookImportService _importService;

  LibraryProvider({
    required BookRepository bookRepository,
    required BookImportService importService,
  })  : _bookRepository = bookRepository,
        _importService = importService;

  // State
  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = false;
  String? _error;
  LibrarySortOrder _sortOrder = LibrarySortOrder.recentlyAdded;
  LibraryViewMode _viewMode = LibraryViewMode.grid;
  String _searchQuery = '';

  // Getters
  /// All books in the library
  List<Book> get books => _filteredBooks.isNotEmpty || _searchQuery.isNotEmpty
      ? _filteredBooks
      : _books;

  /// Loading state indicator
  bool get isLoading => _isLoading;

  /// Error message if an operation failed
  String? get error => _error;

  /// Current sort order
  LibrarySortOrder get sortOrder => _sortOrder;

  /// Current view mode
  LibraryViewMode get viewMode => _viewMode;

  /// Current search query
  String get searchQuery => _searchQuery;

  /// Number of books in the library
  int get bookCount => _books.length;

  /// Number of favorite books
  int get favoriteCount => _books.where((book) => book.isFavorite).length;

  // Methods

  /// Load all books from the repository
  ///
  /// Fetches books from the database and applies current sort order.
  /// Sets loading state and handles errors appropriately.
  /// Alias for loadBooks() to match the requested API.
  Future<void> loadLibrary() async {
    await loadBooks();
  }

  /// Load all books from the repository
  ///
  /// Fetches books from the database and applies current sort order.
  /// Sets loading state and handles errors appropriately.
  /// Automatically attempts to extract covers for books missing them.
  Future<void> loadBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _books = await _bookRepository.getAll();
      _applySorting();
      _applySearch();

      // Extract covers for books that don't have them (in background)
      _extractMissingCovers();
    } catch (e) {
      _error = 'Failed to load books: ${e.toString()}';
      _books = [];
      _filteredBooks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Extract covers for books that don't have them
  ///
  /// Runs in the background without blocking the UI.
  /// Updates books as covers are extracted.
  Future<void> _extractMissingCovers() async {
    final booksWithoutCovers = _books
        .where((book) => book.coverPath == null || book.coverPath!.isEmpty)
        .toList();

    if (booksWithoutCovers.isEmpty) {
      debugPrint('All books have covers');
      return;
    }

    debugPrint('Found ${booksWithoutCovers.length} books without covers, extracting...');

    for (final book in booksWithoutCovers) {
      try {
        final coverPath = await _importService.extractCover(book);
        if (coverPath != null) {
          // Update the book with the new cover path
          final updatedBook = book.copyWith(coverPath: coverPath);
          await _bookRepository.update(updatedBook);

          // Update in local list
          final index = _books.indexWhere((b) => b.id == book.id);
          if (index != -1) {
            _books[index] = updatedBook;
          }

          final filteredIndex = _filteredBooks.indexWhere((b) => b.id == book.id);
          if (filteredIndex != -1) {
            _filteredBooks[filteredIndex] = updatedBook;
          }

          notifyListeners();
          debugPrint('Updated cover for: ${book.title}');
        }
      } catch (e) {
        debugPrint('Failed to extract cover for ${book.title}: $e');
      }
    }
  }

  /// Manually refresh metadata for a specific book
  ///
  /// Re-extracts cover and metadata from the book file.
  /// [id] The unique identifier of the book to refresh
  Future<void> refreshBookMetadata(String id) async {
    final book = _books.firstWhere(
      (b) => b.id == id,
      orElse: () => throw Exception('Book not found'),
    );

    try {
      final coverPath = await _importService.extractCover(book);
      if (coverPath != null) {
        final updatedBook = book.copyWith(coverPath: coverPath);
        await _bookRepository.update(updatedBook);

        // Update in local list
        final index = _books.indexWhere((b) => b.id == id);
        if (index != -1) {
          _books[index] = updatedBook;
        }

        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to refresh metadata: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Import a new book from a file path
  ///
  /// Creates a new book entry in the library from the provided file.
  /// The book will be added to the database and the library will be refreshed.
  /// For EPUB files, metadata and cover will be extracted automatically.
  ///
  /// [filePath] Absolute path to the book file
  /// Returns the imported book if successful
  Future<Book?> importBook(String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use import service to parse book and extract metadata
      final book = await _importService.importBook(filePath);

      // Save to database
      final importedBook = await _bookRepository.insert(book);
      await loadBooks(); // Refresh the library
      return importedBook;
    } catch (e) {
      _error = 'Failed to import book: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a book from the library
  ///
  /// Removes the book from the database along with all associated data
  /// (reading progress, bookmarks, etc.).
  ///
  /// [id] The unique identifier of the book to delete
  /// Returns true if the book was successfully deleted
  Future<bool> deleteBook(String id) async {
    _error = null;

    try {
      final success = await _bookRepository.delete(id);
      if (success) {
        _books.removeWhere((book) => book.id == id);
        _filteredBooks.removeWhere((book) => book.id == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = 'Failed to delete book: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Toggle the favorite status of a book
  ///
  /// If the book is currently a favorite, it will be unmarked.
  /// If it's not a favorite, it will be marked as one.
  ///
  /// [id] The unique identifier of the book
  Future<void> toggleFavorite(String id) async {
    _error = null;

    try {
      final updatedBook = await _bookRepository.toggleFavorite(id);

      // Update in local list
      final index = _books.indexWhere((book) => book.id == id);
      if (index != -1) {
        _books[index] = updatedBook;
      }

      final filteredIndex = _filteredBooks.indexWhere((book) => book.id == id);
      if (filteredIndex != -1) {
        _filteredBooks[filteredIndex] = updatedBook;
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to toggle favorite: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Set the sort order for the library
  ///
  /// Changes how books are sorted in the library view.
  /// The library will be re-sorted immediately.
  ///
  /// [order] The new sort order to apply
  void setSortOrder(LibrarySortOrder order) {
    if (_sortOrder != order) {
      _sortOrder = order;
      _applySorting();
      notifyListeners();
    }
  }

  /// Set the view mode for the library
  ///
  /// Changes between grid and list view modes.
  ///
  /// [mode] The new view mode to apply
  void setViewMode(LibraryViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  /// Search for books by title or author
  ///
  /// Filters the book list to only show books matching the query.
  /// The search is case-insensitive and matches partial strings.
  ///
  /// [query] The search term (empty string to clear search)
  /// Alias for searchBooks() to match the requested API.
  Future<void> search(String query) async {
    await searchBooks(query);
  }

  /// Search for books by title or author
  ///
  /// Filters the book list to only show books matching the query.
  /// The search is case-insensitive and matches partial strings.
  ///
  /// [query] The search term (empty string to clear search)
  Future<void> searchBooks(String query) async {
    _searchQuery = query;
    _error = null;

    if (query.isEmpty) {
      _filteredBooks = [];
      notifyListeners();
      return;
    }

    try {
      _filteredBooks = await _bookRepository.search(query);
      notifyListeners();
    } catch (e) {
      _error = 'Search failed: ${e.toString()}';
      _filteredBooks = [];
      notifyListeners();
    }
  }

  /// Clear the current search and show all books
  void clearSearch() {
    _searchQuery = '';
    _filteredBooks = [];
    notifyListeners();
  }

  /// Get the filtered books based on search query and sort order
  ///
  /// Returns the current list of books after applying search filters
  /// and sorting. This is a convenience method that returns the same
  /// list as the [books] getter.
  List<Book> getFilteredBooks() {
    return books;
  }

  // Private helper methods

  /// Apply the current sort order to the books list
  void _applySorting() {
    switch (_sortOrder) {
      case LibrarySortOrder.recentlyAdded:
        _books.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case LibrarySortOrder.recentlyOpened:
        _books.sort((a, b) {
          if (a.lastOpenedAt == null && b.lastOpenedAt == null) return 0;
          if (a.lastOpenedAt == null) return 1;
          if (b.lastOpenedAt == null) return -1;
          return b.lastOpenedAt!.compareTo(a.lastOpenedAt!);
        });
        break;
      case LibrarySortOrder.title:
        _books.sort((a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case LibrarySortOrder.author:
        _books.sort((a, b) =>
            a.author.toLowerCase().compareTo(b.author.toLowerCase()));
        break;
    }
  }

  /// Apply search filter to books
  void _applySearch() {
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      _filteredBooks = _books
          .where((book) =>
              book.title.toLowerCase().contains(query) ||
              book.author.toLowerCase().contains(query))
          .toList();
    } else {
      _filteredBooks = [];
    }
  }
}
