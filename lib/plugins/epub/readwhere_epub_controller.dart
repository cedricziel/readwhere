import 'dart:async';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:readwhere_epub/readwhere_epub.dart' as epub;

import '../../domain/entities/toc_entry.dart';
import '../reader_content.dart';
import '../reader_controller.dart';
import '../search_result.dart';

/// Reader controller using the readwhere_epub library.
///
/// Implements [ReaderController] to provide chapter navigation,
/// content streaming, search functionality, and support for
/// fixed-layout EPUBs and media overlays.
class ReadwhereEpubController implements ReaderController {
  static final _logger = Logger('ReadwhereEpubController');

  final epub.EpubReader _reader;
  final String filePath;

  late String _bookId;
  late List<TocEntry> _tableOfContents;

  int _currentChapterIndex = 0;
  String? _currentCfi;
  double _progress = 0.0;

  final StreamController<ReaderContent> _contentController =
      StreamController<ReaderContent>.broadcast();

  bool _isInitialized = false;
  bool _isClosed = false;

  // Fixed-layout and media overlay state
  late bool _isFixedLayout;
  late bool _hasMediaOverlays;
  epub.ViewportDimensions? _viewport;

  ReadwhereEpubController._({
    required epub.EpubReader reader,
    required this.filePath,
  }) : _reader = reader;

  /// Create and initialize a controller.
  static Future<ReadwhereEpubController> create(String filePath) async {
    _logger.info('Creating ReadwhereEpubController for: $filePath');

    final reader = await epub.EpubReader.open(filePath);
    final controller = ReadwhereEpubController._(
      reader: reader,
      filePath: filePath,
    );

    await controller._initialize();
    return controller;
  }

  /// Initialize the controller.
  Future<void> _initialize() async {
    if (_isInitialized) {
      _logger.warning('Controller already initialized');
      return;
    }

    try {
      _logger.info('Initializing ReadwhereEpubController');

      // Generate book ID from identifier or file path
      _bookId = _reader.metadata.identifier.isNotEmpty
          ? _reader.metadata.identifier
          : filePath.hashCode.toString();

      // Build table of contents
      _tableOfContents = _convertTocEntries(_reader.navigation.tableOfContents);

      // If no TOC, create one from spine
      if (_tableOfContents.isEmpty) {
        _tableOfContents = _buildTocFromSpine();
      }

      // Initialize fixed-layout and media overlay state
      _isFixedLayout = _reader.book.isFixedLayout;
      _hasMediaOverlays = _reader.hasMediaOverlays;
      _viewport = _reader.book.renditionProperties.viewport;

      if (_isFixedLayout) {
        _logger.info('Fixed-layout EPUB detected with viewport: $_viewport');
      }
      if (_hasMediaOverlays) {
        _logger.info('Media overlays detected');
      }

      _isInitialized = true;
      _logger.info(
        'Controller initialized with ${_reader.chapterCount} chapters',
      );
    } catch (e, stackTrace) {
      _logger.severe('Error initializing controller', e, stackTrace);
      rethrow;
    }
  }

  /// Build TOC entries from spine when no navigation is available.
  List<TocEntry> _buildTocFromSpine() {
    final toc = <TocEntry>[];
    for (var i = 0; i < _reader.chapterCount; i++) {
      final chapter = _reader.getChapter(i);
      toc.add(
        TocEntry(
          id: chapter.id,
          title: chapter.title ?? 'Chapter ${i + 1}',
          href: chapter.href,
          level: 0,
        ),
      );
    }
    return toc;
  }

  /// Convert readwhere_epub TocEntry list to app TocEntry list.
  List<TocEntry> _convertTocEntries(List<epub.TocEntry> entries) {
    return entries.map((entry) => _convertTocEntry(entry)).toList();
  }

  /// Convert a single TocEntry recursively.
  TocEntry _convertTocEntry(epub.TocEntry entry) {
    return TocEntry(
      id: entry.id,
      title: entry.title,
      href: entry.href,
      level: entry.level,
      children: _convertTocEntries(entry.children),
    );
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
    return _reader.chapterCount;
  }

  @override
  int get currentChapterIndex {
    _ensureInitialized();
    return _currentChapterIndex;
  }

