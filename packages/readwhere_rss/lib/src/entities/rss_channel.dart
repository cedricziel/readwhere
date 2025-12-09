import 'package:equatable/equatable.dart';

/// Represents RSS channel metadata
class RssChannel extends Equatable {
  /// Channel title
  final String title;

  /// Channel description
  final String? description;

  /// Website link
  final String? link;

  /// Channel language (e.g., 'en-us')
  final String? language;

  /// Copyright notice
  final String? copyright;

  /// Managing editor email
  final String? managingEditor;

  /// Webmaster email
  final String? webMaster;

  /// Publication date
  final DateTime? pubDate;

  /// Last build date
  final DateTime? lastBuildDate;

  /// Categories
  final List<String> categories;

  /// Generator software
  final String? generator;

  /// RSS specification URL
  final String? docs;

  /// Time to live (minutes to cache)
  final int? ttl;

  /// Image URL
  final String? imageUrl;

  /// Image title
  final String? imageTitle;

  /// Image link
  final String? imageLink;

  /// Image width
  final int? imageWidth;

  /// Image height
  final int? imageHeight;

  const RssChannel({
    required this.title,
    this.description,
    this.link,
    this.language,
    this.copyright,
    this.managingEditor,
    this.webMaster,
    this.pubDate,
    this.lastBuildDate,
    this.categories = const [],
    this.generator,
    this.docs,
    this.ttl,
    this.imageUrl,
    this.imageTitle,
    this.imageLink,
    this.imageWidth,
    this.imageHeight,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    link,
    language,
    copyright,
    managingEditor,
    webMaster,
    pubDate,
    lastBuildDate,
    categories,
    generator,
    docs,
    ttl,
    imageUrl,
    imageTitle,
    imageLink,
    imageWidth,
    imageHeight,
  ];

  @override
  String toString() => 'RssChannel(title: $title, link: $link)';
}
