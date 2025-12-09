import 'package:equatable/equatable.dart';

/// Represents an outline element in an OPML document
class OpmlOutline extends Equatable {
  /// The text attribute - primary display text
  final String? text;

  /// Alternative title (often same as text)
  final String? title;

  /// Type of outline: "rss", "link", or null (folder)
  final String? type;

  /// URL of the RSS/Atom feed (for type="rss")
  final String? xmlUrl;

  /// URL of the website (for type="rss" or type="link")
  final String? htmlUrl;

  /// Description of the feed
  final String? description;

  /// Feed language
  final String? language;

  /// Feed version (e.g., "RSS2")
  final String? version;

  /// Whether the outline is a comment
  final bool? isComment;

  /// Whether the outline is a breakpoint
  final bool? isBreakpoint;

  /// Creation date
  final DateTime? created;

  /// Category/tags
  final String? category;

  /// Nested outline elements (for folders)
  final List<OpmlOutline> children;

  /// Custom attributes not covered by standard fields
  final Map<String, String> customAttributes;

  const OpmlOutline({
    this.text,
    this.title,
    this.type,
    this.xmlUrl,
    this.htmlUrl,
    this.description,
    this.language,
    this.version,
    this.isComment,
    this.isBreakpoint,
    this.created,
    this.category,
    this.children = const [],
    this.customAttributes = const {},
  });

  /// Whether this is an RSS/Atom feed outline
  bool get isFeed => type == 'rss' && xmlUrl != null && xmlUrl!.isNotEmpty;

  /// Whether this is a folder (has children, no xmlUrl)
  bool get isFolder => children.isNotEmpty;

  /// Whether this is a link outline
  bool get isLink => type == 'link' && htmlUrl != null;

  /// Get the display name (prefers text, falls back to title, then xmlUrl)
  String get displayName => text ?? title ?? xmlUrl ?? 'Untitled';

  /// Get all feed outlines recursively (flattened from nested structure)
  List<OpmlOutline> getAllFeeds() {
    final feeds = <OpmlOutline>[];
    if (isFeed) {
      feeds.add(this);
    }
    for (final child in children) {
      feeds.addAll(child.getAllFeeds());
    }
    return feeds;
  }

  /// Get the folder path as a list of folder names
  /// This outline should be part of a tree; call from parent to track path
  List<String> getFolderPath(List<String> currentPath) {
    if (isFolder && !isFeed) {
      return [...currentPath, displayName];
    }
    return currentPath;
  }

  OpmlOutline copyWith({
    String? text,
    String? title,
    String? type,
    String? xmlUrl,
    String? htmlUrl,
    String? description,
    String? language,
    String? version,
    bool? isComment,
    bool? isBreakpoint,
    DateTime? created,
    String? category,
    List<OpmlOutline>? children,
    Map<String, String>? customAttributes,
  }) {
    return OpmlOutline(
      text: text ?? this.text,
      title: title ?? this.title,
      type: type ?? this.type,
      xmlUrl: xmlUrl ?? this.xmlUrl,
      htmlUrl: htmlUrl ?? this.htmlUrl,
      description: description ?? this.description,
      language: language ?? this.language,
      version: version ?? this.version,
      isComment: isComment ?? this.isComment,
      isBreakpoint: isBreakpoint ?? this.isBreakpoint,
      created: created ?? this.created,
      category: category ?? this.category,
      children: children ?? this.children,
      customAttributes: customAttributes ?? this.customAttributes,
    );
  }

  @override
  List<Object?> get props => [
    text,
    title,
    type,
    xmlUrl,
    htmlUrl,
    description,
    language,
    version,
    isComment,
    isBreakpoint,
    created,
    category,
    children,
    customAttributes,
  ];

  @override
  String toString() =>
      'OpmlOutline(text: $text, type: $type, xmlUrl: $xmlUrl, children: ${children.length})';
}
