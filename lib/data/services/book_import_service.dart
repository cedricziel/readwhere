import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:readwhere_cbr/readwhere_cbr.dart' as cbr;
import 'package:readwhere_cbz/readwhere_cbz.dart' as cbz;
import 'package:readwhere_epub/readwhere_epub.dart' as epub;

import '../../domain/entities/book.dart';
import '../../domain/entities/import_result.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

/// Service for importing books into the library
///
/// Handles:
/// - Parsing book files to extract metadata
/// - Extracting and caching cover images
/// - Creating Book entities with proper metadata
class BookImportService {
  final UnifiedPluginRegistry _pluginRegistry;

  BookImportService({required UnifiedPluginRegistry pluginRegistry})
    : _pluginRegistry = pluginRegistry;

  /// Import an EPUB file with validation and return an ImportResult.
  ///
  /// [filePath] Path to the EPUB file
  /// Returns an ImportResult with the book and any validation warnings
  ///
  /// The EPUB is validated before import. Critical errors prevent import,
  /// while warnings are returned with the successful import.
  Future<ImportResult> importEpubWithValidation(String filePath) async {
    // Validate EPUB structure before importing
    final validator = epub.EpubValidator();
    final validation = await validator.validate(filePath);

    if (!validation.isValid) {
      // Critical errors - can't import
      final errorMessages = validation.errors
          .map((e) => '${e.code}: ${e.message}')
          .join('\n');
      return ImportResult.failed(
        reason: 'Invalid EPUB file',
        details: errorMessages,
      );
    }

    // Collect warnings
    final warnings = validation.warnings.map((w) => w.message).toList();

    // Proceed with import
    try {
      final book = await importEpub(filePath);
      return ImportResult.success(book: book, warnings: warnings);
    } catch (e) {
      return ImportResult.failed(
        reason: 'Import failed',
        details: e.toString(),
      );
    }
  }

  /// Import an EPUB file and return a Book entity with full metadata
  ///
  /// [filePath] Path to the EPUB file
  /// Returns a Book entity with extracted metadata and cached cover
  ///
  /// The EPUB file is copied into the app's sandbox to ensure
  /// persistent access (macOS sandbox permissions are temporary for
  /// user-selected files).
  ///
  /// Note: Use [importEpubWithValidation] for validation support.
  Future<Book> importEpub(String filePath) async {
    // Get file info
    final file = File(filePath);
    final fileSize = await file.length();
    final bookId = DateTime.now().millisecondsSinceEpoch.toString();

    String title = p.basenameWithoutExtension(filePath);
    String author = 'Unknown';
    String? coverPath;
    String? publisher;
    String? description;
    String? language;
    DateTime? publishedDate;
    List<String> subjects = const [];

    // Read the file bytes first (while we still have temporary sandbox access)
    final bytes = await file.readAsBytes();
    debugPrint('Read ${bytes.length} bytes from: $filePath');

    if (bytes.isEmpty) {
      throw Exception('File is empty');
    }

    // Check for ZIP signature (EPUBs are ZIP archives)
    if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
      debugPrint('Valid ZIP/EPUB signature detected');
    } else {
      debugPrint('Warning: File does not have ZIP signature');
    }

    // Copy the file to the app's sandbox for persistent access
    final internalPath = await _copyToLibrary(bookId, filePath, bytes);
    debugPrint('Copied EPUB to library: $internalPath');

    try {
      // Parse EPUB using readwhere_epub library
      final reader = await epub.EpubReader.open(internalPath);
      final metadata = reader.metadata;

      title = metadata.title;
      author = metadata.author ?? 'Unknown';
      publisher = metadata.publisher;
      description = metadata.description;
      language = metadata.language;
      publishedDate = metadata.date;
      subjects = metadata.subjects;

      // Save cover image if available
      final cover = reader.getCoverImage();
      if (cover != null) {
        coverPath = await _saveCoverImage(bookId, cover.bytes);
      }
    } catch (e, stackTrace) {
      // If EPUB parsing fails, we still import the book with basic info
      // The book may still be readable even if metadata extraction fails
      debugPrint('Warning: Could not extract EPUB metadata: $e');
      debugPrint('Stack: $stackTrace');
      debugPrint('Importing with filename-based metadata: $title');
    }

