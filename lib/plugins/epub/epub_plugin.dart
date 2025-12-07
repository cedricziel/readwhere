import 'dart:io';
import 'dart:typed_data';

import 'package:epubx/epubx.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../../domain/entities/book_metadata.dart';
import '../reader_controller.dart';
import '../reader_plugin.dart';
import 'epub_reader_controller.dart';
import 'epub_utils.dart';

/// Plugin for reading EPUB format books
class EpubPlugin implements ReaderPlugin {
  static final _logger = Logger('EpubPlugin');

  @override
  String get id => 'com.readwhere.epub';

  @override
  String get name => 'EPUB Reader';

  @override
  String get description => 'Supports EPUB 2.0 and EPUB 3.0 format books';

  @override
  List<String> get supportedExtensions => ['epub', 'epub3'];

  @override
  List<String> get supportedMimeTypes => [
        'application/epub+zip',
        'application/epub',
      ];

  @override
  Future<bool> canHandle(String filePath) async {
    try {
      // Check file extension
      final extension = path.extension(filePath).toLowerCase();
      if (extension != '.epub' && extension != '.epub3') {
        return false;
      }

      // Check if file exists and is readable
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // Try to read the file as EPUB (basic validation)
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return false;
      }

      // EPUB files are ZIP archives, check for ZIP signature
      // ZIP files start with PK (0x50 0x4B)
      if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
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
    try {
      _logger.info('Parsing metadata from: $filePath');

      final bytes = await File(filePath).readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);

      // Extract metadata from Schema.Package.Metadata
      final metadata = epubBook.Schema?.Package?.Metadata;
      final title = epubBook.Title ?? metadata?.Titles?.firstOrNull ?? 'Unknown Title';
      final author = epubBook.Author ?? metadata?.Creators?.firstOrNull?.Creator ?? 'Unknown Author';
      final description = metadata?.Description;
      final publisher = metadata?.Publishers?.firstOrNull;
      final language = metadata?.Languages?.firstOrNull;

      // Parse publish date if available
      DateTime? publishedDate;
      final dateString = metadata?.Dates?.firstOrNull?.Date;
      if (dateString != null) {
        try {
          publishedDate = DateTime.parse(dateString);
        } catch (e) {
          _logger.warning('Failed to parse publication date: $e');
        }
      }

      // Extract cover image using utilities
      Uint8List? coverImage;
      try {
        coverImage = EpubUtils.extractCoverImage(epubBook);
      } catch (e) {
        _logger.warning('Failed to extract cover: $e');
      }

      // Build table of contents using utilities
      final toc = EpubUtils.extractTableOfContents(epubBook);

      final bookMetadata = BookMetadata(
        title: title,
        author: author,
        description: description,
        publisher: publisher,
        language: language,
        publishedDate: publishedDate,
        coverImage: coverImage,
        tableOfContents: toc,
      );

      _logger.info('Parsed metadata: $bookMetadata');
      return bookMetadata;
    } catch (e, stackTrace) {
      _logger.severe('Error parsing metadata from $filePath', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Uint8List?> extractCover(String filePath) async {
    try {
      _logger.info('Extracting cover from: $filePath');

      final bytes = await File(filePath).readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);

      return EpubUtils.extractCoverImage(epubBook);
    } catch (e, stackTrace) {
      _logger.severe('Error extracting cover from $filePath', e, stackTrace);
      return null;
    }
  }

  @override
  Future<ReaderController> openBook(String filePath) async {
    try {
      _logger.info('Opening book: $filePath');

      final bytes = await File(filePath).readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);

      final controller = EpubReaderController(
        epubBook: epubBook,
        filePath: filePath,
      );

      await controller.initialize();

      _logger.info('Book opened successfully: ${epubBook.Title}');
      return controller;
    } catch (e, stackTrace) {
      _logger.severe('Error opening book $filePath', e, stackTrace);
      rethrow;
    }
  }
}
