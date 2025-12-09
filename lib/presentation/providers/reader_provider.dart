import 'package:flutter/foundation.dart';
import 'package:readwhere_cbr_plugin/readwhere_cbr_plugin.dart';
import 'package:readwhere_cbz_plugin/readwhere_cbz_plugin.dart';
import 'package:readwhere_epub_plugin/readwhere_epub_plugin.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/reading_settings.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../../domain/repositories/bookmark_repository.dart';
import 'catalogs_provider.dart';

/// Provider for managing reader state and reading operations
///
/// This provider handles:
/// - Opening and closing books
/// - Managing reading progress
/// - Navigation between chapters
/// - Bookmarks management
/// - Reading settings
/// - Table of contents
/// - DRM detection and blocking
class ReaderProvider extends ChangeNotifier {
  final ReadingProgressRepository _readingProgressRepository;
  final BookmarkRepository _bookmarkRepository;
  final CatalogsProvider? _catalogsProvider;
  final Uuid _uuid = const Uuid();
  final PluginRegistry _pluginRegistry = PluginRegistry();

  ReaderProvider({
    required ReadingProgressRepository readingProgressRepository,
    required BookmarkRepository bookmarkRepository,
    CatalogsProvider? catalogsProvider,
  }) : _readingProgressRepository = readingProgressRepository,
       _bookmarkRepository = bookmarkRepository,
       _catalogsProvider = catalogsProvider;

  // State
  Book? _currentBook;
  ReadingProgress? _progress;
  List<Bookmark> _bookmarks = [];
  ReadingSettings _settings = ReadingSettings.defaults();
  bool _isLoading = false;
  String? _error;
  int _currentChapterIndex = 0;
  List<TocEntry> _tableOfContents = [];
  bool _isDrmBlocked = false;

  // Reader controller (using ReadwhereEpubController)
  ReaderController? _readerController;
  String _currentChapterHtml = '';
  String _currentChapterCss = '';
  Map<String, Uint8List> _currentChapterImages = {};

  // Getters

  /// The currently open book
  Book? get currentBook => _currentBook;

  /// Current reading progress for the open book
  ReadingProgress? get progress => _progress;

  /// All bookmarks for the current book
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  /// Current reading settings
  ReadingSettings get settings => _settings;

  /// Loading state indicator
  bool get isLoading => _isLoading;

  /// Error message if an operation failed
  String? get error => _error;

  /// Whether opening was blocked due to DRM
  bool get isDrmBlocked => _isDrmBlocked;

  /// Current chapter index
  int get currentChapterIndex => _currentChapterIndex;

  /// Table of contents for the current book
  List<TocEntry> get tableOfContents => List.unmodifiable(_tableOfContents);

  /// Whether a book is currently open
  bool get hasOpenBook => _currentBook != null;

  /// Current reading progress as a percentage (0-100)
  double get progressPercentage => (_progress?.progress ?? 0.0) * 100;

  /// Current chapter HTML content
  String get currentChapterHtml => _currentChapterHtml;

  /// Current chapter CSS styles
  String get currentChapterCss => _currentChapterCss;

  /// Current chapter images (href -> bytes)
  Map<String, Uint8List> get currentChapterImages => _currentChapterImages;

  /// The reader controller (if EPUB)
  ReaderController? get readerController => _readerController;

  // Methods

