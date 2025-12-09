import 'dart:convert';

import 'package:http/http.dart' as http;

import '../exceptions/nextcloud_exception.dart';
import 'models/server_info.dart';
import '../auth/models/login_flow_init.dart';
import '../auth/models/login_flow_result.dart';

/// Service for Nextcloud authentication and OCS API calls
///
/// Provides methods for:
/// - Validating app passwords
/// - Initiating OAuth2 Login Flow v2
/// - Polling for OAuth completion
/// - Checking if a URL is a valid Nextcloud server
class OcsApiService {
  final http.Client _client;

  /// User-Agent header for all requests
  final String userAgent;

  OcsApiService(
    this._client, {
    this.userAgent = 'ReadWhere/1.0.0 Nextcloud',
  });

  /// Common headers for OCS API requests
  Map<String, String> _ocsHeaders(String auth) => {
        'Authorization': 'Basic $auth',
        'OCS-APIRequest': 'true',
        'Accept': 'application/json',
        'User-Agent': userAgent,
      };

  /// Validate app password authentication and return server info
  ///
  /// Makes a request to the OCS API to verify credentials and get user info.
  Future<NextcloudServerInfo> validateAppPassword(
    String serverUrl,
    String username,
    String appPassword,
  ) async {
    final baseUrl = normalizeUrl(serverUrl);
    final auth = base64Encode(utf8.encode('$username:$appPassword'));

    try {
      // Get user info from OCS API
      final userResponse = await _client.get(
        Uri.parse('$baseUrl/ocs/v2.php/cloud/user'),
        headers: _ocsHeaders(auth),
      );

      if (userResponse.statusCode != 200) {
        throw NextcloudException(
          'Authentication failed',
          statusCode: userResponse.statusCode,
          response: userResponse.body,
        );
      }

      final userData = jsonDecode(userResponse.body);
      final ocsData = userData['ocs']?['data'];

      if (ocsData == null) {
        throw NextcloudException('Invalid response from server');
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
        serverName = capData['ocs']?['data']?['capabilities']?['theming']
                ?['name'] as String? ??
            'Nextcloud';
      }

      return NextcloudServerInfo(
        serverName: serverName,
        version: version,
        userId: ocsData['id'] as String? ?? username,
        displayName: ocsData['displayname'] as String? ??
            ocsData['id'] as String? ??
            username,
        email: ocsData['email'] as String?,
      );
    } on http.ClientException catch (e) {
      throw NextcloudException('Network error: ${e.message}', cause: e);
    } on FormatException catch (e) {
      throw NextcloudException('Invalid server response: ${e.message}',
          cause: e);
    }
  }

  /// Initiate OAuth2 Login Flow v2
  ///
  /// Returns URLs and token for the browser-based login flow.
  /// See: https://docs.nextcloud.com/server/latest/developer_manual/client_apis/LoginFlow/
  Future<LoginFlowInit> initiateOAuthFlow(String serverUrl) async {
    final baseUrl = normalizeUrl(serverUrl);

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/index.php/login/v2'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': userAgent,
        },
      );

      if (response.statusCode != 200) {
        throw NextcloudException(
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
      throw NextcloudException('Network error: ${e.message}', cause: e);
    } on FormatException catch (e) {
      throw NextcloudException('Invalid server response: ${e.message}',
          cause: e);
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
          'User-Agent': userAgent,
        },
        body: 'token=$pollToken',
      );

      if (response.statusCode == 404) {
        // Still waiting for user authentication
        return null;
      }

      if (response.statusCode != 200) {
        throw NextcloudException(
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
      throw NextcloudException('Network error: ${e.message}', cause: e);
    } on FormatException catch (e) {
      throw NextcloudException('Invalid server response: ${e.message}',
          cause: e);
    }
  }

  /// Test if a URL is a valid Nextcloud server
  Future<bool> isNextcloudServer(String serverUrl) async {
    final baseUrl = normalizeUrl(serverUrl);

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
  static String normalizeUrl(String url) {
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
