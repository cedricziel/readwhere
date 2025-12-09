/// Exception thrown when WebDAV operations fail
class WebDavException implements Exception {
  /// Human-readable error message
  final String message;

  /// HTTP status code if applicable
  final int? statusCode;

  /// Original error that caused this exception
  final Object? cause;

  WebDavException(this.message, {this.statusCode, this.cause});

  @override
  String toString() {
    final status = statusCode != null ? ' (status: $statusCode)' : '';
    return 'WebDavException: $message$status';
  }
}
