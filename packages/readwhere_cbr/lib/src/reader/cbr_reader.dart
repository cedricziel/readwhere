import 'dart:io';
import 'dart:typed_data';

// Reuse types from CBZ package
import 'package:readwhere_cbz/readwhere_cbz.dart';

import '../container/cbr_container.dart';
import '../errors/cbr_exception.dart';

/// Main entry point for reading CBR comic book archives.
///
/// CbrReader provides access to pages, metadata, and thumbnails from a CBR file.
/// Unlike [CbzReader], this extracts the RAR archive to a temp directory.
///
/// ## Basic Usage
///
/// ```dart
/// final reader = await CbrReader.open('comic.cbr');
/// print('Title: ${reader.book.title}');
/// print('Pages: ${reader.pageCount}');
///
/// // Get the cover image
/// final cover = reader.getCoverBytes();
///
/// // Generate a thumbnail
/// final thumbnail = reader.getCoverThumbnail();
///
/// // Access pages
/// for (final page in reader.getAllPages()) {
///   final bytes = reader.getPageBytes(page.index);
///   // ...
/// }
///
/// await reader.dispose();
/// ```
class CbrReader {
  final CbrContainer _container;
  final CbrBook _book;
  final Map<int, Uint8List> _pageCache = {};
  bool _disposed = false;

  CbrReader._(this._container, this._book);

  /// Opens a CBR file from a file path.
  ///
  /// Throws [CbrReadException] if the file cannot be read.
  /// Throws [CbrExtractionException] if extraction fails.
  static Future<CbrReader> open(String filePath, {String? password}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw CbrReadException(
        'File not found: $filePath',
        filePath: filePath,
      );
    }

