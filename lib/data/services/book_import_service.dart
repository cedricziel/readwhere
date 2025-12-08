import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:readwhere_epub/readwhere_epub.dart' as epub;

import '../../domain/entities/book.dart';
import '../../domain/entities/import_result.dart';

/// Service for importing books into the library
///
/// Handles:
/// - Parsing book files to extract metadata
/// - Extracting and caching cover images
/// - Creating Book entities with proper metadata
class BookImportService {
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
  /// Uses the main EPUB parser first, falls back to direct archive extraction.
  /// Returns the new cover path if successful, null otherwise.
  ///
  /// [book] The book to extract cover for
  Future<String?> extractCover(Book book) async {
    debugPrint('extractCover - Attempting to extract cover for: ${book.title}');
    debugPrint('extractCover - Book file path: ${book.filePath}');

    // Only support EPUB for now
    if (book.format.toLowerCase() != 'epub') {
      debugPrint('extractCover - Unsupported format: ${book.format}');
      return null;
    }

    final file = File(book.filePath);
    if (!await file.exists()) {
      debugPrint('extractCover - Book file does not exist');
      return null;
    }

    Uint8List? coverImage;

    // Parse EPUB and extract cover using readwhere_epub
    try {
      debugPrint('extractCover - Parsing EPUB...');
      final reader = await epub.EpubReader.open(book.filePath);
      final cover = reader.getCoverImage();
      coverImage = cover?.bytes;
      if (coverImage != null && coverImage.isNotEmpty) {
        debugPrint('extractCover - Found cover (${coverImage.length} bytes)');
      }
    } catch (e) {
      debugPrint('extractCover - EPUB parsing failed: $e');
    }

    // Save the cover if we found one
    if (coverImage != null && coverImage.isNotEmpty) {
      final coverPath = await _saveCoverImage(book.id, coverImage);
      debugPrint('extractCover - Cover saved to: $coverPath');
      return coverPath;
    }

    debugPrint('extractCover - No cover image found in EPUB');
    return null;
  }
}
