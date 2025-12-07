import 'dart:typed_data';

import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:logging/logging.dart';

import '../../domain/entities/toc_entry.dart';

/// Utilities for working with EPUB files
class EpubUtils {
  static final _logger = Logger('EpubUtils');

  /// Extract table of contents from an EPUB book
  /// Handles both navigation-based and chapter-based TOC
  /// Returns empty list if no TOC is available
  static List<TocEntry> extractTableOfContents(EpubBook epubBook) {
    try {
      // Try chapters first (this is the most reliable source in epubx)
      final chapters = epubBook.Chapters;
      if (chapters != null && chapters.isNotEmpty) {
        _logger.fine('Building TOC from chapters (${chapters.length} chapters)');
        return _buildTocFromChapters(chapters);
      }

      // Fallback to navigation if available
      final navPoints = epubBook.Schema?.Navigation;
      if (navPoints != null) {
        _logger.fine('Building TOC from navigation');
        final navList = _extractNavigationPoints(navPoints);
        if (navList.isNotEmpty) {
          return _buildTocFromNavigation(navList);
        }
      }

      // Last resort: Generate TOC from spine
      final spine = epubBook.Schema?.Package?.Spine?.Items;
      if (spine != null && spine.isNotEmpty) {
        _logger.fine('Building TOC from spine (${spine.length} items)');
        return _buildTocFromSpine(epubBook, spine);
      }

      _logger.warning('No TOC source found in EPUB');
      return [];
    } catch (e, stackTrace) {
      _logger.severe('Error extracting table of contents', e, stackTrace);
      return [];
    }
  }

  /// Extract cover image from an EPUB book
  /// Tries multiple methods to find the cover
  /// Returns null if no cover is found
  static Uint8List? extractCoverImage(EpubBook epubBook) {
    try {
      // Method 1: Try built-in CoverImage property
      final dynamic coverImage = epubBook.CoverImage;
      if (coverImage != null) {
        _logger.fine('Found cover using CoverImage property');
        // CoverImage can be various types, handle them appropriately
        if (coverImage is Uint8List) {
          return coverImage;
        } else if (coverImage is List<int>) {
          return Uint8List.fromList(coverImage);
        } else {
          _logger.warning('Unexpected cover image type: ${coverImage.runtimeType}');
          // Try to convert anyway if it has Content property (epubx Image type)
          try {
            final content = (coverImage as dynamic).Content;
            if (content != null && content is List<int>) {
              return Uint8List.fromList(content);
            }
          } catch (e) {
            _logger.fine('Could not extract content from cover image: $e');
          }
        }
      }

      // Method 2: Look for cover in metadata (EPUB 2.0 style)
      final metadata = epubBook.Schema?.Package?.Metadata;
      // Try to access Meta items dynamically since the API varies
      try {
        final metaItems = (metadata as dynamic).Meta;
        if (metaItems != null && metaItems is List && metaItems.isNotEmpty) {
          for (final meta in metaItems) {
            final metaName = (meta as dynamic).Name;
            if (metaName?.toLowerCase() == 'cover') {
              final coverId = (meta as dynamic).Content;
              if (coverId != null) {
                final cover = _findImageById(epubBook, coverId);
                if (cover != null) {
                  _logger.fine('Found cover using metadata reference: $coverId');
                  return cover;
                }
              }
            }
          }
        }
      } catch (e) {
        _logger.fine('Could not access Meta items: $e');
      }

      // Method 3: Look for cover in manifest (EPUB 3.0 style)
      final manifest = epubBook.Schema?.Package?.Manifest?.Items;
      if (manifest != null) {
        for (final item in manifest) {
          final properties = item.Properties?.toLowerCase() ?? '';
          if (properties.contains('cover-image')) {
            final cover = _findImageByHref(epubBook, item.Href ?? '');
            if (cover != null) {
              _logger.fine('Found cover using manifest properties: ${item.Href}');
              return cover;
            }
          }
        }
      }

      // Method 4: Search for common cover filenames
      final images = epubBook.Content?.Images;
      if (images != null && images.isNotEmpty) {
        final coverKeywords = [
          'cover',
          'cover-image',
          'cover_image',
          'titlepage',
          'title-page',
          'title_page',
          'front',
          'frontcover',
        ];

        for (final keyword in coverKeywords) {
          for (final entry in images.entries) {
            final key = entry.key.toLowerCase();
            if (key.contains(keyword)) {
              final image = entry.value;
              if (image.Content != null && image.Content!.isNotEmpty) {
                _logger.fine('Found cover by keyword match: $keyword in ${entry.key}');
                return Uint8List.fromList(image.Content!);
              }
            }
          }
        }

        // Method 5: Use first image as fallback
        final firstImage = images.values.first;
        if (firstImage.Content != null && firstImage.Content!.isNotEmpty) {
          _logger.fine('Using first image as cover fallback');
          return Uint8List.fromList(firstImage.Content!);
        }
      }

      _logger.fine('No cover image found');
      return null;
    } catch (e, stackTrace) {
      _logger.severe('Error extracting cover image', e, stackTrace);
      return null;
    }
  }

