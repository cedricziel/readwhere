/// Base exception for fanfiction.de client errors.
sealed class FanfictionException implements Exception {
  const FanfictionException(this.message);

  /// Error message describing what went wrong.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception thrown when a network request fails.
class FanfictionNetworkException extends FanfictionException {
  const FanfictionNetworkException(
    super.message, {
    this.statusCode,
    this.url,
  });

  /// HTTP status code (if available).
  final int? statusCode;

  /// The URL that was being accessed.
  final String? url;

  @override
  String toString() {
    final parts = <String>['FanfictionNetworkException: $message'];
    if (statusCode != null) parts.add('(status: $statusCode)');
    if (url != null) parts.add('url: $url');
    return parts.join(' ');
  }
}

/// Exception thrown when parsing HTML content fails.
class FanfictionParseException extends FanfictionException {
  const FanfictionParseException(
    super.message, {
    this.source,
  });

  /// The source content that failed to parse (truncated for debugging).
  final String? source;

  @override
  String toString() {
    if (source != null) {
      final truncated =
          source!.length > 100 ? '${source!.substring(0, 100)}...' : source;
      return 'FanfictionParseException: $message\nSource: $truncated';
    }
    return 'FanfictionParseException: $message';
  }
}

/// Exception thrown when a story or chapter is not found.
class FanfictionNotFoundException extends FanfictionException {
  const FanfictionNotFoundException(
    super.message, {
    this.storyId,
    this.chapterNumber,
  });

  /// The story ID that was not found.
  final String? storyId;

  /// The chapter number that was not found.
  final int? chapterNumber;
}

/// Exception thrown when access is denied (e.g., age-restricted content).
class FanfictionAccessDeniedException extends FanfictionException {
  const FanfictionAccessDeniedException(
    super.message, {
    this.reason,
  });

  /// The reason access was denied.
  final String? reason;
}
