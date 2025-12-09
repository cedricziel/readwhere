/// Base exception for CBR-related errors.
sealed class CbrException implements Exception {
  /// Human-readable error message.
  String get message;

  /// The underlying cause, if any.
  Object? get cause;

  /// Stack trace from the original error.
  StackTrace? get stackTrace;

  @override
  String toString() => 'CbrException: $message';
}

/// Exception thrown when reading a CBR file fails.
class CbrReadException extends CbrException {
  @override
  final String message;

  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  /// The file path that failed to read (if available).
  final String? filePath;

  CbrReadException(
    this.message, {
    this.filePath,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('CbrReadException: $message');
    if (filePath != null) {
      buffer.write(' (file: $filePath)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a requested page is not found.
class CbrPageNotFoundException extends CbrException {
  @override
  final String message;

  @override
  Object? get cause => null;

  @override
  StackTrace? get stackTrace => null;

  /// The page index that was not found.
  final int pageIndex;

  CbrPageNotFoundException(this.pageIndex)
      : message = 'Page not found at index: $pageIndex';

  @override
  String toString() => 'CbrPageNotFoundException: $message';
}

/// Exception thrown when RAR extraction fails.
class CbrExtractionException extends CbrException {
  @override
  final String message;

  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  CbrExtractionException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() => 'CbrExtractionException: $message';
}