  /// Get HTML content from an EPUB chapter
  /// Returns sanitized HTML suitable for rendering
  static String getChapterContent(EpubChapter chapter) {
    try {
      final content = chapter.HtmlContent ?? '';
      if (content.isEmpty) {
        _logger.warning('Chapter "${chapter.Title}" has no content');
        return '<html><body><p>No content available</p></body></html>';
      }

      return content;
    } catch (e, stackTrace) {
      _logger.severe('Error getting chapter content', e, stackTrace);
      return '<html><body><p>Error loading content</p></body></html>';
    }
  }

  /// Clean and sanitize HTML content for flutter_html
  /// Removes problematic tags and attributes
  /// Preserves essential formatting
  static String cleanHtmlContent(String html) {
    try {
      if (html.trim().isEmpty) {
        return '<p>No content</p>';
      }

      final document = html_parser.parse(html);

      // Remove script and style tags
      document.querySelectorAll('script, style').forEach((element) {
        element.remove();
      });

      // Remove potentially problematic attributes
      final problematicAttrs = ['onclick', 'onload', 'onerror', 'onmouseover'];
      for (final element in document.querySelectorAll('*')) {
        for (final attr in problematicAttrs) {
          element.attributes.remove(attr);
        }
      }

      // Get body content or full document
      final body = document.body;
      if (body != null) {
        return body.innerHtml;
      }

      return document.outerHtml;
    } catch (e, stackTrace) {
      _logger.severe('Error cleaning HTML content', e, stackTrace);
      return html; // Return original HTML if cleaning fails
    }
  }

  /// Extract CSS styles from EPUB content
  /// Returns a map of CSS file names to their content
  static Map<String, String> extractStyles(EpubBook epubBook) {
    try {
      final styles = <String, String>{};
      final css = epubBook.Content?.Css;

      if (css != null && css.isNotEmpty) {
        for (final entry in css.entries) {
          final fileName = entry.key;
          final dynamic content = entry.value.Content;
          if (content != null) {
            // Content can be String or List<int>, use dynamic to handle both
            try {
              final String cssString;
              if (content is String) {
                cssString = content;
              } else {
                // Assume it's some iterable of ints
                cssString = String.fromCharCodes(content as List<int>);
              }

              if (cssString.isNotEmpty) {
                styles[fileName] = cssString;
                _logger.fine('Extracted CSS: $fileName (${cssString.length} chars)');
              }
            } catch (e) {
              _logger.warning('Failed to extract CSS from $fileName: $e');
            }
          }
        }
      }

      _logger.fine('Extracted ${styles.length} CSS files');
      return styles;
    } catch (e, stackTrace) {
      _logger.severe('Error extracting styles', e, stackTrace);
      return {};
    }
  }

  /// Get embedded image data by filename or ID
  /// Returns null if not found
  static Uint8List? getEmbeddedImage(EpubBook epubBook, String imageRef) {
    try {
      final images = epubBook.Content?.Images;
      if (images == null || images.isEmpty) {
        return null;
      }

      // Try exact match first
      if (images.containsKey(imageRef)) {
        final content = images[imageRef]!.Content;
        if (content != null && content.isNotEmpty) {
          return Uint8List.fromList(content);
        }
      }

      // Try partial match (handle relative paths)
      final normalizedRef = imageRef.replaceAll('\\', '/');
      for (final entry in images.entries) {
        final normalizedKey = entry.key.replaceAll('\\', '/');
        if (normalizedKey.endsWith(normalizedRef) ||
            normalizedKey.contains(normalizedRef)) {
          final content = entry.value.Content;
          if (content != null && content.isNotEmpty) {
            return Uint8List.fromList(content);
          }
        }
      }

      _logger.fine('Image not found: $imageRef');
      return null;
    } catch (e, stackTrace) {
      _logger.severe('Error getting embedded image: $imageRef', e, stackTrace);
      return null;
    }
  }

