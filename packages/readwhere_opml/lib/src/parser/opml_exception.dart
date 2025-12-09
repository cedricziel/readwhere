/// Base exception for OPML operations
class OpmlException implements Exception {
  /// The error message
  final String message;

  /// The underlying cause (if any)
  final Object? cause;

  const OpmlException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'OpmlException: $message (caused by: $cause)';
    }
    return 'OpmlException: $message';
  }
}

/// Exception thrown when OPML cannot be parsed
class OpmlParseException extends OpmlException {
  const OpmlParseException(super.message, [super.cause]);

  @override
  String toString() => 'OpmlParseException: $message';
}

/// Exception thrown when OPML format is invalid
class OpmlFormatException extends OpmlException {
  const OpmlFormatException(super.message, [super.cause]);

  @override
  String toString() => 'OpmlFormatException: $message';
}
