import '../entities/rss_enclosure.dart';
import '../entities/rss_feed.dart';
import '../entities/rss_item.dart';

/// Extensions and utilities for converting RSS entities
extension RssFeedExtensions on RssFeed {
  /// Filter items to only those with supported enclosures
  RssFeed filterToSupportedFormats() {
    return copyWith(
      items: items.where((item) => item.hasSupportedEnclosures).toList(),
    );
  }

  /// Get the total number of supported enclosures across all items
  int get totalSupportedEnclosures {
    return items.fold(0, (sum, item) => sum + item.supportedEnclosures.length);
  }
}

/// Extensions for RssItem
extension RssItemExtensions on RssItem {
  /// Get the primary enclosure (first supported format)
  RssEnclosure? get primaryEnclosure {
    final supported = supportedEnclosures;
    return supported.isNotEmpty ? supported.first : null;
  }

  /// Get display subtitle (author or category)
  String? get displaySubtitle {
    if (author != null && author!.isNotEmpty) {
      return author;
    }
    if (categories.isNotEmpty) {
      return categories.first.label;
    }
    return null;
  }
}

/// Extensions for RssEnclosure
extension RssEnclosureExtensions on RssEnclosure {
  /// Get a human-readable format name
  String get formatName {
    if (type != null) {
      switch (type!.toLowerCase()) {
        case 'application/epub+zip':
          return 'EPUB';
        case 'application/pdf':
          return 'PDF';
        case 'application/x-mobipocket-ebook':
          return 'MOBI';
        case 'application/x-cbz':
        case 'application/vnd.comicbook+zip':
          return 'CBZ';
        case 'application/x-cbr':
        case 'application/vnd.comicbook-rar':
          return 'CBR';
      }
    }

    // Fall back to extension
    final ext = _getExtension();
    if (ext != null) {
      return ext.toUpperCase();
    }

    return 'Unknown';
  }

  String? _getExtension() {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      if (lastDot >= 0 && lastDot < path.length - 1) {
        return path.substring(lastDot + 1).toLowerCase();
      }
    } catch (_) {}
    return null;
  }

  /// Get human-readable file size
  String? get humanReadableSize {
    if (length == null) return null;

    final bytes = length!;
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
