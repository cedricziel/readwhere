import '../../domain/entities/reading_progress.dart';
import '../database/tables/reading_progress_table.dart';

/// Data model for ReadingProgress entity with database serialization support
///
/// This model extends the domain entity with methods for converting
/// to and from database representations (Map format for SQLite).
class ReadingProgressModel extends ReadingProgress {
  const ReadingProgressModel({
    required super.id,
    required super.bookId,
    super.chapterId,
    required super.cfi,
    required super.progress,
    required super.updatedAt,
  });

  /// Create a ReadingProgressModel from a Map (SQLite row)
  ///
  /// Converts database column types to Dart types:
  /// - INTEGER timestamps to DateTime
  /// - REAL to double for progress
  factory ReadingProgressModel.fromMap(Map<String, dynamic> map) {
    return ReadingProgressModel(
      id: map[ReadingProgressTable.columnId] as String,
      bookId: map[ReadingProgressTable.columnBookId] as String,
      chapterId: map[ReadingProgressTable.columnChapterId] as String?,
      cfi: map[ReadingProgressTable.columnCfi] as String? ?? '',
      progress: (map[ReadingProgressTable.columnProgress] as num).toDouble(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[ReadingProgressTable.columnUpdatedAt] as int,
      ),
    );
  }

  /// Create a ReadingProgressModel from a domain entity
  factory ReadingProgressModel.fromEntity(ReadingProgress progress) {
    return ReadingProgressModel(
      id: progress.id,
      bookId: progress.bookId,
      chapterId: progress.chapterId,
      cfi: progress.cfi,
      progress: progress.progress,
      updatedAt: progress.updatedAt,
    );
  }

  /// Convert to a Map for SQLite storage
  ///
  /// Converts Dart types to database column types:
  /// - DateTime to INTEGER (milliseconds since epoch)
  /// - double to REAL for progress
  Map<String, dynamic> toMap() {
    return {
      ReadingProgressTable.columnId: id,
      ReadingProgressTable.columnBookId: bookId,
      ReadingProgressTable.columnChapterId: chapterId,
      ReadingProgressTable.columnCfi: cfi,
      ReadingProgressTable.columnProgress: progress,
      ReadingProgressTable.columnUpdatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Convert to domain entity (ReadingProgress)
  ReadingProgress toEntity() {
    return ReadingProgress(
      id: id,
      bookId: bookId,
      chapterId: chapterId,
      cfi: cfi,
      progress: progress,
      updatedAt: updatedAt,
    );
  }
}
