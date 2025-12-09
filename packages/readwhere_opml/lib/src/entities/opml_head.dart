import 'package:equatable/equatable.dart';

/// Represents the head section of an OPML document
class OpmlHead extends Equatable {
  /// Document title
  final String? title;

  /// Date the document was created
  final DateTime? dateCreated;

  /// Date the document was last modified
  final DateTime? dateModified;

  /// Owner/author name
  final String? ownerName;

  /// Owner email
  final String? ownerEmail;

  /// Owner unique identifier
  final String? ownerId;

  /// Documentation URL
  final String? docs;

  /// Comma-separated list of line numbers that are expanded
  final String? expansionState;

  /// Scroll position (line number at top of display)
  final int? vertScrollState;

  /// Width of the window
  final int? windowTop;

  /// Height of the window
  final int? windowLeft;

  /// X position of window
  final int? windowBottom;

  /// Y position of window
  final int? windowRight;

  const OpmlHead({
    this.title,
    this.dateCreated,
    this.dateModified,
    this.ownerName,
    this.ownerEmail,
    this.ownerId,
    this.docs,
    this.expansionState,
    this.vertScrollState,
    this.windowTop,
    this.windowLeft,
    this.windowBottom,
    this.windowRight,
  });

  @override
  List<Object?> get props => [
    title,
    dateCreated,
    dateModified,
    ownerName,
    ownerEmail,
    ownerId,
    docs,
    expansionState,
    vertScrollState,
    windowTop,
    windowLeft,
    windowBottom,
    windowRight,
  ];

  @override
  String toString() => 'OpmlHead(title: $title, ownerName: $ownerName)';
}
