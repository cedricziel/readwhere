import '../container/cbz_container.dart';
import '../utils/image_utils.dart';
import 'comic_page.dart';

/// Builds an ordered list of [ComicPage] objects from a [CbzContainer].
///
/// This class handles:
/// - Extracting image files from the archive
/// - Sorting them in natural order for proper page sequence
/// - Detecting image formats and optionally reading dimensions
class PageOrderBuilder {
  final CbzContainer _container;

  /// Whether to eagerly load image dimensions.
  ///
  /// When true, dimensions are read when building the page list.
  /// When false, dimensions are set to null (can be loaded later).
  final bool loadDimensions;

  PageOrderBuilder(
    this._container, {
    this.loadDimensions = false,
  });

  /// Builds the ordered list of pages.
  ///
  /// Pages are sorted using natural sort order based on filenames.
  List<ComicPage> build() {
    final imagePaths = _container.imagePaths;
    final pages = <ComicPage>[];

    for (var i = 0; i < imagePaths.length; i++) {
      final path = imagePaths[i];
      pages.add(_createPage(i, path));
    }

    return pages;
  }

  /// Creates a [ComicPage] for a single image file.
  ComicPage _createPage(int index, String path) {
    final filename = _extractFilename(path);
    final fileSize = _container.getFileSize(path);

    // Determine media type from extension initially
    String mediaType = ImageUtils.getMimeTypeForExtension(
      '.${_extractExtension(path)}',
    );

    int? width;
    int? height;

    if (loadDimensions) {
      final bytes = _container.readImageBytes(path);

      // Detect format from actual bytes (more reliable than extension)
      final format = ImageUtils.detectFormat(bytes);
      if (format.isSupported) {
        mediaType = format.mimeType;
      }

      // Try fast dimension extraction first
      final dims = ImageUtils.getDimensionsFast(bytes);
      if (dims != null) {
        width = dims.width;
        height = dims.height;
      }
    }

    // Determine page type - first page is typically the cover
    final type = index == 0 ? PageType.frontCover : PageType.story;

    return ComicPage(
      index: index,
      filename: filename,
      mediaType: mediaType,
      type: type,
      width: width,
      height: height,
      fileSize: fileSize,
    );
  }

  /// Extracts just the filename from a path.
  String _extractFilename(String path) {
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash == -1) return path;
    return path.substring(lastSlash + 1);
  }

  /// Extracts the file extension without the dot.
  String _extractExtension(String path) {
    final filename = _extractFilename(path);
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == filename.length - 1) return '';
    return filename.substring(dotIndex + 1).toLowerCase();
  }
}

/// Utility to enrich a [ComicPage] with dimension information.
///
/// This can be used to lazily load dimensions when needed.
class PageDimensionLoader {
  final CbzContainer _container;

  PageDimensionLoader(this._container);

  /// Loads dimensions for a single page.
  ///
  /// Returns a new [ComicPage] with width and height populated.
  ComicPage loadDimensions(ComicPage page) {
    if (page.width != null && page.height != null) {
      return page; // Already has dimensions
    }

    final path = _container.imagePaths[page.index];
    final bytes = _container.readImageBytes(path);

    // Try fast extraction first
    var dims = ImageUtils.getDimensionsFast(bytes);

    // Fall back to full decode if fast method fails
    dims ??= ImageUtils.getDimensions(bytes);

    return page.copyWith(
      width: dims.width,
      height: dims.height,
    );
  }

  /// Loads dimensions for all pages.
  ///
  /// Returns a new list with all pages having dimensions populated.
  List<ComicPage> loadAllDimensions(List<ComicPage> pages) {
    return pages.map(loadDimensions).toList();
  }
}

/// Applies metadata from ComicInfo.xml to pages.
///
/// This updates page types, bookmarks, and other metadata
/// based on the `<Pages>` element in ComicInfo.xml.
class PageMetadataApplicator {
  /// Applies page metadata to a list of pages.
  ///
  /// [pageInfos] is a list of metadata entries from ComicInfo.xml,
  /// indexed by page number (the `Image` attribute).
  static List<ComicPage> apply(
    List<ComicPage> pages,
    Map<int, PageMetadata> pageInfos,
  ) {
    return pages.map((page) {
      final info = pageInfos[page.index];
      if (info == null) return page;

      return page.copyWith(
        type: info.type ?? page.type,
        width: info.width ?? page.width,
        height: info.height ?? page.height,
        fileSize: info.fileSize ?? page.fileSize,
        isDoublePage: info.isDoublePage ?? page.isDoublePage,
        bookmark: info.bookmark ?? page.bookmark,
      );
    }).toList();
  }
}

/// Metadata for a single page from ComicInfo.xml.
class PageMetadata {
  final PageType? type;
  final int? width;
  final int? height;
  final int? fileSize;
  final bool? isDoublePage;
  final String? bookmark;

  const PageMetadata({
    this.type,
    this.width,
    this.height,
    this.fileSize,
    this.isDoublePage,
    this.bookmark,
  });
}
