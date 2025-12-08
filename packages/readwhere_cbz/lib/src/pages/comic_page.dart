import 'package:equatable/equatable.dart';

/// Type of comic page based on its content or position.
///
/// Maps to the ComicInfo.xml ComicPageInfo Type attribute.
enum PageType {
  /// Front cover of the comic.
  frontCover('FrontCover'),

  /// Inner cover (inside front/back cover).
  innerCover('InnerCover'),

  /// Roundup or recap page.
  roundup('Roundup'),

  /// Regular story page (default).
  story('Story'),

  /// Advertisement page.
  advertisement('Advertisement'),

  /// Editorial content.
  editorial('Editorial'),

  /// Letters to the editor.
  letters('Letters'),

  /// Preview of another comic.
  preview('Preview'),

  /// Back cover.
  backCover('BackCover'),

  /// Other/miscellaneous content.
  other('Other'),

  /// Marked for deletion (scanlation artifact).
  deleted('Deleted');

  /// The string value used in ComicInfo.xml.
  final String xmlValue;

  const PageType(this.xmlValue);

  /// Parses a string to a [PageType].
  ///
  /// Returns [story] for unknown or null values.
  static PageType parse(String? value) {
    if (value == null || value.isEmpty) return story;

    final lower = value.toLowerCase();
    for (final type in PageType.values) {
      if (type.xmlValue.toLowerCase() == lower) {
        return type;
      }
    }
    return story;
  }
}

/// Represents a single page in a CBZ comic book.
///
/// Contains both structural information (index, filename) and
/// optional metadata from ComicInfo.xml or MetronInfo.xml.
class ComicPage extends Equatable {
  /// Zero-based index of this page in the reading order.
  final int index;

  /// Original filename within the archive (e.g., "page001.jpg").
  final String filename;

  /// MIME type of the image (e.g., "image/jpeg", "image/png").
  final String mediaType;

  /// Type of page content (cover, story, advertisement, etc.).
  final PageType type;

  /// Image width in pixels, if known.
  final int? width;

  /// Image height in pixels, if known.
  final int? height;

  /// File size in bytes, if known.
  final int? fileSize;

  /// Whether this is a double-page spread.
  final bool isDoublePage;

  /// Bookmark or label for this page, if any.
  final String? bookmark;

  const ComicPage({
    required this.index,
    required this.filename,
    required this.mediaType,
    this.type = PageType.story,
    this.width,
    this.height,
    this.fileSize,
    this.isDoublePage = false,
    this.bookmark,
  });

  /// Whether this page is a cover (front or back).
  bool get isCover => type == PageType.frontCover || type == PageType.backCover;

  /// Whether this page is the front cover.
  bool get isFrontCover => type == PageType.frontCover;

  /// Whether this page is the back cover.
  bool get isBackCover => type == PageType.backCover;

  /// Aspect ratio of the image (width/height).
  ///
  /// Returns null if dimensions are not known.
  double? get aspectRatio {
    if (width != null && height != null && height! > 0) {
      return width! / height!;
    }
    return null;
  }

  /// Whether this appears to be a portrait (tall) page.
  ///
  /// Returns null if dimensions are not known.
  bool? get isPortrait {
    final ratio = aspectRatio;
    if (ratio == null) return null;
    return ratio < 1.0;
  }

  /// Whether this appears to be a landscape (wide) page.
  ///
  /// Returns null if dimensions are not known.
  bool? get isLandscape {
    final ratio = aspectRatio;
    if (ratio == null) return null;
    return ratio > 1.0;
  }

  /// File extension extracted from filename.
  String get extension {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == filename.length - 1) return '';
    return filename.substring(dotIndex + 1).toLowerCase();
  }

  /// Creates a copy of this page with updated fields.
  ComicPage copyWith({
    int? index,
    String? filename,
    String? mediaType,
    PageType? type,
    int? width,
    int? height,
    int? fileSize,
    bool? isDoublePage,
    String? bookmark,
  }) {
    return ComicPage(
      index: index ?? this.index,
      filename: filename ?? this.filename,
      mediaType: mediaType ?? this.mediaType,
      type: type ?? this.type,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      isDoublePage: isDoublePage ?? this.isDoublePage,
      bookmark: bookmark ?? this.bookmark,
    );
  }

  @override
  List<Object?> get props => [
        index,
        filename,
        mediaType,
        type,
        width,
        height,
        fileSize,
        isDoublePage,
        bookmark,
      ];

  @override
  String toString() =>
      'ComicPage(index: $index, filename: $filename, type: $type)';
}