  /// Open a book for reading
  ///
  /// Loads the book content, reading progress, bookmarks, and table of contents.
  /// If the book was previously opened, it will resume from the last position.
  /// Books with DRM protection will be blocked from opening.
  ///
  /// [book] The book to open
  Future<void> openBook(Book book) async {
    _isLoading = true;
    _error = null;
    _isDrmBlocked = false;
    notifyListeners();

    // Check for DRM before attempting to open
    if (book.hasDrm) {
      _isDrmBlocked = true;
      _isLoading = false;
      _error = _getDrmErrorMessage(book);
      notifyListeners();
      return;
    }

    try {
      _currentBook = book;

      // Load reading progress
      _progress =
          await _readingProgressRepository.getProgressForBook(book.id) ??
          ReadingProgress(
            id: _uuid.v4(),
            bookId: book.id,
            cfi: '', // Start of book
            progress: 0.0,
            updatedAt: DateTime.now(),
          );

      // Try to fetch progress from Kavita if this book came from a Kavita server
      await _fetchKavitaProgress(book);

      // Load bookmarks
      _bookmarks = await _bookmarkRepository.getBookmarksForBook(book.id);

      // Open the book with the appropriate plugin (checks magic bytes via canHandle)
      final plugin = await _pluginRegistry.getPluginForFile(book.filePath);
      if (plugin != null) {
        _readerController = await plugin.openBook(book.filePath);

        // Get table of contents from the controller
        _tableOfContents = _readerController!.tableOfContents;

        // Set current chapter from progress or start at beginning
        _currentChapterIndex = _getChapterIndexFromCfi(_progress?.cfi);

        // Load the current chapter content
        await _loadChapterContent(_currentChapterIndex);
      } else {
        // No plugin found for this format
        _error = 'No reader plugin found for format: ${book.format}';
        _tableOfContents = [];
        _currentChapterHtml = '';
      }
    } catch (e) {
      _error = 'Failed to open book: ${e.toString()}';
      _currentBook = null;
      _progress = null;
      _bookmarks = [];
      _tableOfContents = [];
      _readerController = null;
      _currentChapterHtml = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get a human-readable DRM error message based on encryption type
  String _getDrmErrorMessage(Book book) {
    switch (book.encryptionType) {
      case EpubEncryptionType.adobeDrm:
        return 'This book is protected by Adobe DRM and cannot be read in ReadWhere. '
            'Please use Adobe Digital Editions or another DRM-compatible reader.';
      case EpubEncryptionType.appleFairPlay:
        return 'This book is protected by Apple FairPlay DRM and can only be read in Apple Books.';
      case EpubEncryptionType.lcp:
        return 'This book is protected by Readium LCP. '
            'A future version of ReadWhere may support LCP decryption.';
      case EpubEncryptionType.unknown:
        return 'This book is protected by an unknown DRM system and cannot be read.';
      default:
        return 'This book has DRM protection and cannot be read.';
    }
  }

  /// Load content for a specific chapter
  Future<void> _loadChapterContent(int chapterIndex) async {
    if (_readerController == null) return;

    try {
      if (_readerController is ReadwhereEpubController) {
        final epubController = _readerController as ReadwhereEpubController;
        _currentChapterHtml = await epubController.getChapterContent(
          chapterIndex,
        );

        // Get CSS styles
        final styles = epubController.getStyles();
        final cssBuffer = StringBuffer();
        for (final entry in styles.entries) {
          cssBuffer.writeln(entry.value);
        }
        _currentChapterCss = cssBuffer.toString();

        // Get images for this chapter
        _currentChapterImages = epubController.getChapterImages(chapterIndex);
      } else if (_readerController is CbrReaderController) {
        final cbrController = _readerController as CbrReaderController;
        _currentChapterHtml = cbrController.getPageContent(chapterIndex);
        _currentChapterCss = '';
        _currentChapterImages = cbrController.getPageImages(chapterIndex);
      } else if (_readerController is CbzReaderController) {
        final cbzController = _readerController as CbzReaderController;
        _currentChapterHtml = cbzController.getPageContent(chapterIndex);
        _currentChapterCss = '';
        _currentChapterImages = cbzController.getPageImages(chapterIndex);
      } else {
        _currentChapterHtml = '<p>Unsupported reader controller type</p>';
        _currentChapterCss = '';
        _currentChapterImages = {};
      }
    } catch (e) {
      _currentChapterHtml = '<p>Error loading chapter: ${e.toString()}</p>';
      _currentChapterImages = {};
    }
  }

  /// Get chapter index from CFI string
  int _getChapterIndexFromCfi(String? cfi) {
    if (cfi == null || cfi.isEmpty) return 0;

    // Try to extract chapter index from CFI
    // Format: "chapter-X-Y" or similar
    final match = RegExp(r'chapter-(\d+)').firstMatch(cfi);
    if (match != null) {
      final index = int.tryParse(match.group(1) ?? '0') ?? 0;
      final maxIndex = _readerController?.totalChapters ?? 1;
      return index.clamp(0, maxIndex - 1);
    }

    return 0;
  }

  /// Close the currently open book
  ///
  /// Saves the current reading progress before closing.
  /// Syncs progress to Kavita if applicable.
  /// Clears all reader state.
  Future<void> closeBook() async {
    if (_currentBook == null) return;

    final bookToClose = _currentBook!;

    // Save progress before closing
    if (_progress != null) {
      await saveProgress();

      // Sync progress to Kavita if this book came from a Kavita server
      await _syncKavitaProgress(bookToClose);
    }

    // Dispose the reader controller
    if (_readerController != null) {
      await _readerController!.dispose();
      _readerController = null;
    }

    _currentBook = null;
    _progress = null;
    _bookmarks = [];
    _tableOfContents = [];
    _currentChapterIndex = 0;
    _currentChapterHtml = '';
    _currentChapterCss = '';
    _currentChapterImages = {};
    _error = null;

    notifyListeners();
  }

  /// Navigate to a specific chapter
  ///
  /// Updates the current chapter index and notifies listeners.
  /// This should be called when the user manually navigates to a chapter.
  ///
  /// [index] The index of the chapter in the table of contents
  Future<void> goToChapter(int index) async {
    final maxChapters =
        _readerController?.totalChapters ?? _tableOfContents.length;
    if (index < 0 || index >= maxChapters) {
      _error = 'Invalid chapter index: $index';
      notifyListeners();
      return;
    }

    _currentChapterIndex = index;
    _error = null;

    // Load the chapter content
    await _loadChapterContent(index);

    // Update progress
    if (_currentBook != null) {
      final progressValue = maxChapters > 0 ? (index + 1) / maxChapters : 0.0;
      final cfi = 'chapter-$index-0';
      _progress = _progress?.copyWith(
        cfi: cfi,
        progress: progressValue,
        updatedAt: DateTime.now(),
      );
    }

    notifyListeners();
  }

  /// Navigate to a specific location in the book
  ///
  /// Updates the reading position using a CFI (Canonical Fragment Identifier).
  /// The progress will be saved automatically.
  ///
  /// [cfi] The location identifier (CFI for EPUB, page number for PDF, etc.)
  Future<void> goToLocation(String cfi) async {
    if (_currentBook == null) {
      _error = 'No book is currently open';
      notifyListeners();
      return;
    }

    try {
      // Calculate progress from CFI (extract chapter info)
      final chapterIndex = _getChapterIndexFromCfi(cfi);
      final maxChapters =
          _readerController?.totalChapters ?? _tableOfContents.length;
      final progressValue = maxChapters > 0
          ? (chapterIndex + 1) / maxChapters
          : 0.0;

      _progress =
          _progress?.copyWith(
            cfi: cfi,
            progress: progressValue,
            updatedAt: DateTime.now(),
          ) ??
          ReadingProgress(
            id: _uuid.v4(),
            bookId: _currentBook!.id,
            cfi: cfi,
            progress: progressValue,
            updatedAt: DateTime.now(),
          );

      await saveProgress();
      _error = null;
    } catch (e) {
      _error = 'Failed to navigate to location: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }

  /// Save the current reading progress
  ///
  /// Persists the progress to the database.
  /// This should be called periodically as the user reads
  /// and before closing the book.
  Future<void> saveProgress() async {
    if (_progress == null || _currentBook == null) return;

    try {
      _progress = await _readingProgressRepository.saveProgress(_progress!);
      _error = null;
    } catch (e) {
      _error = 'Failed to save progress: ${e.toString()}';
    }
    // Don't notify listeners to avoid interrupting reading
  }

  /// Add a bookmark at the current location
  ///
  /// Creates a new bookmark with the provided title at the current
  /// reading position.
  ///
  /// [title] A descriptive title for the bookmark
  /// Returns the created bookmark if successful
  Future<Bookmark?> addBookmark(String title) async {
    if (_currentBook == null || _progress == null) {
      _error = 'No book is currently open';
      notifyListeners();
      return null;
    }

    try {
      final bookmark = Bookmark(
        id: _uuid.v4(),
        bookId: _currentBook!.id,
        chapterId: _currentChapterIndex < _tableOfContents.length
            ? _tableOfContents[_currentChapterIndex].id
            : null,
        cfi: _progress!.cfi,
        title: title,
        createdAt: DateTime.now(),
      );

      final createdBookmark = await _bookmarkRepository.addBookmark(bookmark);
      _bookmarks.add(createdBookmark);
      _bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _error = null;
      notifyListeners();
      return createdBookmark;
    } catch (e) {
      _error = 'Failed to add bookmark: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Remove a bookmark
  ///
  /// Deletes the bookmark from the database and local state.
  ///
  /// [id] The unique identifier of the bookmark to remove
  /// Returns true if the bookmark was successfully removed
  Future<bool> removeBookmark(String id) async {
    try {
      final success = await _bookmarkRepository.deleteBookmark(id);
      if (success) {
        _bookmarks.removeWhere((bookmark) => bookmark.id == id);
        _error = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = 'Failed to remove bookmark: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Navigate to a bookmark
  ///
  /// Jumps to the location saved in the bookmark.
  ///
  /// [bookmark] The bookmark to navigate to
  Future<void> goToBookmark(Bookmark bookmark) async {
    await goToLocation(bookmark.cfi);
  }

  /// Update the reading settings
  ///
  /// Changes the reader appearance and behavior settings.
  /// The new settings will be applied immediately.
  ///
  /// [newSettings] The new settings to apply
  void updateSettings(ReadingSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  /// Update progress while reading
  ///
  /// This should be called as the user scrolls/pages through the book.
  /// Updates the progress without saving to reduce database writes.
  /// Call [saveProgress] periodically to persist changes.
  ///
  /// [cfi] Current location
  /// [progressValue] Progress percentage (0.0 to 1.0)
  void updateProgressWhileReading(String cfi, double progressValue) {
    if (_currentBook == null) return;

    _progress =
        _progress?.copyWith(
          cfi: cfi,
          progress: progressValue,
          updatedAt: DateTime.now(),
        ) ??
        ReadingProgress(
          id: _uuid.v4(),
          bookId: _currentBook!.id,
          cfi: cfi,
          progress: progressValue,
          updatedAt: DateTime.now(),
        );

    // Update chapter index based on CFI
    final newChapterIndex = _getChapterIndexFromCfi(cfi);
    if (newChapterIndex != _currentChapterIndex) {
      _currentChapterIndex = newChapterIndex;
    }

    // Notify listeners to update UI
    notifyListeners();
  }

  /// Navigate to the next chapter
  ///
  /// Advances to the next chapter if available.
  /// Does nothing if already at the last chapter.
  Future<void> nextChapter() async {
    final maxChapters =
        _readerController?.totalChapters ?? _tableOfContents.length;
    if (maxChapters == 0) {
      _error = 'No chapters available';
      notifyListeners();
      return;
    }

    if (_currentChapterIndex < maxChapters - 1) {
      await goToChapter(_currentChapterIndex + 1);
    }
  }

  /// Navigate to the previous chapter
  ///
  /// Goes back to the previous chapter if available.
  /// Does nothing if already at the first chapter.
  Future<void> previousChapter() async {
    final maxChapters =
        _readerController?.totalChapters ?? _tableOfContents.length;
    if (maxChapters == 0) {
      _error = 'No chapters available';
      notifyListeners();
      return;
    }

    if (_currentChapterIndex > 0) {
      await goToChapter(_currentChapterIndex - 1);
    }
  }

  /// Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Kavita Progress Sync Methods

  /// Fetch reading progress from Kavita server if applicable
  ///
  /// If the book came from a Kavita catalog and the server progress is more
  /// recent than the local progress, updates the local progress.
  Future<void> _fetchKavitaProgress(Book book) async {
    final catalogsProvider = _catalogsProvider;
    if (catalogsProvider == null || !book.isFromCatalog) return;

    try {
      final kavitaProgress = await catalogsProvider.fetchProgressFromKavita(
        book,
      );

      if (kavitaProgress != null && kavitaProgress.pageNum > 0) {
        // Convert Kavita page number to progress (0-100 scale)
        final kavitaProgressValue = kavitaProgress.pageNum / 100.0;

        // Use Kavita progress if it's further along (simple heuristic)
        if (kavitaProgressValue > (_progress?.progress ?? 0)) {
          debugPrint('Using Kavita progress: page ${kavitaProgress.pageNum}');
          _progress = _progress?.copyWith(
            progress: kavitaProgressValue.clamp(0.0, 1.0),
            updatedAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch Kavita progress: $e');
      // Non-fatal error, continue with local progress
    }
  }

  /// Sync reading progress to Kavita server if applicable
  ///
  /// Sends the current reading progress to the Kavita server for books
  /// that were downloaded from a Kavita catalog.
  Future<void> _syncKavitaProgress(Book book) async {
    final catalogsProvider = _catalogsProvider;
    final progress = _progress;

    if (catalogsProvider == null || !book.isFromCatalog || progress == null) {
      return;
    }

    try {
      // Calculate page number from progress (0-100 scale for Kavita)
      final pageNum = (progress.progress * 100).round();

      await catalogsProvider.syncProgressToKavita(
        book: book,
        progress: progress.progress,
        pageNum: pageNum,
      );

      debugPrint('Synced progress to Kavita: page $pageNum');
    } catch (e) {
      debugPrint('Failed to sync progress to Kavita: $e');
      // Non-fatal error, progress is still saved locally
    }
  }
}
