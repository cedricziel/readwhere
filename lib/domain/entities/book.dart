import 'package:equatable/equatable.dart';

/// Represents a book in the library
class Book extends Equatable {
  final String id;
  final String title;
  final String author;
  final String filePath;
  final String? coverPath;
  final String format; // epub, pdf, mobi, etc.
  final int fileSize; // in bytes
  final DateTime addedAt;
  final DateTime? lastOpenedAt;
  final bool isFavorite;
  final double? readingProgress; // 0.0 to 1.0

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    this.coverPath,
    required this.format,
    required this.fileSize,
    required this.addedAt,
    this.lastOpenedAt,
    this.isFavorite = false,
    this.readingProgress,
  }) : assert(readingProgress == null || (readingProgress >= 0.0 && readingProgress <= 1.0),
            'Reading progress must be between 0.0 and 1.0');

  /// Creates a copy of this Book with the given fields replaced with new values
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    String? coverPath,
    String? format,
    int? fileSize,
    DateTime? addedAt,
    DateTime? lastOpenedAt,
    bool? isFavorite,
    double? readingProgress,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      coverPath: coverPath ?? this.coverPath,
      format: format ?? this.format,
      fileSize: fileSize ?? this.fileSize,
      addedAt: addedAt ?? this.addedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      readingProgress: readingProgress ?? this.readingProgress,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        filePath,
        coverPath,
        format,
        fileSize,
        addedAt,
        lastOpenedAt,
        isFavorite,
        readingProgress,
      ];

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author, format: $format, '
        'progress: ${readingProgress?.toStringAsFixed(2) ?? "none"})';
  }
}
