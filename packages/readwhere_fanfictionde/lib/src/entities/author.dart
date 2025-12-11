import 'package:equatable/equatable.dart';

/// Represents an author on fanfiction.de.
class Author extends Equatable {
  const Author({
    required this.username,
    this.displayName,
    this.profileUrl,
  });

  /// The unique username used in URLs (e.g., 'JohnDoe' in /u/JohnDoe).
  final String username;

  /// The display name shown on the profile (may differ from username).
  final String? displayName;

  /// Full URL to the author's profile page.
  final String? profileUrl;

  /// URL to the author's Atom feed for their stories.
  String get atomFeedUrl =>
      'https://www.fanfiktion.de/feed/author/$username/stories/atom.xml';

  /// URL to the author's profile page.
  String get url => profileUrl ?? 'https://www.fanfiktion.de/u/$username';

  @override
  List<Object?> get props => [username, displayName, profileUrl];

  @override
  String toString() => 'Author(username: $username, displayName: $displayName)';
}
