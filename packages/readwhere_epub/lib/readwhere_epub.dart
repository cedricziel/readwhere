/// A robust, EPUB 3.3 compliant library for reading EPUB files.
///
/// This library provides a clean API for parsing and reading EPUB publications,
/// including metadata extraction, table of contents, chapter content, and resources.
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:readwhere_epub/readwhere_epub.dart';
///
/// void main() async {
///   final reader = await EpubReader.open('/path/to/book.epub');
///
///   print('Title: ${reader.metadata.title}');
///   print('Author: ${reader.metadata.author}');
///
///   // Get chapter content
///   final chapter = reader.getChapter(0);
///   print(chapter.plainText);
///
///   // Get cover image
///   final cover = reader.getCoverImage();
///   if (cover != null) {
///     print('Cover: ${cover.bytes.length} bytes');
///   }
/// }
/// ```
library readwhere_epub;

// Core API
export 'src/reader/epub_reader.dart';
export 'src/reader/epub_book.dart';

// Models
export 'src/package/metadata/metadata.dart';
export 'src/package/manifest/manifest.dart';
export 'src/package/spine/spine.dart';
export 'src/navigation/toc.dart';
export 'src/content/content_document.dart';

// Security
export 'src/content/html_sanitizer.dart';

// Validation
export 'src/validation/epub_validator.dart';

// CFI (Canonical Fragment Identifier)
export 'src/cfi/epub_cfi.dart';
export 'src/cfi/cfi_step.dart';

// Search
export 'src/search/search_engine.dart';
export 'src/search/search_options.dart';
export 'src/search/search_result.dart';

// Resources
export 'src/resources/resource.dart';
export 'src/resources/stylesheet.dart';
export 'src/resources/image.dart';

// Errors
export 'src/errors/epub_exception.dart';
