import 'dart:convert';

import 'webdav_auth.dart';

/// HTTP Basic Authentication for WebDAV
///
/// Uses username and password encoded in Base64.
class BasicAuth implements WebDavAuth {
  /// The username
  final String username;

  /// The password or app password
  final String password;

  BasicAuth({
    required this.username,
    required this.password,
  });

  @override
  Map<String, String> get headers {
    final credentials = base64Encode(utf8.encode('$username:$password'));
    return {
      'Authorization': 'Basic $credentials',
    };
  }

  @override
  Future<void> onAuthenticationFailed() async {
    // Basic auth cannot be refreshed, so this is a no-op
  }
}
