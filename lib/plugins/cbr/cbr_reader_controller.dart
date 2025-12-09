import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';
import 'package:readwhere_cbr/readwhere_cbr.dart' as cbr;
import 'package:readwhere_panel_detection/readwhere_panel_detection.dart';

import 'package:readwhere_plugin/readwhere_plugin.dart';

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

  // Panel detection state
  final Map<int, List<Panel>> _panelCache = {};
  int _currentPanelIndex = 0;
  bool _panelModeEnabled = false;
  ReadingDirection _readingDirection = ReadingDirection.leftToRight;

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

  // ============================================================
  // Panel Detection and Navigation
  // ============================================================

  /// Whether panel mode is enabled.
  bool get panelModeEnabled => _panelModeEnabled;

  /// Current panel index within the current page.
  int get currentPanelIndex => _currentPanelIndex;

  /// Current reading direction for panel sorting.
  ReadingDirection get readingDirection => _readingDirection;

  /// Enable or disable panel mode.
  void setPanelMode(bool enabled) {
    _panelModeEnabled = enabled;
    if (enabled) {
      _currentPanelIndex = 0;
    }
    _logger.info('Panel mode ${enabled ? "enabled" : "disabled"}');
  }

  /// Set the reading direction for panel sorting.
  void setReadingDirection(ReadingDirection direction) {
    if (_readingDirection != direction) {
      _readingDirection = direction;
      // Clear cache to re-sort panels
      _panelCache.clear();
      _logger.info('Reading direction set to $direction');
    }
  }

  /// Detect panels for a specific page.
  ///
  /// Results are cached for efficiency.
  List<Panel> detectPanels(int pageIndex) {
    _ensureInitialized();

    if (pageIndex < 0 || pageIndex >= _reader.pageCount) {
      return [];
    }

    // Check cache first
    if (_panelCache.containsKey(pageIndex)) {
      return _panelCache[pageIndex]!;
    }

    final pageBytes = _reader.getPageBytes(pageIndex);
    if (pageBytes == null) {
      return [];
    }

    final detector = PanelDetector(
      options: PanelDetectionOptions(
        readingDirection: _readingDirection,
        minPanelAreaFraction: 0.02,
        maxPanelAreaFraction: 0.90,
      ),
    );

    final result = detector.detect(pageBytes);

    if (result.success && result.panels.isNotEmpty) {
      _panelCache[pageIndex] = result.panels;
      _logger.info(
        'Detected ${result.panels.length} panels on page $pageIndex',
      );
      return result.panels;
    }

    // Return empty list if detection failed or no panels found
    _panelCache[pageIndex] = [];
    return [];
  }

  /// Get the number of panels on a page.
  int getPanelCount(int pageIndex) {
    final panels = detectPanels(pageIndex);
    return panels.length;
  }

  /// Get the current panel, or null if not in panel mode or no panels.
  Panel? getCurrentPanel() {
    if (!_panelModeEnabled) return null;

    final panels = detectPanels(_currentPageIndex);
    if (panels.isEmpty || _currentPanelIndex >= panels.length) {
      return null;
    }

    return panels[_currentPanelIndex];
  }

  /// Get all panels for the current page.
  List<Panel> getCurrentPagePanels() {
    return detectPanels(_currentPageIndex);
  }

  /// Navigate to a specific panel on the current page.
  void goToPanel(int panelIndex) {
    _ensureInitialized();

    final panels = detectPanels(_currentPageIndex);
    if (panels.isEmpty) return;

    _currentPanelIndex = panelIndex.clamp(0, panels.length - 1);
    _logger.info('Navigated to panel $_currentPanelIndex');
  }

  /// Navigate to the next panel.
  ///
  /// If at the last panel, advances to the first panel of the next page.
  /// Returns true if navigation was successful.
  Future<bool> nextPanel() async {
    _ensureInitialized();
    _ensureNotClosed();

    if (!_panelModeEnabled) {
      await nextChapter();
      return true;
    }

    final panels = detectPanels(_currentPageIndex);

    if (panels.isEmpty) {
      // No panels detected, just go to next page
      if (_currentPageIndex < _reader.pageCount - 1) {
        await goToChapter(_currentPageIndex + 1);
        _currentPanelIndex = 0;
        return true;
      }
      return false;
    }

    if (_currentPanelIndex < panels.length - 1) {
      // Go to next panel on same page
      _currentPanelIndex++;
      _logger.info('Moved to panel $_currentPanelIndex');
      return true;
    } else {
      // Go to first panel of next page
      if (_currentPageIndex < _reader.pageCount - 1) {
        await goToChapter(_currentPageIndex + 1);
        _currentPanelIndex = 0;
        return true;
      }
      return false;
    }
  }

  /// Navigate to the previous panel.
  ///
  /// If at the first panel, goes to the last panel of the previous page.
  /// Returns true if navigation was successful.
  Future<bool> previousPanel() async {
    _ensureInitialized();
    _ensureNotClosed();

    if (!_panelModeEnabled) {
      await previousChapter();
      return true;
    }

    if (_currentPanelIndex > 0) {
      // Go to previous panel on same page
      _currentPanelIndex--;
      _logger.info('Moved to panel $_currentPanelIndex');
      return true;
    } else {
      // Go to last panel of previous page
      if (_currentPageIndex > 0) {
        await goToChapter(_currentPageIndex - 1);
        final panels = detectPanels(_currentPageIndex);
        _currentPanelIndex = panels.isEmpty ? 0 : panels.length - 1;
        return true;
      }
      return false;
    }
  }

  /// Get cropped image bytes for a specific panel.
  ///
  /// Returns null if the panel doesn't exist or image processing fails.
  Uint8List? getPanelImage(int pageIndex, int panelIndex) {
    _ensureInitialized();

    final panels = detectPanels(pageIndex);
    if (panels.isEmpty || panelIndex >= panels.length) {
      return null;
    }

    final pageBytes = _reader.getPageBytes(pageIndex);
    if (pageBytes == null) {
      return null;
    }

    try {
      final image = img.decodeImage(pageBytes);
      if (image == null) {
        return null;
      }

      final panel = panels[panelIndex];

      // Crop the image to the panel bounds
      final cropped = img.copyCrop(
        image,
        x: panel.x.clamp(0, image.width - 1),
        y: panel.y.clamp(0, image.height - 1),
        width: panel.width.clamp(1, image.width - panel.x),
        height: panel.height.clamp(1, image.height - panel.y),
      );

      // Encode back to PNG
      return Uint8List.fromList(img.encodePng(cropped));
    } catch (e) {
      _logger.warning('Failed to crop panel image: $e');
      return null;
    }
  }

  /// Get cropped image bytes for the current panel.
  Uint8List? getCurrentPanelImage() {
    if (!_panelModeEnabled) {
      return getPageBytes(_currentPageIndex);
    }

    return getPanelImage(_currentPageIndex, _currentPanelIndex);
  }

  /// Clear the panel cache (e.g., when reading direction changes).
  void clearPanelCache() {
    _panelCache.clear();
    _logger.info('Panel cache cleared');
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
