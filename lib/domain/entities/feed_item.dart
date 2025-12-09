import 'package:readwhere_rss/readwhere_rss.dart';

/// Domain entity representing an RSS/Atom feed item (article)
class FeedItem {
  final String id;
  final String feedId;
  final String title;
  final String? content;
  final String? description;
  final String? link;
  final String? author;
  final DateTime? pubDate;
  final String? thumbnailUrl;
  final bool isRead;
  final bool isStarred;
  final DateTime fetchedAt;

  /// Original enclosures from the RSS item (for download functionality)
  final List<RssEnclosure> enclosures;

  const FeedItem({
    required this.id,
    required this.feedId,
    required this.title,
    this.content,
    this.description,
    this.link,
    this.author,
    this.pubDate,
    this.thumbnailUrl,
    this.isRead = false,
    this.isStarred = false,
    required this.fetchedAt,
    this.enclosures = const [],
  });

  /// The content to display - prefers full content over description
  String get displayContent => content ?? description ?? '';

  /// Whether this item has any content to display
  bool get hasContent => content != null || description != null;

  /// Whether this item has downloadable enclosures
  bool get hasEnclosures => enclosures.isNotEmpty;

  /// Filter enclosures to only supported ebook/comic formats
  List<RssEnclosure> get supportedEnclosures {
    const supportedExtensions = ['.epub', '.pdf', '.cbz', '.cbr', '.mobi'];
    const supportedMimeTypes = [
      'application/epub+zip',
      'application/pdf',
      'application/x-cbz',
      'application/x-cbr',
      'application/vnd.comicbook+zip',
      'application/vnd.comicbook-rar',
    ];

    return enclosures.where((e) {
      final url = e.url.toLowerCase();
      final type = e.type?.toLowerCase() ?? '';

      return supportedExtensions.any((ext) => url.endsWith(ext)) ||
          supportedMimeTypes.contains(type);
    }).toList();
  }

  /// Whether this item has supported ebook/comic downloads
  bool get hasSupportedEnclosures => supportedEnclosures.isNotEmpty;

  /// Create a copy with updated fields
  FeedItem copyWith({
    String? id,
    String? feedId,
    String? title,
    String? content,
    String? description,
    String? link,
    String? author,
    DateTime? pubDate,
    String? thumbnailUrl,
    bool? isRead,
    bool? isStarred,
    DateTime? fetchedAt,
    List<RssEnclosure>? enclosures,
  }) {
    return FeedItem(
      id: id ?? this.id,
      feedId: feedId ?? this.feedId,
      title: title ?? this.title,
      content: content ?? this.content,
      description: description ?? this.description,
      link: link ?? this.link,
      author: author ?? this.author,
      pubDate: pubDate ?? this.pubDate,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      enclosures: enclosures ?? this.enclosures,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedItem && other.id == id && other.feedId == feedId;
  }

  @override
  int get hashCode => id.hashCode ^ feedId.hashCode;

  @override
  String toString() {
    return 'FeedItem(id: $id, feedId: $feedId, title: $title, isRead: $isRead)';
  }
}
