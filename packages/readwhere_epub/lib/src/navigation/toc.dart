import 'package:equatable/equatable.dart';

import '../utils/path_utils.dart';

/// A single entry in the table of contents.
class TocEntry extends Equatable {
  /// Unique identifier for this entry.
  final String id;

  /// Display title.
  final String title;

  /// Target href (may include fragment identifier).
  final String href;

  /// Nesting level (0 = top level).
  final int level;

  /// Child entries (sub-sections).
  final List<TocEntry> children;

  /// Whether this entry is hidden from display.
  final bool hidden;

  const TocEntry({
    required this.id,
    required this.title,
    required this.href,
    this.level = 0,
    this.children = const [],
    this.hidden = false,
  });

  /// The document href without fragment identifier.
  String get documentHref => PathUtils.removeFragment(href);

  /// The fragment identifier, if present.
  String? get fragment => PathUtils.getFragment(href);

  /// Whether this entry has children.
  bool get hasChildren => children.isNotEmpty;

  /// Total number of descendants (including children of children).
  int get totalDescendants {
    var count = children.length;
    for (final child in children) {
      count += child.totalDescendants;
    }
    return count;
  }

  /// Flattens this entry and all descendants into a list.
  List<TocEntry> flatten() {
    final result = <TocEntry>[this];
    for (final child in children) {
      result.addAll(child.flatten());
    }
    return result;
  }

  @override
  List<Object?> get props => [id, title, href, level, children, hidden];

  @override
  String toString() => 'TocEntry($title -> $href)';

  /// Creates a copy with modified fields.
  TocEntry copyWith({
    String? id,
    String? title,
    String? href,
    int? level,
    List<TocEntry>? children,
    bool? hidden,
  }) {
    return TocEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      href: href ?? this.href,
      level: level ?? this.level,
      children: children ?? this.children,
      hidden: hidden ?? this.hidden,
    );
  }
}

/// A page list entry (for fixed-layout or print-replica EPUBs).
class PageEntry extends Equatable {
  /// Target href.
  final String href;

  /// Page label (e.g., "42", "xi").
  final String label;

  /// Numeric page number, if parseable.
  final int? pageNumber;

  const PageEntry({
    required this.href,
    required this.label,
    this.pageNumber,
  });

  @override
  List<Object?> get props => [href, label, pageNumber];
}

/// A landmark entry for structural navigation.
class Landmark extends Equatable {
  /// Target href.
  final String href;

  /// Display title.
  final String title;

  /// Landmark type (epub:type value).
  final LandmarkType type;

  const Landmark({
    required this.href,
    required this.title,
    required this.type,
  });

  @override
  List<Object?> get props => [href, title, type];
}

/// Landmark types per EPUB specification.
enum LandmarkType {
  cover,
  titlePage,
  toc,
  bodymatter,
  frontmatter,
  backmatter,
  loi, // List of illustrations
  lot, // List of tables
  preface,
  bibliography,
  bookIndex, // renamed from 'index' to avoid conflict with enum index
  glossary,
  acknowledgments,
  copyright,
  dedication,
  epigraph,
  foreword,
  other;

  /// Parses a landmark type from epub:type value.
  static LandmarkType fromEpubType(String type) {
    final lower = type.toLowerCase().replaceAll('-', '');
    return switch (lower) {
      'cover' => LandmarkType.cover,
      'titlepage' => LandmarkType.titlePage,
      'toc' => LandmarkType.toc,
      'bodymatter' => LandmarkType.bodymatter,
      'frontmatter' => LandmarkType.frontmatter,
      'backmatter' => LandmarkType.backmatter,
      'loi' => LandmarkType.loi,
      'lot' => LandmarkType.lot,
      'preface' => LandmarkType.preface,
      'bibliography' => LandmarkType.bibliography,
      'index' => LandmarkType.bookIndex,
      'glossary' => LandmarkType.glossary,
      'acknowledgments' || 'acknowledgements' => LandmarkType.acknowledgments,
      'copyright' || 'copyrightpage' => LandmarkType.copyright,
      'dedication' => LandmarkType.dedication,
      'epigraph' => LandmarkType.epigraph,
      'foreword' => LandmarkType.foreword,
      _ => LandmarkType.other,
    };
  }
}

/// Source of the navigation data.
enum NavigationSource {
  /// EPUB 3 navigation document.
  navDocument,

  /// EPUB 2 NCX file.
  ncx,

  /// Generated from spine (fallback).
  spine,
}

/// Complete navigation structure for an EPUB.
class EpubNavigation extends Equatable {
  /// Table of contents entries.
  final List<TocEntry> tableOfContents;

  /// Page list (for fixed-layout or print-replica).
  final List<PageEntry> pageList;

  /// Landmarks for structural navigation.
  final List<Landmark> landmarks;

  /// Source of the navigation data.
  final NavigationSource source;

  const EpubNavigation({
    this.tableOfContents = const [],
    this.pageList = const [],
    this.landmarks = const [],
    required this.source,
  });

  /// Whether the table of contents is empty.
  bool get isEmpty => tableOfContents.isEmpty;

  /// Whether the table of contents has entries.
  bool get isNotEmpty => tableOfContents.isNotEmpty;

  /// Number of top-level TOC entries.
  int get length => tableOfContents.length;

  /// Flattens the TOC hierarchy into a linear list.
  List<TocEntry> get flattenedToc {
    final result = <TocEntry>[];
    for (final entry in tableOfContents) {
      result.addAll(entry.flatten());
    }
    return result;
  }

  /// Gets the maximum depth of the TOC hierarchy.
  int get maxDepth {
    if (tableOfContents.isEmpty) return 0;

    int findMaxDepth(List<TocEntry> entries, int currentDepth) {
      var max = currentDepth;
      for (final entry in entries) {
        if (entry.children.isNotEmpty) {
          final childMax = findMaxDepth(entry.children, currentDepth + 1);
          if (childMax > max) max = childMax;
        }
      }
      return max;
    }

    return findMaxDepth(tableOfContents, 1);
  }

  /// Finds a TOC entry by href.
  TocEntry? findByHref(String href) {
    final normalizedHref = href.toLowerCase();
    final docHref = PathUtils.removeFragment(normalizedHref);

    TocEntry? findInList(List<TocEntry> entries) {
      for (final entry in entries) {
        final entryDocHref = entry.documentHref.toLowerCase();
        if (entryDocHref == docHref ||
            entry.href.toLowerCase() == normalizedHref) {
          return entry;
        }
        if (entry.children.isNotEmpty) {
          final found = findInList(entry.children);
          if (found != null) return found;
        }
      }
      return null;
    }

    return findInList(tableOfContents);
  }

  /// Gets a landmark by type.
  Landmark? getLandmark(LandmarkType type) {
    return landmarks.where((l) => l.type == type).firstOrNull;
  }

  /// Gets the cover landmark.
  Landmark? get cover => getLandmark(LandmarkType.cover);

  /// Gets the bodymatter landmark.
  Landmark? get bodymatter => getLandmark(LandmarkType.bodymatter);

  /// Gets the TOC landmark.
  Landmark? get tocLandmark => getLandmark(LandmarkType.toc);

  /// Whether a page list is available.
  bool get hasPageList => pageList.isNotEmpty;

  /// Gets a page by number.
  PageEntry? getPage(int pageNumber) {
    return pageList.where((p) => p.pageNumber == pageNumber).firstOrNull;
  }

  @override
  List<Object?> get props => [tableOfContents, pageList, landmarks, source];
}
