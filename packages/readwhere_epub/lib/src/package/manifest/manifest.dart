import 'package:equatable/equatable.dart';

/// A single item in the EPUB manifest.
///
/// Each manifest item represents a resource (content document, stylesheet,
/// image, etc.) included in the EPUB.
class ManifestItem extends Equatable {
  /// Unique identifier for this item within the manifest.
  final String id;

  /// Path to the resource, relative to the OPF file.
  final String href;

  /// MIME type of the resource.
  final String mediaType;

  /// Properties for this item (e.g., "nav", "cover-image", "scripted").
  final Set<String> properties;

  /// ID of a fallback item for foreign resources.
  final String? fallback;

  /// ID of the media overlay document for this item.
  final String? mediaOverlay;

  const ManifestItem({
    required this.id,
    required this.href,
    required this.mediaType,
    this.properties = const {},
    this.fallback,
    this.mediaOverlay,
  });

  /// Whether this item is an XHTML content document.
  bool get isXhtml =>
      mediaType == 'application/xhtml+xml' || mediaType == 'text/html';

  /// Whether this item is a CSS stylesheet.
  bool get isCss => mediaType == 'text/css';

  /// Whether this item is an image.
  bool get isImage => mediaType.startsWith('image/');

  /// Whether this item is a font.
  bool get isFont =>
      mediaType.startsWith('font/') ||
      mediaType == 'application/font-woff' ||
      mediaType == 'application/font-woff2' ||
      mediaType == 'application/vnd.ms-opentype' ||
      mediaType == 'application/font-sfnt';

  /// Whether this item is audio.
  bool get isAudio => mediaType.startsWith('audio/');

  /// Whether this item is video.
  bool get isVideo => mediaType.startsWith('video/');

  /// Whether this item is the navigation document (EPUB 3).
  bool get isNav => properties.contains('nav');

  /// Whether this item is the cover image.
  bool get isCoverImage => properties.contains('cover-image');

  /// Whether this item contains scripting.
  bool get isScripted => properties.contains('scripted');

  /// Whether this item contains MathML.
  bool get hasMathML => properties.contains('mathml');

  /// Whether this item contains SVG.
  bool get hasSVG => properties.contains('svg');

  /// Whether this item uses remote resources.
  bool get hasRemoteResources => properties.contains('remote-resources');

  /// Whether this is a core media type (doesn't need fallback).
  bool get isCoreMediaType {
    return _coreMediaTypes.contains(mediaType);
  }

  /// File extension extracted from href.
  String get extension {
    final dotIndex = href.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex >= href.length - 1) {
      return '';
    }
    return href.substring(dotIndex);
  }

  @override
  List<Object?> get props =>
      [id, href, mediaType, properties, fallback, mediaOverlay];

  @override
  String toString() => 'ManifestItem($id: $href [$mediaType])';

  /// Core media types per EPUB 3.3 specification.
  static const Set<String> _coreMediaTypes = {
    // Image
    'image/gif',
    'image/jpeg',
    'image/png',
    'image/svg+xml',
    'image/webp',
    // Audio
    'audio/mpeg',
    'audio/mp4',
    'audio/ogg',
    // Content
    'application/xhtml+xml',
    'text/css',
    'application/javascript',
    // Font
    'font/otf',
    'font/ttf',
    'font/woff',
    'font/woff2',
    'application/font-woff',
    'application/font-woff2',
    'application/vnd.ms-opentype',
    'application/font-sfnt',
    // Other
    'application/smil+xml',
    'application/x-dtbncx+xml', // NCX
  };
}

/// The complete manifest of an EPUB package.
///
/// Contains all resources declared in the package document.
class EpubManifest extends Equatable {
  final Map<String, ManifestItem> _itemsById;
  final Map<String, ManifestItem> _itemsByHref;

  EpubManifest._(this._itemsById, this._itemsByHref);

  /// Creates a manifest from a list of items.
  factory EpubManifest(List<ManifestItem> items) {
    final byId = <String, ManifestItem>{};
    final byHref = <String, ManifestItem>{};

    for (final item in items) {
      byId[item.id] = item;
      byHref[item.href.toLowerCase()] = item;
    }

    return EpubManifest._(byId, byHref);
  }

  /// All manifest items.
  Iterable<ManifestItem> get items => _itemsById.values;

  /// Number of items in the manifest.
  int get length => _itemsById.length;

  /// Gets an item by its manifest ID.
  ManifestItem? operator [](String id) => _itemsById[id];

  /// Gets an item by its manifest ID.
  ManifestItem? getById(String id) => _itemsById[id];

  /// Gets an item by its href (case-insensitive).
  ManifestItem? getByHref(String href) {
    return _itemsByHref[href.toLowerCase()];
  }

  /// All items with a specific media type.
  Iterable<ManifestItem> itemsByMediaType(String mediaType) {
    return items.where((item) => item.mediaType == mediaType);
  }

  /// All items with a specific property.
  Iterable<ManifestItem> itemsByProperty(String property) {
    return items.where((item) => item.properties.contains(property));
  }

  /// All XHTML content documents.
  Iterable<ManifestItem> get contentDocuments {
    return items.where((item) => item.isXhtml);
  }

  /// All CSS stylesheets.
  Iterable<ManifestItem> get stylesheets {
    return items.where((item) => item.isCss);
  }

  /// All images.
  Iterable<ManifestItem> get images {
    return items.where((item) => item.isImage);
  }

  /// All fonts.
  Iterable<ManifestItem> get fonts {
    return items.where((item) => item.isFont);
  }

  /// The navigation document (EPUB 3), if present.
  ManifestItem? get navigationDocument {
    return items.where((item) => item.isNav).firstOrNull;
  }

  /// The NCX document (EPUB 2), if present.
  ManifestItem? get ncx {
    return items
        .where(
          (item) => item.mediaType == 'application/x-dtbncx+xml',
        )
        .firstOrNull;
  }

  /// The cover image item, if declared with cover-image property.
  ManifestItem? get coverImage {
    return items.where((item) => item.isCoverImage).firstOrNull;
  }

  /// Checks if an item exists by ID.
  bool containsId(String id) => _itemsById.containsKey(id);

  /// Checks if an item exists by href.
  bool containsHref(String href) =>
      _itemsByHref.containsKey(href.toLowerCase());

  @override
  List<Object?> get props => [_itemsById];
}
