import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:readwhere_cbr/readwhere_cbr.dart' as cbr;

import '../../domain/entities/toc_entry.dart';
import '../reader_content.dart';
import '../reader_controller.dart';
import '../search_result.dart';

/// Reader controller for CBR comic books.
///
/// Implements [ReaderController] to provide page navigation
/// and content streaming for CBR files. Each "chapter" represents
/// a page in the comic.
class CbrReaderController implements ReaderController {
  static final _logger = Logger('CbrReaderController');

  final cbr.CbrReader _reader;
  final String filePath;

  late String _bookId;
  late List<TocEntry> _tableOfContents;

  int _currentPageIndex = 0;
  double _progress = 0.0;

  final StreamController<ReaderContent> _contentController =
      StreamController<ReaderContent>.broadcast();

  bool _isInitialized = false;
  bool _isClosed = false;

  CbrReaderController._({required cbr.CbrReader reader, required this.filePath})
    : _reader = reader;

  /// Create and initialize a controller.
  static Future<CbrReaderController> create(String filePath) async {
    _logger.info('Creating CbrReaderController for: $filePath');

    final reader = await cbr.CbrReader.open(filePath);
    final controller = CbrReaderController._(
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
      _logger.info('Initializing CbrReaderController');

      // Generate book ID from file path
      _bookId = filePath.hashCode.toString();

      // Build table of contents from pages
      _tableOfContents = _buildTocFromPages();

      _isInitialized = true;
      _logger.info('Controller initialized with ${_reader.pageCount} pages');
    } catch (e, stackTrace) {
      _logger.severe('Error initializing controller', e, stackTrace);
      rethrow;
    }
  }

  /// Build TOC entries from pages.
  List<TocEntry> _buildTocFromPages() {
    final toc = <TocEntry>[];
    final pages = _reader.getAllPages();

    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      toc.add(
        TocEntry(
          id: 'page-$i',
          title: 'Page ${i + 1}',
          href: page.filename,
          level: 0,
        ),
      );
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
    return _reader.pageCount;
  }

  @override
  int get currentChapterIndex {
    _ensureInitialized();
    return _currentPageIndex;
  }

  @override
  double get progress {
    _ensureInitialized();
    return _progress;
  }

  @override
  Stream<ReaderContent> get contentStream => _contentController.stream;

  @override
  bool get isFixedLayout => true;

