import 'package:equatable/equatable.dart';

/// Represents a bookmark in a book
class Bookmark extends Equatable {
  final String id;
  final String bookId;
  final String? chapterId;
  final String cfi; // Canonical Fragment Identifier for EPUB
  final String title;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.bookId,
    this.chapterId,
    required this.cfi,
    required this.title,
    required this.createdAt,
  });

  /// Creates a copy of this Bookmark with the given fields replaced
  Bookmark copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    String? cfi,
    String? title,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      cfi: cfi ?? this.cfi,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        chapterId,
        cfi,
        title,
        createdAt,
      ];

  @override
  String toString() {
    return 'Bookmark(id: $id, title: $title, bookId: $bookId, createdAt: $createdAt)';
  }
}
