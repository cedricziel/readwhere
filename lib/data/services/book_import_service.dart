import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/book.dart';
import '../../plugins/epub/epub_parser.dart';

/// Service for importing books into the library
///
/// Handles:
/// - Parsing book files to extract metadata
/// - Extracting and caching cover images
/// - Creating Book entities with proper metadata
class BookImportService {
  /// Import an EPUB file and return a Book entity with full metadata
  ///
  /// [filePath] Path to the EPUB file
  /// Returns a Book entity with extracted metadata and cached cover
  ///
  /// The EPUB file is copied into the app's sandbox to ensure
  /// persistent access (macOS sandbox permissions are temporary for
  /// user-selected files).
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
      // Try to parse the EPUB file for metadata (using internal copy)
      final epubBook = await EpubParser.parseBook(internalPath);

      // Extract metadata
      final metadata = EpubParser.extractMetadata(epubBook);
      title = metadata.title;
      author = metadata.author;

      // Save cover image if available
      if (metadata.coverImage != null) {
        coverPath = await _saveCoverImage(bookId, metadata.coverImage!);
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
      String bookId, String originalPath, Uint8List bytes) async {
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

  /// Save cover image to app's cache directory
  ///
  /// Returns the path where the cover was saved
  Future<String?> _saveCoverImage(String bookId, Uint8List imageData) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final coversDir = Directory(p.join(appDir.path, 'covers'));

      // Create covers directory if it doesn't exist
      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }

      // Determine image format from magic bytes
      final extension = _getImageExtension(imageData);
      final coverPath = p.join(coversDir.path, '$bookId$extension');

      // Write cover image to file
      final coverFile = File(coverPath);
      await coverFile.writeAsBytes(imageData);

      return coverPath;
    } catch (e) {
      // Return null if cover saving fails - not critical
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
    if (data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47) {
      return '.png';
    }

    // Check for GIF
    if (data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46) {
      return '.gif';
    }

    // Check for WebP
    if (data.length >= 12 &&
        data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46 &&
        data[8] == 0x57 && data[9] == 0x45 && data[10] == 0x42 && data[11] == 0x50) {
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
}
