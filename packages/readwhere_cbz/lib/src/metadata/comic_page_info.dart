import 'package:equatable/equatable.dart';

import '../pages/comic_page.dart';

/// Metadata for a single page from ComicInfo.xml `<Pages>` element.
///
/// This corresponds to the `<Page>` elements within `<Pages>`.
class ComicPageInfo extends Equatable {
  /// Page index (from `Image` attribute).
  final int index;

  /// Page type (from `Type` attribute).
  final PageType? type;

  /// Whether this is a double-page spread (from `DoublePage` attribute).
  final bool? doublePage;

  /// Image width in pixels (from `ImageWidth` attribute).
  final int? imageWidth;

  /// Image height in pixels (from `ImageHeight` attribute).
  final int? imageHeight;

  /// Image file size in bytes (from `ImageSize` attribute).
  final int? imageSize;

  /// Bookmark label (from `Bookmark` attribute).
  final String? bookmark;

  /// Key value (from `Key` attribute, undocumented).
  final String? key;

  const ComicPageInfo({
    required this.index,
    this.type,
    this.doublePage,
    this.imageWidth,
    this.imageHeight,
    this.imageSize,
    this.bookmark,
    this.key,
  });

  @override
  List<Object?> get props => [
        index,
        type,
        doublePage,
        imageWidth,
        imageHeight,
        imageSize,
        bookmark,
        key,
      ];

  @override
  String toString() => 'ComicPageInfo(index: $index, type: ${type?.name})';
}