  /// Generate a CFI (Canonical Fragment Identifier) for a position in a chapter
  /// Simplified CFI generation for basic navigation
  /// Format: epubcfi(/6/[spine-position]!/4[/element-path][:character-offset])
  static String generateCfi({
    required String chapterId,
    required int spinePosition,
    String? elementPath,
    int? characterOffset,
  }) {
    try {
      // Spine position in CFI format (even numbers)
      final spineIndex = (spinePosition * 2) + 2;

      // Build CFI
      final cfiParts = ['/6/$spineIndex'];

      // Add chapter ID if available
      if (chapterId.isNotEmpty) {
        cfiParts.add('[$chapterId]');
      }

      cfiParts.add('!');

      // Add element path if available
      if (elementPath != null && elementPath.isNotEmpty) {
        cfiParts.add(elementPath);
      } else {
        cfiParts.add('/4'); // Default to body element
      }

      // Add character offset if available
      if (characterOffset != null) {
        cfiParts.add(':$characterOffset');
      }

      final cfi = 'epubcfi(${cfiParts.join('')})';
      _logger.fine('Generated CFI: $cfi');
      return cfi;
    } catch (e, stackTrace) {
      _logger.severe('Error generating CFI', e, stackTrace);
      // Return a fallback CFI
      return 'epubcfi(/6/${(spinePosition * 2) + 2}!/4)';
    }
  }

  /// Parse a CFI string and extract components
  /// Returns a map with spine position, chapter ID, and offset
  static Map<String, dynamic> parseCfi(String cfi) {
    try {
      final result = <String, dynamic>{
        'spinePosition': 0,
        'chapterId': null,
        'elementPath': null,
        'characterOffset': null,
      };

      // Remove epubcfi() wrapper
      final content = cfi.replaceAll('epubcfi(', '').replaceAll(')', '');

      // Split by ! to separate spine and content parts
      final parts = content.split('!');
      if (parts.isEmpty) return result;

      // Parse spine part (e.g., /6/4[chapter-id])
      final spinePart = parts[0];
      final spineMatch = RegExp(r'/6/(\d+)(?:\[([^\]]+)\])?').firstMatch(spinePart);
      if (spineMatch != null) {
        final spineIndex = int.tryParse(spineMatch.group(1) ?? '0') ?? 0;
        result['spinePosition'] = (spineIndex - 2) ~/ 2;
        result['chapterId'] = spineMatch.group(2);
      }

      // Parse content part if available
      if (parts.length > 1) {
        final contentPart = parts[1];

        // Extract character offset
        final offsetMatch = RegExp(r':(\d+)').firstMatch(contentPart);
        if (offsetMatch != null) {
          result['characterOffset'] = int.tryParse(offsetMatch.group(1) ?? '0');
        }

        // Extract element path (everything before the offset)
        final pathPart = contentPart.split(':')[0];
        if (pathPart.isNotEmpty) {
          result['elementPath'] = pathPart;
        }
      }

      _logger.fine('Parsed CFI: $result');
      return result;
    } catch (e, stackTrace) {
      _logger.severe('Error parsing CFI: $cfi', e, stackTrace);
      return {
        'spinePosition': 0,
        'chapterId': null,
        'elementPath': null,
        'characterOffset': null,
      };
    }
  }

