# EPUB Plugin for ReadWhere

Comprehensive EPUB 2.0 and EPUB 3.0 reader plugin for the ReadWhere e-reader application, powered by the custom `readwhere_epub` library.

## Overview

The EPUB plugin provides full support for reading EPUB format books, including:

- **Metadata Extraction**: Title, author, publisher, language, description, cover image
- **Table of Contents**: Hierarchical TOC parsing from EPUB 3 nav documents and EPUB 2 NCX
- **Chapter Navigation**: Forward, backward, and direct chapter access
- **Full-text Search**: Search across all chapters with context
- **CFI Support**: Canonical Fragment Identifier for precise location tracking
- **Content Rendering**: HTML content with embedded CSS and images
- **Image Handling**: Automatic extraction and mapping of embedded images

## Architecture

### Core Components

#### 1. ReadwhereEpubPlugin (`readwhere_epub_plugin.dart`)

Main plugin implementation that implements `ReaderPlugin`.

**Key Methods:**
- `canHandle(String filePath)`: Validates EPUB files by checking extension and ZIP signature
- `parseMetadata(String filePath)`: Extracts complete book metadata using `readwhere_epub`
- `openBook(String filePath)`: Creates and initializes a `ReadwhereEpubController`
- `extractCover(String filePath)`: Retrieves cover image as `Uint8List`

**Supported Formats:**
- Extensions: `.epub`, `.epub3`
- MIME Types: `application/epub+zip`, `application/epub`

#### 2. ReadwhereEpubController (`readwhere_epub_controller.dart`)

Reading session controller that implements `ReaderController`.

**Features:**
- Chapter navigation (next, previous, goto)
- Content streaming via `contentStream`
- Progress tracking (0.0 to 1.0)
- Full-text search with context
- CFI generation and parsing
- Image and CSS extraction

**State Management:**
- Current chapter index
- Reading progress percentage
- Current CFI location
- Broadcast stream for content updates

### Library: readwhere_epub

The plugin is powered by `readwhere_epub`, a custom EPUB 3.3 compliant library located in `packages/readwhere_epub/`. This library provides:

- **EpubReader**: Main entry point for opening and reading EPUB files
- **EpubMetadata**: Complete Dublin Core metadata support
- **EpubNavigation**: TOC, page list, and landmarks
- **EpubChapter**: Chapter content with plain text extraction
- **CoverExtractor**: Multi-strategy cover image detection

## Usage

### Basic Setup

```dart
import 'package:readwhere/plugins/plugins.dart';

// Initialize plugin registry
final registry = PluginRegistry();
registry.register(ReadwhereEpubPlugin());
```

### Open an EPUB Book

```dart
// Find plugin for file
final plugin = await registry.getPluginForFile('/path/to/book.epub');

if (plugin != null) {
  // Parse metadata
  final metadata = await plugin.parseMetadata('/path/to/book.epub');
  print('Title: ${metadata.title}');
  print('Author: ${metadata.author}');

  // Open book for reading
  final controller = await plugin.openBook('/path/to/book.epub');

  // Navigate to first chapter
  await controller.goToChapter(0);

  // Cleanup
  await controller.dispose();
}
```

### Navigate Chapters

```dart
// Go to specific chapter
await controller.goToChapter(5);

// Next chapter
await controller.nextChapter();

// Previous chapter
await controller.previousChapter();

// Navigate using CFI
final cfi = controller.getCurrentCfi();
await controller.goToLocation(cfi);
```

### Listen to Content Updates

```dart
controller.contentStream.listen((content) {
  print('Chapter: ${content.chapterTitle}');
  print('HTML: ${content.htmlContent}');
  print('CSS: ${content.cssContent}');
  print('Images: ${content.images.length}');
});
```

### Search Book Content

```dart
final results = await controller.search('keyword');

for (final result in results) {
  print('Chapter: ${result.chapterTitle}');
  print('Text: ${result.text}');
  print('CFI: ${result.cfi}');
}
```

### Extract Cover Image

