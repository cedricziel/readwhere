import 'package:flutter/foundation.dart';
import '../../data/services/book_import_service.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/library_facet.dart';
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
  }) : _bookRepository = bookRepository,
       _importService = importService;

  // State
  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = false;
  String? _error;
  LibrarySortOrder _sortOrder = LibrarySortOrder.recentlyAdded;
  LibraryViewMode _viewMode = LibraryViewMode.grid;
  String _searchQuery = '';

  // Facet filter state
  // Key: field key (e.g., "format"), Value: set of selected values
  Map<String, Set<String>> _selectedFacets = {};

  // Getters
  /// All books in the library (filtered by search and facets)
  List<Book> get books =>
      _filteredBooks.isNotEmpty || _searchQuery.isNotEmpty || hasFacetFilters
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

  /// Currently selected facets by field key
  Map<String, Set<String>> get selectedFacets =>
      Map.unmodifiable(_selectedFacets);

  /// Whether any facet filters are active
  bool get hasFacetFilters => _selectedFacets.isNotEmpty;

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

    debugPrint(
      'Found ${booksWithoutCovers.length} books without covers, extracting...',
    );

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

          final filteredIndex = _filteredBooks.indexWhere(
            (b) => b.id == book.id,
          );
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
  /// Re-extracts all metadata (title, author, publisher, description, etc.)
  /// and cover from the book file.
  ///
  /// [id] The unique identifier of the book to refresh
  /// Returns true if metadata was successfully refreshed
  Future<bool> refreshBookMetadata(String id) async {
    final book = _books.firstWhere(
      (b) => b.id == id,
      orElse: () => throw Exception('Book not found'),
    );

    try {
      final updatedBook = await _importService.refreshMetadata(book);
      if (updatedBook != null) {
        await _bookRepository.update(updatedBook);

        // Update in local list
        final index = _books.indexWhere((b) => b.id == id);
        if (index != -1) {
          _books[index] = updatedBook;
        }

        // Update in filtered list if present
        final filteredIndex = _filteredBooks.indexWhere((b) => b.id == id);
        if (filteredIndex != -1) {
          _filteredBooks[filteredIndex] = updatedBook;
        }

        notifyListeners();
        debugPrint('Refreshed metadata for: ${updatedBook.title}');
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to refresh metadata: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Refresh metadata for all books in the library
  ///
  /// Re-extracts metadata from all book files. This is useful after
  /// adding new metadata fields or to fix books with incomplete metadata.
  ///
  /// [onProgress] Optional callback for progress updates (current, total, bookTitle)
  /// Returns the number of books successfully refreshed
  Future<int> refreshAllMetadata({
    void Function(int current, int total, String bookTitle)? onProgress,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    var refreshedCount = 0;
    final total = _books.length;

    try {
      for (var i = 0; i < _books.length; i++) {
        final book = _books[i];
        onProgress?.call(i + 1, total, book.title);

        final updatedBook = await _importService.refreshMetadata(book);
        if (updatedBook != null) {
          await _bookRepository.update(updatedBook);
          _books[i] = updatedBook;

          // Update in filtered list if present
          final filteredIndex = _filteredBooks.indexWhere(
            (b) => b.id == book.id,
          );
          if (filteredIndex != -1) {
            _filteredBooks[filteredIndex] = updatedBook;
          }

          refreshedCount++;
        }
      }

      debugPrint('Refreshed metadata for $refreshedCount/$total books');
    } catch (e) {
      _error = 'Failed to refresh metadata: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return refreshedCount;
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
    _applyFilters();
    notifyListeners();
  }

  // ===== Facet Filtering =====

  /// Compute available facet groups from current books
  ///
  /// Returns facet groups with counts based on all books (not filtered).
  /// Active facets are marked based on current selections.
  List<LibraryFacetGroup> getAvailableFacetGroups() {
    final groups = <LibraryFacetGroup>[];

    // Format facets
    groups.add(_buildFormatFacets());

    // Language facets
    groups.add(_buildLanguageFacets());

    // Subject facets
    final subjectGroup = _buildSubjectFacets();
    if (subjectGroup.facets.isNotEmpty) {
      groups.add(subjectGroup);
    }

    // Status facets (favorites, reading progress)
    groups.add(_buildStatusFacets());

    return groups;
  }

  LibraryFacetGroup _buildFormatFacets() {
    final formatCounts = <String, int>{};
    for (final book in _books) {
      final format = book.format.toLowerCase();
      formatCounts[format] = (formatCounts[format] ?? 0) + 1;
    }

    final selectedFormats =
        _selectedFacets[LibraryFacetFields.format] ?? <String>{};

    final facets = formatCounts.entries.map((e) {
      final id = '${LibraryFacetFields.format}:${e.key}';
      return LibraryFacet(
        id: id,
        title: e.key.toUpperCase(),
        count: e.value,
        isActive: selectedFormats.contains(e.key),
      );
    }).toList()..sort((a, b) => b.count.compareTo(a.count));

    return LibraryFacetGroup(
      name: 'Format',
      fieldKey: LibraryFacetFields.format,
      facets: facets,
    );
  }

  LibraryFacetGroup _buildLanguageFacets() {
    final languageCounts = <String, int>{};
    for (final book in _books) {
      final lang = book.language ?? 'unknown';
      languageCounts[lang] = (languageCounts[lang] ?? 0) + 1;
    }

    final selectedLanguages =
        _selectedFacets[LibraryFacetFields.language] ?? <String>{};

    final facets = languageCounts.entries.map((e) {
      final id = '${LibraryFacetFields.language}:${e.key}';
      return LibraryFacet(
        id: id,
        title: _getLanguageName(e.key),
        count: e.value,
        isActive: selectedLanguages.contains(e.key),
      );
    }).toList()..sort((a, b) => b.count.compareTo(a.count));

    return LibraryFacetGroup(
      name: 'Language',
      fieldKey: LibraryFacetFields.language,
      facets: facets,
    );
  }

  LibraryFacetGroup _buildSubjectFacets() {
    final subjectCounts = <String, int>{};
    for (final book in _books) {
      for (final subject in book.subjects) {
        final normalized = subject.toLowerCase().trim();
        if (normalized.isNotEmpty) {
          subjectCounts[normalized] = (subjectCounts[normalized] ?? 0) + 1;
        }
      }
    }

    final selectedSubjects =
        _selectedFacets[LibraryFacetFields.subject] ?? <String>{};

    // Only show top 20 subjects
    final sortedEntries = subjectCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topSubjects = sortedEntries.take(20);

    final facets = topSubjects.map((e) {
      final id = '${LibraryFacetFields.subject}:${e.key}';
      return LibraryFacet(
        id: id,
        title: _capitalize(e.key),
        count: e.value,
        isActive: selectedSubjects.contains(e.key),
      );
    }).toList();

    return LibraryFacetGroup(
      name: 'Subject',
      fieldKey: LibraryFacetFields.subject,
      facets: facets,
    );
  }

  LibraryFacetGroup _buildStatusFacets() {
    final selectedStatus =
        _selectedFacets[LibraryFacetFields.status] ?? <String>{};

    final favoriteCount = _books.where((b) => b.isFavorite).length;
    final unreadCount = _books
        .where((b) => b.readingProgress == null || b.readingProgress == 0)
        .length;
    final inProgressCount = _books
        .where(
          (b) =>
              b.readingProgress != null &&
              b.readingProgress! > 0 &&
              b.readingProgress! < 1,
        )
        .length;
    final completedCount = _books.where((b) => b.readingProgress == 1.0).length;

    return LibraryFacetGroup(
      name: 'Status',
      fieldKey: LibraryFacetFields.status,
      facets: [
        LibraryFacet(
          id: '${LibraryFacetFields.status}:${LibraryStatusFacets.favorites}',
          title: 'Favorites',
          count: favoriteCount,
          isActive: selectedStatus.contains(LibraryStatusFacets.favorites),
        ),
        LibraryFacet(
          id: '${LibraryFacetFields.status}:${LibraryStatusFacets.unread}',
          title: 'Unread',
          count: unreadCount,
          isActive: selectedStatus.contains(LibraryStatusFacets.unread),
        ),
        LibraryFacet(
          id: '${LibraryFacetFields.status}:${LibraryStatusFacets.inProgress}',
          title: 'In Progress',
          count: inProgressCount,
          isActive: selectedStatus.contains(LibraryStatusFacets.inProgress),
        ),
        LibraryFacet(
          id: '${LibraryFacetFields.status}:${LibraryStatusFacets.completed}',
          title: 'Completed',
          count: completedCount,
          isActive: selectedStatus.contains(LibraryStatusFacets.completed),
        ),
      ],
    );
  }

  /// Toggle a facet selection
  ///
  /// [fieldKey] The facet group field key (e.g., "format", "language")
  /// [value] The facet value to toggle (e.g., "epub", "en")
  void toggleFacet(String fieldKey, String value) {
    final selections = _selectedFacets.putIfAbsent(fieldKey, () => <String>{});

    if (selections.contains(value)) {
      selections.remove(value);
      if (selections.isEmpty) {
        _selectedFacets.remove(fieldKey);
      }
    } else {
      selections.add(value);
    }

    _applyFilters();
    notifyListeners();
  }

  /// Set facet selections from a map (used when applying from sheet)
  ///
  /// [selections] Map of field key to set of selected values
  void setFacetSelections(Map<String, Set<String>> selections) {
    _selectedFacets = Map.from(
      selections.map((k, v) => MapEntry(k, Set<String>.from(v))),
    );
    _applyFilters();
    notifyListeners();
  }

  /// Clear all facet filters
  void clearFacetFilters() {
    _selectedFacets.clear();
    _applyFilters();
    notifyListeners();
  }

  /// Apply combined search and facet filtering
  void _applyFilters() {
    var result = List<Book>.from(_books);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where(
            (book) =>
                book.title.toLowerCase().contains(query) ||
                book.author.toLowerCase().contains(query),
          )
          .toList();
    }

    // Apply facet filters
    for (final entry in _selectedFacets.entries) {
      final fieldKey = entry.key;
      final values = entry.value;

      if (values.isEmpty) continue;

      result = result.where((book) {
        switch (fieldKey) {
          case LibraryFacetFields.format:
            return values.contains(book.format.toLowerCase());

          case LibraryFacetFields.language:
            final lang = book.language ?? 'unknown';
            return values.contains(lang);

          case LibraryFacetFields.subject:
            final bookSubjects = book.subjects
                .map((s) => s.toLowerCase().trim())
                .toSet();
            return values.any((v) => bookSubjects.contains(v));

          case LibraryFacetFields.status:
            return values.any((status) {
              switch (status) {
                case LibraryStatusFacets.favorites:
                  return book.isFavorite;
                case LibraryStatusFacets.unread:
                  return book.readingProgress == null ||
                      book.readingProgress == 0;
                case LibraryStatusFacets.inProgress:
                  return book.readingProgress != null &&
                      book.readingProgress! > 0 &&
                      book.readingProgress! < 1;
                case LibraryStatusFacets.completed:
                  return book.readingProgress == 1.0;
                default:
                  return false;
              }
            });

          default:
            return true;
        }
      }).toList();
    }

    _filteredBooks = result;
  }

  String _getLanguageName(String code) {
    const languageNames = {
      'en': 'English',
      'de': 'German',
      'fr': 'French',
      'es': 'Spanish',
      'it': 'Italian',
      'pt': 'Portuguese',
      'nl': 'Dutch',
      'ru': 'Russian',
      'ja': 'Japanese',
      'zh': 'Chinese',
      'ko': 'Korean',
      'unknown': 'Unknown',
    };
    return languageNames[code] ?? code.toUpperCase();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
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
        _books.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case LibrarySortOrder.author:
        _books.sort(
          (a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()),
        );
        break;
    }
  }

  /// Apply search filter to books (legacy - calls _applyFilters)
  void _applySearch() {
    _applyFilters();
  }
}
