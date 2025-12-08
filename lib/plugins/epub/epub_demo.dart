/// Demonstration of EPUB plugin usage
///
/// This file provides practical examples of how to use the EPUB plugin
/// to read and navigate EPUB books in the readwhere app.

import 'package:logging/logging.dart';

import '../plugin_registry.dart';
import 'readwhere_epub_plugin.dart';

/// Initialize the EPUB plugin with the registry
void initializeEpubPlugin() {
  final registry = PluginRegistry();

  // Register the EPUB plugin
  registry.register(ReadwhereEpubPlugin());

  print('EPUB plugin registered successfully');
  print('Supported extensions: ${registry.getSupportedExtensions()}');
  print('Supported MIME types: ${registry.getSupportedMimeTypes()}');
}

/// Example: Parse EPUB metadata
Future<void> parseEpubMetadata(String filePath) async {
  final logger = Logger('EpubDemo');

  try {
    final registry = PluginRegistry();
    final plugin = await registry.getPluginForFile(filePath);

    if (plugin == null) {
      logger.warning('No plugin found for file: $filePath');
      return;
    }

    logger.info('Using plugin: ${plugin.name}');

    // Parse metadata
    final metadata = await plugin.parseMetadata(filePath);

    print('Title: ${metadata.title}');
    print('Author: ${metadata.author}');
    print('Publisher: ${metadata.publisher ?? "N/A"}');
    print('Language: ${metadata.language ?? "N/A"}');
    print('Description: ${metadata.description ?? "N/A"}');
    print('Published Date: ${metadata.publishedDate ?? "N/A"}');
    print('Has Cover: ${metadata.coverImage != null}');
    print('TOC Entries: ${metadata.tableOfContents.length}');

    // Display table of contents
    if (metadata.tableOfContents.isNotEmpty) {
      print('\nTable of Contents:');
      _printTocEntries(metadata.tableOfContents);
    }
  } catch (e, stackTrace) {
    logger.severe('Error parsing metadata', e, stackTrace);
  }
}

/// Helper to print TOC entries recursively
void _printTocEntries(List<dynamic> entries, {int indent = 0}) {
  for (final entry in entries) {
    final spacing = '  ' * indent;
    print('$spacing- ${entry.title} (${entry.href})');
    if (entry.children.isNotEmpty) {
      _printTocEntries(entry.children, indent: indent + 1);
    }
  }
}

/// Example: Extract and save EPUB cover image
Future<void> extractEpubCover(String filePath, String outputPath) async {
  final logger = Logger('EpubDemo');

  try {
    final registry = PluginRegistry();
    final plugin = await registry.getPluginForFile(filePath);

    if (plugin == null) {
      logger.warning('No plugin found for file: $filePath');
      return;
    }

    // Extract cover image
    final coverImage = await plugin.extractCover(filePath);

    if (coverImage != null) {
      // In a real app, you would save this to a file
      print('Cover image extracted: ${coverImage.length} bytes');
      // Example: await File(outputPath).writeAsBytes(coverImage);
    } else {
      print('No cover image found');
    }
  } catch (e, stackTrace) {
    logger.severe('Error extracting cover', e, stackTrace);
  }
}

