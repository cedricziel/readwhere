import 'package:equatable/equatable.dart';

import 'opml_head.dart';
import 'opml_outline.dart';

/// Represents an OPML document
class OpmlDocument extends Equatable {
  /// OPML version (typically "1.0" or "2.0")
  final String version;

  /// Document head with metadata
  final OpmlHead? head;

  /// Top-level outline elements
  final List<OpmlOutline> outlines;

  const OpmlDocument({
    required this.version,
    this.head,
    required this.outlines,
  });

  /// Create an empty OPML 2.0 document
  factory OpmlDocument.empty({String? title}) {
    return OpmlDocument(
      version: '2.0',
      head: title != null ? OpmlHead(title: title) : null,
      outlines: const [],
    );
  }

  /// Whether this is OPML 1.0
  bool get isVersion1 => version == '1.0';

  /// Whether this is OPML 2.0
  bool get isVersion2 => version == '2.0';

  /// Get all feed outlines (type="rss" with xmlUrl)
  List<OpmlOutline> get feedOutlines {
    return _collectFeeds(outlines);
  }

  /// Get all folder outlines (those with children)
  List<OpmlOutline> get folderOutlines {
    return outlines.where((o) => o.isFolder && !o.isFeed).toList();
  }

  /// Get all feeds recursively, flattened from any nested folders
  List<OpmlOutline> get allFeeds {
    return _collectAllFeeds(outlines);
  }

  /// Get the total number of feeds (including nested)
  int get feedCount => allFeeds.length;

  /// Get document title from head
  String? get title => head?.title;

  List<OpmlOutline> _collectFeeds(List<OpmlOutline> outlines) {
    return outlines.where((o) => o.isFeed).toList();
  }

  List<OpmlOutline> _collectAllFeeds(List<OpmlOutline> outlines) {
    final feeds = <OpmlOutline>[];
    for (final outline in outlines) {
      if (outline.isFeed) {
        feeds.add(outline);
      }
      if (outline.children.isNotEmpty) {
        feeds.addAll(_collectAllFeeds(outline.children));
      }
    }
    return feeds;
  }

  OpmlDocument copyWith({
    String? version,
    OpmlHead? head,
    List<OpmlOutline>? outlines,
  }) {
    return OpmlDocument(
      version: version ?? this.version,
      head: head ?? this.head,
      outlines: outlines ?? this.outlines,
    );
  }

  @override
  List<Object?> get props => [version, head, outlines];

  @override
  String toString() =>
      'OpmlDocument(version: $version, title: ${head?.title}, outlines: ${outlines.length}, feeds: $feedCount)';
}
