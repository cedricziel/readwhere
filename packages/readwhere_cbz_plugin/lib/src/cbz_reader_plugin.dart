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
///
/// Implements the unified plugin architecture with [PluginBase] and
/// [ReaderCapability] mixin.
class CbzReaderPlugin extends PluginBase with ReaderCapability {
  late Logger _log;

  @override
  String get id => 'com.readwhere.cbz';

  @override
  String get name => 'CBZ Reader';

  @override
  String get description => 'Supports CBZ (Comic Book ZIP) format comics';

  @override
  String get version => '1.0.0';

  @override
  List<String> get supportedExtensions => ['cbz'];

  @override
  List<String> get supportedMimeTypes => [
    'application/vnd.comicbook+zip',
    'application/x-cbz',
  ];

  @override
  List<String> get capabilityNames => ['ReaderCapability'];

  @override
  Future<void> initialize(PluginContext context) async {
    _log = context.logger;
    _log.info('CBZ plugin initialized');
  }

  @override
  Future<void> dispose() async {
    _log.info('CBZ plugin disposed');
  }

  @override
  Future<bool> canHandleFile(String filePath) async {
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
      _log.fine('Cannot handle file $filePath: $e');
      return false;
    }
  }

  @override
  Future<BookMetadata> parseMetadata(String filePath) async {
    cbz.CbzReader? reader;
    try {
      _log.info('Parsing metadata from: $filePath');

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
        _log.warning('Failed to extract cover: $e');
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

      _log.info('Parsed metadata: ${bookMetadata.title}');
      return bookMetadata;
    } catch (e, stackTrace) {
      _log.severe('Error parsing metadata from $filePath', e, stackTrace);
      rethrow;
    } finally {
      reader?.dispose();
    }
  }

  @override
  Future<Uint8List?> extractCover(String filePath) async {
    cbz.CbzReader? reader;
    try {
      _log.info('Extracting cover from: $filePath');

      reader = await cbz.CbzReader.open(filePath);

      // Try thumbnail first, fall back to full cover
      var cover = reader.getCoverThumbnail(options: cbz.ThumbnailOptions.cover);
      cover ??= reader.getCoverBytes();

      return cover;
    } catch (e, stackTrace) {
      _log.severe('Error extracting cover from $filePath', e, stackTrace);
      return null;
    } finally {
      reader?.dispose();
    }
  }

  @override
  Future<ReaderController> openBook(
    String filePath, {
    Map<String, String>? credentials,
  }) async {
    try {
      _log.info('Opening book: $filePath');

      final controller = await CbzReaderController.create(filePath);

      _log.info('Book opened successfully');
      return controller;
    } catch (e, stackTrace) {
      _log.severe('Error opening book $filePath', e, stackTrace);
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
