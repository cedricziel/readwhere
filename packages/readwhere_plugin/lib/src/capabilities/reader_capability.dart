import 'dart:typed_data';

import '../core/plugin_base.dart';
import '../reader/book_metadata.dart';
import '../reader/reader_controller.dart';

/// Capability for reading book files in specific formats.
///
/// Plugins with this capability can parse, display, and navigate
/// through book content (EPUB, CBZ, CBR, PDF, etc.).
///
/// Example:
/// ```dart
/// class EpubPlugin extends PluginBase with ReaderCapability {
///   @override
///   List<String> get supportedExtensions => ['epub', 'epub3'];
///
///   @override
///   List<String> get supportedMimeTypes => [
///     'application/epub+zip',
///     'application/epub',
///   ];
///
///   @override
///   Future<bool> canHandleFile(String filePath) async {
///     // Check for ZIP signature + extension
///     return _hasZipSignature(filePath) &&
///            _hasEpubExtension(filePath);
///   }
///
///   // ... implement other methods
/// }
/// ```
mixin ReaderCapability on PluginBase {
  /// File extensions this reader supports (without leading dot).
  ///
  /// Example: `['epub', 'epub3']`, `['cbz']`, `['pdf']`
  List<String> get supportedExtensions;

  /// MIME types this reader supports.
  ///
  /// Example: `['application/epub+zip']`, `['application/pdf']`
  List<String> get supportedMimeTypes;

  /// Check if this plugin can handle the given file.
  ///
  /// Should perform quick validation (e.g., checking file extension
  /// and magic bytes) without fully parsing the file.
  ///
  /// This is called after extension matching to verify the file is
  /// actually in the expected format (e.g., distinguish real EPUB
  /// from a renamed ZIP file).
  ///
  /// Returns true if the plugin can handle the file.
  Future<bool> canHandleFile(String filePath);

  /// Parse metadata from the book file.
  ///
  /// Extracts:
  /// - Title, author, description
  /// - Cover image
  /// - Table of contents
  /// - Encryption/DRM info
  /// - Format-specific metadata
  ///
  /// Throws an exception if the file cannot be parsed.
  Future<BookMetadata> parseMetadata(String filePath);

  /// Open the book and return a controller for reading.
  ///
  /// The controller manages:
  /// - Navigation (chapters, pages, CFI locations)
  /// - Content retrieval
  /// - Search
  /// - Progress tracking
  ///
  /// The caller is responsible for disposing the controller when done.
  ///
  /// Throws an exception if the file cannot be opened.
  Future<ReaderController> openBook(String filePath);

  /// Extract the cover image from the book file.
  ///
  /// Returns null if no cover image is found.
  ///
  /// This is separate from [parseMetadata] for cases where you only
  /// need the cover (e.g., updating library thumbnails).
  Future<Uint8List?> extractCover(String filePath);

  /// Check if this reader supports a specific file extension.
  bool supportsExtension(String extension) {
    final ext = extension.toLowerCase().replaceFirst('.', '');
    return supportedExtensions.contains(ext);
  }

  /// Check if this reader supports a specific MIME type.
  bool supportsMimeType(String mimeType) {
    return supportedMimeTypes.contains(mimeType.toLowerCase());
  }
}
