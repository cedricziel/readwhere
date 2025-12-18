import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../container/epub_container.dart';
import '../content/content_document.dart';
import '../decryption/decryption_context.dart';
import '../encryption/encryption_info.dart';
import '../encryption/encryption_parser.dart';
import '../errors/epub_exception.dart';
import '../media/smil_models.dart';
import '../media/smil_parser.dart';
import '../navigation/nav_document.dart';
import '../navigation/ncx_parser.dart';
import '../navigation/toc.dart';
import '../package/manifest/manifest.dart';
import '../package/metadata/metadata.dart';
import '../package/package_document.dart';
import '../package/spine/spine.dart';
import '../resources/cover_extractor.dart';
import '../resources/image.dart';
import '../resources/resource.dart';
import '../resources/stylesheet.dart';
import '../utils/path_utils.dart';
import 'epub_book.dart';

/// Primary entry point for reading EPUB files.
///
/// Example usage:
/// ```dart
/// final reader = await EpubReader.open('/path/to/book.epub');
/// print('Title: ${reader.metadata.title}');
/// print('Author: ${reader.metadata.author}');
///
/// // Get chapters
/// for (var i = 0; i < reader.spine.length; i++) {
///   final chapter = reader.getChapter(i);
///   print('Chapter ${i + 1}: ${chapter.title}');
/// }
///
/// // Get cover
/// final cover = reader.getCoverImage();
/// if (cover != null) {
///   print('Cover: ${cover.bytes.length} bytes');
/// }
/// ```
class EpubReader {
  /// The underlying EPUB container (ZIP archive).
  final EpubContainer _container;

  /// The parsed package document.
  final PackageDocument _package;

  /// The navigation structure.
  final EpubNavigation _navigation;

  /// Decryption context for encrypted resources.
  final DecryptionContext _decryptionContext;

  /// Cached chapters.
  final Map<int, EpubChapter> _chapterCache = {};

  EpubReader._({
    required EpubContainer container,
    required PackageDocument package,
    required EpubNavigation navigation,
    required DecryptionContext decryptionContext,
  })  : _container = container,
        _package = package,
        _navigation = navigation,
        _decryptionContext = decryptionContext;

  /// Opens an EPUB from a file path.
  ///
  /// [filePath] - Path to the EPUB file.
  /// [passphrase] - Optional passphrase for LCP-protected EPUBs.
  ///
  /// Throws [EpubReadException] if the file cannot be read.
  /// Throws [EpubValidationException] if the EPUB structure is invalid.
  /// Throws [EpubParseException] if parsing fails.
  static Future<EpubReader> open(String filePath, {String? passphrase}) async {
    final container = await EpubContainer.fromFile(filePath);
    return _createFromContainer(container, passphrase: passphrase);
  }

  /// Opens an EPUB from bytes.
  ///
  /// [bytes] - The EPUB file content.
  /// [passphrase] - Optional passphrase for LCP-protected EPUBs.
  ///
  /// Throws [EpubReadException] if the bytes are not a valid ZIP.
  /// Throws [EpubValidationException] if the EPUB structure is invalid.
  /// Throws [EpubParseException] if parsing fails.
  static EpubReader openBytes(Uint8List bytes, {String? passphrase}) {
    final container = EpubContainer.fromBytes(bytes);
    return _createFromContainer(container, passphrase: passphrase);
  }

  /// Opens an EPUB from a File object.
  ///
  /// [file] - The EPUB file.
  /// [passphrase] - Optional passphrase for LCP-protected EPUBs.
  static Future<EpubReader> openFile(File file, {String? passphrase}) async {
    final bytes = await file.readAsBytes();
    return openBytes(bytes, passphrase: passphrase);
  }

  static EpubReader _createFromContainer(
    EpubContainer container, {
    String? passphrase,
  }) {
    // Parse OPF package document
    final opfContent = container.readOpf();
    final package = PackageDocument.parse(opfContent, container.opfPath);

    // Parse navigation (try EPUB 3 nav doc first, then NCX)
    final navigation = _parseNavigation(container, package);

    // Create decryption context
    final encryptionInfo = EncryptionParser.parse(
      container.getEncryptionXml(),
      hasRightsFile: container.hasRightsFile(),
      hasLcpLicense: container.hasLcpLicense(),
    );

    final decryptionContext = DecryptionContext.create(
      uniqueIdentifier: package.uniqueIdentifier ?? '',
      encryptionInfo: encryptionInfo,
      lcpLicenseJson: container.getLcpLicenseJson(),
      lcpPassphrase: passphrase,
    );

    return EpubReader._(
      container: container,
      package: package,
      navigation: navigation,
      decryptionContext: decryptionContext,
    );
  }

