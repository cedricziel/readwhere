import 'package:html/parser.dart' as html_parser;

import '../container/epub_container.dart';
import '../errors/epub_exception.dart';
import '../package/manifest/manifest.dart';
import '../package/metadata/metadata.dart';
import '../package/spine/spine.dart';
import '../utils/path_utils.dart';
import 'image.dart';

/// Extracts cover images from EPUB files using multiple strategies.
class CoverExtractor {
  CoverExtractor._();

  /// Attempts to extract the cover image using multiple strategies.
  ///
  /// Returns null if no cover image is found.
  static CoverImage? extractCover({
    required EpubContainer container,
    required EpubManifest manifest,
    required EpubMetadata metadata,
    required EpubSpine spine,
  }) {
    // Strategy 1: EPUB 3 manifest cover-image property
    var cover = _fromManifestProperty(container, manifest);
    if (cover != null) return cover;

    // Strategy 2: EPUB 2 metadata <meta name="cover" content="id">
    cover = _fromMetadataCoverMeta(container, manifest, metadata);
    if (cover != null) return cover;

    // Strategy 3: Guide reference (EPUB 2)
    cover = _fromGuideReference(container, manifest);
    if (cover != null) return cover;

    // Strategy 4: First image in first spine item
    cover = _fromFirstSpineItem(container, manifest, spine);
    if (cover != null) return cover;

    // Strategy 5: Heuristic - image named "cover"
    cover = _fromCoverNameHeuristic(container, manifest);
    if (cover != null) return cover;

    return null;
  }

  /// Strategy 1: EPUB 3 manifest item with cover-image property.
  static CoverImage? _fromManifestProperty(
    EpubContainer container,
    EpubManifest manifest,
  ) {
    final coverItem = manifest.coverImage;
    if (coverItem == null) return null;

    final image = _loadImage(container, coverItem);
    if (image == null) return null;

    return CoverImage(
      image: image,
      method: CoverDiscoveryMethod.manifestProperty,
    );
  }

  /// Strategy 2: EPUB 2 metadata cover meta element.
  static CoverImage? _fromMetadataCoverMeta(
    EpubContainer container,
    EpubManifest manifest,
    EpubMetadata metadata,
  ) {
    final coverId = metadata.coverImageId;
    if (coverId == null) return null;

    final coverItem = manifest.getById(coverId);
    if (coverItem == null) return null;

    final image = _loadImage(container, coverItem);
    if (image == null) return null;

    return CoverImage(
      image: image,
      method: CoverDiscoveryMethod.metadataCoverMeta,
    );
  }

  /// Strategy 3: Guide reference with type="cover".
  static CoverImage? _fromGuideReference(
    EpubContainer container,
    EpubManifest manifest,
  ) {
    // Look for XHTML cover page and extract first image from it
    for (final item in manifest.items) {
      final href = item.href.toLowerCase();
      if (item.isXhtml &&
          (href.contains('cover') || item.id.toLowerCase().contains('cover'))) {
        final image = _extractFirstImageFromDocument(container, item);
        if (image != null) {
          return CoverImage(
            image: image,
            method: CoverDiscoveryMethod.guideReference,
          );
        }
      }
    }
    return null;
  }

  /// Strategy 4: First image in first spine item.
  static CoverImage? _fromFirstSpineItem(
    EpubContainer container,
    EpubManifest manifest,
    EpubSpine spine,
  ) {
    if (spine.isEmpty) return null;

    final firstSpineItem = spine.items.first;
    final manifestItem = manifest.getById(firstSpineItem.idref);
    if (manifestItem == null || !manifestItem.isXhtml) return null;

    final image = _extractFirstImageFromDocument(container, manifestItem);
    if (image != null) {
      return CoverImage(
        image: image,
        method: CoverDiscoveryMethod.firstSpineImage,
      );
    }
    return null;
  }

  /// Strategy 5: Image with "cover" in filename.
  static CoverImage? _fromCoverNameHeuristic(
    EpubContainer container,
    EpubManifest manifest,
  ) {
    // Look for images with "cover" in the name
    for (final item in manifest.items) {
      if (item.isImage) {
        final filename = PathUtils.basename(item.href).toLowerCase();
        final id = item.id.toLowerCase();
        if (filename.contains('cover') || id.contains('cover')) {
          final image = _loadImage(container, item);
          if (image != null) {
            return CoverImage(
              image: image,
              method: CoverDiscoveryMethod.coverNameHeuristic,
            );
          }
        }
      }
    }
    return null;
  }

  /// Loads an image from a manifest item.
  static EpubImage? _loadImage(
    EpubContainer container,
    ManifestItem item,
  ) {
    if (!item.isImage) return null;

    try {
      final path = container.resolveOpfRelativePath(item.href);
      final bytes = container.readFileBytes(path);

      return EpubImage(
        id: item.id,
        href: item.href,
        mediaType: item.mediaType,
        bytes: bytes,
        properties: item.properties,
      );
    } on EpubResourceNotFoundException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Extracts the first image from an XHTML document.
  static EpubImage? _extractFirstImageFromDocument(
    EpubContainer container,
    ManifestItem documentItem,
  ) {
    try {
      final path = container.resolveOpfRelativePath(documentItem.href);
      final content = container.readFileString(path);

      final document = html_parser.parse(content);
      final imgElements = document.querySelectorAll('img, image');

      for (final img in imgElements) {
        final src = img.attributes['src'] ??
            img.attributes['xlink:href'] ??
            img.attributes['href'];
        if (src == null || src.isEmpty) continue;

        // Skip data URIs
        if (src.startsWith('data:')) continue;

        // Resolve the image path relative to the document
        final imagePath = PathUtils.resolve(path, src);

        // Try to load the image
        try {
          final bytes = container.readFileBytes(imagePath);

          // Determine media type
          final mediaType = _guessMediaType(imagePath);

          return EpubImage(
            id: PathUtils.basename(imagePath),
            href: imagePath,
            mediaType: mediaType,
            bytes: bytes,
          );
        } on EpubResourceNotFoundException {
          continue;
        }
      }
    } catch (_) {
      // Ignore errors
    }
    return null;
  }

  /// Guesses the media type from a file path.
  static String _guessMediaType(String path) {
    final ext = PathUtils.extension(path).toLowerCase();
    return switch (ext) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.gif' => 'image/gif',
      '.webp' => 'image/webp',
      '.svg' => 'image/svg+xml',
      '.avif' => 'image/avif',
      _ => 'image/jpeg', // Default
    };
  }
}
