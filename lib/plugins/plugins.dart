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
library plugins;

export 'epub/epub.dart';
export 'plugin_registry.dart';
export 'reader_content.dart';
export 'reader_controller.dart';
export 'reader_plugin.dart';
export 'search_result.dart';
