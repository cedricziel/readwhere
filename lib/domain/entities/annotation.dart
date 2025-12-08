import 'package:equatable/equatable.dart';

/// Color options for annotations/highlights
enum AnnotationColor { yellow, green, blue, pink, purple, orange }

/// Represents an annotation or highlight in a book
class Annotation extends Equatable {
  final String id;
  final String bookId;
  final String? chapterId;
  final String cfiStart; // Start position using Canonical Fragment Identifier
  final String cfiEnd; // End position using Canonical Fragment Identifier
  final String text; // The highlighted text
  final String? note; // Optional user note
  final AnnotationColor color;
  final DateTime createdAt;

  const Annotation({
    required this.id,
    required this.bookId,
    this.chapterId,
    required this.cfiStart,
    required this.cfiEnd,
    required this.text,
    this.note,
    required this.color,
    required this.createdAt,
  });

  /// Creates a copy of this Annotation with the given fields replaced
  Annotation copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    String? cfiStart,
    String? cfiEnd,
    String? text,
    String? note,
    AnnotationColor? color,
    DateTime? createdAt,
  }) {
    return Annotation(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      cfiStart: cfiStart ?? this.cfiStart,
      cfiEnd: cfiEnd ?? this.cfiEnd,
      text: text ?? this.text,
      note: note ?? this.note,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    bookId,
    chapterId,
    cfiStart,
    cfiEnd,
    text,
    note,
    color,
    createdAt,
  ];

  @override
  String toString() {
    return 'Annotation(id: $id, bookId: $bookId, color: $color, '
        'text: "${text.length > 50 ? '${text.substring(0, 50)}...' : text}")';
  }
}
