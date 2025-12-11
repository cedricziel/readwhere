# Reader Plugin System

This directory contains the plugin architecture for the readwhere e-reader application. The plugin system provides an extensible way to support multiple book formats.

## Architecture

### Core Components

1. **ReaderPlugin** (`reader_plugin.dart`)
   - Abstract interface that all format-specific plugins must implement
   - Defines methods for file validation, metadata parsing, cover extraction, and book opening
   - Each plugin declares supported file extensions and MIME types

2. **ReaderController** (`reader_controller.dart`)
   - Abstract controller for managing a reading session
   - Provides navigation, content retrieval, and search functionality
   - Emits location change events for progress tracking

3. **UnifiedPluginRegistry** (from `readwhere_plugin` package)
   - Registry for managing all plugins (reader, catalog, etc.)
   - Handles plugin discovery and file-to-plugin matching
   - Integrated with service locator for dependency injection

### Models

- **ReadingLocation** (`reading_location.dart`) - Represents a position within a book
- **SearchResult** (`search_result.dart`) - Represents a search match with context

### Plugins

#### EPUB Plugin (`epub/`)

The EPUB plugin provides support for EPUB 2.0 and EPUB 3.0 format books.

**Features:**
- Metadata extraction (title, author, publisher, language, etc.)
- Cover image extraction
- Table of contents parsing
- Chapter navigation
- Full-text search
- CFI (Canonical Fragment Identifier) support

**Implementation:**
- `epub_plugin.dart` - Plugin interface implementation
- `epub_reader_controller.dart` - Reading session controller

## Usage

### Basic Setup

Plugins are registered in the service locator (`service_locator.dart`):

```dart
// In setupServiceLocator()
sl.registerLazySingletonAsync<UnifiedPluginRegistry>(() async {
  final registry = UnifiedPluginRegistry();

  await registry.register(
    ReadwhereEpubPlugin(),
    storageFactory: storageFactory,
    contextFactory: contextFactory,
  );
  // Register other plugins...

  return registry;
});
```

### Opening a Book

```dart
Future<void> openBook(String filePath) async {
  // Get registry from service locator
  final registry = sl<UnifiedPluginRegistry>();

  // Find appropriate plugin using ReaderCapability
  final plugin = await registry.forFile<ReaderCapability>(filePath);
  if (plugin == null) {
    throw Exception('Unsupported file format');
  }

  // Parse metadata
  final metadata = await plugin.parseMetadata(filePath);
  print('Title: ${metadata.title}');

  // Open book
  final controller = await plugin.openBook(filePath);

  // Navigate to first chapter
  await controller.goToChapter(0);

  // Get content
  final content = await controller.getChapterContent(0);

  // Listen to location changes
  controller.locationChanges.listen((location) {
    print('Progress: ${location.progress * 100}%');
  });

  // Search
  final results = await controller.search('keyword');

  // Clean up
  await controller.close();
}
```

### Creating a Custom Plugin

To add support for a new format, implement the `ReaderPlugin` interface:

```dart
class MyFormatPlugin implements ReaderPlugin {
  @override
  String get id => 'com.readwhere.myformat';

  @override
  String get name => 'My Format Reader';

  @override
  List<String> get supportedExtensions => ['myf', 'myformat'];

  @override
  Future<bool> canHandle(String filePath) async {
    // Validate file format
  }

  @override
  Future<BookMetadata> parseMetadata(String filePath) async {
    // Extract metadata
  }

  @override
  Future<Uint8List?> extractCover(String filePath) async {
    // Extract cover image
  }

  @override
  Future<ReaderController> openBook(String filePath) async {
    // Return a controller instance
  }
}
```

Then create a corresponding `ReaderController` implementation:

```dart
class MyFormatReaderController implements ReaderController {
  // Implement all required methods
}
```

## Error Handling

All plugin methods use exceptions for error handling:

- **File not found**: Standard `FileSystemException`
- **Invalid format**: Custom exceptions or `FormatException`
- **Parse errors**: Plugin-specific exceptions
- **Index out of bounds**: `ArgumentError`
- **Controller not initialized**: `StateError`
- **Controller closed**: `StateError`

Example:

```dart
try {
  final controller = await plugin.openBook(filePath);
  await controller.goToChapter(index);
} catch (e) {
  print('Error: $e');
}
```

## File Structure

```
lib/plugins/
├── README.md                    # This file
├── plugins.dart                 # Barrel export file (re-exports from readwhere_plugin)

packages/
├── readwhere_plugin/            # Core plugin interfaces
│   └── lib/src/
│       ├── core/                # UnifiedPluginRegistry, PluginBase
│       ├── capabilities/        # ReaderCapability, CatalogCapability, etc.
│       └── reader/              # ReaderPlugin, ReaderController, etc.
├── readwhere_epub_plugin/       # EPUB format plugin
├── readwhere_cbz_plugin/        # CBZ comic plugin
└── readwhere_cbr_plugin/        # CBR comic plugin
```

## Dependencies

The plugin system relies on these packages:

- `epubx` - EPUB parsing library
- `logging` - Logging framework
- `path` - Path manipulation
- `uuid` - Unique ID generation
- `equatable` - Value equality

## Future Enhancements

Planned features for the plugin system:

1. **PDF Plugin** - Support for PDF format books
2. **MOBI Plugin** - Support for Kindle MOBI format
3. **Audio Plugin** - Support for audiobooks
4. **Web Plugin** - Support for web-based content
5. **Plugin Marketplace** - Download and install third-party plugins
6. **Plugin Configuration** - Per-plugin settings and preferences
7. **Plugin Caching** - Cache parsed metadata for performance
8. **Incremental Loading** - Load chapters on-demand
9. **Advanced Search** - Regex and fuzzy search support
10. **Annotations API** - Plugin-agnostic annotation system

## Testing

See `example_usage.dart` for comprehensive usage examples and test scenarios.

## License

Part of the readwhere e-reader application.