  /// Strip HTML tags from text
  /// Useful for search and text extraction
  static String stripHtmlTags(String html) {
    try {
      if (html.trim().isEmpty) {
        return '';
      }

      final document = html_parser.parse(html);
      return document.body?.text ?? '';
    } catch (e) {
      // Fallback to regex-based stripping
      final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
      return html
          .replaceAll(exp, ' ')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
  }

  // Private helper methods

  /// Build TOC from navigation points
  static List<TocEntry> _buildTocFromNavigation(List<EpubNavigationPoint> navigation) {
    final entries = <TocEntry>[];
    for (var i = 0; i < navigation.length; i++) {
      entries.add(_convertNavPointToTocEntry(navigation[i], i, 0));
    }
    return entries;
  }

  /// Build TOC from chapters
  static List<TocEntry> _buildTocFromChapters(List<EpubChapter> chapters) {
    final entries = <TocEntry>[];
    for (var i = 0; i < chapters.length; i++) {
      entries.add(_convertChapterToTocEntry(chapters[i], i, 0));
    }
    return entries;
  }

  /// Build TOC from spine items (last resort)
  static List<TocEntry> _buildTocFromSpine(
    EpubBook epubBook,
    List<EpubSpineItemRef> spineItems,
  ) {
    final entries = <TocEntry>[];
    final manifest = epubBook.Schema?.Package?.Manifest?.Items ?? [];

    for (var i = 0; i < spineItems.length; i++) {
      final spineItem = spineItems[i];

      // Find corresponding manifest item
      final manifestItem = manifest.where((item) => item.Id == spineItem.IdRef).firstOrNull;

      final href = manifestItem?.Href ?? '';
      final title = _extractTitleFromHref(href);

      entries.add(TocEntry(
        id: spineItem.IdRef ?? 'spine_$i',
        title: title,
        href: href,
        level: 0,
      ));
    }

    return entries;
  }

  /// Extract navigation points from EpubNavigation
  static List<EpubNavigationPoint> _extractNavigationPoints(dynamic navigation) {
    final List<EpubNavigationPoint> points = [];

    // Handle different possible types for navigation
    if (navigation == null) return points;

    // If it's already a list, return it
    if (navigation is List<EpubNavigationPoint>) {
      return navigation;
    }

    // If it has a NavMap property (common in epubx)
    try {
      final navMap = (navigation as dynamic).NavMap;
      if (navMap != null) {
        final navPoints = (navMap as dynamic).Points;
        if (navPoints is List) {
          return navPoints.cast<EpubNavigationPoint>();
        }
      }
    } catch (e) {
      _logger.fine('Could not extract nav points from navigation: $e');
    }

    return points;
  }

  /// Convert navigation point to TOC entry
  static TocEntry _convertNavPointToTocEntry(
    EpubNavigationPoint navPoint,
    int index,
    int level,
  ) {
    final children = <TocEntry>[];

    // Try to access child navigation points
    try {
      final childPoints = (navPoint as dynamic).Children;
      if (childPoints != null && childPoints is List && childPoints.isNotEmpty) {
        for (var i = 0; i < childPoints.length; i++) {
          if (childPoints[i] is EpubNavigationPoint) {
            children.add(_convertNavPointToTocEntry(
              childPoints[i] as EpubNavigationPoint,
              i,
              level + 1,
            ));
          }
        }
      }
    } catch (e) {
      // No children or error accessing them
      _logger.fine('No children for nav point at level $level: $e');
    }

    // Get the navigation label
    String title = 'Chapter ${index + 1}';
    try {
      final labels = (navPoint as dynamic).NavigationLabels;
      if (labels != null && labels is List && labels.isNotEmpty) {
        final firstLabel = labels.first;
        title = (firstLabel as dynamic).Text ?? title;
      }
    } catch (e) {
      _logger.fine('Could not get label from nav point: $e');
    }

    // Get the content source
    String href = '';
    try {
      final content = (navPoint as dynamic).Content;
      if (content != null) {
        final source = (content as dynamic).Source;
        href = source?.toString() ?? '';
      }
    } catch (e) {
      _logger.fine('Could not get href from nav point: $e');
    }

    return TocEntry(
      id: navPoint.Id ?? 'nav_$index',
      title: title,
      href: href,
      level: level,
      children: children,
    );
  }

  /// Convert chapter to TOC entry
  static TocEntry _convertChapterToTocEntry(
    EpubChapter chapter,
    int index,
    int level,
  ) {
    final children = <TocEntry>[];
    if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
      for (var i = 0; i < chapter.SubChapters!.length; i++) {
        children.add(_convertChapterToTocEntry(chapter.SubChapters![i], i, level + 1));
      }
    }

    return TocEntry(
      id: chapter.Anchor ?? 'chapter_$index',
      title: chapter.Title ?? 'Chapter ${index + 1}',
      href: chapter.ContentFileName ?? '',
      level: level,
      children: children,
    );
  }

  /// Find image by ID in manifest
  static Uint8List? _findImageById(EpubBook epubBook, String id) {
    try {
      final manifest = epubBook.Schema?.Package?.Manifest?.Items;
      if (manifest == null) return null;

      final item = manifest.firstWhere(
        (item) => item.Id == id,
        orElse: () => EpubManifestItem(),
      );

      if (item.Href != null) {
        return _findImageByHref(epubBook, item.Href!);
      }

      return null;
    } catch (e) {
      _logger.fine('Image not found by ID: $id');
      return null;
    }
  }

  /// Find image by href/path
  static Uint8List? _findImageByHref(EpubBook epubBook, String href) {
    try {
      final images = epubBook.Content?.Images;
      if (images == null) return null;

      // Try exact match
      if (images.containsKey(href)) {
        final content = images[href]!.Content;
        if (content != null && content.isNotEmpty) {
          return Uint8List.fromList(content);
        }
      }

      // Try normalized path matching
      final normalizedHref = href.replaceAll('\\', '/');
      for (final entry in images.entries) {
        final normalizedKey = entry.key.replaceAll('\\', '/');
        if (normalizedKey == normalizedHref ||
            normalizedKey.endsWith(normalizedHref)) {
          final content = entry.value.Content;
          if (content != null && content.isNotEmpty) {
            return Uint8List.fromList(content);
          }
        }
      }

      return null;
    } catch (e) {
      _logger.fine('Image not found by href: $href');
      return null;
    }
  }

  /// Extract a readable title from href
  static String _extractTitleFromHref(String href) {
    try {
      // Remove path and extension
      final fileName = href.split('/').last.split('.').first;

      // Convert underscores and hyphens to spaces
      final title = fileName
          .replaceAll('_', ' ')
          .replaceAll('-', ' ')
          .trim();

      // Capitalize first letter of each word
      final words = title.split(' ');
      final capitalizedWords = words.map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      });

      return capitalizedWords.join(' ');
    } catch (e) {
      return 'Untitled';
    }
  }
}
