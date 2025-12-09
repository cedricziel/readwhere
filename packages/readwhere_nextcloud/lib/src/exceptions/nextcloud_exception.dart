/// Exception thrown when Nextcloud API calls fail
class NextcloudException implements Exception {
  /// Human-readable error message
  final String message;

  /// HTTP status code if applicable
  final int? statusCode;

  /// Raw response body for debugging
  final String? response;

  /// Original error that caused this exception
  final Object? cause;

  NextcloudException(
    this.message, {
    this.statusCode,
    this.response,
    this.cause,
  });

  @override
  String toString() {
    final status = statusCode != null ? ' (status: $statusCode)' : '';
    return 'NextcloudException: $message$status';
  }
}
