# EPUB Plugin for ReadWhere

Comprehensive EPUB 2.0 and EPUB 3.0 reader plugin for the ReadWhere e-reader application.

## Overview

The EPUB plugin provides full support for reading EPUB format books, including:

- **Metadata Extraction**: Title, author, publisher, language, description, cover image
- **Table of Contents**: Hierarchical TOC parsing from EPUB navigation
- **Chapter Navigation**: Forward, backward, and direct chapter access
- **Full-text Search**: Search across all chapters with context
- **CFI Support**: Canonical Fragment Identifier for precise location tracking
- **Content Rendering**: HTML content with embedded CSS and images
- **Image Handling**: Automatic extraction and mapping of embedded images

## Architecture

### Core Components

#### 1. EpubPlugin (`epub_plugin.dart`)

Main plugin implementation that extends `ReaderPlugin`.

**Key Methods:**
- `canHandle(String filePath)`: Validates EPUB files by checking extension and ZIP signature
- `parseMetadata(String filePath)`: Extracts complete book metadata
- `openBook(String filePath)`: Creates and initializes an `EpubReaderController`
- `extractCover(String filePath)`: Retrieves cover image as `Uint8List`

**Supported Formats:**
- Extensions: `.epub`, `.epub3`
- MIME Types: `application/epub+zip`, `application/epub`

#### 2. EpubReaderController (`epub_reader_controller.dart`)

Reading session controller that extends `ReaderController`.

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

#### 3. EpubParser (`epub_parser.dart`)

Helper utilities for EPUB file parsing.

**Utilities:**
- `parseBook(String filePath)`: Parse EPUB file to `EpubBook` object
- `extractMetadata(EpubBook)`: Convert to `BookMetadata`
- `extractCover(EpubBook)`: Get cover image
- `getChapterContent(EpubBook, int)`: Retrieve chapter HTML
- `getAllImages(EpubBook)`: Extract all embedded images
- `getAllCssFiles(EpubBook)`: Extract all stylesheets

#### 4. EpubUtils (`epub_utils.dart`)

Low-level EPUB manipulation utilities.

**Functionality:**
- Table of contents extraction (multiple methods)
- Cover image detection (metadata, manifest, filenames)
- HTML sanitization and cleaning
- CSS extraction and combination
- CFI parsing and generation
- Image reference resolution

## Usage

### Basic Setup

```dart
import 'package:readwhere/plugins/plugins.dart';

// Initialize plugin registry
final registry = PluginRegistry();
registry.register(EpubPlugin());
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
EPUB File
    ↓
EpubPlugin.openBook()
    ↓
EpubParser.parseBook()
    ↓
EpubBook (epubx library)
    ↓
EpubReaderController
    ↓
ReaderContent (via contentStream)
    ↓
UI Layer
```

## Content Structure

### ReaderContent

Each chapter is delivered as a `ReaderContent` object:

```dart
class ReaderContent {
  final String chapterId;          // Unique chapter identifier
  final String chapterTitle;       // Chapter title
  final String htmlContent;        // Sanitized HTML
  final String cssContent;         // Combined CSS
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

### HTML Sanitization

The plugin automatically sanitizes HTML content by:
- Removing `<script>` tags
- Stripping dangerous event handlers (`onclick`, `onload`, etc.)
- Preserving document structure
- Maintaining embedded styles and classes

### Image Handling

Images are extracted and mapped in multiple ways:
1. Direct references from chapter HTML
2. Normalized path resolution
3. Fallback to manifest entries
4. Support for relative and absolute paths

### CFI (Canonical Fragment Identifier)

CFI format used for location tracking:
```
epubcfi(/6/4!/4/2/1)
```

Components:
- Spine position (chapter index)
- Character offset (optional)
- Element path (future enhancement)

### Table of Contents Extraction

Multiple fallback methods:
1. **Chapters** (primary): From `EpubBook.Chapters`
2. **Navigation**: From EPUB 3.0 nav document
3. **NCX**: From EPUB 2.0 NCX file
4. **Spine**: Generated from spine items

## Error Handling

The plugin handles various error scenarios:

- **Invalid EPUB files**: Returns `false` from `canHandle()`
- **Missing chapters**: Throws `ArgumentError` with bounds info
- **Corrupted content**: Logs warning and provides fallback
- **Missing images**: Returns empty map, continues operation
- **Invalid CFI**: Logs error, maintains current position

## Performance Considerations

### Memory Management
- Chapters loaded on-demand
- Images extracted per-chapter basis
- CSS combined once at initialization
- Stream-based content delivery

### Optimization Tips
1. Dispose controllers when done
2. Cancel stream subscriptions
3. Use CFI for bookmarking instead of full content
4. Limit search result count for large books

## Testing

Run EPUB plugin tests:

```bash
flutter test test/plugins/epub/
```

Test coverage includes:
- File format validation
- Metadata extraction
- Chapter navigation
- Search functionality
- CFI generation/parsing
- Error handling

## Dependencies

- **epubx** (^4.0.0): Core EPUB parsing
- **html** (^0.15.5): HTML parsing and sanitization
- **archive** (^3.6.1): ZIP file handling

## Future Enhancements

- [ ] Advanced CFI with element paths
- [ ] Annotation support
- [ ] Highlight management
- [ ] Reading statistics
- [ ] Font and style customization
- [ ] Text-to-speech integration
- [ ] Accessibility improvements
- [ ] FXL (Fixed Layout) support

## Contributing

When contributing to the EPUB plugin:

1. Maintain compatibility with EPUB 2.0 and 3.0 specs
2. Add tests for new features
3. Update documentation
4. Follow Dart/Flutter style guidelines
5. Ensure backward compatibility

## License

See the main ReadWhere project LICENSE file.

## References

- [EPUB 3.3 Specification](https://www.w3.org/TR/epub-33/)
- [EPUB CFI Specification](https://idpf.org/epub/linking/cfi/)
- [epubx Library](https://pub.dev/packages/epubx)
