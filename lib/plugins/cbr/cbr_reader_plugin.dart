import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:readwhere_cbr/readwhere_cbr.dart' as cbr;

import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'cbr_reader_controller.dart';

/// CBR plugin using the readwhere_cbr library.
///
/// This plugin provides support for CBR (Comic Book RAR) files,
/// reusing metadata parsing from the CBZ package.
class CbrReaderPlugin implements ReaderPlugin {
  static final _logger = Logger('CbrReaderPlugin');

  @override
  String get id => 'com.readwhere.cbr';

  @override
  String get name => 'CBR Reader';

  @override
  String get description => 'Supports CBR (Comic Book RAR) format comics';

  @override
  List<String> get supportedExtensions => ['cbr', 'cbz'];

  @override
  List<String> get supportedMimeTypes => [
    'application/vnd.comicbook-rar',
    'application/x-cbr',
  ];

  @override
  Future<bool> canHandle(String filePath) async {
    try {
      // Check file extension - accept both .cbr and .cbz
      // (some servers mislabel RAR files with .cbz extension)
      final extension = path.extension(filePath).toLowerCase();
      if (extension != '.cbr' && extension != '.cbz') {
        return false;
      }

      // Check if file exists and is readable
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // Check for RAR signature - this is the authoritative check
      final bytes = await file.openRead(0, 7).first;
      if (bytes.length < 7) {
        return false;
      }

      // RAR files start with "Rar!" (0x52 0x61 0x72 0x21)
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x61 &&
          bytes[2] == 0x72 &&
          bytes[3] == 0x21) {
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
    cbr.CbrReader? reader;
    try {
      _logger.info('Parsing metadata from: $filePath');

      reader = await cbr.CbrReader.open(filePath);
      final book = reader.book;

      // Extract cover image
      Uint8List? coverImage;
      try {
        coverImage = reader.getCoverThumbnail(
          options: cbr.ThumbnailOptions.cover,
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
      await reader?.dispose();
    }
  }

  @override
  Future<Uint8List?> extractCover(String filePath) async {
    cbr.CbrReader? reader;
    try {
      _logger.info('Extracting cover from: $filePath');

      reader = await cbr.CbrReader.open(filePath);
      _logger.info('CBR reader opened, ${reader.pageCount} pages found');

      // Try thumbnail first, fall back to full cover
      var cover = reader.getCoverThumbnail(options: cbr.ThumbnailOptions.cover);
      _logger.info('Cover thumbnail result: ${cover?.length ?? 0} bytes');

      cover ??= reader.getCoverBytes();
      _logger.info('Cover bytes result: ${cover?.length ?? 0} bytes');

      return cover;
    } catch (e, stackTrace) {
      _logger.severe(
        'Error extracting cover from $filePath: $e',
        e,
        stackTrace,
      );
      return null;
    } finally {
      await reader?.dispose();
    }
  }

  @override
  Future<ReaderController> openBook(String filePath) async {
    try {
      _logger.info('Opening book: $filePath');

      final controller = await CbrReaderController.create(filePath);

      _logger.info('Book opened successfully');
      return controller;
    } catch (e, stackTrace) {
      _logger.severe('Error opening book $filePath', e, stackTrace);
      rethrow;
    }
  }

  /// Build TOC entries from pages.
  List<TocEntry> _buildTocFromPages(cbr.CbrReader reader) {
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
