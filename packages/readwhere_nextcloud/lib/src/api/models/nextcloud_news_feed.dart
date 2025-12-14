import 'package:equatable/equatable.dart';

/// Represents a feed subscription in Nextcloud News
class NextcloudNewsFeed extends Equatable {
  /// Unique feed ID in Nextcloud News
  final int id;

  /// Feed URL
  final String url;

  /// Feed title
  final String title;

  /// URL to the feed's favicon
  final String? faviconLink;

  /// Timestamp when feed was added
  final int? added;

  /// Next scheduled update time
  final int? nextUpdateTime;

  /// Folder ID (null if in root)
  final int? folderId;

  /// Number of unread items
  final int unreadCount;

  /// Ordering preference
  final int? ordering;

  /// Link to the feed's website
  final String? link;

  /// Whether the feed is pinned
  final bool pinned;

  /// Number of consecutive update errors
  final int updateErrorCount;

  /// Last update error message
  final String? lastUpdateError;

  const NextcloudNewsFeed({
    required this.id,
    required this.url,
    required this.title,
    this.faviconLink,
    this.added,
    this.nextUpdateTime,
    this.folderId,
    this.unreadCount = 0,
    this.ordering,
    this.link,
    this.pinned = false,
    this.updateErrorCount = 0,
    this.lastUpdateError,
  });

  /// Create from JSON map
  factory NextcloudNewsFeed.fromJson(Map<String, dynamic> json) {
    return NextcloudNewsFeed(
      id: json['id'] as int,
      url: json['url'] as String,
      title: json['title'] as String? ?? '',
      faviconLink: json['faviconLink'] as String?,
      added: json['added'] as int?,
      nextUpdateTime: json['nextUpdateTime'] as int?,
      folderId: json['folderId'] as int?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      ordering: json['ordering'] as int?,
      link: json['link'] as String?,
      pinned: json['pinned'] as bool? ?? false,
      updateErrorCount: json['updateErrorCount'] as int? ?? 0,
      lastUpdateError: json['lastUpdateError'] as String?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        if (faviconLink != null) 'faviconLink': faviconLink,
        if (added != null) 'added': added,
        if (nextUpdateTime != null) 'nextUpdateTime': nextUpdateTime,
        if (folderId != null) 'folderId': folderId,
        'unreadCount': unreadCount,
        if (ordering != null) 'ordering': ordering,
        if (link != null) 'link': link,
        'pinned': pinned,
        'updateErrorCount': updateErrorCount,
        if (lastUpdateError != null) 'lastUpdateError': lastUpdateError,
      };

  @override
  List<Object?> get props => [
        id,
        url,
        title,
        faviconLink,
        added,
        nextUpdateTime,
        folderId,
        unreadCount,
        ordering,
        link,
        pinned,
        updateErrorCount,
        lastUpdateError,
      ];
}
