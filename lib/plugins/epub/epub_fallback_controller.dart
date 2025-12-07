import 'dart:async';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import '../../domain/entities/toc_entry.dart';
import '../reader_content.dart';
import '../reader_controller.dart';
import '../search_result.dart';
import 'epub_fallback_reader.dart';

/// Fallback controller for reading EPUB files when epubx fails
/// Uses the archive package directly to parse EPUBs
class EpubFallbackController implements ReaderController {
  static final _logger = Logger('EpubFallbackController');

  final EpubFallbackReader _reader;
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

  EpubFallbackController._({
    required EpubFallbackReader reader,
    required this.filePath,
  }) : _reader = reader;

  /// Create and initialize a fallback controller
  static Future<EpubFallbackController> create(String filePath) async {
    _logger.info('Creating fallback controller for: $filePath');

    final reader = await EpubFallbackReader.parse(filePath);
    final controller = EpubFallbackController._(
      reader: reader,
      filePath: filePath,
    );

    await controller.initialize();
    return controller;
  }

  /// Initialize the controller
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.warning('Controller already initialized');
      return;
    }

    try {
      _logger.info('Initializing fallback EPUB reader controller');

      // Generate book ID from file path
      _bookId = filePath.hashCode.toString();

      // Build table of contents from spine items
      _tableOfContents = _buildTableOfContents();

      _isInitialized = true;
      _logger.info(
        'Fallback controller initialized with ${_reader.chapterCount} chapters',
      );
    } catch (e, stackTrace) {
      _logger.severe('Error initializing fallback controller', e, stackTrace);
      rethrow;
    }
  }

  List<TocEntry> _buildTableOfContents() {
    final toc = <TocEntry>[];
    for (var i = 0; i < _reader.chapterCount; i++) {
      toc.add(TocEntry(
        id: 'chapter_$i',
        title: 'Chapter ${i + 1}',
        href: 'chapter_$i',
        level: 0,
      ));
    }
    return toc;
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

    if (index < 0 || index >= _reader.chapterCount) {
      throw ArgumentError(
          'Chapter index $index out of bounds (0-${_reader.chapterCount - 1})');
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

      // Simple CFI parsing - extract spine position
      final match = RegExp(r'/(\d+)').firstMatch(cfi);
      if (match != null) {
        final spinePosition = int.tryParse(match.group(1) ?? '') ?? 0;
        if (spinePosition >= 0 && spinePosition < _reader.chapterCount) {
          _currentChapterIndex = spinePosition;
          _updateProgress();
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

  /// Get the content of a specific chapter
  Future<String> getChapterContent(int index) async {
    _ensureInitialized();
    _ensureNotClosed();

    if (index < 0 || index >= _reader.chapterCount) {
      throw ArgumentError(
          'Chapter index $index out of bounds (0-${_reader.chapterCount - 1})');
    }

    try {
      _logger.fine('Getting content for chapter $index');
      final content = _reader.getChapterContent(index);

      if (content == null) {
        return '<p>Unable to load chapter content</p>';
      }

      // Clean the HTML content
      return _cleanHtmlContent(content);
    } catch (e, stackTrace) {
      _logger.severe('Error getting chapter content for index $index', e,
          stackTrace);
      rethrow;
    }
  }

  /// Clean HTML content for safe rendering
  String _cleanHtmlContent(String html) {
    // Remove script tags
    var cleaned = html.replaceAll(
        RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '');

    // Remove event handlers (onclick, onload, etc.)
    cleaned = cleaned.replaceAll(
        RegExp(r'\s+on\w+\s*=\s*"[^"]*"', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(
        RegExp(r"\s+on\w+\s*=\s*'[^']*'", caseSensitive: false), '');

    return cleaned;
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

      for (var i = 0; i < _reader.chapterCount; i++) {
        final content = _reader.getChapterContent(i);
        if (content == null) continue;

        // Remove HTML tags for text search
        final plainText = _stripHtmlTags(content);
        final lowerText = plainText.toLowerCase();

        // Find all occurrences
        var startIndex = 0;
        while (true) {
          final index = lowerText.indexOf(searchTerm, startIndex);
          if (index == -1) break;

          // Extract context around the match
          final contextStart = (index - 100).clamp(0, plainText.length);
          final contextEnd =
              (index + searchTerm.length + 100).clamp(0, plainText.length);
          var context = plainText.substring(contextStart, contextEnd);

          if (contextStart > 0) context = '...$context';
          if (contextEnd < plainText.length) context = '$context...';

          final cfi = 'epubcfi(/6/$i!/4/1:$index)';

          results.add(SearchResult(
            chapterId: 'chapter_$i',
            chapterTitle: 'Chapter ${i + 1}',
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

  String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  String? getCurrentCfi() {
    _ensureInitialized();
    return _currentCfi ?? 'epubcfi(/6/$_currentChapterIndex!/4/1:0)';
  }

  @override
  Future<void> dispose() async {
    if (_isClosed) {
      _logger.fine('Controller already closed');
      return;
    }

    try {
      _logger.info('Disposing fallback reader controller');
      await _contentController.close();
      _isClosed = true;
    } catch (e, stackTrace) {
      _logger.severe('Error disposing controller', e, stackTrace);
      rethrow;
    }
  }

  /// Get the cover image if available
  Uint8List? getCover() {
    return _reader.getCover();
  }

  /// Get metadata about the EPUB
  Map<String, dynamic> getMetadata() {
    _ensureInitialized();

    return {
      'title': _reader.title,
      'author': _reader.author,
      'totalChapters': _reader.chapterCount,
      'hasTableOfContents': _tableOfContents.isNotEmpty,
    };
  }

  /// Update reading progress based on current chapter
  void _updateProgress() {
    if (_reader.chapterCount == 0) {
      _progress = 0.0;
      return;
    }

    _progress = (_currentChapterIndex + 1) / _reader.chapterCount;
    _progress = _progress.clamp(0.0, 1.0);
  }

  /// Emit current chapter content to the content stream
  Future<void> _emitContent() async {
    if (_contentController.isClosed) return;

    try {
      final htmlContent = await getChapterContent(_currentChapterIndex);
      final chapterTitle = 'Chapter ${_currentChapterIndex + 1}';
      final chapterId = 'chapter_$_currentChapterIndex';

      final content = ReaderContent(
        chapterId: chapterId,
        chapterTitle: chapterTitle,
        htmlContent: htmlContent,
        cssContent: '',
        images: const {},
      );

      _contentController.add(content);
    } catch (e, stackTrace) {
      _logger.severe('Error emitting content', e, stackTrace);
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('Controller not initialized. Call initialize() first.');
    }
  }

  void _ensureNotClosed() {
    if (_isClosed) {
      throw StateError('Controller is closed');
    }
  }
}
