import 'package:equatable/equatable.dart';

/// Base exception for all CBZ-related errors.
///
/// All CBZ exceptions extend this class, providing a consistent
/// interface for error handling throughout the library.
sealed class CbzException implements Exception {
  /// Human-readable error message.
  final String message;

  /// The underlying cause of this exception, if any.
  final Object? cause;

  /// Stack trace at the point of exception creation.
  final StackTrace? stackTrace;

  const CbzException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception thrown when a CBZ file cannot be read or is corrupted.
///
/// This includes:
/// - File not found errors
/// - Permission errors
/// - Invalid ZIP structure
/// - I/O errors during reading
class CbzReadException extends CbzException {
  /// The file path that could not be read, if applicable.
  final String? filePath;

  const CbzReadException(
    super.message, {
    this.filePath,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    if (filePath != null) {
      return 'CbzReadException: $message (file: $filePath)';
    }
    return 'CbzReadException: $message';
  }
}

/// Exception thrown when CBZ structure validation fails.
///
/// Contains a list of specific validation errors that were found.
class CbzValidationException extends CbzException {
  /// List of validation errors found.
  final List<CbzValidationError> errors;

  const CbzValidationException(
    super.message,
    this.errors, {
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    final errorSummary = errors.map((e) => '  - ${e.message}').join('\n');
    return 'CbzValidationException: $message\nErrors:\n$errorSummary';
  }
}

/// Exception thrown when parsing CBZ metadata fails.
///
/// This includes XML parsing errors in ComicInfo.xml or MetronInfo.xml.
class CbzParseException extends CbzException {
  /// Path to the document where parsing failed.
  final String? documentPath;

  /// Line number where the error occurred, if known.
  final int? lineNumber;

  /// Column number where the error occurred, if known.
  final int? column;

  const CbzParseException(
    super.message, {
    this.documentPath,
    this.lineNumber,
    this.column,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    final parts = <String>['CbzParseException: $message'];
    if (documentPath != null) {
      parts.add('in $documentPath');
    }
    if (lineNumber != null) {
      parts.add('at line $lineNumber');
      if (column != null) {
        parts.add('column $column');
      }
    }
    return parts.join(' ');
  }
}

/// Exception thrown when a requested page cannot be found.
class CbzPageNotFoundException extends CbzException {
  /// The page index that was not found.
  final int pageIndex;

  const CbzPageNotFoundException(this.pageIndex)
      : super('Page not found at index: $pageIndex');

  @override
  String toString() => 'CbzPageNotFoundException: page $pageIndex';
}

/// Exception thrown when an image cannot be processed.
///
/// This may occur during:
/// - Image format detection
/// - Dimension extraction
/// - Thumbnail generation
class CbzImageException extends CbzException {
  /// The path to the image that caused the error.
  final String? imagePath;

  const CbzImageException(
    super.message, {
    this.imagePath,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    if (imagePath != null) {
      return 'CbzImageException: $message (image: $imagePath)';
    }
    return 'CbzImageException: $message';
  }
}

/// Severity levels for validation errors.
enum CbzValidationSeverity {
  /// Error: Invalid structure, may prevent rendering.
  error,

  /// Warning: Non-standard but may work in some readers.
  warning,

  /// Info: Best practice suggestion.
  info,
}

/// A single validation error with details.
class CbzValidationError extends Equatable {
  /// Severity of this validation error.
  final CbzValidationSeverity severity;

  /// Error code for programmatic handling.
  final String code;

  /// Human-readable error message.
  final String message;

  /// Location where the error was found (file path).
  final String? location;

  const CbzValidationError({
    required this.severity,
    required this.code,
    required this.message,
    this.location,
  });

  @override
  List<Object?> get props => [severity, code, message, location];

  @override
  String toString() {
    final severityStr = severity.name.toUpperCase();
    if (location != null) {
      return '[$severityStr] $code: $message (at $location)';
    }
    return '[$severityStr] $code: $message';
  }
}

/// Result of CBZ validation.
class CbzValidationResult extends Equatable {
  /// Whether the CBZ is valid (no errors).
  final bool isValid;

  /// Critical errors that indicate invalid structure.
  final List<CbzValidationError> errors;

  /// Warnings about non-standard content.
  final List<CbzValidationError> warnings;

  /// Informational messages and suggestions.
  final List<CbzValidationError> info;

  const CbzValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.info = const [],
  });

  /// All issues regardless of severity.
  List<CbzValidationError> get allIssues => [...errors, ...warnings, ...info];

  /// Total number of issues found.
  int get totalIssues => allIssues.length;

  @override
  List<Object?> get props => [isValid, errors, warnings, info];
}
