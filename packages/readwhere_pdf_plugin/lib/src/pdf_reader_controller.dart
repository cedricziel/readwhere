import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:readwhere_pdf/readwhere_pdf.dart' as pdf;
import 'package:readwhere_plugin/readwhere_plugin.dart';

/// Reader controller for PDF files.
///
/// Implements [ReaderController] to provide page navigation
/// and content streaming for PDF files. Each "chapter" represents
/// a page in the PDF.
class PdfReaderController implements ReaderController {
  static final _logger = Logger('PdfReaderController');

  final pdf.PdfReader _reader;

  /// The file path of the PDF being read.
  final String filePath;

  late String _bookId;
  late List<TocEntry> _tableOfContents;

  int _currentPageIndex = 0;
  double _progress = 0.0;

  final StreamController<ReaderContent> _contentController =
      StreamController<ReaderContent>.broadcast();

  bool _isInitialized = false;
  bool _isClosed = false;

  PdfReaderController._({required pdf.PdfReader reader, required this.filePath})
    : _reader = reader;

  /// Create and initialize a controller.
  static Future<PdfReaderController> create(String filePath) async {
    _logger.info('Creating PdfReaderController for: $filePath');

    final reader = await pdf.PdfReader.open(filePath);
    final controller = PdfReaderController._(
      reader: reader,
      filePath: filePath,
    );

    await controller._initialize();
    return controller;
  }

  /// Create a controller for a password-protected PDF.
  static Future<PdfReaderController> createWithPassword(
    String filePath,
    String password,
  ) async {
    _logger.info('Creating PdfReaderController with password for: $filePath');

    final reader = await pdf.PdfReader.openWithPassword(filePath, password);
    final controller = PdfReaderController._(
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
      _logger.info('Initializing PdfReaderController');

      // Generate book ID from file path
      _bookId = filePath.hashCode.toString();

      // Build table of contents from outline or pages
      _tableOfContents = _buildToc();

      _isInitialized = true;
      _logger.info('Controller initialized with ${_reader.pageCount} pages');
    } catch (e, stackTrace) {
      _logger.severe('Error initializing controller', e, stackTrace);
      rethrow;
    }
  }

  /// Build TOC entries from outline or pages.
  List<TocEntry> _buildToc() {
    final outline = _reader.outline;

    if (outline != null && outline.isNotEmpty) {
      // Use PDF outline
      return outline.map(_convertOutlineEntry).toList();
    }

    // Fall back to page-based TOC
    final toc = <TocEntry>[];
    for (var i = 0; i < _reader.pageCount; i++) {
      toc.add(
        TocEntry(
          id: 'page-$i',
          title: 'Page ${i + 1}',
          href: 'page-$i',
          level: 0,
        ),
      );
    }
    return toc;
  }

  TocEntry _convertOutlineEntry(pdf.PdfOutlineEntry entry) {
    return TocEntry(
      id: entry.pageIndex != null ? 'page-${entry.pageIndex}' : entry.title,
      title: entry.title,
      href: entry.pageIndex != null ? 'page-${entry.pageIndex}' : '',
      level: entry.depth,
      children: entry.children.map(_convertOutlineEntry).toList(),
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
    _ensureInitialized();
    _ensureNotClosed();

    if (query.isEmpty) {
      return [];
    }

    _logger.info('Searching for: $query');
    final results = <SearchResult>[];
    final queryLower = query.toLowerCase();

    // Search through all pages
    for (var i = 0; i < _reader.pageCount; i++) {
      try {
        final pageText = await _reader.getPageText(i);
        final textLower = pageText.toLowerCase();

        var startIndex = 0;
        while (true) {
          final index = textLower.indexOf(queryLower, startIndex);
          if (index == -1) break;

          // Extract context around the match
          final contextStart = (index - 30).clamp(0, pageText.length);
          final contextEnd = (index + query.length + 30).clamp(
            0,
            pageText.length,
          );
          final context = pageText.substring(contextStart, contextEnd);

          results.add(
            SearchResult(
              chapterId: 'page-$i',
              chapterTitle: 'Page ${i + 1}',
              text: context,
              cfi: 'page-$i#$index',
            ),
          );

          startIndex = index + 1;
        }
      } catch (e) {
        _logger.warning('Error searching page $i: $e');
      }
    }

    _logger.info('Found ${results.length} results');
    return results;
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
      _logger.info('Disposing PdfReaderController');
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
      final pageBytes = await _reader.getPageImage(_currentPageIndex);

      // Create HTML wrapper for the image
      final images = <String, Uint8List>{};
      final base64Image = base64Encode(pageBytes);

      final htmlContent =
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
  <img src="data:image/png;base64,$base64Image" alt="Page ${_currentPageIndex + 1}">
</body>
</html>
''';

      // Also provide raw image in images map
      images['page-$_currentPageIndex'] = pageBytes;

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

      // Emit error content
      final errorHtml =
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

      _contentController.add(
        ReaderContent(
          chapterId: 'page-$_currentPageIndex',
          chapterTitle: 'Page ${_currentPageIndex + 1}',
          htmlContent: errorHtml,
          cssContent: '',
          images: const {},
        ),
      );
    }
  }

  /// Get the raw image bytes for a specific page.
  ///
  /// This provides direct access to page images for custom rendering.
  Future<Uint8List?> getPageBytes(int index) async {
    _ensureInitialized();

    if (index < 0 || index >= _reader.pageCount) {
      return null;
    }

    try {
      return await _reader.getPageImage(index);
    } catch (e) {
      _logger.warning('Error getting page bytes: $e');
      return null;
    }
  }

  /// Get HTML content for a specific page.
  ///
  /// Returns the page as an HTML document with embedded base64 image.
  Future<String> getPageContent(int index) async {
    _ensureInitialized();

    if (index < 0 || index >= _reader.pageCount) {
      return '<p>Page not found</p>';
    }

    try {
      final pageBytes = await _reader.getPageImage(index);
      final base64Image = base64Encode(pageBytes);

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
  <img src="data:image/png;base64,$base64Image" alt="Page ${index + 1}">
</body>
</html>
''';
    } catch (e) {
      _logger.warning('Error getting page content: $e');
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
  }

  /// Get page info (dimensions, rotation).
  pdf.PdfPage? getPageInfo(int index) {
    _ensureInitialized();

    if (index < 0 || index >= _reader.pageCount) {
      return null;
    }

    return _reader.book.pages[index];
  }

  /// Get a thumbnail for a specific page.
  Future<Uint8List?> getPageThumbnail(int index, {int maxWidth = 200}) async {
    _ensureInitialized();

    if (index < 0 || index >= _reader.pageCount) {
      return null;
    }

    try {
      return await _reader.getPageThumbnail(index, maxWidth: maxWidth);
    } catch (e) {
      _logger.warning('Error getting thumbnail: $e');
      return null;
    }
  }

  /// Get text content for a specific page.
  Future<String> getPageText(int index) async {
    _ensureInitialized();

    if (index < 0 || index >= _reader.pageCount) {
      return '';
    }

    return await _reader.getPageText(index);
  }

  /// Get text blocks with positions for a specific page.
  Future<List<pdf.TextBlock>> getTextBlocks(int index) async {
    _ensureInitialized();

    if (index < 0 || index >= _reader.pageCount) {
      return [];
    }

    return await _reader.getTextBlocks(index);
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
