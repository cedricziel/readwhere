import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:readwhere_pdf/readwhere_pdf.dart' as pdf;
import 'package:readwhere_plugin/readwhere_plugin.dart';

import 'pdf_reader_controller.dart';

/// PDF plugin using the readwhere_pdf library.
///
/// This plugin provides support for PDF files with full reading capabilities
/// including metadata extraction, page navigation, and text selection.
///
/// Implements the unified plugin architecture with [PluginBase] and
/// [ReaderCapability] mixin.
class PdfReaderPlugin extends PluginBase with ReaderCapability {
  late Logger _log;

  @override
  String get id => 'com.readwhere.pdf';

  @override
  String get name => 'PDF Reader';

  @override
  String get description => 'Supports PDF (Portable Document Format) files';

  @override
  String get version => '1.0.0';

  @override
  List<String> get supportedExtensions => ['pdf'];

  @override
  List<String> get supportedMimeTypes => ['application/pdf'];

  @override
  List<String> get capabilityNames => ['ReaderCapability'];

  @override
  Future<void> initialize(PluginContext context) async {
    _log = context.logger;
    _log.info('PDF plugin initialized');
  }

  @override
  Future<void> dispose() async {
    _log.info('PDF plugin disposed');
  }

  @override
  Future<bool> canHandleFile(String filePath) async {
    try {
      // Check file extension
      final extension = path.extension(filePath).toLowerCase();
      if (extension != '.pdf') {
        return false;
      }

      // Check if file exists and is readable
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // Check for PDF signature (%PDF-)
      return await pdf.PdfUtils.isPdfFile(filePath);
    } catch (e) {
      _log.fine('Cannot handle file $filePath: $e');
      return false;
    }
  }

  @override
  Future<BookMetadata> parseMetadata(String filePath) async {
    pdf.PdfReader? reader;
    try {
      _log.info('Parsing metadata from: $filePath');

      reader = await pdf.PdfReader.open(filePath);
      final book = reader.book;

      // Extract cover image (first page as thumbnail)
      Uint8List? coverImage;
      try {
        coverImage = await reader.getCoverImage();
      } catch (e) {
        _log.warning('Failed to extract cover: $e');
      }

      // Build table of contents from outline
      final toc = _buildTocFromOutline(book.outline);

      // Get title from metadata or filename
      String title = book.title ?? path.basenameWithoutExtension(filePath);
      String? author = book.author;

      final bookMetadata = BookMetadata(
        title: title,
        author: author ?? 'Unknown Author',
        description: book.subject,
        coverImage: coverImage,
        tableOfContents: toc,
        isFixedLayout: true, // PDFs are always fixed layout
      );

      _log.info('Parsed metadata: ${bookMetadata.title}');
      return bookMetadata;
    } on pdf.PdfPasswordRequiredException {
      // Return metadata indicating password is required
      _log.info('PDF requires password: $filePath');
      return BookMetadata(
        title: path.basenameWithoutExtension(filePath),
        author: 'Unknown Author',
        encryptionType:
            EpubEncryptionType.unknown, // Use unknown for PDF encryption
        encryptionDescription: 'Password-protected PDF',
        isFixedLayout: true,
      );
    } catch (e, stackTrace) {
      _log.severe('Error parsing metadata from $filePath', e, stackTrace);
      rethrow;
    } finally {
      await reader?.dispose();
    }
  }

  @override
  Future<Uint8List?> extractCover(String filePath) async {
    pdf.PdfReader? reader;
    try {
      _log.info('Extracting cover from: $filePath');

      reader = await pdf.PdfReader.open(filePath);
      return await reader.getPageThumbnail(0);
    } on pdf.PdfPasswordRequiredException {
      _log.info('Cannot extract cover from password-protected PDF');
      return null;
    } catch (e, stackTrace) {
      _log.severe('Error extracting cover from $filePath', e, stackTrace);
      return null;
    } finally {
      await reader?.dispose();
    }
  }

  @override
  Future<ReaderController> openBook(
    String filePath, {
    Map<String, String>? credentials,
  }) async {
    try {
      _log.info('Opening book: $filePath');

      // Check for PDF password in credentials
      final password = credentials?['password'];

      PdfReaderController controller;
      if (password != null) {
        _log.info('Opening with password');
        controller = await PdfReaderController.createWithPassword(
          filePath,
          password,
        );
      } else {
        controller = await PdfReaderController.create(filePath);
      }

      _log.info('Book opened successfully');
      return controller;
    } catch (e, stackTrace) {
      _log.severe('Error opening book $filePath', e, stackTrace);
      rethrow;
    }
  }

  /// Open a password-protected PDF.
  @Deprecated('Use openBook with credentials parameter instead')
  Future<ReaderController> openBookWithPassword(
    String filePath,
    String password,
  ) async {
    return openBook(filePath, credentials: {'password': password});
  }

  /// Build TOC entries from PDF outline.
  List<TocEntry> _buildTocFromOutline(List<pdf.PdfOutlineEntry>? outline) {
    if (outline == null || outline.isEmpty) {
      return [];
    }

    return outline.map((entry) => _convertOutlineEntry(entry)).toList();
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
}
