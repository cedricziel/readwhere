import 'package:equatable/equatable.dart';

import '../../core/constants/app_constants.dart';

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

  const OpdsLink({
    required this.href,
    required this.rel,
    required this.type,
    this.title,
    this.length,
    this.price,
    this.currency,
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

  /// Get the file extension based on MIME type
  String? get fileExtension {
    switch (type) {
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
      default:
        return null;
    }
  }

  /// Whether this link's format is supported by the app
  bool get isSupportedFormat {
    final ext = fileExtension;
    if (ext == null) return false;
    return AppConstants.supportedBookFormats.contains(ext);
  }

  OpdsLink copyWith({
    String? href,
    String? rel,
    String? type,
    String? title,
    int? length,
    String? price,
    String? currency,
  }) {
    return OpdsLink(
      href: href ?? this.href,
      rel: rel ?? this.rel,
      type: type ?? this.type,
      title: title ?? this.title,
      length: length ?? this.length,
      price: price ?? this.price,
      currency: currency ?? this.currency,
    );
  }

  @override
  List<Object?> get props => [href, rel, type, title, length, price, currency];

  @override
  String toString() => 'OpdsLink(rel: $rel, type: $type, href: $href)';
}
