/// Exception thrown by Synology Drive API operations.
class SynologyException implements Exception {
  /// Creates a new [SynologyException].
  const SynologyException(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.response,
    this.cause,
  });

  /// The error message.
  final String message;

  /// HTTP status code, if available.
  final int? statusCode;

  /// Synology API error code, if available.
  final int? errorCode;

  /// Raw response body, if available.
  final String? response;

  /// The original error that caused this exception.
  final Object? cause;

  /// Whether this exception indicates an authentication failure.
  bool get isAuthError =>
      statusCode == 401 ||
      statusCode == 403 ||
      errorCode == 400 || // Invalid password
      errorCode == 401 || // Account disabled
      errorCode == 402 || // Permission denied
      errorCode == 403; // 2-step verification required

  /// Whether this exception indicates a session expiry.
  bool get isSessionExpired =>
      errorCode == 105 || // Invalid session
      errorCode == 106 || // Session timeout
      errorCode == 119; // SID not found

  /// Whether this exception indicates a network error.
  bool get isNetworkError => cause is Exception && statusCode == null;

  @override
  String toString() {
    final buffer = StringBuffer('SynologyException: $message');
    if (statusCode != null) {
      buffer.write(' (HTTP $statusCode)');
    }
    if (errorCode != null) {
      buffer.write(' [error code: $errorCode]');
    }
    return buffer.toString();
  }
}
