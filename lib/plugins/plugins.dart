/// Plugin system for the readwhere e-reader app
///
/// This library provides the core plugin infrastructure for handling
/// different book formats. Plugins implement the [ReaderPlugin] interface
/// to support formats like EPUB, PDF, CBZ, etc.
///
/// Example usage:
/// ```dart
/// // Register a plugin
/// final registry = PluginRegistry();
/// registry.register(MyEpubPlugin());
///
/// // Find a plugin for a file
/// final plugin = await registry.getPluginForFile('/path/to/book.epub');
/// if (plugin != null) {
///   final metadata = await plugin.parseMetadata('/path/to/book.epub');
///   final controller = await plugin.openBook('/path/to/book.epub');
/// }
/// ```
library;

// Re-export plugin interfaces from package
export 'package:readwhere_plugin/readwhere_plugin.dart'
    show
        PluginRegistry,
        ReaderContent,
        ReaderController,
        ReaderPlugin,
        SearchResult,
        ReadingLocation,
        BookMetadata,
        TocEntry,
        EpubEncryptionType;

// Export plugin implementations
export 'cbr/cbr.dart';
export 'cbz/cbz.dart';
export 'epub/epub.dart';
