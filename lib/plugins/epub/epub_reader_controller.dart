import 'dart:async';
import 'dart:typed_data';

import 'package:epubx/epubx.dart';
import 'package:logging/logging.dart';

import '../../domain/entities/toc_entry.dart';
import '../reader_content.dart';
import '../reader_controller.dart';
import '../search_result.dart';
import 'epub_utils.dart';

/// Controller for reading EPUB format books
class EpubReaderController implements ReaderController {
  static final _logger = Logger('EpubReaderController');

  final EpubBook epubBook;
  final String filePath;

  late String _bookId;
  late List<TocEntry> _tableOfContents;
  late List<EpubChapter> _flatChapters;
  late Map<String, String> _styles;

  int _currentChapterIndex = 0;
  String? _currentCfi;
  double _progress = 0.0;

  final StreamController<ReaderContent> _contentController =
      StreamController<ReaderContent>.broadcast();

  bool _isInitialized = false;
  bool _isClosed = false;

  EpubReaderController({
    required this.epubBook,
    required this.filePath,
  });

  /// Initialize the controller
  /// Must be called before using the controller
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.warning('Controller already initialized');
      return;
    }

    try {
      _logger.info('Initializing EPUB reader controller');

      // Generate book ID from file path
      _bookId = filePath.hashCode.toString();

      // Build table of contents using utilities
      _tableOfContents = EpubUtils.extractTableOfContents(epubBook);

      // Flatten chapters for easier navigation
      _flatChapters = _flattenChapters(epubBook.Chapters ?? []);

      // Extract CSS styles
      _styles = EpubUtils.extractStyles(epubBook);

      _isInitialized = true;
      _logger.info(
        'Controller initialized with ${_flatChapters.length} chapters '
        'and ${_styles.length} CSS files',
      );
    } catch (e, stackTrace) {
      _logger.severe('Error initializing controller', e, stackTrace);
      rethrow;
    }
  }

  @override
  String get bookId {
    _ensureInitialized();
    return _bookId;
  }

  @override
  List<TocEntry> get tableOfContents {
    _ensureInitialized();
    return _tableOfContents;
  }

  @override
  int get totalChapters {
    _ensureInitialized();
    return _flatChapters.length;
  }

  @override
  int get currentChapterIndex {
    _ensureInitialized();
    return _currentChapterIndex;
  }

  String? get currentCfi {
    _ensureInitialized();
    return _currentCfi;
  }

  @override
  double get progress {
    _ensureInitialized();
    return _progress;
  }

  @override
  Stream<ReaderContent> get contentStream => _contentController.stream;

  @override
  Future<void> goToChapter(int index) async {
    _ensureInitialized();
    _ensureNotClosed();

    if (index < 0 || index >= _flatChapters.length) {
      throw ArgumentError('Chapter index $index out of bounds (0-${_flatChapters.length - 1})');
    }

    try {
      _logger.info('Navigating to chapter $index');
      _currentChapterIndex = index;
      _updateProgress();
      await _emitContent();
    } catch (e, stackTrace) {
      _logger.severe('Error navigating to chapter $index', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> goToLocation(String cfi) async {
    _ensureInitialized();
    _ensureNotClosed();

    try {
      _logger.info('Navigating to CFI: $cfi');

      // Parse CFI to extract chapter information
      final cfiData = EpubUtils.parseCfi(cfi);
      final spinePosition = cfiData['spinePosition'] as int;

      // Navigate to the chapter if position is valid
      if (spinePosition >= 0 && spinePosition < _flatChapters.length) {
        _currentChapterIndex = spinePosition;
        _updateProgress();
      }

      _currentCfi = cfi;
      await _emitContent();
    } catch (e, stackTrace) {
      _logger.severe('Error navigating to CFI $cfi', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> nextChapter() async {
    _ensureInitialized();
    _ensureNotClosed();

    if (_currentChapterIndex < _flatChapters.length - 1) {
      await goToChapter(_currentChapterIndex + 1);
    }
  }

  @override
  Future<void> previousChapter() async {
    _ensureInitialized();
    _ensureNotClosed();

    if (_currentChapterIndex > 0) {
      await goToChapter(_currentChapterIndex - 1);
    }
  }

  /// Get the content of a specific chapter
  /// This is a helper method, not part of the ReaderController interface
  Future<String> getChapterContent(int index) async {
    _ensureInitialized();
    _ensureNotClosed();

    if (index < 0 || index >= _flatChapters.length) {
      throw ArgumentError('Chapter index $index out of bounds (0-${_flatChapters.length - 1})');
    }

    try {
      _logger.fine('Getting content for chapter $index');
      final chapter = _flatChapters[index];

      // Get HTML content using utilities
      final content = EpubUtils.getChapterContent(chapter);

      // Clean HTML content for safe rendering
      final cleanedContent = EpubUtils.cleanHtmlContent(content);

      return cleanedContent;
    } catch (e, stackTrace) {
      _logger.severe('Error getting chapter content for index $index', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<SearchResult>> search(String query) async {
    _ensureInitialized();
    _ensureNotClosed();

    if (query.trim().isEmpty) {
      return [];
    }

    try {
      _logger.info('Searching for: $query');
      final results = <SearchResult>[];
      final searchTerm = query.toLowerCase();

      for (var i = 0; i < _flatChapters.length; i++) {
        final chapter = _flatChapters[i];
        final content = EpubUtils.getChapterContent(chapter);

        // Remove HTML tags for text search using utilities
        final plainText = EpubUtils.stripHtmlTags(content);
        final lowerText = plainText.toLowerCase();

        // Find all occurrences
        var startIndex = 0;
        while (true) {
          final index = lowerText.indexOf(searchTerm, startIndex);
          if (index == -1) break;

          // Extract context around the match (100 chars before and after)
          final contextStart = (index - 100).clamp(0, plainText.length);
          final contextEnd = (index + searchTerm.length + 100).clamp(0, plainText.length);
          var context = plainText.substring(contextStart, contextEnd);

          // Add ellipsis if truncated
          if (contextStart > 0) context = '...$context';
          if (contextEnd < plainText.length) context = '$context...';

          // Generate CFI using utilities
          final cfi = EpubUtils.generateCfi(
            chapterId: chapter.Anchor ?? 'chapter_$i',
            spinePosition: i,
            characterOffset: index,
          );

          results.add(SearchResult(
            chapterId: chapter.Anchor ?? 'chapter_$i',
            chapterTitle: chapter.Title ?? 'Chapter ${i + 1}',
            text: context,
            cfi: cfi,
          ));

          startIndex = index + searchTerm.length;
        }
      }

      _logger.info('Found ${results.length} results for query: $query');
      return results;
    } catch (e, stackTrace) {
      _logger.severe('Error searching for "$query"', e, stackTrace);
      return [];
    }
  }

  @override
  String? getCurrentCfi() {
    _ensureInitialized();
    return generateCurrentCfi();
  }

  @override
  Future<void> dispose() async {
    if (_isClosed) {
      _logger.fine('Controller already closed');
      return;
    }

    try {
      _logger.info('Disposing reader controller');
      await _contentController.close();
      _isClosed = true;
    } catch (e, stackTrace) {
      _logger.severe('Error disposing controller', e, stackTrace);
      rethrow;
    }
  }

  /// Get all CSS styles from the EPUB
  /// Returns a map of filename to CSS content
  Map<String, String> getStyles() {
    _ensureInitialized();
    return Map.unmodifiable(_styles);
  }

  /// Get a specific CSS file by name
  /// Returns null if not found
  String? getStyleByName(String fileName) {
    _ensureInitialized();
    return _styles[fileName];
  }

  /// Get an embedded image by reference
  /// The imageRef can be a filename, path, or ID
  /// Returns null if not found
  Uint8List? getEmbeddedImage(String imageRef) {
    _ensureInitialized();
    return EpubUtils.getEmbeddedImage(epubBook, imageRef);
  }

  /// Get all available images in the EPUB
  /// Returns a map of filename to image data
  Map<String, Uint8List> getAllImages() {
    _ensureInitialized();

    try {
      final images = <String, Uint8List>{};
      final epubImages = epubBook.Content?.Images;

      if (epubImages != null) {
        for (final entry in epubImages.entries) {
          final content = entry.value.Content;
          if (content != null && content.isNotEmpty) {
            images[entry.key] = Uint8List.fromList(content);
          }
        }
      }

      return images;
    } catch (e, stackTrace) {
      _logger.severe('Error getting all images', e, stackTrace);
      return {};
    }
  }

  /// Generate a CFI for the current reading position
  /// Useful for bookmarking
  String generateCurrentCfi() {
    _ensureInitialized();

    final chapter = _flatChapters[_currentChapterIndex];
    return EpubUtils.generateCfi(
      chapterId: chapter.Anchor ?? 'chapter_$_currentChapterIndex',
      spinePosition: _currentChapterIndex,
    );
  }

  /// Get metadata about the EPUB
  Map<String, dynamic> getMetadata() {
    _ensureInitialized();

    final metadata = epubBook.Schema?.Package?.Metadata;
    return {
      'title': epubBook.Title ?? 'Unknown',
      'author': epubBook.Author ?? 'Unknown',
      'publisher': metadata?.Publishers?.firstOrNull,
      'language': metadata?.Languages?.firstOrNull,
      'description': metadata?.Description,
      'subjects': metadata?.Subjects ?? [],
      'rights': metadata?.Rights?.firstOrNull,
      'identifier': metadata?.Identifiers?.firstOrNull?.Identifier,
      'totalChapters': _flatChapters.length,
      'hasTableOfContents': _tableOfContents.isNotEmpty,
    };
  }


  /// Flatten nested chapters into a linear list
  List<EpubChapter> _flattenChapters(List<EpubChapter> chapters) {
    final flat = <EpubChapter>[];
    for (final chapter in chapters) {
      flat.add(chapter);
      if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
        flat.addAll(_flattenChapters(chapter.SubChapters!));
      }
    }
    return flat;
  }

  /// Update reading progress based on current chapter
  void _updateProgress() {
    if (_flatChapters.isEmpty) {
      _progress = 0.0;
      return;
    }

    _progress = (_currentChapterIndex + 1) / _flatChapters.length;
    _progress = _progress.clamp(0.0, 1.0);
  }

  /// Emit current chapter content to the content stream
  Future<void> _emitContent() async {
    if (_contentController.isClosed) return;

    try {
      final chapter = _flatChapters[_currentChapterIndex];
      final htmlContent = await getChapterContent(_currentChapterIndex);
      final chapterTitle = chapter.Title ?? 'Chapter ${_currentChapterIndex + 1}';
      final chapterId = chapter.Anchor ?? 'chapter_$_currentChapterIndex';

      // Get CSS styles
      final cssBuffer = StringBuffer();
      for (final entry in _styles.entries) {
        cssBuffer.writeln(entry.value);
      }
      final cssContent = cssBuffer.toString();

      // Get images referenced in this chapter
      final images = <String, Uint8List>{};
      // For now, we'll let the consumer fetch images on demand
      // You could parse the HTML and pre-load referenced images here if needed

      final content = ReaderContent(
        chapterId: chapterId,
        chapterTitle: chapterTitle,
        htmlContent: htmlContent,
        cssContent: cssContent,
        images: images,
      );

      _contentController.add(content);
    } catch (e, stackTrace) {
      _logger.severe('Error emitting content', e, stackTrace);
    }
  }

  /// Ensure controller is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('Controller not initialized. Call initialize() first.');
    }
  }

  /// Ensure controller is not closed
  void _ensureNotClosed() {
    if (_isClosed) {
      throw StateError('Controller is closed');
    }
  }
}
