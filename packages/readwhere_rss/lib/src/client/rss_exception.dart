/// Base exception for RSS operations
class RssException implements Exception {
  /// The error message
  final String message;

  /// The underlying cause (if any)
  final Object? cause;

  const RssException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'RssException: $message (caused by: $cause)';
    }
    return 'RssException: $message';
  }
}

/// Exception thrown when a feed cannot be fetched
class RssFetchException extends RssException {
  /// HTTP status code (if available)
  final int? statusCode;

  /// The feed URL that failed
  final String url;

  const RssFetchException(
    String message, {
    required this.url,
    this.statusCode,
    Object? cause,
  }) : super(message, cause);

  @override
  String toString() {
    final status = statusCode != null ? ' (HTTP $statusCode)' : '';
    return 'RssFetchException: $message$status - URL: $url';
  }
}

/// Exception thrown when a feed cannot be parsed
class RssParseException extends RssException {
  /// The feed URL that failed to parse
  final String? url;

  const RssParseException(String message, {this.url, Object? cause})
    : super(message, cause);

  @override
  String toString() {
    if (url != null) {
      return 'RssParseException: $message - URL: $url';
    }
    return 'RssParseException: $message';
  }
}

/// Exception thrown when authentication fails
class RssAuthException extends RssException {
  /// The feed URL that failed auth
  final String url;

  const RssAuthException(String message, {required this.url, Object? cause})
    : super(message, cause);

  @override
  String toString() => 'RssAuthException: $message - URL: $url';
}

/// Exception thrown when a download fails
class RssDownloadException extends RssException {
  /// The enclosure URL that failed
  final String url;

  /// HTTP status code (if available)
  final int? statusCode;

  const RssDownloadException(
    String message, {
    required this.url,
    this.statusCode,
    Object? cause,
  }) : super(message, cause);

  @override
  String toString() {
    final status = statusCode != null ? ' (HTTP $statusCode)' : '';
    return 'RssDownloadException: $message$status - URL: $url';
  }
}
