import 'package:equatable/equatable.dart';

/// Represents a downloadable file in a catalog entry.
///
/// This is typically an acquisition link in OPDS or a file in
/// a Nextcloud/Kavita library.
class CatalogFile extends Equatable {
  const CatalogFile({
    required this.href,
    required this.mimeType,
    this.size,
    this.title,
    this.isPrimary = false,
    this.properties = const {},
  });

  /// The URL to download this file.
  final String href;

  /// The MIME type of the file (e.g., 'application/epub+zip').
  final String mimeType;

  /// The size of the file in bytes, if known.
  final int? size;

  /// Optional title/label for this file.
  final String? title;

  /// Whether this is the primary/preferred file for the entry.
  ///
  /// For entries with multiple files (e.g., EPUB and PDF versions),
  /// this indicates which one should be preferred.
  final bool isPrimary;

  /// Additional provider-specific properties.
  final Map<String, dynamic> properties;

  /// Returns the file extension based on the MIME type or href.
  String? get extension {
    // Try to get from MIME type first
    final ext = _mimeToExtension[mimeType.toLowerCase()];
    if (ext != null) return ext;

    // Fall back to parsing the href
    final uri = Uri.tryParse(href);
    if (uri != null) {
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1 && lastDot < path.length - 1) {
        return path.substring(lastDot + 1).toLowerCase();
      }
    }
    return null;
  }

  /// Whether this file is an EPUB.
  bool get isEpub =>
      mimeType.toLowerCase() == 'application/epub+zip' || extension == 'epub';

  /// Whether this file is a PDF.
  bool get isPdf =>
      mimeType.toLowerCase() == 'application/pdf' || extension == 'pdf';

  /// Whether this file is a comic book archive.
  bool get isComic {
    final ext = extension;
    return ext == 'cbz' || ext == 'cbr' || ext == 'cb7';
  }

  static const _mimeToExtension = {
    'application/epub+zip': 'epub',
    'application/pdf': 'pdf',
    'application/x-cbz': 'cbz',
    'application/x-cbr': 'cbr',
    'application/vnd.comicbook+zip': 'cbz',
    'application/vnd.comicbook-rar': 'cbr',
    'application/x-mobipocket-ebook': 'mobi',
    'application/vnd.amazon.ebook': 'azw',
  };

  @override
  List<Object?> get props => [
    href,
    mimeType,
    size,
    title,
    isPrimary,
    properties,
  ];
}