  @override
  Future<void> goToChapter(int index) async {
    _ensureInitialized();
    _ensureNotClosed();

    if (index < 0 || index >= _reader.pageCount) {
      throw ArgumentError(
        'Page index $index out of bounds (0-${_reader.pageCount - 1})',
      );
    }

    try {
      _logger.info('Navigating to page $index');
      _currentPageIndex = index;
      _updateProgress();
      await _emitContent();
    } catch (e, stackTrace) {
      _logger.severe('Error navigating to page $index', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> goToLocation(String cfi) async {
    _ensureInitialized();
    _ensureNotClosed();

    try {
      _logger.info('Navigating to location: $cfi');

      // Parse simple page-based location format "page-X"
      final pageMatch = RegExp(r'page-(\d+)').firstMatch(cfi);
      if (pageMatch != null) {
        final pageIndex = int.tryParse(pageMatch.group(1) ?? '') ?? 0;
        if (pageIndex >= 0 && pageIndex < _reader.pageCount) {
          _currentPageIndex = pageIndex;
          _updateProgress();
        }
      }

      await _emitContent();
    } catch (e, stackTrace) {
      _logger.severe('Error navigating to location $cfi', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> nextChapter() async {
    _ensureInitialized();
    _ensureNotClosed();

    if (_currentPageIndex < _reader.pageCount - 1) {
      await goToChapter(_currentPageIndex + 1);
    }
  }

  @override
  Future<void> previousChapter() async {
    _ensureInitialized();
    _ensureNotClosed();

    if (_currentPageIndex > 0) {
      await goToChapter(_currentPageIndex - 1);
    }
  }

  @override
  Future<List<SearchResult>> search(String query) async {
    // Comics don't support text search
    _logger.info('Search not supported for CBR files');
    return [];
  }

  @override
  String? getCurrentCfi() {
    _ensureInitialized();
    return 'page-$_currentPageIndex';
  }

  @override
  Future<void> dispose() async {
    if (_isClosed) {
      _logger.fine('Controller already closed');
      return;
    }

    try {
      _logger.info('Disposing CbrReaderController');
      await _contentController.close();
      await _reader.dispose();
      _isClosed = true;
    } catch (e, stackTrace) {
      _logger.severe('Error disposing controller', e, stackTrace);
      rethrow;
    }
  }

  /// Update reading progress based on current page.
  void _updateProgress() {
    if (_reader.pageCount == 0) {
      _progress = 0.0;
      return;
    }

    _progress = (_currentPageIndex + 1) / _reader.pageCount;
    _progress = _progress.clamp(0.0, 1.0);
  }

  /// Emit current page content to the content stream.
  Future<void> _emitContent() async {
    if (_contentController.isClosed) return;

    try {
      final page = _reader.getPage(_currentPageIndex);
      final pageBytes = _reader.getPageBytes(_currentPageIndex);

      // Create HTML wrapper for the image
      String htmlContent;
      final images = <String, Uint8List>{};

      if (pageBytes != null) {
        // Embed image as base64 data URI for immediate display
        final base64Image = base64Encode(pageBytes);
        final mimeType = page.mediaType;

        htmlContent =
            '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      margin: 0;
      padding: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background: #000;
    }
    img {
      max-width: 100%;
      max-height: 100vh;
      object-fit: contain;
    }
  </style>
</head>
<body>
  <img src="data:$mimeType;base64,$base64Image" alt="Page ${_currentPageIndex + 1}">
</body>
</html>
''';

        // Also provide raw image in images map
        images[page.filename] = pageBytes;
      } else {
        htmlContent =
            '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      margin: 0;
      padding: 20px;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background: #1a1a1a;
      color: #fff;
      font-family: system-ui, sans-serif;
    }
  </style>
</head>
<body>
  <p>Failed to load page ${_currentPageIndex + 1}</p>
</body>
</html>
''';
      }

      final content = ReaderContent(
        chapterId: 'page-$_currentPageIndex',
        chapterTitle: 'Page ${_currentPageIndex + 1}',
        htmlContent: htmlContent,
        cssContent: '',
        images: images,
      );

      _contentController.add(content);
    } catch (e, stackTrace) {
      _logger.severe('Error emitting content', e, stackTrace);
    }
  }

  /// Get the raw image bytes for a specific page.
  ///
  /// This provides direct access to page images for custom rendering.
  Uint8List? getPageBytes(int index) {
    _ensureInitialized();

    if (index < 0 || index >= _reader.pageCount) {
      return null;
    }

    return _reader.getPageBytes(index);
  }

  /// Get HTML content for a specific page.
  ///
  /// Returns the page as an HTML document with embedded base64 image.
  String getPageContent(int index) {
    _ensureInitialized();

    if (index < 0 || index >= _reader.pageCount) {
      return '<p>Page not found</p>';
    }

    final page = _reader.getPage(index);
    final pageBytes = _reader.getPageBytes(index);

    if (pageBytes == null) {
      return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      margin: 0;
      padding: 20px;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background: #1a1a1a;
      color: #fff;
      font-family: system-ui, sans-serif;
    }
  </style>
</head>
<body>
  <p>Failed to load page ${index + 1}</p>
</body>
</html>
''';
    }

    final base64Image = base64Encode(pageBytes);
    final mimeType = page.mediaType;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      margin: 0;
      padding: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background: #000;
    }
    img {
      max-width: 100%;
      max-height: 100vh;
      object-fit: contain;
    }
  </style>
</head>
<body>
  <img src="data:$mimeType;base64,$base64Image" alt="Page ${index + 1}">
</body>
</html>
''';
  }

  /// Get all images for the current page (for compatibility with reader UI).
  Map<String, Uint8List> getPageImages(int index) {
    _ensureInitialized();

    if (index < 0 || index >= _reader.pageCount) {
      return {};
    }

    final page = _reader.getPage(index);
    final pageBytes = _reader.getPageBytes(index);

    if (pageBytes == null) return {};

    return {page.filename: pageBytes};
  }

  /// Get page metadata.
  cbr.ComicPage? getPageInfo(int index) {
    _ensureInitialized();

    if (index < 0 || index >= _reader.pageCount) {
      return null;
    }

    return _reader.getPage(index);
  }

  /// Get a thumbnail for a specific page.
  Uint8List? getPageThumbnail(int index, {cbr.ThumbnailOptions? options}) {
    _ensureInitialized();

    if (index < 0 || index >= _reader.pageCount) {
      return null;
    }

    return _reader.getThumbnail(index, options: options);
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
