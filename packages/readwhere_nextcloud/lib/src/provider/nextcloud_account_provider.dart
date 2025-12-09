import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../api/ocs_api_service.dart';
import '../auth/models/nextcloud_account_info.dart';

/// Nextcloud implementation of [AccountProvider].
///
/// Supports both basic (app password) and OAuth2 (Login Flow v2)
/// authentication mechanisms.
///
/// Note: Nextcloud's OAuth2 Login Flow v2 returns an app password,
/// not traditional OAuth tokens. The app password acts like a
/// long-lived access token.
class NextcloudAccountProvider implements AccountProvider {
  /// Creates an account provider with the given OCS API service.
  NextcloudAccountProvider(this._api);

  final OcsApiService _api;

  @override
  String get id => 'nextcloud';

  @override
  Set<AuthType> get supportedAuthTypes => {
        AuthType.basic,
        AuthType.oauth2,
      };

  @override
  Future<AccountInfo> authenticate(
    String serverUrl,
    AuthCredentials credentials,
  ) async {
    if (credentials is! BasicAuthCredentials) {
      throw ArgumentError(
        'Nextcloud authenticate requires BasicAuthCredentials. '
        'For OAuth, use startOAuthFlow/pollOAuthFlow instead.',
      );
    }

    final serverInfo = await _api.validateAppPassword(
      serverUrl,
      credentials.username,
      credentials.password,
    );

    return NextcloudAccountInfo.fromServerInfo(
      serverInfo,
      // Note: catalogId is not known at this point, caller should set it
      catalogId: '',
      authType: AuthType.basic,
      serverUrl: OcsApiService.normalizeUrl(serverUrl),
    );
  }

  @override
  Future<OAuthFlowInit?> startOAuthFlow(String serverUrl) async {
    final init = await _api.initiateOAuthFlow(serverUrl);
    return OAuthFlowInit(
      loginUrl: init.loginUrl,
      pollEndpoint: init.pollEndpoint,
      pollToken: init.pollToken,
    );
  }

  @override
  Future<OAuthFlowResult?> pollOAuthFlow(
    String pollEndpoint,
    String pollToken,
  ) async {
    final result = await _api.pollOAuthFlow(pollEndpoint, pollToken);

    if (result == null) {
      return null;
    }

    // Nextcloud Login Flow v2 returns an app password, not OAuth tokens.
    // We convert it to OAuth2Credentials where the accessToken is the app password.
    return OAuthFlowResult(
      credentials: OAuth2Credentials(
        accessToken: result.appPassword,
        // App passwords don't expire and don't have refresh tokens
        refreshToken: null,
        expiresAt: null,
      ),
      serverUrl: result.server,
      userId: result.loginName,
      displayName: result.loginName,
    );
  }

  @override
  Future<void> logout(AccountInfo account) async {
    // Nextcloud app passwords are long-lived and typically not revoked
    // programmatically. Users manage them via the Nextcloud web interface.
    // This is a no-op for now.
  }

  @override
  Future<OAuth2Credentials?> refreshToken(OAuth2Credentials credentials) async {
    // Nextcloud app passwords don't expire and don't need refreshing.
    // Return the same credentials.
    return credentials;
  }

  @override
  bool supportsAuthType(AuthType type) => supportedAuthTypes.contains(type);

  @override
  bool get supportsOAuth => supportsAuthType(AuthType.oauth2);

  @override
  bool get supportsBasicAuth => supportsAuthType(AuthType.basic);
}
