/// Plugin system for the readwhere e-reader app
///
/// This library provides the core plugin infrastructure for handling
/// different book formats. Plugins implement the [ReaderCapability] mixin
/// to support formats like EPUB, PDF, CBZ, etc.
///
/// Example usage:
/// ```dart
/// // Get the plugin registry from service locator
/// final registry = sl<UnifiedPluginRegistry>();
///
/// // Find a plugin for a file
/// final plugin = await registry.forFile<ReaderCapability>('/path/to/book.epub');
/// if (plugin != null) {
///   final metadata = await plugin.parseMetadata('/path/to/book.epub');
///   final controller = await plugin.openBook('/path/to/book.epub');
/// }
/// ```
library;

// Re-export plugin interfaces from package
export 'package:readwhere_plugin/readwhere_plugin.dart'
    show
        // ignore: deprecated_member_use
        PluginRegistry, // Deprecated: use UnifiedPluginRegistry instead
        UnifiedPluginRegistry,
        ReaderCapability,
        ReaderContent,
        ReaderController,
        ReaderPlugin,
        SearchResult,
        ReadingLocation,
        BookMetadata,
        TocEntry,
        EpubEncryptionType;

// Re-export plugin implementations from packages
export 'package:readwhere_cbr_plugin/readwhere_cbr_plugin.dart';
export 'package:readwhere_cbz_plugin/readwhere_cbz_plugin.dart';
export 'package:readwhere_epub_plugin/readwhere_epub_plugin.dart';
