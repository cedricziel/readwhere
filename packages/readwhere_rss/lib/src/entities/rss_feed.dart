import 'package:equatable/equatable.dart';

import 'rss_channel.dart';
import 'rss_item.dart';

/// The format of an RSS/Atom feed
enum RssFeedFormat {
  /// RSS 2.0 format
  rss2,

  /// RSS 1.0 (RDF) format
  rss1,

  /// Atom 1.0 format
  atom,

  /// Unknown format
  unknown,
}

/// Represents a parsed RSS or Atom feed
class RssFeed extends Equatable {
  /// Unique identifier for the feed
  final String id;

  /// Feed title
  final String title;

  /// Feed description/subtitle
  final String? description;

  /// Link to the website
  final String? link;

  /// Feed image/icon URL
  final String? imageUrl;

  /// Last build/update date
  final DateTime? lastBuildDate;

  /// Publication date
  final DateTime? pubDate;

  /// The feed format (RSS 2.0, RSS 1.0, Atom)
  final RssFeedFormat format;

  /// RSS channel metadata (for RSS feeds)
  final RssChannel? channel;

  /// Items/entries in the feed
  final List<RssItem> items;

  /// The URL this feed was fetched from
  final String feedUrl;

  /// Feed language
  final String? language;

  /// Feed author (common in Atom)
  final String? author;

  /// Feed copyright
  final String? copyright;

  /// Generator software
  final String? generator;

  const RssFeed({
    required this.id,
    required this.title,
    this.description,
    this.link,
    this.imageUrl,
    this.lastBuildDate,
    this.pubDate,
    required this.format,
    this.channel,
    required this.items,
    required this.feedUrl,
    this.language,
    this.author,
    this.copyright,
    this.generator,
  });

  /// Whether this is an RSS 2.0 feed
  bool get isRss2 => format == RssFeedFormat.rss2;

  /// Whether this is an RSS 1.0 (RDF) feed
  bool get isRss1 => format == RssFeedFormat.rss1;

  /// Whether this is an Atom feed
  bool get isAtom => format == RssFeedFormat.atom;

  /// Get the best available date
  DateTime? get date => lastBuildDate ?? pubDate;

  /// Whether this feed has any items with downloadable ebooks
  bool get hasEbookItems => items.any((i) => i.hasEbookEnclosures);

  /// Whether this feed has any items with downloadable comics
  bool get hasComicItems => items.any((i) => i.hasComicEnclosures);

  /// Whether this feed has any items with supported formats
  bool get hasSupportedItems => items.any((i) => i.hasSupportedEnclosures);

  /// Get all items with ebook enclosures
  List<RssItem> get ebookItems =>
      items.where((i) => i.hasEbookEnclosures).toList();

  /// Get all items with comic enclosures
  List<RssItem> get comicItems =>
      items.where((i) => i.hasComicEnclosures).toList();

  /// Get all items with supported format enclosures
  List<RssItem> get supportedItems =>
      items.where((i) => i.hasSupportedEnclosures).toList();

  /// Number of items in the feed
  int get itemCount => items.length;

  RssFeed copyWith({
    String? id,
    String? title,
    String? description,
    String? link,
    String? imageUrl,
    DateTime? lastBuildDate,
    DateTime? pubDate,
    RssFeedFormat? format,
    RssChannel? channel,
    List<RssItem>? items,
    String? feedUrl,
    String? language,
    String? author,
    String? copyright,
    String? generator,
  }) {
    return RssFeed(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      link: link ?? this.link,
      imageUrl: imageUrl ?? this.imageUrl,
      lastBuildDate: lastBuildDate ?? this.lastBuildDate,
      pubDate: pubDate ?? this.pubDate,
      format: format ?? this.format,
      channel: channel ?? this.channel,
      items: items ?? this.items,
      feedUrl: feedUrl ?? this.feedUrl,
      language: language ?? this.language,
      author: author ?? this.author,
      copyright: copyright ?? this.copyright,
      generator: generator ?? this.generator,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    link,
    imageUrl,
    lastBuildDate,
    pubDate,
    format,
    channel,
    items,
    feedUrl,
    language,
    author,
    copyright,
    generator,
  ];

  @override
  String toString() =>
      'RssFeed(id: $id, title: $title, format: $format, items: ${items.length})';
}
