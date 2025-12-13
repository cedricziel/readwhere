import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;

import '../errors/pdf_exceptions.dart';
import '../metadata/pdf_metadata.dart';
import '../navigation/pdf_outline.dart';
import '../pages/page_cache.dart';
import '../pages/pdf_page.dart';
import '../pages/pdf_render_options.dart';
import '../pages/text_block.dart';
import '../utils/pdf_utils.dart';
import 'pdf_book.dart';

/// The main entry point for reading PDF files.
///
/// Use [PdfReader.open] to open a PDF file from a path, or [PdfReader.openBytes]
/// to open from bytes. Use [PdfReader.openWithPassword] for password-protected PDFs.
class PdfReader {
  final pdfrx.PdfDocument _document;
  final String? _filePath;
  final PageCache _cache;

  late final PdfBook _book;
  bool _isDisposed = false;

  PdfReader._({
    required pdfrx.PdfDocument document,
    String? filePath,
    PageCache? cache,
  }) : _document = document,
       _filePath = filePath,
       _cache = cache ?? PageCache();

  /// Opens a PDF file from the given path.
  ///
  /// Throws [PdfReadException] if the file cannot be read.
  /// Throws [PdfParseException] if the file is not a valid PDF.
  /// Throws [PdfPasswordRequiredException] if the PDF requires a password.
  static Future<PdfReader> open(String filePath) async {
    try {
      // Verify file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw PdfReadException('File not found', filePath: filePath);
      }

      // Verify PDF signature
      if (!await PdfUtils.isPdfFile(filePath)) {
        throw PdfParseException('Not a valid PDF file', filePath: filePath);
      }

      // Open with pdfrx
      final document = await pdfrx.PdfDocument.openFile(filePath);

      final reader = PdfReader._(document: document, filePath: filePath);
      await reader._initialize();
      return reader;
    } on PdfException {
      rethrow;
    } on pdfrx.PdfPasswordException {
      throw PdfPasswordRequiredException(filePath: filePath);
    } catch (e) {
      throw PdfReadException(
        'Failed to open PDF file',
        filePath: filePath,
        cause: e,
      );
    }
  }

  /// Opens a PDF file from the given path with a password.
  ///
  /// Throws [PdfIncorrectPasswordException] if the password is wrong.
  static Future<PdfReader> openWithPassword(
    String filePath,
    String password,
  ) async {
    try {
      // Verify file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw PdfReadException('File not found', filePath: filePath);
      }

      // Open with pdfrx and password provider
      final document = await pdfrx.PdfDocument.openFile(
        filePath,
        passwordProvider: () => password,
        firstAttemptByEmptyPassword: false,
      );

      final reader = PdfReader._(document: document, filePath: filePath);
      await reader._initialize();
      return reader;
    } on PdfException {
      rethrow;
    } on pdfrx.PdfPasswordException {
      throw PdfIncorrectPasswordException(filePath: filePath);
    } catch (e) {
      throw PdfReadException(
        'Failed to open PDF file',
        filePath: filePath,
        cause: e,
      );
    }
  }

  /// Opens a PDF from bytes.
  ///
  /// Throws [PdfParseException] if the bytes are not a valid PDF.
  /// Throws [PdfPasswordRequiredException] if the PDF requires a password.
  static Future<PdfReader> openBytes(Uint8List bytes) async {
    try {
      // Verify PDF signature
      if (!PdfUtils.isPdfBytes(bytes)) {
        throw const PdfParseException('Not a valid PDF file');
      }

      // Open with pdfrx
      final document = await pdfrx.PdfDocument.openData(bytes);

      final reader = PdfReader._(document: document);
      await reader._initialize();
      return reader;
    } on PdfException {
      rethrow;
    } on pdfrx.PdfPasswordException {
      throw const PdfPasswordRequiredException();
    } catch (e) {
      throw PdfReadException('Failed to open PDF from bytes', cause: e);
    }
  }

  /// Opens a PDF from bytes with a password.
  static Future<PdfReader> openBytesWithPassword(
    Uint8List bytes,
    String password,
  ) async {
    try {
      final document = await pdfrx.PdfDocument.openData(
        bytes,
        passwordProvider: () => password,
        firstAttemptByEmptyPassword: false,
      );

      final reader = PdfReader._(document: document);
      await reader._initialize();
      return reader;
    } on PdfException {
      rethrow;
    } on pdfrx.PdfPasswordException {
      throw const PdfIncorrectPasswordException();
    } catch (e) {
      throw PdfReadException('Failed to open PDF from bytes', cause: e);
    }
  }

  /// Initializes the reader by parsing metadata and page info.
  Future<void> _initialize() async {
    final pages = <PdfPage>[];
    for (var i = 0; i < _document.pages.length; i++) {
      final page = _document.pages[i];
      pages.add(
        PdfPage(
          index: i,
          width: page.width,
          height: page.height,
          rotation: page.rotation.index * 90, // Convert enum index to degrees
        ),
      );
    }

    final outline = await _parseOutline();
    final metadata = _parseMetadata();

    _book = PdfBook(
      metadata: metadata,
      pageCount: _document.pages.length,
      pages: pages,
      outline: outline,
      isEncrypted: _document.isEncrypted,
      requiresPassword:
          false, // We wouldn't have opened it if password was required
    );
  }

  /// Parses metadata from the document.
  ///
  /// Note: pdfrx does not expose PDF metadata (title, author, etc.) directly.
  /// This returns empty metadata. For full metadata extraction, consider
  /// using a native PDF parser or accessing the PDF info dictionary directly.
  PdfMetadata _parseMetadata() {
    // pdfrx doesn't expose PDF document metadata properties
    // Title/author extraction would require parsing the PDF info dictionary
    return const PdfMetadata();
  }

  /// Parses the document outline.
  Future<List<PdfOutlineEntry>?> _parseOutline() async {
    final outline = await _document.loadOutline();
    if (outline.isEmpty) return null;

    return _convertOutlineNodes(outline, 0);
  }

  List<PdfOutlineEntry> _convertOutlineNodes(
    List<pdfrx.PdfOutlineNode> nodes,
    int depth,
  ) {
    return nodes.map((node) {
      return PdfOutlineEntry(
        title: node.title,
        pageIndex: node.dest?.pageNumber != null
            ? node.dest!.pageNumber -
                  1 // Convert to 0-based
            : null,
        children: _convertOutlineNodes(node.children, depth + 1),
        depth: depth,
      );
    }).toList();
  }

  /// The parsed book data.
  PdfBook get book {
    _checkNotDisposed();
    return _book;
  }

  /// The number of pages in the document.
  int get pageCount {
    _checkNotDisposed();
    return _document.pages.length;
  }

  /// The document metadata.
  PdfMetadata get metadata {
    _checkNotDisposed();
    return _book.metadata;
  }

  /// The document outline (table of contents), if available.
  List<PdfOutlineEntry>? get outline {
    _checkNotDisposed();
    return _book.outline;
  }

  /// Whether the document is encrypted.
  bool get isEncrypted {
    _checkNotDisposed();
    return _document.isEncrypted;
  }

  /// The file path, if opened from a file.
  String? get filePath => _filePath;

  /// Renders a page to an image.
  ///
  /// Returns the image as PNG bytes.
  Future<Uint8List> getPageImage(
    int index, {
    PdfRenderOptions options = PdfRenderOptions.standard,
  }) async {
    _checkNotDisposed();
    _checkPageIndex(index);

    // Check cache
    final cacheKey = PageCache.pageKey(index, options.scale);
    final cached = _cache.get(cacheKey);
    if (cached != null) return cached;

    // Render page
    final page = _document.pages[index];

    // Calculate pixel dimensions
    var pixelWidth = (page.width * options.scale).round();
    var pixelHeight = (page.height * options.scale).round();

    // Apply max constraints
    if (options.maxWidth != null && pixelWidth > options.maxWidth!) {
      final ratio = options.maxWidth! / pixelWidth;
      pixelWidth = options.maxWidth!;
      pixelHeight = (pixelHeight * ratio).round();
    }
    if (options.maxHeight != null && pixelHeight > options.maxHeight!) {
      final ratio = options.maxHeight! / pixelHeight;
      pixelHeight = options.maxHeight!;
      pixelWidth = (pixelWidth * ratio).round();
    }

    final image = await page.render(
      width: pixelWidth,
      height: pixelHeight,
      backgroundColor: options.backgroundColor,
      annotationRenderingMode: options.includeAnnotations
          ? pdfrx.PdfAnnotationRenderingMode.annotationAndForms
          : pdfrx.PdfAnnotationRenderingMode.none,
    );

    if (image == null) {
      throw PdfRenderException('Failed to render page', pageIndex: index);
    }

    final png = await image.createImage();
    final byteData = await png.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw PdfRenderException('Failed to encode page image', pageIndex: index);
    }

    final bytes = byteData.buffer.asUint8List();

    // Cache the result
    _cache.put(cacheKey, bytes);

    return bytes;
  }

  /// Gets the cover image (first page as a thumbnail).
  Future<Uint8List?> getCoverImage() async {
    _checkNotDisposed();
    if (pageCount == 0) return null;

    return getPageThumbnail(0);
  }

  /// Gets a thumbnail for a page.
  Future<Uint8List> getPageThumbnail(int index, {int maxWidth = 200}) async {
    _checkNotDisposed();
    _checkPageIndex(index);

    // Check cache
    final cacheKey = PageCache.thumbnailKey(index, maxWidth);
    final cached = _cache.get(cacheKey);
    if (cached != null) return cached;

    // Render thumbnail
    final bytes = await getPageImage(
      index,
      options: PdfRenderOptions(scale: 1.0, maxWidth: maxWidth),
    );

    _cache.put(cacheKey, bytes);
    return bytes;
  }

  /// Gets the dimensions of a page at a given scale.
  Future<PageDimensions> getPageDimensions(
    int index, {
    double scale = 1.0,
  }) async {
    _checkNotDisposed();
    _checkPageIndex(index);

    final page = _document.pages[index];
    return PageDimensions(
      width: (page.width * scale).round(),
      height: (page.height * scale).round(),
    );
  }

  /// Extracts all text from a page.
  Future<String> getPageText(int index) async {
    _checkNotDisposed();
    _checkPageIndex(index);

    final page = _document.pages[index];
    final textPage = await page.loadText();
    return textPage?.fullText ?? '';
  }

  /// Extracts text blocks from a page with position information.
  Future<List<TextBlock>> getTextBlocks(int index) async {
    _checkNotDisposed();
    _checkPageIndex(index);

    final page = _document.pages[index];
    final textPage = await page.loadStructuredText();

    final fullText = textPage.fullText;
    if (fullText.isEmpty) return [];

    final blocks = <TextBlock>[];

    for (final fragment in textPage.fragments) {
      final text = fragment.text;
      final bounds = fragment.bounds;

      blocks.add(
        TextBlock(
          text: text,
          bounds: ui.Rect.fromLTRB(
            bounds.left,
            bounds.top,
            bounds.right,
            bounds.bottom,
          ),
          pageIndex: index,
          startOffset: fragment.index,
          endOffset: fragment.index + fragment.length,
        ),
      );
    }

    return blocks;
  }

  /// Clears the page cache.
  void clearCache() {
    _cache.clear();
  }

  /// Disposes of resources.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _cache.clear();
    _document.dispose();
  }

  void _checkNotDisposed() {
    if (_isDisposed) {
      throw StateError('PdfReader has been disposed');
    }
  }

  void _checkPageIndex(int index) {
    if (index < 0 || index >= pageCount) {
      throw RangeError.range(index, 0, pageCount - 1, 'index');
    }
  }
}