  @override
  double get progress {
    _ensureInitialized();
    return _progress;
  }

  /// Whether this EPUB is a fixed-layout (pre-paginated) book.
  bool get isFixedLayout {
    _ensureInitialized();
    return _isFixedLayout;
  }

  /// Whether this EPUB has media overlays (audio synchronization).
  bool get hasMediaOverlays {
    _ensureInitialized();
    return _hasMediaOverlays;
  }

  /// The viewport dimensions for fixed-layout EPUBs.
  ///
  /// Returns null for reflowable EPUBs or if no viewport is specified.
  epub.ViewportDimensions? get viewport {
    _ensureInitialized();
    return _viewport;
  }

  /// Get the viewport width in logical pixels.
  ///
  /// Returns null if no viewport is specified.
  int? get viewportWidth => _viewport?.width;

  /// Get the viewport height in logical pixels.
  ///
  /// Returns null if no viewport is specified.
  int? get viewportHeight => _viewport?.height;

  /// Get the rendition properties for the current spine item.
  ///
  /// This allows checking per-item rendition overrides.
  epub.SpineItemRendition? getSpineItemRendition(int index) {
    _ensureInitialized();
    if (index < 0 || index >= _reader.chapterCount) {
      return null;
    }
    return _reader.book.spine[index].rendition;
  }

  /// Get the media overlay for a specific chapter, if available.
  epub.MediaOverlay? getMediaOverlay(int chapterIndex) {
    _ensureInitialized();
    if (!_hasMediaOverlays) return null;
    if (chapterIndex < 0 || chapterIndex >= _reader.chapterCount) {
      return null;
    }
    return _reader.getMediaOverlayBySpineIndex(chapterIndex);
  }

  @override
  Stream<ReaderContent> get contentStream => _contentController.stream;

