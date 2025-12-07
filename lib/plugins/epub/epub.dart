// EPUB reader plugin for the readwhere e-reader app
//
// This library provides comprehensive support for reading EPUB 2.0 and EPUB 3.0 format books.
// It includes:
// - Metadata extraction (title, author, cover, etc.)
// - Table of contents parsing
// - Chapter navigation
// - Full-text search
// - CFI (Canonical Fragment Identifier) support
//
// Example usage:
// ```dart
// // Register the EPUB plugin
// final registry = PluginRegistry();
// registry.register(EpubPlugin());
//
// // Open an EPUB file
// final plugin = await registry.getPluginForFile('/path/to/book.epub');
// if (plugin != null) {
//   // Parse metadata
//   final metadata = await plugin.parseMetadata('/path/to/book.epub');
//   print('Title: ${metadata.title}');
//   print('Author: ${metadata.author}');
//
//   // Open the book for reading
//   final controller = await plugin.openBook('/path/to/book.epub');
//
//   // Navigate to first chapter
//   await controller.goToChapter(0);
//
//   // Listen to content stream
//   controller.contentStream.listen((content) {
//     print('Chapter: ${content.chapterTitle}');
//     print('HTML: ${content.htmlContent}');
//   });
//
//   // Search within the book
//   final results = await controller.search('keyword');
//   for (final result in results) {
//     print('Found in ${result.chapterTitle}: ${result.text}');
//   }
//
//   // Clean up
//   await controller.dispose();
// }
// ```

export 'epub_parser.dart';
export 'epub_plugin.dart';
export 'epub_reader_controller.dart';
export 'epub_utils.dart';
