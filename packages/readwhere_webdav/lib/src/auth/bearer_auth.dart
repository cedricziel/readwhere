import 'webdav_auth.dart';

/// Bearer token authentication for WebDAV
///
/// Uses an OAuth2 access token or similar bearer token.
class BearerAuth implements WebDavAuth {
  /// The bearer token (access token)
  final String token;

  /// Optional callback to refresh the token when it expires
  final Future<String?> Function()? onRefreshToken;

  BearerAuth({
    required this.token,
    this.onRefreshToken,
  });

  @override
  Map<String, String> get headers => {
        'Authorization': 'Bearer $token',
      };

  @override
  Future<void> onAuthenticationFailed() async {
    if (onRefreshToken != null) {
      await onRefreshToken!();
    }
  }
}