  @override
  Future<void> goToChapter(int index) async {
    _ensureInitialized();
    _ensureNotClosed();

    if (index < 0 || index >= _reader.chapterCount) {
      throw ArgumentError(
        'Chapter index $index out of bounds (0-${_reader.chapterCount - 1})',
      );
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

      // Try to parse as proper EPUB CFI
      final parsedCfi = epub.EpubCfi.tryParse(cfi);
      if (parsedCfi != null) {
        // Valid EPUB CFI - use spine index
        final spineIndex = parsedCfi.spineIndex;
        if (spineIndex >= 0 && spineIndex < _reader.chapterCount) {
          _currentChapterIndex = spineIndex;
          _updateProgress();
        }
      } else {
        // Fallback: try legacy format "chapter-X-Y" or simple index extraction
        final legacyMatch = RegExp(r'chapter-(\d+)').firstMatch(cfi);
        if (legacyMatch != null) {
          final chapterIndex = int.tryParse(legacyMatch.group(1) ?? '') ?? 0;
          if (chapterIndex >= 0 && chapterIndex < _reader.chapterCount) {
            _currentChapterIndex = chapterIndex;
            _updateProgress();
          }
        }
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

    if (_currentChapterIndex < _reader.chapterCount - 1) {
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

  @override
  Future<List<SearchResult>> search(String query) async {
    _ensureInitialized();
    _ensureNotClosed();

    if (query.trim().isEmpty) {
      return [];
    }

    try {
      _logger.info('Searching for: $query');

      // Collect all chapters for search
      final chapters = <epub.EpubChapter>[];
      for (var i = 0; i < _reader.chapterCount; i++) {
        chapters.add(_reader.getChapter(i));
      }

      // Use EpubSearchEngine for advanced search
      final engine = epub.EpubSearchEngine(chapters);
      final results = <SearchResult>[];

      await for (final result in engine.search(
        query,
        options: const epub.SearchOptions(
          caseSensitive: false,
          contextChars: 100,
          maxResults: 200,
        ),
      )) {
        results.add(
          SearchResult(
            chapterId: result.chapterId,
            chapterTitle:
                result.chapterTitle ?? 'Chapter ${result.chapterIndex + 1}',
            text: result.fullContext,
            cfi: result.cfi?.toString() ?? '',
          ),
        );
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
    // Return stored CFI if available, otherwise generate from current position
    if (_currentCfi != null) {
      return _currentCfi;
    }
    // Generate proper EPUB CFI for current chapter
    return epub.EpubCfi.fromSpineIndex(_currentChapterIndex).toString();
  }

  @override
  Future<void> dispose() async {
    if (_isClosed) {
      _logger.fine('Controller already closed');
      return;
    }

    try {
      _logger.info('Disposing ReadwhereEpubController');
      await _contentController.close();
      _reader.clearCache();
      _isClosed = true;
    } catch (e, stackTrace) {
      _logger.severe('Error disposing controller', e, stackTrace);
      rethrow;
    }
  }

  /// Update reading progress based on current chapter.
  void _updateProgress() {
    if (_reader.chapterCount == 0) {
      _progress = 0.0;
      return;
    }

    _progress = (_currentChapterIndex + 1) / _reader.chapterCount;
    _progress = _progress.clamp(0.0, 1.0);
  }

  /// Emit current chapter content to the content stream.
  Future<void> _emitContent() async {
    if (_contentController.isClosed) return;

    try {
      final chapter = _reader.getChapter(_currentChapterIndex);

      // Sanitize HTML to prevent XSS attacks
      final sanitizedHtml = epub.HtmlSanitizer.sanitize(
        chapter.content,
        options: const epub.SanitizeOptions(
          allowStyles: true,
          allowDataImages: true,
        ),
      );

      // Collect CSS from stylesheets
      final cssContent = _collectStylesheets(chapter);

      // Collect images
      final images = _collectImages(chapter);

      final content = ReaderContent(
        chapterId: chapter.id,
        chapterTitle: chapter.title ?? 'Chapter ${_currentChapterIndex + 1}',
        htmlContent: sanitizedHtml,
        cssContent: cssContent,
        images: images,
      );

      _contentController.add(content);
    } catch (e, stackTrace) {
      _logger.severe('Error emitting content', e, stackTrace);
    }
  }

  /// Collect CSS from chapter's referenced stylesheets.
  String _collectStylesheets(epub.EpubChapter chapter) {
    final cssBuffer = StringBuffer();

    for (final href in chapter.stylesheetHrefs) {
      try {
        final stylesheets = _reader.getStylesheets();
        final stylesheet = stylesheets
            .where((s) => s.href.endsWith(href) || href.endsWith(s.href))
            .firstOrNull;

        if (stylesheet != null) {
          cssBuffer.writeln(stylesheet.content);
        }
      } catch (e) {
        _logger.fine('Could not load stylesheet $href: $e');
      }
    }

    return cssBuffer.toString();
  }

  /// Collect images referenced in the chapter.
  Map<String, Uint8List> _collectImages(epub.EpubChapter chapter) {
    final images = <String, Uint8List>{};

    for (final href in chapter.imageHrefs) {
      try {
        final image = _reader.getImage(href);
        if (image != null) {
          images[href] = image.bytes;
        }
      } catch (e) {
        _logger.fine('Could not load image $href: $e');
      }
    }

    return images;
  }

  /// Get the HTML content of a specific chapter.
  ///
  /// This method provides direct access to chapter content for backward
  /// compatibility with providers that don't use the stream-based approach.
  Future<String> getChapterContent(int index) async {
    _ensureInitialized();
    _ensureNotClosed();

    if (index < 0 || index >= _reader.chapterCount) {
      throw ArgumentError(
        'Chapter index $index out of bounds (0-${_reader.chapterCount - 1})',
      );
    }

    try {
      final chapter = _reader.getChapter(index);
      return chapter.content;
    } catch (e, stackTrace) {
      _logger.severe(
        'Error getting chapter content for index $index',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Get all CSS stylesheets as a map of href to content.
  ///
  /// This method provides direct access to stylesheets for backward
  /// compatibility with providers that don't use the stream-based approach.
  Map<String, String> getStyles() {
    _ensureInitialized();

    final styles = <String, String>{};
    try {
      for (final stylesheet in _reader.getStylesheets()) {
        styles[stylesheet.href] = stylesheet.content;
      }
    } catch (e) {
      _logger.fine('Error getting styles: $e');
    }
    return styles;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('Controller not initialized.');
    }
  }

  void _ensureNotClosed() {
    if (_isClosed) {
      throw StateError('Controller is closed');
    }
  }
}
