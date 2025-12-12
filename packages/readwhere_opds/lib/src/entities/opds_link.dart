import 'package:equatable/equatable.dart';

/// OPDS link relation types
class OpdsLinkRel {
  static const String self = 'self';
  static const String start = 'start';
  static const String subsection = 'subsection';
  static const String search = 'search';
  static const String next = 'next';
  static const String previous = 'previous';
  static const String first = 'first';
  static const String last = 'last';
  static const String acquisition = 'http://opds-spec.org/acquisition';
  static const String acquisitionOpenAccess =
      'http://opds-spec.org/acquisition/open-access';
  static const String acquisitionBuy = 'http://opds-spec.org/acquisition/buy';
  static const String acquisitionBorrow =
      'http://opds-spec.org/acquisition/borrow';
  static const String acquisitionSample =
      'http://opds-spec.org/acquisition/sample';
  static const String image = 'http://opds-spec.org/image';
  static const String thumbnail = 'http://opds-spec.org/image/thumbnail';
  static const String facet = 'http://opds-spec.org/facet';
  static const String related = 'related';
  static const String alternate = 'alternate';

  OpdsLinkRel._();
}

/// OPDS common MIME types
class OpdsMimeType {
  static const String atomFeed = 'application/atom+xml';
  static const String opdsNavigation =
      'application/atom+xml;profile=opds-catalog;kind=navigation';
  static const String opdsAcquisition =
      'application/atom+xml;profile=opds-catalog;kind=acquisition';
  static const String opensearchDescription =
      'application/opensearchdescription+xml';
  static const String epub = 'application/epub+zip';
  static const String pdf = 'application/pdf';
  static const String mobi = 'application/x-mobipocket-ebook';
  static const String cbz = 'application/vnd.comicbook+zip';
  static const String cbr = 'application/vnd.comicbook-rar';

  OpdsMimeType._();
}

/// Default supported book formats for OPDS
const List<String> defaultSupportedFormats = [
  'epub',
  'pdf',
  'mobi',
  'azw',
  'azw3',
  'cbr',
  'cbz',
];

/// Represents an OPDS link element
class OpdsLink extends Equatable {
  /// The URL this link points to
  final String href;

  /// The relationship type (rel attribute)
  final String rel;

  /// The MIME type of the linked resource
  final String type;

  /// Optional title for the link
  final String? title;

  /// Optional length in bytes (for acquisition links)
  final int? length;

  /// Optional price (for paid acquisition)
  final String? price;

  /// Optional currency code (for paid acquisition)
  final String? currency;

  /// Facet group name (for facet links)
  final String? facetGroup;

  /// Whether this facet is active (for facet links)
  final bool? activeFacet;

  /// Item count for this facet (from thr:count)
  final int? count;

  const OpdsLink({
    required this.href,
    required this.rel,
    required this.type,
    this.title,
    this.length,
    this.price,
    this.currency,
    this.facetGroup,
    this.activeFacet,
    this.count,
  });

  /// Whether this is a navigation link
  bool get isNavigation =>
      rel == OpdsLinkRel.subsection ||
      type.contains('kind=navigation') ||
      (type == OpdsMimeType.atomFeed && !isAcquisition);

  /// Whether this is an acquisition link (book download)
  bool get isAcquisition => rel.startsWith('http://opds-spec.org/acquisition');

  /// Whether this is an image link
  bool get isImage => rel == OpdsLinkRel.image || rel == OpdsLinkRel.thumbnail;

  /// Whether this is a thumbnail link
  bool get isThumbnail => rel == OpdsLinkRel.thumbnail;

  /// Whether this is a search link
  bool get isSearch => rel == OpdsLinkRel.search;

  /// Whether this is a facet link
  bool get isFacet => rel == OpdsLinkRel.facet;

  /// Whether this is a pagination link
  bool get isPagination =>
      rel == OpdsLinkRel.next ||
      rel == OpdsLinkRel.previous ||
      rel == OpdsLinkRel.first ||
      rel == OpdsLinkRel.last;

  /// Whether this link points to an EPUB file
  bool get isEpub => type == OpdsMimeType.epub;

  /// Whether this link points to a PDF file
  bool get isPdf => type == OpdsMimeType.pdf;

  /// Get the file extension based on MIME type or URL
  String? get fileExtension {
    // First try MIME type
    final mimeExt = _extensionFromMimeType(type);
    if (mimeExt != null) return mimeExt;

    // Fallback: try to extract from URL
    return _extensionFromUrl(href);
  }

  /// Extract extension from MIME type
  static String? _extensionFromMimeType(String mimeType) {
    final normalizedType = mimeType.toLowerCase().trim();

    // Exact matches
    switch (normalizedType) {
      case OpdsMimeType.epub:
        return 'epub';
      case OpdsMimeType.pdf:
        return 'pdf';
      case OpdsMimeType.mobi:
        return 'mobi';
      case OpdsMimeType.cbz:
        return 'cbz';
      case OpdsMimeType.cbr:
        return 'cbr';
    }

    // Handle variations (x-cbr, x-cbz, etc.)
    if (normalizedType.contains('cbz') ||
        normalizedType.contains('comicbook+zip')) {
      return 'cbz';
    }
    if (normalizedType.contains('cbr') ||
        normalizedType.contains('comicbook-rar') ||
        normalizedType.contains('x-rar')) {
      return 'cbr';
    }
    if (normalizedType.contains('epub')) {
      return 'epub';
    }
    if (normalizedType.contains('pdf')) {
      return 'pdf';
    }
    if (normalizedType.contains('mobi') ||
        normalizedType.contains('mobipocket')) {
      return 'mobi';
    }

    return null;
  }

  /// Extract extension from URL path
  static String? _extensionFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();

      // Common book extensions
      const extensions = ['epub', 'pdf', 'mobi', 'azw', 'azw3', 'cbr', 'cbz'];
      for (final ext in extensions) {
        if (path.endsWith('.$ext')) {
          return ext;
        }
      }
    } catch (_) {
      // Invalid URL, ignore
    }
    return null;
  }

  /// Whether this link's format is supported by the app.
  ///
  /// Uses [defaultSupportedFormats] by default. Use [isSupportedFormatWith]
  /// to check against a custom list of supported formats.
  bool get isSupportedFormat => isSupportedFormatWith(defaultSupportedFormats);

  /// Whether this link's format is in the given list of supported formats.
  bool isSupportedFormatWith(List<String> supportedFormats) {
    final ext = fileExtension;
    if (ext == null) return false;
    return supportedFormats.contains(ext);
  }

  OpdsLink copyWith({
    String? href,
    String? rel,
    String? type,
    String? title,
    int? length,
    String? price,
    String? currency,
    String? facetGroup,
    bool? activeFacet,
    int? count,
  }) {
    return OpdsLink(
      href: href ?? this.href,
      rel: rel ?? this.rel,
      type: type ?? this.type,
      title: title ?? this.title,
      length: length ?? this.length,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      facetGroup: facetGroup ?? this.facetGroup,
      activeFacet: activeFacet ?? this.activeFacet,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [
    href,
    rel,
    type,
    title,
    length,
    price,
    currency,
    facetGroup,
    activeFacet,
    count,
  ];

  @override
  String toString() => 'OpdsLink(rel: $rel, type: $type, href: $href)';
}
