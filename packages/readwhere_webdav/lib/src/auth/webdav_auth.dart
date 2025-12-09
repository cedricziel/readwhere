/// Abstract interface for WebDAV authentication
///
/// Implement this interface to provide custom authentication strategies.
abstract class WebDavAuth {
  /// Get HTTP headers for authentication
  ///
  /// These headers will be added to all WebDAV requests.
  Map<String, String> get headers;

  /// Optional callback when authentication fails
  ///
  /// Can be used to refresh tokens or handle re-authentication.
  Future<void> onAuthenticationFailed() async {}
}