    // Create and return the Book entity with internal path
    return Book(
      id: bookId,
      title: title,
      author: author,
      filePath: internalPath,
      coverPath: coverPath,
      format: 'epub',
      fileSize: fileSize,
      addedAt: DateTime.now(),
      publisher: publisher,
      description: description,
      language: language,
      publishedDate: publishedDate,
      subjects: subjects,
    );
  }

  /// Copy book file to app's library directory
  ///
  /// Returns the path to the copied file
  Future<String> _copyToLibrary(
    String bookId,
    String originalPath,
    Uint8List bytes,
  ) async {
    final appDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory(p.join(appDir.path, 'books'));

    // Create books directory if it doesn't exist
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }

    // Use bookId + original extension for unique filename
    final extension = p.extension(originalPath);
    final newPath = p.join(booksDir.path, '$bookId$extension');

    // Write the file
    final newFile = File(newPath);
    await newFile.writeAsBytes(bytes);

    return newPath;
  }

  /// Import a book based on its file extension
  ///
  /// Currently supports: EPUB
  /// Future support: PDF, MOBI, CBZ, etc.
  Future<Book> importBook(String filePath) async {
    final extension = p.extension(filePath).toLowerCase();

    switch (extension) {
      case '.epub':
        return importEpub(filePath);
      default:
        // For unsupported formats, create a basic Book entry
        return _createBasicBook(filePath);
    }
  }

  /// Save cover image to app's support directory
  ///
  /// Returns the path where the cover was saved
  Future<String?> _saveCoverImage(String bookId, Uint8List imageData) async {
    try {
      // Use Application Support directory for cached/generated content
      // On macOS sandboxed: ~/Library/Containers/{bundle-id}/Data/Library/Application Support/{app}
      final appDir = await getApplicationSupportDirectory();
      debugPrint('Cover save - App support dir: ${appDir.path}');

      final coversDir = Directory(p.join(appDir.path, 'covers'));
      debugPrint('Cover save - Covers dir: ${coversDir.path}');

      // Create covers directory if it doesn't exist
      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
        debugPrint('Cover save - Created covers directory');
      }

      // Determine image format from magic bytes
      final extension = _getImageExtension(imageData);
      final coverPath = p.join(coversDir.path, '$bookId$extension');
      debugPrint('Cover save - Cover path: $coverPath');
      debugPrint('Cover save - Image data size: ${imageData.length} bytes');

      // Write cover image to file
      final coverFile = File(coverPath);
      await coverFile.writeAsBytes(imageData);

      // Verify the file was written
      final exists = await coverFile.exists();
      final size = exists ? await coverFile.length() : 0;
      debugPrint('Cover save - File exists: $exists, size: $size bytes');

      return coverPath;
    } catch (e, stackTrace) {
      // Log the error for debugging
      debugPrint('Cover save - Error: $e');
      debugPrint('Cover save - Stack: $stackTrace');
      return null;
    }
  }

  /// Get image file extension from magic bytes
  String _getImageExtension(Uint8List data) {
    if (data.length < 4) return '.png';

    // Check for JPEG
    if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) {
      return '.jpg';
    }

    // Check for PNG
    if (data[0] == 0x89 &&
        data[1] == 0x50 &&
        data[2] == 0x4E &&
        data[3] == 0x47) {
      return '.png';
    }

    // Check for GIF
    if (data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46) {
      return '.gif';
    }

    // Check for WebP
    if (data.length >= 12 &&
        data[0] == 0x52 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x46 &&
        data[8] == 0x57 &&
        data[9] == 0x45 &&
        data[10] == 0x42 &&
        data[11] == 0x50) {
      return '.webp';
    }

    // Default to PNG
    return '.png';
  }

  /// Create a basic Book entry for unsupported formats
  Future<Book> _createBasicBook(String filePath) async {
    final file = File(filePath);
    final fileSize = await file.exists() ? await file.length() : 0;
    final fileName = p.basenameWithoutExtension(filePath);
    final extension = p.extension(filePath).toLowerCase().replaceFirst('.', '');
    final bookId = DateTime.now().millisecondsSinceEpoch.toString();

    // Copy file to library for persistent access
    final bytes = await file.readAsBytes();
    final internalPath = await _copyToLibrary(bookId, filePath, bytes);

    return Book(
      id: bookId,
      title: fileName,
      author: 'Unknown',
      filePath: internalPath,
      format: extension,
      fileSize: fileSize,
      addedAt: DateTime.now(),
    );
  }

  /// Delete cached cover image for a book
  Future<void> deleteCover(String? coverPath) async {
    if (coverPath == null) return;

    try {
      final file = File(coverPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore errors when deleting covers
    }
  }

  /// Re-extract cover image for an existing book
  ///
  /// Attempts to extract and save the cover from the book file.
  /// Uses the plugin system to find the appropriate handler for the format.
  /// Returns the new cover path if successful, null otherwise.
  ///
  /// [book] The book to extract cover for
  Future<String?> extractCover(Book book) async {
    debugPrint('extractCover - Attempting to extract cover for: ${book.title}');
    debugPrint('extractCover - Book file path: ${book.filePath}');
    debugPrint('extractCover - Book format: ${book.format}');

    final file = File(book.filePath);
    if (!await file.exists()) {
      debugPrint('extractCover - Book file does not exist');
      return null;
    }

    Uint8List? coverImage;

    // Try to find a plugin that can handle this file
    final plugin = await _pluginRegistry.forFile<ReaderCapability>(
      book.filePath,
    );

    if (plugin != null) {
      // Use plugin's extractCover method
      debugPrint('extractCover - Using plugin: ${plugin.name}');
      try {
        coverImage = await plugin.extractCover(book.filePath);
        if (coverImage != null && coverImage.isNotEmpty) {
          debugPrint('extractCover - Found cover (${coverImage.length} bytes)');
        }
      } catch (e) {
        debugPrint('extractCover - Plugin extraction failed: $e');
      }
    } else {
      // Fallback to EPUB-specific extraction for backwards compatibility
      if (book.format.toLowerCase() == 'epub') {
        try {
          debugPrint('extractCover - Fallback: Parsing EPUB...');
          final reader = await epub.EpubReader.open(book.filePath);
          final cover = reader.getCoverImage();
          coverImage = cover?.bytes;
          if (coverImage != null && coverImage.isNotEmpty) {
            debugPrint(
              'extractCover - Found cover (${coverImage.length} bytes)',
            );
          }
        } catch (e) {
          debugPrint('extractCover - EPUB parsing failed: $e');
        }
      } else {
        debugPrint('extractCover - No plugin found for format: ${book.format}');
      }
    }

    // Save the cover if we found one
    if (coverImage != null && coverImage.isNotEmpty) {
      final coverPath = await _saveCoverImage(book.id, coverImage);
      debugPrint('extractCover - Cover saved to: $coverPath');
      return coverPath;
    }

    debugPrint('extractCover - No cover image found');
    return null;
  }

  /// Refresh metadata for an existing book by re-parsing the book file.
  ///
  /// Re-extracts metadata (title, author, publisher, description, etc.)
  /// from the book file and returns an updated Book entity.
  /// The original book ID, file path, and user data (favorites, progress)
  /// are preserved.
  ///
  /// Supports EPUB, CBZ, and CBR formats.
  ///
  /// Returns the updated Book if successful, null if parsing fails.
  ///
  /// [book] The book to refresh metadata for
  Future<Book?> refreshMetadata(Book book) async {
    debugPrint('refreshMetadata - Refreshing metadata for: ${book.title}');
    debugPrint('refreshMetadata - Book file path: ${book.filePath}');
    debugPrint('refreshMetadata - Book format: ${book.format}');

    final file = File(book.filePath);
    if (!await file.exists()) {
      debugPrint('refreshMetadata - Book file does not exist');
      return null;
    }

    final format = book.format.toLowerCase();

    switch (format) {
      case 'epub':
        return _refreshEpubMetadata(book);
      case 'cbz':
        return _refreshCbzMetadata(book);
      case 'cbr':
        return _refreshCbrMetadata(book);
      default:
        debugPrint(
          'refreshMetadata - Format $format not supported for metadata refresh',
        );
        return null;
    }
  }

  /// Refresh metadata for an EPUB book.
  Future<Book?> _refreshEpubMetadata(Book book) async {
    try {
      final reader = await epub.EpubReader.open(book.filePath);
      final metadata = reader.metadata;

      debugPrint('refreshMetadata - Extracted title: ${metadata.title}');
      debugPrint('refreshMetadata - Extracted author: ${metadata.author}');

      // Extract cover if missing
      String? coverPath = book.coverPath;
      if (coverPath == null || coverPath.isEmpty) {
        final cover = reader.getCoverImage();
        if (cover != null) {
          coverPath = await _saveCoverImage(book.id, cover.bytes);
          debugPrint('refreshMetadata - Extracted new cover: $coverPath');
        }
      }

      return book.copyWith(
        title: metadata.title,
        author: metadata.author ?? 'Unknown',
        publisher: metadata.publisher,
        description: metadata.description,
        language: metadata.language,
        publishedDate: metadata.date,
        subjects: metadata.subjects,
        coverPath: coverPath,
      );
    } catch (e, stackTrace) {
      debugPrint('refreshMetadata - Failed to parse EPUB: $e');
      debugPrint('refreshMetadata - Stack: $stackTrace');
      return null;
    }
  }

  /// Refresh metadata for a CBZ book.
  ///
  /// If the file is actually a RAR archive (mislabeled .cbz), falls back
  /// to CBR parsing.
  Future<Book?> _refreshCbzMetadata(Book book) async {
    // Check if the file is actually a RAR archive (mislabeled .cbz)
    final file = File(book.filePath);
    final bytes = await file.readAsBytes();
    if (bytes.length >= 4 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x61 &&
        bytes[2] == 0x72 &&
        bytes[3] == 0x21) {
      // RAR signature detected, use CBR reader
      debugPrint(
        'refreshMetadata - CBZ file is actually RAR, using CBR reader',
      );
      return _refreshCbrMetadata(book);
    }

    try {
      final reader = await cbz.CbzReader.open(book.filePath);
      final cbzBook = reader.book;

      debugPrint('refreshMetadata - Extracted title: ${cbzBook.displayTitle}');
      debugPrint('refreshMetadata - Extracted author: ${cbzBook.author}');
      debugPrint(
        'refreshMetadata - Has ComicInfo: ${cbzBook.comicInfo != null}',
      );
      debugPrint(
        'refreshMetadata - Has MetronInfo: ${cbzBook.metronInfo != null}',
      );

      // Check if we have actual metadata or just defaults
      final hasMetadata =
          cbzBook.comicInfo != null || cbzBook.metronInfo != null;

      // Extract cover if missing
      String? coverPath = book.coverPath;
      if (coverPath == null || coverPath.isEmpty) {
        final coverBytes = reader.getCoverBytes();
        if (coverBytes != null) {
          coverPath = await _saveCoverImage(book.id, coverBytes);
          debugPrint('refreshMetadata - Extracted new cover: $coverPath');
        }
      }

      reader.dispose();

      // If no metadata file was found, preserve existing book info
      // (only update cover if we found one)
      if (!hasMetadata) {
        debugPrint(
          'refreshMetadata - No metadata file found, preserving existing title',
        );
        if (coverPath != null && coverPath != book.coverPath) {
          return book.copyWith(coverPath: coverPath);
        }
        return book; // Return unchanged book
      }

      // Build subjects from genres + tags
      final subjects = [...cbzBook.genres, ...cbzBook.tags];

      return book.copyWith(
        title: cbzBook.displayTitle,
        author: cbzBook.author ?? book.author,
        publisher: cbzBook.publisher,
        description: cbzBook.summary,
        language: cbzBook.languageISO,
        publishedDate: cbzBook.releaseDate,
        subjects: subjects.isNotEmpty ? subjects : null,
        coverPath: coverPath,
      );
    } catch (e, stackTrace) {
      debugPrint('refreshMetadata - Failed to parse CBZ: $e');
      debugPrint('refreshMetadata - Stack: $stackTrace');
      return null;
    }
  }

  /// Refresh metadata for a CBR book.
  Future<Book?> _refreshCbrMetadata(Book book) async {
    try {
      final reader = await cbr.CbrReader.open(book.filePath);
      final cbrBook = reader.book;

      debugPrint('refreshMetadata - Extracted title: ${cbrBook.displayTitle}');
      debugPrint('refreshMetadata - Extracted author: ${cbrBook.author}');
      debugPrint(
        'refreshMetadata - Has ComicInfo: ${cbrBook.comicInfo != null}',
      );
      debugPrint(
        'refreshMetadata - Has MetronInfo: ${cbrBook.metronInfo != null}',
      );

      // Check if we have actual metadata or just defaults
      final hasMetadata =
          cbrBook.comicInfo != null || cbrBook.metronInfo != null;

      // Extract cover if missing
      String? coverPath = book.coverPath;
      if (coverPath == null || coverPath.isEmpty) {
        final coverBytes = reader.getCoverBytes();
        if (coverBytes != null) {
          coverPath = await _saveCoverImage(book.id, coverBytes);
          debugPrint('refreshMetadata - Extracted new cover: $coverPath');
        }
      }

      await reader.dispose();

      // If no metadata file was found, preserve existing book info
      // (only update cover if we found one)
      if (!hasMetadata) {
        debugPrint(
          'refreshMetadata - No metadata file found, preserving existing title',
        );
        if (coverPath != null && coverPath != book.coverPath) {
          return book.copyWith(coverPath: coverPath);
        }
        return book; // Return unchanged book
      }

      // Build subjects from genres + tags
      final subjects = [...cbrBook.genres, ...cbrBook.tags];

      return book.copyWith(
        title: cbrBook.displayTitle,
        author: cbrBook.author ?? book.author,
        publisher: cbrBook.publisher,
        description: cbrBook.summary,
        language: cbrBook.languageISO,
        publishedDate: cbrBook.releaseDate,
        subjects: subjects.isNotEmpty ? subjects : null,
        coverPath: coverPath,
      );
    } catch (e, stackTrace) {
      debugPrint('refreshMetadata - Failed to parse CBR: $e');
      debugPrint('refreshMetadata - Stack: $stackTrace');
      return null;
    }
  }

  /// Refresh metadata for multiple books.
  ///
  /// Returns a map of book IDs to updated Book entities.
  /// Books that fail to refresh are not included in the result.
  ///
  /// [books] The books to refresh metadata for
  /// [onProgress] Optional callback for progress updates (current, total)
  Future<Map<String, Book>> refreshMetadataForBooks(
    List<Book> books, {
    void Function(int current, int total)? onProgress,
  }) async {
    final results = <String, Book>{};
    var current = 0;

    for (final book in books) {
      current++;
      onProgress?.call(current, books.length);

      final updated = await refreshMetadata(book);
      if (updated != null) {
        results[book.id] = updated;
      }
    }

    debugPrint(
      'refreshMetadataForBooks - Refreshed ${results.length}/${books.length} books',
    );
    return results;
  }
}
