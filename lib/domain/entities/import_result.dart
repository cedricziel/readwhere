import 'package:equatable/equatable.dart';

import 'book.dart';

/// Result of a book import operation.
///
/// Contains the imported book (if successful) along with any
/// warnings that were encountered during validation.
class ImportResult extends Equatable {
  /// Whether the import was successful.
  final bool success;

  /// The imported book (null if import failed).
  final Book? book;

  /// Error reason if import failed.
  final String? errorReason;

  /// Detailed error information.
  final String? errorDetails;

  /// Validation warnings (non-fatal issues).
  final List<String> warnings;

  const ImportResult._({
    required this.success,
    this.book,
    this.errorReason,
    this.errorDetails,
    this.warnings = const [],
  });

  /// Create a successful import result.
  factory ImportResult.success({
    required Book book,
    List<String> warnings = const [],
  }) {
    return ImportResult._(
      success: true,
      book: book,
      warnings: warnings,
    );
  }

  /// Create a failed import result.
  factory ImportResult.failed({
    required String reason,
    String? details,
  }) {
    return ImportResult._(
      success: false,
      errorReason: reason,
      errorDetails: details,
    );
  }

  /// Whether there are validation warnings.
  bool get hasWarnings => warnings.isNotEmpty;

  @override
  List<Object?> get props => [success, book, errorReason, errorDetails, warnings];
}
