import 'dart:io';
import 'dart:typed_data';

import '../container/cbz_container.dart';
import '../errors/cbz_exception.dart';
import '../metadata/comic_info/comic_info.dart';
import '../metadata/comic_info/comic_info_parser.dart';
import '../metadata/metron_info/metron_info.dart';
import '../metadata/metron_info/metron_info_parser.dart';
import '../pages/comic_page.dart';
import '../thumbnails/thumbnail_generator.dart';
import '../thumbnails/thumbnail_options.dart';
import '../utils/image_utils.dart';
import 'cbz_book.dart';

/// Main entry point for reading CBZ comic book archives.
///
/// CbzReader provides access to pages, metadata, and thumbnails from a CBZ file.
///
/// ## Basic Usage
///
/// ```dart
/// final reader = await CbzReader.open('comic.cbz');
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
/// reader.dispose();
/// ```
class CbzReader {
  final CbzContainer _container;
  final CbzBook _book;
  final Map<int, Uint8List> _pageCache = {};
  bool _disposed = false;

  CbzReader._(this._container, this._book);

  /// Opens a CBZ file from a file path.
  ///
  /// Throws [CbzReadException] if the file cannot be read.
  static Future<CbzReader> open(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw CbzReadException(
        'File not found: $filePath',
        filePath: filePath,
      );
    }
    final bytes = await file.readAsBytes();
    return openBytes(bytes);
  }

  /// Opens a CBZ file from a [File] object.
  ///
  /// Throws [CbzReadException] if the file cannot be read.
  static Future<CbzReader> openFile(File file) async {
    if (!await file.exists()) {
      throw CbzReadException(
        'File not found: ${file.path}',
        filePath: file.path,
      );
    }
    final bytes = await file.readAsBytes();
    return openBytes(bytes);
  }

  /// Opens a CBZ file from raw bytes.
  ///
  /// This is useful when the CBZ data is already in memory.
  ///
  /// Throws [CbzReadException] if the data is not a valid CBZ archive.
  static CbzReader openBytes(Uint8List bytes) {
    try {
      final container = CbzContainer.fromBytes(bytes);
      final book = _parseBook(container);
      return CbzReader._(container, book);
    } catch (e, st) {
      if (e is CbzException) rethrow;
      throw CbzReadException(
        'Failed to open CBZ: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Parses the book from the container.
  static CbzBook _parseBook(CbzContainer container) {
    // Get ordered pages (already sorted by CbzContainer)
    final orderedPaths = container.imagePaths;
    final pages = _buildPages(container, orderedPaths);

    // Try to parse metadata
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
      return CbzBook.fromMetronInfo(metronInfo, pages).copyWith(
        comicInfo: comicInfo,
      );
    } else if (comicInfo != null) {
      return CbzBook.fromComicInfo(comicInfo, pages);
    } else {
      return CbzBook.pagesOnly(pages);
    }
  }

  /// Builds ComicPage objects from ordered paths.
  static List<ComicPage> _buildPages(
    CbzContainer container,
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
  CbzBook get book => _book;

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
  /// Throws [CbzPageNotFoundException] if the index is out of bounds.
  ComicPage getPage(int index) {
    _checkDisposed();
    if (index < 0 || index >= _book.pages.length) {
      throw CbzPageNotFoundException(index);
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
  /// Throws [CbzPageNotFoundException] if the index is out of bounds.
  Uint8List? getPageBytes(int index) {
    _checkDisposed();
    if (index < 0 || index >= _book.pages.length) {
      throw CbzPageNotFoundException(index);
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
  /// After calling dispose, the reader can no longer be used.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _pageCache.clear();
    _container.close();
  }

  /// Checks if the reader has been disposed.
  void _checkDisposed() {
    if (_disposed) {
      throw StateError('CbzReader has been disposed');
    }
  }
}
