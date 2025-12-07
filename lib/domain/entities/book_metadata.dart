import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'toc_entry.dart';

/// Represents metadata parsed from a book file
class BookMetadata extends Equatable {
  final String title;
  final String author;
  final String? description;
  final String? publisher;
  final String? language;
  final DateTime? publishedDate;
  final Uint8List? coverImage;
  final List<TocEntry> tableOfContents;

  const BookMetadata({
    required this.title,
    required this.author,
    this.description,
    this.publisher,
    this.language,
    this.publishedDate,
    this.coverImage,
    this.tableOfContents = const [],
  });

  /// Creates a copy of this BookMetadata with the given fields replaced
  BookMetadata copyWith({
    String? title,
    String? author,
    String? description,
    String? publisher,
    String? language,
    DateTime? publishedDate,
    Uint8List? coverImage,
    List<TocEntry>? tableOfContents,
  }) {
    return BookMetadata(
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      publisher: publisher ?? this.publisher,
      language: language ?? this.language,
      publishedDate: publishedDate ?? this.publishedDate,
      coverImage: coverImage ?? this.coverImage,
      tableOfContents: tableOfContents ?? this.tableOfContents,
    );
  }

  @override
  List<Object?> get props => [
        title,
        author,
        description,
        publisher,
        language,
        publishedDate,
        coverImage,
        tableOfContents,
      ];

  @override
  String toString() {
    return 'BookMetadata(title: $title, author: $author, '
        'publisher: $publisher, language: $language, '
        'hasCover: ${coverImage != null}, tocEntries: ${tableOfContents.length})';
  }
}
