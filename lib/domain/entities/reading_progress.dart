import 'package:equatable/equatable.dart';

/// Represents the reading progress for a specific book
class ReadingProgress extends Equatable {
  final String id;
  final String bookId;
  final String? chapterId;
  final String cfi; // Canonical Fragment Identifier for EPUB
  final double progress; // 0.0 to 1.0
  final DateTime updatedAt;

  const ReadingProgress({
    required this.id,
    required this.bookId,
    this.chapterId,
    required this.cfi,
    required this.progress,
    required this.updatedAt,
  }) : assert(
         progress >= 0.0 && progress <= 1.0,
         'Progress must be between 0.0 and 1.0',
       );

  /// Creates a copy of this ReadingProgress with the given fields replaced
  ReadingProgress copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    String? cfi,
    double? progress,
    DateTime? updatedAt,
  }) {
    return ReadingProgress(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      cfi: cfi ?? this.cfi,
      progress: progress ?? this.progress,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, bookId, chapterId, cfi, progress, updatedAt];

  @override
  String toString() {
    return 'ReadingProgress(bookId: $bookId, progress: ${progress.toStringAsFixed(2)}, '
        'cfi: $cfi, updatedAt: $updatedAt)';
  }
}
