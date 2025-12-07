import 'dart:io';
import 'dart:typed_data';

import 'package:epubx/epubx.dart';
import 'package:logging/logging.dart';

import '../../domain/entities/book_metadata.dart';
import '../../domain/entities/toc_entry.dart';
import 'epub_utils.dart';

/// Helper class for parsing EPUB files
/// Provides methods to extract metadata, content, and other information from EPUB books
class EpubParser {
  static final _logger = Logger('EpubParser');

  /// Parse an EPUB file and return the EpubBook object
  ///
  /// Throws an exception if the file cannot be read or parsed
  static Future<EpubBook> parseBook(String filePath) async {
    try {
      _logger.info('Parsing EPUB file: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('File not found', filePath);
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw FormatException('EPUB file is empty', filePath);
      }

      final epubBook = await EpubReader.readBook(bytes);
      _logger.info('Successfully parsed EPUB: ${epubBook.Title ?? "Unknown"}');

      return epubBook;
    } catch (e, stackTrace) {
      _logger.severe('Error parsing EPUB file: $filePath', e, stackTrace);
      rethrow;
    }
  }

  /// Extract metadata from an EPUB book
  ///
  /// Returns BookMetadata with title, author, description, cover, and TOC
  static BookMetadata extractMetadata(EpubBook epubBook) {
    try {
      _logger.fine('Extracting metadata from EPUB');

      // Extract basic metadata from Schema.Package.Metadata
      final metadata = epubBook.Schema?.Package?.Metadata;
      final title = epubBook.Title ??
                   metadata?.Titles?.firstOrNull ??
                   'Unknown Title';
      final author = epubBook.Author ??
                    metadata?.Creators?.firstOrNull?.Creator ??
                    'Unknown Author';
      final description = metadata?.Description;
      final publisher = metadata?.Publishers?.firstOrNull;
      final language = metadata?.Languages?.firstOrNull;

      // Parse publish date if available
      DateTime? publishedDate;
      final dateString = metadata?.Dates?.firstOrNull?.Date;
      if (dateString != null) {
        try {
          publishedDate = DateTime.parse(dateString);
        } catch (e) {
          _logger.warning('Failed to parse publication date: $dateString - $e');
        }
      }

      // Extract cover image
      Uint8List? coverImage;
      try {
        coverImage = extractCover(epubBook);
      } catch (e) {
        _logger.warning('Failed to extract cover: $e');
      }

      // Build table of contents
      final toc = extractTableOfContents(epubBook);

      final bookMetadata = BookMetadata(
        title: title,
        author: author,
        description: description,
        publisher: publisher,
        language: language,
        publishedDate: publishedDate,
        coverImage: coverImage,
        tableOfContents: toc,
      );

      _logger.fine('Extracted metadata: $bookMetadata');
      return bookMetadata;
    } catch (e, stackTrace) {
      _logger.severe('Error extracting metadata', e, stackTrace);
      rethrow;
    }
  }

  /// Extract table of contents from an EPUB book
  ///
  /// Tries multiple methods to build the TOC:
  /// 1. EPUB 3.0 navigation document
  /// 2. EPUB 2.0 NCX file (via Chapters)
  /// 3. Spine items as fallback
  ///
  /// Returns empty list if no TOC is available
  static List<TocEntry> extractTableOfContents(EpubBook epubBook) {
    try {
      _logger.fine('Extracting table of contents');
      return EpubUtils.extractTableOfContents(epubBook);
    } catch (e, stackTrace) {
      _logger.severe('Error extracting table of contents', e, stackTrace);
      return [];
    }
  }

  /// Extract cover image from an EPUB book
  ///
  /// Tries multiple methods to find the cover:
  /// 1. Built-in CoverImage property
  /// 2. Metadata reference (EPUB 2.0 style)
  /// 3. Manifest properties (EPUB 3.0 style)
  /// 4. Common cover filenames
  /// 5. First image as fallback
  ///
  /// Returns null if no cover is found
  static Uint8List? extractCover(EpubBook epubBook) {
    try {
      _logger.fine('Extracting cover image');
      return EpubUtils.extractCoverImage(epubBook);
    } catch (e, stackTrace) {
      _logger.severe('Error extracting cover', e, stackTrace);
      return null;
    }
  }

  /// Get HTML content for a specific chapter
  ///
  /// The chapter index is 0-based and refers to flattened chapters
  /// Returns sanitized HTML suitable for rendering
  ///
  /// Throws ArgumentError if chapter index is out of bounds
  static String getChapterContent(EpubBook epubBook, int chapterIndex) {
    try {
      _logger.fine('Getting content for chapter $chapterIndex');

      // Flatten chapters
      final flatChapters = _flattenChapters(epubBook.Chapters ?? []);

      if (chapterIndex < 0 || chapterIndex >= flatChapters.length) {
        throw ArgumentError(
          'Chapter index $chapterIndex out of bounds (0-${flatChapters.length - 1})',
        );
      }

      final chapter = flatChapters[chapterIndex];
      final content = EpubUtils.getChapterContent(chapter);
      final cleanedContent = EpubUtils.cleanHtmlContent(content);

      return cleanedContent;
    } catch (e, stackTrace) {
      _logger.severe('Error getting chapter content for index $chapterIndex', e, stackTrace);
      rethrow;
    }
  }