    final container = await CbrContainer.fromFile(filePath, password: password);
    final book = _parseBook(container);
    return CbrReader._(container, book);
  }

  /// Opens a CBR file from a [File] object.
  ///
  /// Throws [CbrReadException] if the file cannot be read.
  static Future<CbrReader> openFile(File file, {String? password}) async {
    if (!await file.exists()) {
      throw CbrReadException(
        'File not found: ${file.path}',
        filePath: file.path,
      );
    }

    final container =
        await CbrContainer.fromFileObject(file, password: password);
    final book = _parseBook(container);
    return CbrReader._(container, book);
  }

  /// Parses the book from the container.
  static CbrBook _parseBook(CbrContainer container) {
    // Get ordered pages (already sorted by CbrContainer)
    final orderedPaths = container.imagePaths;
    final pages = _buildPages(container, orderedPaths);

    // Try to parse metadata (reuse CBZ parsers)
    ComicInfo? comicInfo;
    MetronInfo? metronInfo;

    // Prefer MetronInfo if both exist (it's more structured)
    if (container.hasMetronInfo) {
      try {
        final xml = container.readMetronInfo();
        if (xml != null) {
          metronInfo = MetronInfoParser.parse(xml);
        }
      } catch (_) {
        // Ignore parsing errors, try ComicInfo next
      }
    }

    if (container.hasComicInfo) {
      try {
        final xml = container.readComicInfo();
        if (xml != null) {
          comicInfo = ComicInfoParser.parse(xml);
        }
      } catch (_) {
        // Ignore parsing errors
      }
    }

    // Build book from metadata
    if (metronInfo != null) {
      return CbrBook.fromMetronInfo(metronInfo, pages).copyWith(
        comicInfo: comicInfo,
      );
    } else if (comicInfo != null) {
      return CbrBook.fromComicInfo(comicInfo, pages);
    } else {
      return CbrBook.pagesOnly(pages);
    }
  }

  /// Builds ComicPage objects from ordered paths.
  static List<ComicPage> _buildPages(
    CbrContainer container,
    List<String> orderedPaths,
  ) {
    final pages = <ComicPage>[];

    for (var i = 0; i < orderedPaths.length; i++) {
      final path = orderedPaths[i];
      final bytes = container.readPageByPath(path);

      // Detect format and dimensions
      ImageDimensions? dimensions;
      String mediaType = 'application/octet-stream';

      if (bytes != null) {
        final format = ImageUtils.detectFormat(bytes);
        mediaType = format.mimeType;
        dimensions = ImageUtils.getDimensionsFast(bytes);
      }

      pages.add(ComicPage(
        index: i,
        filename: path,
        mediaType: mediaType,
        width: dimensions?.width,
        height: dimensions?.height,
      ));
    }

    return pages;
  }

  // ============================================================
  // Public API
  // ============================================================

  /// The parsed book data including metadata.
  CbrBook get book => _book;

  /// Number of pages in the comic.
  int get pageCount => _book.pageCount;

  /// The ComicInfo.xml metadata (if available).
  ComicInfo? get comicInfo => _book.comicInfo;

  /// The MetronInfo.xml metadata (if available).
  MetronInfo? get metronInfo => _book.metronInfo;

  /// The source of the primary metadata.
  MetadataSource get metadataSource => _book.metadataSource;

  /// Gets a page by index.
  ///
  /// Throws [CbrPageNotFoundException] if the index is out of bounds.
  ComicPage getPage(int index) {
    _checkDisposed();
    if (index < 0 || index >= _book.pages.length) {
      throw CbrPageNotFoundException(index);
    }
    return _book.pages[index];
  }

  /// Gets all pages in reading order.
  List<ComicPage> getAllPages() {
    _checkDisposed();
    return List.unmodifiable(_book.pages);
  }

  /// Streams pages one at a time to reduce memory usage.
  Stream<ComicPage> streamPages() async* {
    _checkDisposed();
    for (final page in _book.pages) {
      yield page;
    }
  }

  /// Gets the raw image bytes for a page.
  ///
  /// Results are cached in memory. Use [clearCache] to free memory.
  ///
  /// Throws [CbrPageNotFoundException] if the index is out of bounds.
  Uint8List? getPageBytes(int index) {
    _checkDisposed();
    if (index < 0 || index >= _book.pages.length) {
      throw CbrPageNotFoundException(index);
    }

    // Check cache first
    if (_pageCache.containsKey(index)) {
      return _pageCache[index];
    }

    // Load from container
    final page = _book.pages[index];
    final bytes = _container.readPageByPath(page.filename);
    if (bytes != null) {
      _pageCache[index] = bytes;
    }
    return bytes;
  }

  /// Gets the raw bytes for the cover image.
  ///
  /// Returns null if no cover is available.
  Uint8List? getCoverBytes() {
    _checkDisposed();
    final cover = _book.coverPage;
    if (cover == null) return null;
    return getPageBytes(cover.index);
  }

  /// Generates a thumbnail for a specific page.
  ///
  /// Returns null if the page cannot be read or decoded.
  Uint8List? getThumbnail(int index, {ThumbnailOptions? options}) {
    _checkDisposed();
    final bytes = getPageBytes(index);
    if (bytes == null) return null;

    try {
      return ThumbnailGenerator.generate(
        bytes,
        options ?? ThumbnailOptions.grid,
      );
    } catch (_) {
      return null;
    }
  }

  /// Generates a thumbnail for the cover image.
  ///
  /// Returns null if no cover is available or cannot be decoded.
  Uint8List? getCoverThumbnail({ThumbnailOptions? options}) {
    _checkDisposed();
    final cover = _book.coverPage;
    if (cover == null) return null;
    return getThumbnail(cover.index,
        options: options ?? ThumbnailOptions.cover);
  }

  /// Clears the page cache to free memory.
  void clearCache() {
    _checkDisposed();
    _pageCache.clear();
  }

  /// Disposes the reader and releases resources.
  ///
  /// This cleans up the temp directory used for extraction.
  /// After calling dispose, the reader can no longer be used.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pageCache.clear();
    await _container.close();
  }

  /// Synchronously disposes the reader.
  void disposeSync() {
    if (_disposed) return;
    _disposed = true;
    _pageCache.clear();
    _container.closeSync();
  }

  /// Checks if the reader has been disposed.
  void _checkDisposed() {
    if (_disposed) {
      throw StateError('CbrReader has been disposed');
    }
  }
}

/// Type alias for CBR book (uses same structure as CBZ).
typedef CbrBook = CbzBook;
