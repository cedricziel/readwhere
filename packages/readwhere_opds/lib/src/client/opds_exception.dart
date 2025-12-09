/// Exception thrown when OPDS operations fail
class OpdsException implements Exception {
  /// Human-readable error message
  final String message;

  /// HTTP status code if this was an HTTP error
  final int? statusCode;

  /// The underlying cause of the exception
  final dynamic cause;

  /// Creates an OPDS exception
  OpdsException(this.message, {this.statusCode, this.cause});

  @override
  String toString() =>
      'OpdsException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}
