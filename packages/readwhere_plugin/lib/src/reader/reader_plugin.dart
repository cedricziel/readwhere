import 'dart:typed_data';

import 'book_metadata.dart';
import 'reader_controller.dart';

/// Abstract interface for reader plugins
///
/// Each plugin handles a specific book format (e.g., EPUB, PDF, CBZ).
/// Plugins are responsible for parsing metadata, extracting covers,
/// and creating reader controllers for their supported formats.
abstract class ReaderPlugin {
  /// Unique identifier for this plugin
  String get id;

  /// Human-readable name of the plugin
  String get name;

  /// Description of what this plugin does
  String get description;

  /// List of file extensions this plugin supports (e.g., ['epub', 'epub3'])
  List<String> get supportedExtensions;

  /// List of MIME types this plugin supports (e.g., ['application/epub+zip'])
  List<String> get supportedMimeTypes;

  /// Check if this plugin can handle the given file
  ///
  /// This method should perform quick validation (e.g., checking file extension
  /// or magic numbers) without fully parsing the file.
  Future<bool> canHandle(String filePath);

  /// Parse metadata from the book file
  ///
  /// This includes title, author, description, cover image, table of contents, etc.
  /// Throws an exception if the file cannot be parsed.
  Future<BookMetadata> parseMetadata(String filePath);

  /// Open the book and return a controller for reading it
  ///
  /// The controller manages navigation, content retrieval, and search.
  /// [credentials] - Optional credentials for encrypted books (e.g., passphrase, password).
  /// Throws an exception if the file cannot be opened.
  Future<ReaderController> openBook(
    String filePath, {
    Map<String, String>? credentials,
  });

  /// Extract the cover image from the book file
  ///
  /// Returns null if no cover image is found.
  /// This is separate from parseMetadata for cases where you only need the cover.
  Future<Uint8List?> extractCover(String filePath);
}