  /// Parses navigation from nav document or NCX.
  static EpubNavigation _parseNavigation(
    EpubContainer container,
    PackageDocument package,
  ) {
    // Try EPUB 3 navigation document first
    final navItem = package.manifest.navigationDocument;
    if (navItem != null) {
      try {
        final navPath = container.resolveOpfRelativePath(navItem.href);
        final navContent = container.readFileString(navPath);
        return NavDocumentParser.parse(navContent, documentPath: navPath);
      } catch (_) {
        // Fall through to NCX
      }
    }

    // Try EPUB 2 NCX
    final ncxItem = package.manifest.ncx;
    if (ncxItem != null) {
      try {
        final ncxPath = container.resolveOpfRelativePath(ncxItem.href);
        final ncxContent = container.readFileString(ncxPath);
        return NcxParser.parse(ncxContent, documentPath: ncxPath);
      } catch (_) {
        // Fall through to spine fallback
      }
    }

    // Generate navigation from spine as last resort
    return _generateNavigationFromSpine(package);
  }

  /// Generates navigation from spine when no TOC is available.
  static EpubNavigation _generateNavigationFromSpine(PackageDocument package) {
    final entries = <TocEntry>[];

    for (var i = 0; i < package.spine.length; i++) {
      final spineItem = package.spine.items[i];
      final manifestItem = package.manifest.getById(spineItem.idref);
      if (manifestItem == null) continue;

      entries.add(TocEntry(
        id: 'spine-$i',
        title: 'Chapter ${i + 1}',
        href: manifestItem.href,
        level: 0,
      ));
    }

    return EpubNavigation(
      tableOfContents: entries,
      source: NavigationSource.spine,
    );
  }

  // ============================================================
  // Main accessors
  // ============================================================

  /// The complete parsed book.
  EpubBook get book => EpubBook(
        version: _package.version,
        uniqueIdentifier: _package.uniqueIdentifier,
        metadata: _package.metadata,
        manifest: _package.manifest,
        spine: _package.spine,
        navigation: _navigation,
        renditionProperties: _package.renditionProperties,
      );

  /// Book metadata.
  EpubMetadata get metadata => _package.metadata;

  /// Navigation structure (TOC, page list, landmarks).
  EpubNavigation get navigation => _navigation;

  /// Reading order.
  EpubSpine get spine => _package.spine;

  /// All resources.
  EpubManifest get manifest => _package.manifest;

  /// EPUB version.
  EpubVersion get version => _package.version;

  /// Book title.
  String get title => metadata.title;

  /// Primary author.
  String? get author => metadata.author;

  /// Number of chapters.
  int get chapterCount => spine.length;

  // ============================================================
  // Chapter access
  // ============================================================

  /// Gets a chapter by spine index.
  ///
  /// Throws [RangeError] if the index is out of bounds.
  /// Throws [EpubResourceNotFoundException] if the content cannot be found.
  EpubChapter getChapter(int index) {
    if (index < 0 || index >= spine.length) {
      throw RangeError.range(index, 0, spine.length - 1, 'index');
    }

    // Check cache
    if (_chapterCache.containsKey(index)) {
      return _chapterCache[index]!;
    }

    final spineItem = spine.items[index];
    final manifestItem = manifest.getById(spineItem.idref);
    if (manifestItem == null) {
      throw EpubResourceNotFoundException(spineItem.idref);
    }

    final path = _container.resolveOpfRelativePath(manifestItem.href);
    final content = _readDecryptedString(path);

    // Find title from navigation
    final title = _findTitleForHref(manifestItem.href);

    // Resolve resource paths in content
    final resolvedContent =
        ContentExtractor.resolveResourcePaths(content, path);

    final chapter = EpubChapter(
      id: manifestItem.id,
      href: manifestItem.href,
      title: title,
      spineIndex: index,
      content: resolvedContent,
      mediaType: manifestItem.mediaType,
      isLinear: spineItem.linear,
      properties: manifestItem.properties,
    );

    // Cache the chapter
    _chapterCache[index] = chapter;

    return chapter;
  }

  /// Gets a chapter by manifest ID.
  ///
  /// Returns null if the chapter is not found in the spine.
  EpubChapter? getChapterById(String id) {
    for (var i = 0; i < spine.length; i++) {
      if (spine.items[i].idref == id) {
        return getChapter(i);
      }
    }
    return null;
  }

