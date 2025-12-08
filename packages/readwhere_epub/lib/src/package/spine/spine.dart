import 'package:equatable/equatable.dart';

import '../../fxl/rendition_properties.dart';

/// A single item in the EPUB spine.
///
/// Spine items define the reading order of the publication.
class SpineItem extends Equatable {
  /// Reference to the manifest item ID.
  final String idref;

  /// Whether this item is in the linear reading flow.
  ///
  /// Non-linear items are typically auxiliary content like notes or indexes
  /// that should not appear in the main reading sequence.
  final bool linear;

  /// Properties for this spine item.
  final Set<String> properties;

  /// Per-item rendition overrides.
  final SpineItemRendition rendition;

  const SpineItem({
    required this.idref,
    this.linear = true,
    this.properties = const {},
    this.rendition = const SpineItemRendition(),
  });

  /// Page spread direction for this item.
  PageSpread? get pageSpread {
    if (properties.contains('page-spread-left')) {
      return PageSpread.left;
    }
    if (properties.contains('page-spread-right')) {
      return PageSpread.right;
    }
    if (properties.contains('page-spread-center')) {
      return PageSpread.center;
    }
    return null;
  }

  /// Whether this item should start on a new spread.
  bool get renditionSpreadNone => properties.contains('rendition:spread-none');

  @override
  List<Object?> get props => [idref, linear, properties, rendition];

  @override
  String toString() => 'SpineItem($idref, linear: $linear)';
}

/// Page spread position for fixed-layout EPUBs.
enum PageSpread {
  /// Item should appear on the left page.
  left,

  /// Item should appear on the right page.
  right,

  /// Item should appear centered (single page view).
  center,
}

/// Page progression direction.
enum PageProgression {
  /// Left-to-right reading (default for LTR languages).
  ltr,

  /// Right-to-left reading (for RTL languages like Arabic/Hebrew).
  rtl,

  /// Use system default.
  defaultDirection,
}

/// The spine of an EPUB package.
///
/// Defines the default reading order of the publication.
class EpubSpine extends Equatable {
  /// Ordered list of spine items.
  final List<SpineItem> items;

  /// ID of the NCX document (EPUB 2 compatibility).
  final String? toc;

  /// Page progression direction.
  final PageProgression pageProgression;

  const EpubSpine({
    required this.items,
    this.toc,
    this.pageProgression = PageProgression.defaultDirection,
  });

  /// Number of items in the spine.
  int get length => items.length;

  /// Whether the spine is empty.
  bool get isEmpty => items.isEmpty;

  /// Whether the spine has items.
  bool get isNotEmpty => items.isNotEmpty;

  /// Gets a spine item by index.
  SpineItem operator [](int index) => items[index];

  /// Gets the spine index for a manifest item ID.
  ///
  /// Returns -1 if the item is not in the spine.
  int indexOfIdref(String idref) {
    for (var i = 0; i < items.length; i++) {
      if (items[i].idref == idref) {
        return i;
      }
    }
    return -1;
  }

  /// Gets the spine item for a manifest item ID.
  SpineItem? getByIdref(String idref) {
    return items.where((item) => item.idref == idref).firstOrNull;
  }

  /// Only linear items (those in the main reading flow).
  List<SpineItem> get linearItems {
    return items.where((item) => item.linear).toList();
  }

  /// Only non-linear items.
  List<SpineItem> get nonLinearItems {
    return items.where((item) => !item.linear).toList();
  }

  /// Whether the spine has a reference to an NCX document.
  bool get hasNcxReference => toc != null;

  /// Whether this is RTL reading direction.
  bool get isRtl => pageProgression == PageProgression.rtl;

  @override
  List<Object?> get props => [items, toc, pageProgression];
}