/// Example: Open and navigate through an EPUB book
Future<void> readEpubBook(String filePath) async {
  final logger = Logger('EpubDemo');

  try {
    final registry = PluginRegistry();
    final plugin = await registry.getPluginForFile(filePath);

    if (plugin == null) {
      logger.warning('No plugin found for file: $filePath');
      return;
    }

    // Open the book
    final controller = await plugin.openBook(filePath);

    print('Book ID: ${controller.bookId}');
    print('Total Chapters: ${controller.totalChapters}');
    print('Current Chapter: ${controller.currentChapterIndex}');
    print('Progress: ${(controller.progress * 100).toStringAsFixed(2)}%');

    // Listen to content updates
    final subscription = controller.contentStream.listen((content) {
      print('\nChapter Updated:');
      print('  ID: ${content.chapterId}');
      print('  Title: ${content.chapterTitle}');
      print('  HTML Length: ${content.htmlContent.length}');
      print('  CSS Length: ${content.cssContent.length}');
      print('  Images: ${content.images.length}');
    });

    // Navigate to first chapter
    await controller.goToChapter(0);

    // Navigate through a few chapters
    if (controller.totalChapters > 1) {
      await controller.nextChapter();
      print('Navigated to next chapter: ${controller.currentChapterIndex}');
    }

    if (controller.currentChapterIndex > 0) {
      await controller.previousChapter();
      print('Navigated to previous chapter: ${controller.currentChapterIndex}');
    }

    // Get current reading position (CFI)
    final currentCfi = controller.getCurrentCfi();
    print('Current CFI: $currentCfi');

    // Navigate using CFI
    if (currentCfi != null) {
      await controller.goToLocation(currentCfi);
      print('Navigated to CFI location');
    }

    // Clean up
    await subscription.cancel();
    await controller.dispose();

    print('Book closed successfully');
  } catch (e, stackTrace) {
    logger.severe('Error reading book', e, stackTrace);
  }
}

/// Example: Search within an EPUB book
Future<void> searchEpubBook(String filePath, String query) async {
  final logger = Logger('EpubDemo');

  try {
    final registry = PluginRegistry();
    final plugin = await registry.getPluginForFile(filePath);

    if (plugin == null) {
      logger.warning('No plugin found for file: $filePath');
      return;
    }

    // Open the book
    final controller = await plugin.openBook(filePath);

    // Perform search
    print('Searching for "$query"...');
    final results = await controller.search(query);

    print('Found ${results.length} results\n');

    // Display first 10 results
    for (var i = 0; i < results.length && i < 10; i++) {
      final result = results[i];
      print('Result ${i + 1}:');
      print('  Chapter: ${result.chapterTitle}');
      print('  Text: ${result.text}');
      print('  CFI: ${result.cfi}');
      print('');
    }

    // Clean up
    await controller.dispose();
  } catch (e, stackTrace) {
    logger.severe('Error searching book', e, stackTrace);
  }
}

/// Example: Display book table of contents
Future<void> displayTableOfContents(String filePath) async {
  final logger = Logger('EpubDemo');

  try {
    final registry = PluginRegistry();
    final plugin = await registry.getPluginForFile(filePath);

    if (plugin == null) {
      logger.warning('No plugin found for file: $filePath');
      return;
    }

    // Open the book
    final controller = await plugin.openBook(filePath);

    // Display TOC
    print('Table of Contents:');
    print('=================\n');

    for (final entry in controller.tableOfContents) {
      _printTocEntry(entry);
    }

    // Clean up
    await controller.dispose();
  } catch (e, stackTrace) {
    logger.severe('Error displaying TOC', e, stackTrace);
  }
}

void _printTocEntry(dynamic entry, {int level = 0}) {
  final indent = '  ' * level;
  print('$indent${entry.title}');

  if (entry.children.isNotEmpty) {
    for (final child in entry.children) {
      _printTocEntry(child, level: level + 1);
    }
  }
}

/// Main demonstration function
Future<void> main() async {
  // Set up logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.message}');
  });

  // Initialize EPUB plugin
  initializeEpubPlugin();

  // Example book path (replace with actual path)
  const bookPath = '/path/to/sample.epub';

  print('\n=== Parsing Metadata ===\n');
  await parseEpubMetadata(bookPath);

  print('\n=== Extracting Cover ===\n');
  await extractEpubCover(bookPath, '/path/to/cover.jpg');

  print('\n=== Reading Book ===\n');
  await readEpubBook(bookPath);

  print('\n=== Searching Book ===\n');
  await searchEpubBook(bookPath, 'chapter');

  print('\n=== Table of Contents ===\n');
  await displayTableOfContents(bookPath);
}