  /// Gets a chapter by href.
  ///
  /// Returns null if the chapter is not found in the spine.
  EpubChapter? getChapterByHref(String href) {
    final normalizedHref = PathUtils.normalize(href).toLowerCase();
    final docHref = PathUtils.removeFragment(normalizedHref);

    for (var i = 0; i < spine.length; i++) {
      final spineItem = spine.items[i];
      final manifestItem = manifest.getById(spineItem.idref);
      if (manifestItem == null) continue;

      final itemHref = PathUtils.normalize(manifestItem.href).toLowerCase();
      if (itemHref == docHref || itemHref == normalizedHref) {
        return getChapter(i);
      }
    }
    return null;
  }

  /// Streams all chapters in reading order.
  Stream<EpubChapter> streamChapters() async* {
    for (var i = 0; i < spine.length; i++) {
      yield getChapter(i);
    }
  }

  /// Gets all chapters as a list.
  List<EpubChapter> getAllChapters() {
    return List.generate(spine.length, (i) => getChapter(i));
  }

  /// Finds the TOC title for a given href.
  String? _findTitleForHref(String href) {
    final normalizedHref = href.toLowerCase();
    final docHref = PathUtils.removeFragment(normalizedHref);

    for (final entry in navigation.flattenedToc) {
      final entryDocHref = entry.documentHref.toLowerCase();
      if (entryDocHref == docHref) {
        return entry.title;
      }
    }
    return null;
  }

  // ============================================================
  // Decryption helpers
  // ============================================================

  /// Reads and decrypts a file as bytes.
  Uint8List _readDecryptedBytes(String path) {
    final bytes = _container.readFileBytes(path);
    return _decryptionContext.decryptResource(path, bytes);
  }

  /// Reads and decrypts a file as a string (UTF-8).
  String _readDecryptedString(String path) {
    final bytes = _readDecryptedBytes(path);
    return utf8.decode(bytes);
  }

  // ============================================================
  // Resource access
  // ============================================================

  /// Gets any resource by href.
  ///
  /// Throws [EpubResourceNotFoundException] if the resource is not found.
  /// Throws [DecryptionException] if decryption fails.
  GenericResource getResource(String href) {
    final path = _container.resolveOpfRelativePath(href);
    final bytes = _readDecryptedBytes(path);

    final manifestItem = manifest.getByHref(href);

    return GenericResource(
      id: manifestItem?.id ?? PathUtils.basename(href),
      href: href,
      mediaType: manifestItem?.mediaType ?? 'application/octet-stream',
      bytes: bytes,
      properties: manifestItem?.properties ?? {},
    );
  }

  /// Gets a resource by manifest ID.
  ///
  /// Throws [EpubResourceNotFoundException] if the resource is not found.
  GenericResource getResourceById(String id) {
    final item = manifest.getById(id);
    if (item == null) {
      throw EpubResourceNotFoundException(id);
    }
    return getResource(item.href);
  }

  // ============================================================
  // Cover image
  // ============================================================

  /// Gets the cover image.
  ///
  /// Uses multiple strategies to find the cover:
  /// 1. EPUB 3 manifest cover-image property
  /// 2. EPUB 2 metadata cover meta element
  /// 3. Guide reference
  /// 4. First image in first spine item
  /// 5. Image with "cover" in filename
  CoverImage? getCoverImage() {
    return CoverExtractor.extractCover(
      container: _container,
      manifest: manifest,
      metadata: metadata,
      spine: spine,
    );
  }

  /// Gets the cover image bytes, or null if not found.
  Uint8List? getCoverBytes() {
    return getCoverImage()?.bytes;
  }

  // ============================================================
  // Stylesheets
  // ============================================================

  /// Gets all CSS stylesheets in the EPUB.
  List<EpubStylesheet> getStylesheets() {
    final stylesheets = <EpubStylesheet>[];

    for (final item in manifest.items) {
      if (item.isCss) {
        try {
          final path = _container.resolveOpfRelativePath(item.href);
          final bytes = _readDecryptedBytes(path);
          stylesheets.add(EpubStylesheet(
            id: item.id,
            href: item.href,
            bytes: bytes,
            properties: item.properties,
          ));
        } catch (_) {
          // Skip unavailable stylesheets
        }
      }
    }

    return stylesheets;
  }

  /// Gets a stylesheet collection.
  StylesheetCollection get stylesheetCollection =>
      StylesheetCollection(getStylesheets());

  // ============================================================
  // Images
  // ============================================================

  /// Gets all images in the EPUB.
  List<EpubImage> getImages() {
    final images = <EpubImage>[];

    for (final item in manifest.items) {
      if (item.isImage) {
        try {
          final path = _container.resolveOpfRelativePath(item.href);
          final bytes = _readDecryptedBytes(path);
          images.add(EpubImage(
            id: item.id,
            href: item.href,
            mediaType: item.mediaType,
            bytes: bytes,
            properties: item.properties,
          ));
        } catch (_) {
          // Skip unavailable images
        }
      }
    }

    return images;
  }

