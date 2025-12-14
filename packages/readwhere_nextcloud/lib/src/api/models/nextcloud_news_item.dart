import 'package:equatable/equatable.dart';

/// Represents an article/item in Nextcloud News
class NextcloudNewsItem extends Equatable {
  /// Unique item ID in Nextcloud News
  final int id;

  /// GUID from the feed
  final String guid;

  /// Hash of the GUID (used for starring)
  final String guidHash;

  /// URL to the article
  final String? url;

  /// Article title
  final String title;

  /// Article author
  final String? author;

  /// Publication date (Unix timestamp)
  final int? pubDate;

  /// Last updated date (Unix timestamp)
  final int? updatedDate;

  /// Article body/content (HTML)
  final String? body;

  /// Enclosure MIME type (e.g., for podcasts)
  final String? enclosureMime;

  /// Enclosure URL
  final String? enclosureLink;

  /// Media thumbnail URL
  final String? mediaThumbnail;

  /// ID of the feed this item belongs to
  final int feedId;

  /// Whether the item is unread
  final bool unread;

  /// Whether the item is starred
  final bool starred;

  /// Last modification timestamp
  final int lastModified;

  /// Fingerprint for deduplication
  final String? fingerprint;

  /// Content hash
  final String? contentHash;

  const NextcloudNewsItem({
    required this.id,
    required this.guid,
    required this.guidHash,
    this.url,
    required this.title,
    this.author,
    this.pubDate,
    this.updatedDate,
    this.body,
    this.enclosureMime,
    this.enclosureLink,
    this.mediaThumbnail,
    required this.feedId,
    this.unread = true,
    this.starred = false,
    required this.lastModified,
    this.fingerprint,
    this.contentHash,
  });

  /// Whether the item has been read
  bool get isRead => !unread;

  /// Whether the item is starred
  bool get isStarred => starred;

  /// Publication date as DateTime
  DateTime? get pubDateTime => pubDate != null
      ? DateTime.fromMillisecondsSinceEpoch(pubDate! * 1000)
      : null;

  /// Create from JSON map
  factory NextcloudNewsItem.fromJson(Map<String, dynamic> json) {
    return NextcloudNewsItem(
      id: json['id'] as int,
      guid: json['guid'] as String? ?? '',
      guidHash: json['guidHash'] as String? ?? '',
      url: json['url'] as String?,
      title: json['title'] as String? ?? '',
      author: json['author'] as String?,
      pubDate: json['pubDate'] as int?,
      updatedDate: json['updatedDate'] as int?,
      body: json['body'] as String?,
      enclosureMime: json['enclosureMime'] as String?,
      enclosureLink: json['enclosureLink'] as String?,
      mediaThumbnail: json['mediaThumbnail'] as String?,
      feedId: json['feedId'] as int,
      unread: json['unread'] as bool? ?? true,
      starred: json['starred'] as bool? ?? false,
      lastModified: json['lastModified'] as int? ?? 0,
      fingerprint: json['fingerprint'] as String?,
      contentHash: json['contentHash'] as String?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'guid': guid,
        'guidHash': guidHash,
        if (url != null) 'url': url,
        'title': title,
        if (author != null) 'author': author,
        if (pubDate != null) 'pubDate': pubDate,
        if (updatedDate != null) 'updatedDate': updatedDate,
        if (body != null) 'body': body,
        if (enclosureMime != null) 'enclosureMime': enclosureMime,
        if (enclosureLink != null) 'enclosureLink': enclosureLink,
        if (mediaThumbnail != null) 'mediaThumbnail': mediaThumbnail,
        'feedId': feedId,
        'unread': unread,
        'starred': starred,
        'lastModified': lastModified,
        if (fingerprint != null) 'fingerprint': fingerprint,
        if (contentHash != null) 'contentHash': contentHash,
      };

  @override
  List<Object?> get props => [
        id,
        guid,
        guidHash,
        url,
        title,
        author,
        pubDate,
        updatedDate,
        body,
        enclosureMime,
        enclosureLink,
        mediaThumbnail,
        feedId,
        unread,
        starred,
        lastModified,
        fingerprint,
        contentHash,
      ];
}
