/// Base exception for all PDF-related errors.
///
/// This is the root of the PDF exception hierarchy.
sealed class PdfException implements Exception {
  final String message;
  final Object? cause;

  const PdfException(this.message, [this.cause]);

  @override
  String toString() =>
      'PdfException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Exception thrown when reading a PDF file fails.
class PdfReadException extends PdfException {
  final String? filePath;

  const PdfReadException(String message, {this.filePath, Object? cause})
    : super(message, cause);

  @override
  String toString() {
    final buffer = StringBuffer('PdfReadException: $message');
    if (filePath != null) buffer.write(' (file: $filePath)');
    if (cause != null) buffer.write('\nCaused by: $cause');
    return buffer.toString();
  }
}

/// Exception thrown when parsing a PDF file fails.
class PdfParseException extends PdfException {
  final String? filePath;

  const PdfParseException(String message, {this.filePath, Object? cause})
    : super(message, cause);

  @override
  String toString() =>
      'PdfParseException: $message${filePath != null ? ' (file: $filePath)' : ''}';
}

/// Exception thrown when a password-protected PDF requires a password.
class PdfPasswordRequiredException extends PdfException {
  final String? filePath;

  const PdfPasswordRequiredException({
    this.filePath,
    String message = 'PDF requires a password to open',
  }) : super(message);

  @override
  String toString() =>
      'PdfPasswordRequiredException: $message${filePath != null ? ' (file: $filePath)' : ''}';
}

/// Exception thrown when the provided password is incorrect.
class PdfIncorrectPasswordException extends PdfException {
  final String? filePath;

  const PdfIncorrectPasswordException({
    this.filePath,
    String message = 'Incorrect password provided',
  }) : super(message);

  @override
  String toString() =>
      'PdfIncorrectPasswordException: $message${filePath != null ? ' (file: $filePath)' : ''}';
}

/// Exception thrown when rendering a PDF page fails.
class PdfRenderException extends PdfException {
  final int? pageIndex;

  const PdfRenderException(String message, {this.pageIndex, Object? cause})
    : super(message, cause);

  @override
  String toString() =>
      'PdfRenderException: $message${pageIndex != null ? ' (page: $pageIndex)' : ''}';
}

/// Exception thrown when a requested resource is not found.
class PdfResourceNotFoundException extends PdfException {
  final String resourceId;

  const PdfResourceNotFoundException(this.resourceId)
    : super('Resource not found: $resourceId');

  @override
  String toString() => 'PdfResourceNotFoundException: $message';
}
