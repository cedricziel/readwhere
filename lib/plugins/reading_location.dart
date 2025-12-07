import 'package:equatable/equatable.dart';

/// Represents a location within a book while reading
class ReadingLocation extends Equatable {
  /// Chapter index (0-based)
  final int chapterIndex;

  /// CFI (Canonical Fragment Identifier) for precise location within chapter
  final String? cfi;

  /// Reading progress as percentage (0.0 to 1.0)
  final double progress;

  /// Timestamp when this location was recorded
  final DateTime timestamp;

  const ReadingLocation({
    required this.chapterIndex,
    this.cfi,
    required this.progress,
    required this.timestamp,
  }) : assert(progress >= 0.0 && progress <= 1.0,
            'Progress must be between 0.0 and 1.0');

  /// Creates a copy of this ReadingLocation with the given fields replaced
  ReadingLocation copyWith({
    int? chapterIndex,
    String? cfi,
    double? progress,
    DateTime? timestamp,
  }) {
    return ReadingLocation(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      cfi: cfi ?? this.cfi,
      progress: progress ?? this.progress,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
        chapterIndex,
        cfi,
        progress,
        timestamp,
      ];

  @override
  String toString() {
    return 'ReadingLocation(chapter: $chapterIndex, '
        'cfi: $cfi, progress: ${progress.toStringAsFixed(2)})';
  }
}
