import 'package:equatable/equatable.dart';

/// Represents a media attachment in an RSS item
class RssEnclosure extends Equatable {
  /// The URL of the enclosure
  final String url;

  /// The MIME type of the enclosure (e.g., 'application/epub+zip')
  final String? type;

  /// The file size in bytes
  final int? length;

  /// Optional title for the enclosure
  final String? title;

  const RssEnclosure({required this.url, this.type, this.length, this.title});

  /// MIME types that are considered ebook formats
  static const ebookMimeTypes = {
    'application/epub+zip',
    'application/x-mobipocket-ebook',
    'application/pdf',
    'application/x-fictionbook+xml',
    'application/fb2+zip',
  };

  /// MIME types that are considered comic formats
  static const comicMimeTypes = {
    'application/x-cbz',
    'application/x-cbr',
    'application/x-cb7',
    'application/vnd.comicbook+zip',
    'application/vnd.comicbook-rar',
  };

  /// File extensions that are considered ebook formats
  static const ebookExtensions = {'epub', 'mobi', 'azw', 'azw3', 'pdf', 'fb2'};

  /// File extensions that are considered comic formats
  static const comicExtensions = {'cbz', 'cbr', 'cb7', 'cbt'};

  /// Whether this enclosure is an ebook based on MIME type or URL extension
  bool get isEbook {
    if (type != null && ebookMimeTypes.contains(type!.toLowerCase())) {
      return true;
    }
    final ext = _getExtension();
    return ext != null && ebookExtensions.contains(ext.toLowerCase());
  }

  /// Whether this enclosure is a comic based on MIME type or URL extension
  bool get isComic {
    if (type != null && comicMimeTypes.contains(type!.toLowerCase())) {
      return true;
    }
    final ext = _getExtension();
    return ext != null && comicExtensions.contains(ext.toLowerCase());
  }

  /// Whether this enclosure is a supported format (ebook or comic)
  bool get isSupportedFormat => isEbook || isComic;

  /// Get the file extension from the URL
  String? _getExtension() {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      if (lastDot >= 0 && lastDot < path.length - 1) {
        return path.substring(lastDot + 1).toLowerCase();
      }
    } catch (_) {
      // Invalid URL
    }
    return null;
  }

  /// Get the filename from the URL
  String? get filename {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final lastSlash = path.lastIndexOf('/');
      if (lastSlash >= 0 && lastSlash < path.length - 1) {
        return Uri.decodeComponent(path.substring(lastSlash + 1));
      }
    } catch (_) {
      // Invalid URL
    }
    return null;
  }

  @override
  List<Object?> get props => [url, type, length, title];

  @override
  String toString() => 'RssEnclosure(url: $url, type: $type, length: $length)';
}
