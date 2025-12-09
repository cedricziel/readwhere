import 'package:equatable/equatable.dart';

import 'rss_category.dart';
import 'rss_enclosure.dart';

/// Represents an item/entry in an RSS or Atom feed
class RssItem extends Equatable {
  /// Unique identifier (guid in RSS, id in Atom)
  final String id;

  /// The item title
  final String title;

  /// Short description/summary
  final String? description;

  /// Full content (content:encoded in RSS, content in Atom)
  final String? content;

  /// Link to the full article/page
  final String? link;

  /// Author name
  final String? author;

  /// Author email (common in Atom)
  final String? authorEmail;

  /// Publication date
  final DateTime? pubDate;

  /// Last updated date (common in Atom)
  final DateTime? updated;

  /// Media attachments
  final List<RssEnclosure> enclosures;

  /// Categories/tags
  final List<RssCategory> categories;

  /// Thumbnail image URL (from media:thumbnail, itunes:image, etc.)
  final String? thumbnailUrl;

  /// Comments URL
  final String? commentsUrl;

  /// Source feed info (title and url)
  final String? sourceTitle;
  final String? sourceUrl;

  const RssItem({
    required this.id,
    required this.title,
    this.description,
    this.content,
    this.link,
    this.author,
    this.authorEmail,
    this.pubDate,
    this.updated,
    this.enclosures = const [],
    this.categories = const [],
    this.thumbnailUrl,
    this.commentsUrl,
    this.sourceTitle,
    this.sourceUrl,
  });

  /// Whether this item has any downloadable ebook enclosures
  bool get hasEbookEnclosures => enclosures.any((e) => e.isEbook);

  /// Whether this item has any downloadable comic enclosures
  bool get hasComicEnclosures => enclosures.any((e) => e.isComic);

  /// Whether this item has any supported format enclosures
  bool get hasSupportedEnclosures => enclosures.any((e) => e.isSupportedFormat);

  /// Get all ebook enclosures
  List<RssEnclosure> get ebookEnclosures =>
      enclosures.where((e) => e.isEbook).toList();

  /// Get all comic enclosures
  List<RssEnclosure> get comicEnclosures =>
      enclosures.where((e) => e.isComic).toList();

  /// Get all supported format enclosures
  List<RssEnclosure> get supportedEnclosures =>
      enclosures.where((e) => e.isSupportedFormat).toList();

  /// Get the best available date (pubDate or updated)
  DateTime? get date => pubDate ?? updated;

  /// Get the best available content (content or description)
  String? get bestContent => content ?? description;

  RssItem copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    String? link,
    String? author,
    String? authorEmail,
    DateTime? pubDate,
    DateTime? updated,
    List<RssEnclosure>? enclosures,
    List<RssCategory>? categories,
    String? thumbnailUrl,
    String? commentsUrl,
    String? sourceTitle,
    String? sourceUrl,
  }) {
    return RssItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      link: link ?? this.link,
      author: author ?? this.author,
      authorEmail: authorEmail ?? this.authorEmail,
      pubDate: pubDate ?? this.pubDate,
      updated: updated ?? this.updated,
      enclosures: enclosures ?? this.enclosures,
      categories: categories ?? this.categories,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      commentsUrl: commentsUrl ?? this.commentsUrl,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceUrl: sourceUrl ?? this.sourceUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    content,
    link,
    author,
    authorEmail,
    pubDate,
    updated,
    enclosures,
    categories,
    thumbnailUrl,
    commentsUrl,
    sourceTitle,
    sourceUrl,
  ];

  @override
  String toString() =>
      'RssItem(id: $id, title: $title, enclosures: ${enclosures.length})';
}