  /// Gets an image by href.
  EpubImage? getImage(String href) {
    final item = manifest.getByHref(href);
    if (item == null || !item.isImage) return null;

    try {
      final path = _container.resolveOpfRelativePath(item.href);
      final bytes = _readDecryptedBytes(path);
      return EpubImage(
        id: item.id,
        href: item.href,
        mediaType: item.mediaType,
        bytes: bytes,
        properties: item.properties,
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // Media Overlays
  // ============================================================

  /// Whether this EPUB has any media overlays.
  bool get hasMediaOverlays {
    return manifest.items.any((item) => item.mediaOverlay != null);
  }

  /// Gets all media overlay manifest items.
  List<ManifestItem> get mediaOverlayItems {
    return manifest.items
        .where((item) =>
            item.mediaType == 'application/smil+xml' ||
            item.properties.contains('media-overlay'))
        .toList();
  }

  /// Gets the media overlay for a specific content document (by manifest ID).
  ///
  /// Returns null if the content document has no media overlay.
  MediaOverlay? getMediaOverlay(String contentId) {
    final contentItem = manifest.getById(contentId);
    if (contentItem == null || contentItem.mediaOverlay == null) return null;

    return getMediaOverlayById(contentItem.mediaOverlay!);
  }

  /// Gets a media overlay by its manifest ID.
  MediaOverlay? getMediaOverlayById(String overlayId) {
    final overlayItem = manifest.getById(overlayId);
    if (overlayItem == null) return null;

    try {
      final path = _container.resolveOpfRelativePath(overlayItem.href);
      final content = _readDecryptedString(path);
      return SmilParser.parse(content, overlayId, overlayItem.href);
    } catch (_) {
      return null;
    }
  }

  /// Gets the media overlay for a spine item by index.
  MediaOverlay? getMediaOverlayBySpineIndex(int index) {
    if (index < 0 || index >= spine.length) return null;

    final spineItem = spine[index];
    return getMediaOverlay(spineItem.idref);
  }

  /// Gets all media overlays in reading order.
  List<MediaOverlay> getAllMediaOverlays() {
    final overlays = <MediaOverlay>[];

    for (var i = 0; i < spine.length; i++) {
      final overlay = getMediaOverlayBySpineIndex(i);
      if (overlay != null) {
        overlays.add(overlay);
      }
    }

    return overlays;
  }

  // ============================================================
  // Validation and info
  // ============================================================

  /// Whether the EPUB has encryption metadata.
  bool get hasEncryption => _container.hasEncryption();

  /// Detailed encryption information.
  ///
  /// Returns [EncryptionInfo.none] if no encryption is detected.
  EncryptionInfo get encryptionInfo => _decryptionContext.encryptionInfo;

  /// The decryption context for this EPUB.
  ///
  /// Use this to check decryption status and capabilities.
  DecryptionContext get decryptionContext => _decryptionContext;

  /// Whether the content can be decrypted.
  ///
  /// Returns true if:
  /// - The EPUB is not encrypted
  /// - The EPUB uses only font obfuscation (no credentials needed)
  /// - LCP encryption and a valid passphrase was provided
  ///
  /// Returns false if:
  /// - Adobe DRM or Apple FairPlay is used (not supported)
  /// - LCP encryption but no/invalid passphrase was provided
  bool get canDecrypt => _decryptionContext.canDecrypt;

  /// Whether this EPUB requires credentials (passphrase) to read.
  ///
  /// Returns true if the EPUB is LCP protected and no valid passphrase
  /// was provided when opening.
  bool get requiresCredentials => _decryptionContext.requiresCredentials;

  /// The passphrase hint for LCP-protected EPUBs.
  ///
  /// Returns null if not LCP protected or no hint is available.
  String? get lcpPassphraseHint => _decryptionContext.lcpPassphraseHint;

  /// Whether this EPUB has an LCP license.
  bool get hasLcpLicense => _container.hasLcpLicense();

  /// A human-readable description of the encryption status.
  String get encryptionDescription => _decryptionContext.description;

  /// Total number of files in the EPUB.
  int get fileCount => _container.fileCount;

  /// All file paths in the EPUB.
  List<String> get filePaths => _container.filePaths;

  /// Checks if a file exists in the EPUB.
  bool hasFile(String path) => _container.hasFile(path);

  /// Clears the chapter cache to free memory.
  void clearCache() {
    _chapterCache.clear();
  }
}
