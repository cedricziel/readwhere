import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:readwhere_cbz/readwhere_cbz.dart' as cbz;

import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'cbz_reader_controller.dart';

/// CBZ plugin using the readwhere_cbz library.
///
/// This plugin provides support for CBZ (Comic Book ZIP) files,
/// which are ZIP archives containing sequential comic/manga images.
class CbzReaderPlugin implements ReaderPlugin {
  static final _logger = Logger('CbzReaderPlugin');

  @override
  String get id => 'com.readwhere.cbz';

  @override
  String get name => 'CBZ Reader';

  @override
  String get description => 'Supports CBZ (Comic Book ZIP) format comics';

  @override
  List<String> get supportedExtensions => ['cbz'];

  @override
  List<String> get supportedMimeTypes => [
    'application/vnd.comicbook+zip',
    'application/x-cbz',
  ];

  @override
  Future<bool> canHandle(String filePath) async {
    try {
      // Check file extension
      final extension = path.extension(filePath).toLowerCase();
      if (extension != '.cbz') {
        return false;
      }

      // Check if file exists and is readable
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // Check for ZIP signature (PK header)
      final bytes = await file.openRead(0, 4).first;
      if (bytes.length < 4) {
        return false;
      }

      // ZIP files start with "PK" (0x50 0x4B 0x03 0x04)
      if (bytes[0] == 0x50 &&
          bytes[1] == 0x4B &&
          bytes[2] == 0x03 &&
          bytes[3] == 0x04) {
        return true;
      }

      return false;
    } catch (e) {
      _logger.fine('Cannot handle file $filePath: $e');
      return false;
    }
  }

  @override
  Future<BookMetadata> parseMetadata(String filePath) async {
    cbz.CbzReader? reader;
    try {
      _logger.info('Parsing metadata from: $filePath');

      reader = await cbz.CbzReader.open(filePath);
      final book = reader.book;

      // Extract cover image
      Uint8List? coverImage;
      try {
        coverImage = reader.getCoverThumbnail(
          options: cbz.ThumbnailOptions.cover,
        );
        coverImage ??= reader.getCoverBytes();
      } catch (e) {
        _logger.warning('Failed to extract cover: $e');
      }

      // Build table of contents from pages
      final toc = _buildTocFromPages(reader);

      // Get metadata from ComicInfo.xml or MetronInfo.xml if available
      String title = book.title ?? path.basenameWithoutExtension(filePath);
      String author = book.author ?? 'Unknown Author';

      final bookMetadata = BookMetadata(
        title: title,
        author: author,
        description: book.summary,
        publisher: book.publisher,
        language: book.languageISO,
        publishedDate: book.releaseDate,
        coverImage: coverImage,
        tableOfContents: toc,
        isFixedLayout: true, // Comics are always fixed layout
      );

      _logger.info('Parsed metadata: ${bookMetadata.title}');
      return bookMetadata;
    } catch (e, stackTrace) {
      _logger.severe('Error parsing metadata from $filePath', e, stackTrace);
      rethrow;
    } finally {
      reader?.dispose();
    }
  }

  @override
  Future<Uint8List?> extractCover(String filePath) async {
    cbz.CbzReader? reader;
    try {
      _logger.info('Extracting cover from: $filePath');

      reader = await cbz.CbzReader.open(filePath);

      // Try thumbnail first, fall back to full cover
      var cover = reader.getCoverThumbnail(options: cbz.ThumbnailOptions.cover);
      cover ??= reader.getCoverBytes();

      return cover;
    } catch (e, stackTrace) {
      _logger.severe('Error extracting cover from $filePath', e, stackTrace);
      return null;
    } finally {
      reader?.dispose();
    }
  }

  @override
  Future<ReaderController> openBook(String filePath) async {
    try {
      _logger.info('Opening book: $filePath');

      final controller = await CbzReaderController.create(filePath);

      _logger.info('Book opened successfully');
      return controller;
    } catch (e, stackTrace) {
      _logger.severe('Error opening book $filePath', e, stackTrace);
      rethrow;
    }
  }

  /// Build TOC entries from pages.
  List<TocEntry> _buildTocFromPages(cbz.CbzReader reader) {
    final toc = <TocEntry>[];
    final pages = reader.getAllPages();

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
}
