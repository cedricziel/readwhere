/// Exception thrown when Kavita API operations fail
class KavitaApiException implements Exception {
  /// Human-readable error message
  final String message;

  /// HTTP status code if this was an HTTP error
  final int? statusCode;

  /// The underlying cause of the exception
  final dynamic cause;

  /// Creates a Kavita API exception
  KavitaApiException(this.message, {this.statusCode, this.cause});

  @override
  String toString() =>
      'KavitaApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}