  /// Get combined CSS from all stylesheets in the EPUB
  ///
  /// Returns a single string with all CSS content concatenated
  /// Returns empty string if no CSS is found
  static String getChapterCss(EpubBook epubBook) {
    try {
      _logger.fine('Getting CSS styles');

      final styles = EpubUtils.extractStyles(epubBook);
      if (styles.isEmpty) {
        _logger.fine('No CSS styles found');
        return '';
      }

      // Combine all CSS files into a single string
      final cssBuffer = StringBuffer();
      for (final entry in styles.entries) {
        cssBuffer.writeln('/* ${entry.key} */');
        cssBuffer.writeln(entry.value);
        cssBuffer.writeln();
      }

      final combinedCss = cssBuffer.toString();
      _logger.fine('Combined ${styles.length} CSS files (${combinedCss.length} chars)');

      return combinedCss;
    } catch (e, stackTrace) {
      _logger.severe('Error getting CSS styles', e, stackTrace);
      return '';
    }
  }

  /// Get a specific CSS file by name
  ///
  /// Returns null if the file is not found
  static String? getCssFile(EpubBook epubBook, String fileName) {
    try {
      final styles = EpubUtils.extractStyles(epubBook);
      return styles[fileName];
    } catch (e, stackTrace) {
      _logger.severe('Error getting CSS file: $fileName', e, stackTrace);
      return null;
    }
  }

  /// Get all CSS files as a map
  ///
  /// Returns a map of filename to CSS content
  static Map<String, String> getAllCssFiles(EpubBook epubBook) {
    try {
      return EpubUtils.extractStyles(epubBook);
    } catch (e, stackTrace) {
      _logger.severe('Error getting all CSS files', e, stackTrace);
      return {};
    }
  }

  /// Get an embedded image by reference
  ///
  /// The imageRef can be a filename, path, or ID
  /// Returns null if not found
  static Uint8List? getImage(EpubBook epubBook, String imageRef) {
    try {
      return EpubUtils.getEmbeddedImage(epubBook, imageRef);
    } catch (e, stackTrace) {
      _logger.severe('Error getting image: $imageRef', e, stackTrace);
      return null;
    }
  }

  /// Get all images in the EPUB
  ///
  /// Returns a map of filename to image data
  static Map<String, Uint8List> getAllImages(EpubBook epubBook) {
    try {
      _logger.fine('Getting all images');

      final images = <String, Uint8List>{};
      final epubImages = epubBook.Content?.Images;

      if (epubImages != null) {
        for (final entry in epubImages.entries) {
          final content = entry.value.Content;
          if (content != null && content.isNotEmpty) {
            images[entry.key] = Uint8List.fromList(content);
          }
        }
      }

      _logger.fine('Found ${images.length} images');
      return images;
    } catch (e, stackTrace) {
      _logger.severe('Error getting all images', e, stackTrace);
      return {};
    }
  }

  /// Get the total number of chapters in the EPUB
  ///
  /// Returns the count of flattened chapters
  static int getChapterCount(EpubBook epubBook) {
    try {
      final flatChapters = _flattenChapters(epubBook.Chapters ?? []);
      return flatChapters.length;
    } catch (e, stackTrace) {
      _logger.severe('Error getting chapter count', e, stackTrace);
      return 0;
    }
  }

  /// Get chapter title for a specific index
  ///
  /// Returns null if index is out of bounds
  static String? getChapterTitle(EpubBook epubBook, int chapterIndex) {
    try {
      final flatChapters = _flattenChapters(epubBook.Chapters ?? []);

      if (chapterIndex < 0 || chapterIndex >= flatChapters.length) {
        return null;
      }

      final chapter = flatChapters[chapterIndex];
      return chapter.Title ?? 'Chapter ${chapterIndex + 1}';
    } catch (e, stackTrace) {
      _logger.severe('Error getting chapter title for index $chapterIndex', e, stackTrace);
      return null;
    }
  }

  /// Get all flattened chapters from the EPUB
  ///
  /// Returns a list of chapters in reading order
  static List<EpubChapter> getChapters(EpubBook epubBook) {
    try {
      return _flattenChapters(epubBook.Chapters ?? []);
    } catch (e, stackTrace) {
      _logger.severe('Error getting chapters', e, stackTrace);
      return [];
    }
  }

  // Private helper methods

  /// Flatten nested chapters into a linear list
  static List<EpubChapter> _flattenChapters(List<EpubChapter> chapters) {
    final flat = <EpubChapter>[];
    for (final chapter in chapters) {
      flat.add(chapter);
      if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
        flat.addAll(_flattenChapters(chapter.SubChapters!));
      }
    }
    return flat;
  }
}
