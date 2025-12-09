import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';

/// Exception thrown when Nextcloud API calls fail
class NextcloudApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? response;

  NextcloudApiException(this.message, {this.statusCode, this.response});

  @override
  String toString() => 'NextcloudApiException: $message (status: $statusCode)';
}

/// Server information returned after successful authentication
class NextcloudServerInfo {
  final String serverName;
  final String version;
  final String userId;
  final String displayName;
  final String? email;

  NextcloudServerInfo({
    required this.serverName,
    required this.version,
    required this.userId,
    required this.displayName,
    this.email,
  });
}

/// Login Flow v2 initialization response
class LoginFlowInit {
  /// URL to open in browser for user authentication
  final String loginUrl;

  /// Endpoint to poll for authentication completion
  final String pollEndpoint;

  /// Token to use when polling
  final String pollToken;

  LoginFlowInit({
    required this.loginUrl,
    required this.pollEndpoint,
    required this.pollToken,
  });
}

/// Login Flow v2 result (returned after successful authentication)
class LoginFlowResult {
  final String server;
  final String loginName;
  final String appPassword;

  LoginFlowResult({
    required this.server,
    required this.loginName,
    required this.appPassword,
  });
}

/// Service for Nextcloud authentication and OCS API calls
class NextcloudApiService {
  final http.Client _client;

  /// User-Agent header for all requests
  static const String _userAgent = AppConstants.nextcloudUserAgent;

  NextcloudApiService(this._client);

  /// Common headers for OCS API requests
  Map<String, String> _ocsHeaders(String auth) => {
        'Authorization': 'Basic $auth',
        'OCS-APIRequest': 'true',
        'Accept': 'application/json',
        'User-Agent': _userAgent,
      };

  /// Validate app password authentication and return server info
  ///
  /// Makes a request to the OCS API to verify credentials and get user info.
  Future<NextcloudServerInfo> validateAppPassword(
    String serverUrl,
    String username,
    String appPassword,
  ) async {
    final baseUrl = _normalizeUrl(serverUrl);
    final auth = base64Encode(utf8.encode('$username:$appPassword'));

    try {
      // Get user info from OCS API
      final userResponse = await _client.get(
        Uri.parse('$baseUrl/ocs/v2.php/cloud/user'),
        headers: _ocsHeaders(auth),
      );

      if (userResponse.statusCode != 200) {
        throw NextcloudApiException(
          'Authentication failed',
          statusCode: userResponse.statusCode,
          response: userResponse.body,
        );
      }

      final userData = jsonDecode(userResponse.body);
      final ocsData = userData['ocs']?['data'];

      if (ocsData == null) {
        throw NextcloudApiException('Invalid response from server');
      }

      // Get server capabilities for version info
      final capResponse = await _client.get(
        Uri.parse('$baseUrl/ocs/v2.php/cloud/capabilities'),
        headers: _ocsHeaders(auth),
      );

      String version = 'Unknown';
      String serverName = 'Nextcloud';

      if (capResponse.statusCode == 200) {
        final capData = jsonDecode(capResponse.body);
        final versionInfo =
            capData['ocs']?['data']?['version'] as Map<String, dynamic>?;
        if (versionInfo != null) {
          version = versionInfo['string'] as String? ?? 'Unknown';
        }
        serverName =
            capData['ocs']?['data']?['capabilities']?['theming']?['name']
                as String? ??
            'Nextcloud';
      }

      return NextcloudServerInfo(
        serverName: serverName,
        version: version,
        userId: ocsData['id'] as String? ?? username,
        displayName:
            ocsData['displayname'] as String? ??
            ocsData['id'] as String? ??
            username,
        email: ocsData['email'] as String?,
      );
    } on http.ClientException catch (e) {
      throw NextcloudApiException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw NextcloudApiException('Invalid server response: ${e.message}');
    }
  }

  /// Initiate OAuth2 Login Flow v2
  ///
  /// Returns URLs and token for the browser-based login flow.
  /// See: https://docs.nextcloud.com/server/latest/developer_manual/client_apis/LoginFlow/
  Future<LoginFlowInit> initiateOAuthFlow(String serverUrl) async {
    final baseUrl = _normalizeUrl(serverUrl);

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/index.php/login/v2'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': _userAgent,
        },
      );

      if (response.statusCode != 200) {
        throw NextcloudApiException(
          'Failed to initiate login flow',
          statusCode: response.statusCode,
          response: response.body,
        );
      }

      final data = jsonDecode(response.body);

      return LoginFlowInit(
        loginUrl: data['login'] as String,
        pollEndpoint: data['poll']['endpoint'] as String,
        pollToken: data['poll']['token'] as String,
      );
    } on http.ClientException catch (e) {
      throw NextcloudApiException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw NextcloudApiException('Invalid server response: ${e.message}');
    }
  }

  /// Poll for OAuth2 Login Flow completion
  ///
  /// Returns null if authentication is still pending.
  /// Returns LoginFlowResult when authentication completes.
  /// Throws on error or timeout.
  Future<LoginFlowResult?> pollOAuthFlow(
    String pollEndpoint,
    String pollToken,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse(pollEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': _userAgent,
        },
        body: 'token=$pollToken',
      );

      if (response.statusCode == 404) {
        // Still waiting for user authentication
        return null;
      }

      if (response.statusCode != 200) {
        throw NextcloudApiException(
          'Login flow failed or timed out',
          statusCode: response.statusCode,
          response: response.body,
        );
      }

      final data = jsonDecode(response.body);

      return LoginFlowResult(
        server: data['server'] as String,
        loginName: data['loginName'] as String,
        appPassword: data['appPassword'] as String,
      );
    } on http.ClientException catch (e) {
      throw NextcloudApiException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw NextcloudApiException('Invalid server response: ${e.message}');
    }
  }

  /// Test if a URL is a valid Nextcloud server
  Future<bool> isNextcloudServer(String serverUrl) async {
    final baseUrl = _normalizeUrl(serverUrl);

    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/status.php'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      return data['installed'] == true && data['productname'] != null;
    } catch (_) {
      return false;
    }
  }

  /// Normalize server URL (remove trailing slash, ensure https)
  String _normalizeUrl(String url) {
    var normalized = url.trim();

    // Remove trailing slash
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    // Add https if no scheme provided
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }

    return normalized;
  }
}
