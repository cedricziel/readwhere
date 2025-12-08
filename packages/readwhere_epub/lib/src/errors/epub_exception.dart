import 'package:equatable/equatable.dart';

/// Base exception for all EPUB-related errors.
///
/// All EPUB exceptions extend this class, providing a consistent
/// interface for error handling throughout the library.
sealed class EpubException implements Exception {
  /// Human-readable error message.
  final String message;

  /// The underlying cause of this exception, if any.
  final Object? cause;

  /// Stack trace at the point of exception creation.
  final StackTrace? stackTrace;

  const EpubException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception thrown when an EPUB file cannot be read or is corrupted.
///
/// This includes:
/// - File not found errors
/// - Permission errors
/// - Invalid ZIP structure
/// - I/O errors during reading
class EpubReadException extends EpubException {
  /// The file path that could not be read, if applicable.
  final String? filePath;

  const EpubReadException(
    super.message, {
    this.filePath,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    if (filePath != null) {
      return 'EpubReadException: $message (file: $filePath)';
    }
    return 'EpubReadException: $message';
  }
}

/// Exception thrown when EPUB structure validation fails.
///
/// Contains a list of specific validation errors that were found.
class EpubValidationException extends EpubException {
  /// List of validation errors found.
  final List<EpubValidationError> errors;

  const EpubValidationException(
    super.message,
    this.errors, {
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    final errorSummary = errors.map((e) => '  - ${e.message}').join('\n');
    return 'EpubValidationException: $message\nErrors:\n$errorSummary';
  }
}

/// Exception thrown when parsing EPUB content fails.
///
/// This includes XML parsing errors, malformed content documents,
/// and structural issues in the package document.
class EpubParseException extends EpubException {
  /// Path to the document where parsing failed.
  final String? documentPath;

  /// Line number where the error occurred, if known.
  final int? lineNumber;

  /// Column number where the error occurred, if known.
  final int? column;

  const EpubParseException(
    super.message, {
    this.documentPath,
    this.lineNumber,
    this.column,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    final parts = <String>['EpubParseException: $message'];
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

/// Exception thrown when CFI (Canonical Fragment Identifier) parsing fails.
class EpubCfiParseException extends EpubException {
  /// The CFI string that failed to parse.
  final String cfiString;

  const EpubCfiParseException(
    super.message,
    this.cfiString, {
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'EpubCfiParseException: $message (CFI: $cfiString)';
}

/// Exception thrown when a resource cannot be found in the EPUB.
class EpubResourceNotFoundException extends EpubException {
  /// The path/href of the resource that was not found.
  final String resourcePath;

  const EpubResourceNotFoundException(this.resourcePath)
      : super('Resource not found: $resourcePath');

  @override
  String toString() => 'EpubResourceNotFoundException: $resourcePath';
}

/// Exception thrown when encrypted content is encountered.
///
/// This library does not support DRM decryption, so this exception
/// is thrown when encrypted content is detected.
class EpubEncryptionException extends EpubException {
  /// The encryption algorithm or DRM type detected.
  final String? encryptionType;

  const EpubEncryptionException(
    super.message, {
    this.encryptionType,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    if (encryptionType != null) {
      return 'EpubEncryptionException: $message (type: $encryptionType)';
    }
    return 'EpubEncryptionException: $message';
  }
}

/// Severity levels for validation errors.
enum EpubValidationSeverity {
  /// Error: Violates EPUB specification, may prevent rendering.
  error,

  /// Warning: Non-standard but may work in some readers.
  warning,

  /// Info: Best practice suggestion.
  info,
}

/// A single validation error with details.
class EpubValidationError extends Equatable {
  /// Severity of this validation error.
  final EpubValidationSeverity severity;

  /// Error code for programmatic handling.
  final String code;

  /// Human-readable error message.
  final String message;

  /// Location where the error was found (file path or CFI).
  final String? location;

  const EpubValidationError({
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

/// Result of EPUB validation.
class EpubValidationResult extends Equatable {
  /// Whether the EPUB is valid (no errors).
  final bool isValid;

  /// Critical errors that violate the specification.
  final List<EpubValidationError> errors;

  /// Warnings about non-standard content.
  final List<EpubValidationError> warnings;

  /// Informational messages and suggestions.
  final List<EpubValidationError> info;

  /// Detected EPUB version, if parseable.
  final EpubVersion? detectedVersion;

  const EpubValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.info = const [],
    this.detectedVersion,
  });

  /// All issues regardless of severity.
  List<EpubValidationError> get allIssues => [...errors, ...warnings, ...info];

  /// Total number of issues found.
  int get totalIssues => allIssues.length;

  @override
  List<Object?> get props => [isValid, errors, warnings, info, detectedVersion];
}

/// EPUB specification version.
enum EpubVersion {
  /// EPUB 2.0 (OPF 2.0)
  epub2('2.0'),

  /// EPUB 3.0
  epub30('3.0'),

  /// EPUB 3.1
  epub31('3.1'),

  /// EPUB 3.2
  epub32('3.2'),

  /// EPUB 3.3
  epub33('3.3');

  /// The version string (e.g., "3.0", "3.3")
  final String value;

  const EpubVersion(this.value);

  /// Parses a version string to an [EpubVersion].
  ///
  /// Returns [epub2] for "2.0", [epub30] for "3.0", etc.
  /// Returns the closest match for unknown versions.
  static EpubVersion parse(String value) {
    final normalized = value.trim();
    return EpubVersion.values.firstWhere(
      (v) => v.value == normalized,
      orElse: () {
        // Handle variants like "3" -> epub30
        if (normalized.startsWith('3')) {
          return epub33; // Default to latest 3.x
        }
        if (normalized.startsWith('2')) {
          return epub2;
        }
        return epub33; // Default to latest
      },
    );
  }

  /// Whether this version is EPUB 3.x.
  bool get isEpub3 => value.startsWith('3');

  /// Whether this version is EPUB 2.x.
  bool get isEpub2 => value.startsWith('2');

  @override
  String toString() => 'EPUB $value';
}
