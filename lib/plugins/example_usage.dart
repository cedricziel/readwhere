/// Example usage of the plugin system
///
/// This file demonstrates how to use the plugin system to read books
/// in various formats. This is not meant to be imported, but rather
/// serves as documentation and reference.

import 'package:logging/logging.dart';

import 'plugins.dart';

/// Initialize the plugin system
void initializePlugins() {
  // Get the singleton registry
  final registry = PluginRegistry();

  // Register the EPUB plugin
  registry.register(EpubPlugin());

  // Future: Register other plugins
  // registry.register(PdfPlugin());
  // registry.register(MobiPlugin());

  print('Registered ${registry.pluginCount} plugins');
  print('Supported extensions: ${registry.getSupportedExtensions().join(", ")}');
}

/// Example: Open and read a book
Future<void> openAndReadBook(String filePath) async {
  final logger = Logger('ExampleUsage');

  try {
    // Get the plugin registry
    final registry = PluginRegistry();

    // Find a plugin that can handle this file
    final plugin = await registry.getPluginForFile(filePath);
    if (plugin == null) {
      logger.warning('No plugin found for file: $filePath');
      return;
    }

    logger.info('Using plugin: ${plugin.name}');

    // Parse metadata first
    final metadata = await plugin.parseMetadata(filePath);
    logger.info('Book title: ${metadata.title}');
    logger.info('Author: ${metadata.author}');
    logger.info('Language: ${metadata.language}');
    logger.info('TOC entries: ${metadata.tableOfContents.length}');

    // Extract cover image
    final coverImage = await plugin.extractCover(filePath);
    if (coverImage != null) {
      logger.info('Cover image: ${coverImage.length} bytes');
    }

    // Open the book for reading
    final controller = await plugin.openBook(filePath);

    logger.info('Book ID: ${controller.bookId}');
    logger.info('Total chapters: ${controller.totalChapters}');

    // Listen to content changes
    controller.contentStream.listen((content) {
      logger.info('Chapter changed: ${content.chapterTitle}');
      logger.info('Content length: ${content.htmlContent.length} characters');
    });

    // Navigate to first chapter
    await controller.goToChapter(0);

    // Search within the book
    final searchResults = await controller.search('the');
    logger.info('Found ${searchResults.length} search results');
    for (final result in searchResults.take(5)) {
      logger.info('  - ${result.chapterTitle}: ${result.text}');
    }

    // Navigate to different chapters
    for (var i = 0; i < controller.totalChapters.clamp(0, 3); i++) {
      await controller.goToChapter(i);
      logger.info('Progress: ${(controller.progress * 100).toStringAsFixed(1)}%');
    }

    // Dispose the controller when done
    await controller.dispose();
  } catch (e, stackTrace) {
    logger.severe('Error reading book', e, stackTrace);
  }
}

/// Example: Browse supported formats
void browseSupportedFormats() {
  final registry = PluginRegistry();

  print('Available plugins:');
  for (final plugin in registry.getAllPlugins()) {
    print('\n${plugin.name} (${plugin.id})');
    print('  Description: ${plugin.description}');
    print('  Extensions: ${plugin.supportedExtensions.join(", ")}');
    print('  MIME types: ${plugin.supportedMimeTypes.join(", ")}');
  }
}

/// Example: Register a custom plugin
void registerCustomPlugin() {
  // Register custom plugin
  // final registry = PluginRegistry();
  // final customPlugin = MyCustomPlugin();
  // registry.register(customPlugin);

  // Unregister by ID
  // registry.unregister(customPlugin.id);
}

/// Example: Get plugin by ID
void getPluginById() {
  final registry = PluginRegistry();

  final plugin = registry.getPluginById('com.readwhere.epub');
  if (plugin != null) {
    print('Found plugin: ${plugin.name}');
  } else {
    print('Plugin not found');
  }
}

/// Example: Handle errors gracefully
Future<void> handleErrors(String filePath) async {
  final logger = Logger('ErrorHandling');
  final registry = PluginRegistry();

  try {
    final plugin = await registry.getPluginForFile(filePath);
    if (plugin == null) {
      throw Exception('Unsupported file format');
    }

    final controller = await plugin.openBook(filePath);

    // Try to access an invalid chapter
    try {
      await controller.goToChapter(9999);
    } catch (e) {
      logger.warning('Invalid chapter index: $e');
    }

    await controller.dispose();
  } catch (e) {
    logger.severe('Error handling book: $e');
  }
}

/// Main example function
Future<void> main() async {
  // Set up logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Initialize plugins
  initializePlugins();

  // Browse available plugins
  browseSupportedFormats();

  // Example book path (replace with actual path)
  const bookPath = '/path/to/book.epub';

  // Open and read a book
  await openAndReadBook(bookPath);

  // Handle errors
  await handleErrors('/path/to/invalid.txt');
}