```dart
final coverBytes = await plugin.extractCover('/path/to/book.epub');

if (coverBytes != null) {
  // Display or save cover image
  final image = Image.memory(coverBytes);
}
```

### Access Table of Contents

```dart
for (final entry in controller.tableOfContents) {
  print('${entry.level}: ${entry.title}');

  for (final child in entry.children) {
    print('  ${child.title}');
  }
}
```

## Data Flow

```
EPUB File (.epub)
    |
    v
ReadwhereEpubPlugin.openBook()
    |
    v
readwhere_epub.EpubReader.open()
    |
    v
ReadwhereEpubController
    |
    v
ReaderContent (via contentStream)
    |
    v
UI Layer
```

## Content Structure

### ReaderContent

Each chapter is delivered as a `ReaderContent` object:

```dart
class ReaderContent {
  final String chapterId;          // Unique chapter identifier
  final String chapterTitle;       // Chapter title
  final String htmlContent;        // Chapter HTML content
  final String cssContent;         // Combined CSS stylesheets
  final Map<String, Uint8List> images;  // Embedded images
}
```

### BookMetadata

Extracted book metadata:

```dart
class BookMetadata {
  final String title;
  final String author;
  final String? description;
  final String? publisher;
  final String? language;
  final DateTime? publishedDate;
  final Uint8List? coverImage;
  final List<TocEntry> tableOfContents;
}
```

## Implementation Details

### Cover Image Extraction

The `readwhere_epub` library uses multiple strategies to find cover images:
1. EPUB 3 manifest `cover-image` property
2. EPUB 2 metadata `cover` meta element
3. Guide references
4. First image in first spine item
5. Image with "cover" in filename

### CFI (Canonical Fragment Identifier)

CFI format used for location tracking:
```
epubcfi(/6/4!/4/1:0)
```

Components:
- Spine position (chapter index)
- Element path
- Character offset

### Table of Contents Extraction

The library uses multiple fallback methods:
1. **EPUB 3 Nav Document**: Modern navigation document
2. **EPUB 2 NCX**: Navigation Center eXtended
3. **Spine Fallback**: Generated from spine items when no TOC exists

## Error Handling

The plugin handles various error scenarios:

- **Invalid EPUB files**: Returns `false` from `canHandle()`
- **Missing chapters**: Throws `ArgumentError` with bounds info
- **Corrupted content**: Logs warning and provides fallback
- **Missing images**: Returns empty map, continues operation
- **Invalid CFI**: Logs error, maintains current position

## Performance Considerations

### Memory Management
- Chapters loaded on-demand with caching
- Images extracted per-chapter basis
- CSS collected from referenced stylesheets
- Stream-based content delivery

### Optimization Tips
1. Dispose controllers when done
2. Cancel stream subscriptions
3. Use CFI for bookmarking instead of full content
4. Use `clearCache()` to free memory when needed

## Testing

Run tests for the readwhere_epub library:

```bash
cd packages/readwhere_epub
flutter test
```

Test coverage includes:
- Path utilities
- XML utilities
- TOC parsing
- Navigation structures
- Error handling

## Dependencies

The plugin uses `readwhere_epub` which depends on:

- **archive** (^3.6.1): ZIP file handling
- **xml** (^6.5.0): XML parsing for OPF, NCX, and nav documents
- **html** (^0.15.5): HTML parsing for content documents
- **equatable** (^2.0.7): Value equality for models
- **collection** (^1.18.0): Collection utilities
- **path** (^1.9.0): Path manipulation

## Future Enhancements

- [ ] Advanced CFI with precise character positioning
- [ ] Full-text search with highlighting
- [ ] Annotation support
- [ ] Fixed-layout EPUB (FXL) support
- [ ] Media overlays (SMIL) support
- [ ] EPUB validation
- [ ] Text-to-speech integration

## References

- [EPUB 3.3 Specification](https://www.w3.org/TR/epub-33/)
- [EPUB CFI Specification](https://idpf.org/epub/linking/cfi/)
- [readwhere_epub Library](packages/readwhere_epub/)
