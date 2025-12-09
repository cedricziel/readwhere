import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../api/kavita_api_client.dart';

/// Kavita implementation of [AccountProvider].
///
/// Kavita uses API key authentication. The API key can be
/// obtained from the user's settings page in the Kavita web UI.
class KavitaAccountProvider implements AccountProvider {
  /// Creates an account provider with the given Kavita API client.
  KavitaAccountProvider(this._apiClient);

  final KavitaApiClient _apiClient;

  @override
  String get id => 'kavita';

  @override
  Set<AuthType> get supportedAuthTypes => {AuthType.apiKey};

  @override
  Future<AccountInfo> authenticate(
    String serverUrl,
    AuthCredentials credentials,
  ) async {
    if (credentials is! ApiKeyCredentials) {
      throw ArgumentError('Kavita requires API key authentication');
    }

    final serverInfo = await _apiClient.authenticate(
      serverUrl,
      credentials.apiKey,
    );

    return KavitaAccountInfo(
      serverUrl: serverUrl,
      serverName: serverInfo.serverName,
      serverVersion: serverInfo.version,
      apiKey: credentials.apiKey,
    );
  }

  @override
  Future<OAuthFlowInit?> startOAuthFlow(String serverUrl) async {
    // Kavita doesn't use OAuth
    return null;
  }

  @override
  Future<OAuthFlowResult?> pollOAuthFlow(
    String pollEndpoint,
    String pollToken,
  ) async {
    // Kavita doesn't use OAuth
    return null;
  }

  @override
  Future<void> logout(AccountInfo account) async {
    // Nothing to do for Kavita - API key auth is stateless
  }

  @override
  Future<OAuth2Credentials?> refreshToken(OAuth2Credentials credentials) async {
    // Kavita doesn't use OAuth tokens
    return null;
  }

  @override
  bool supportsAuthType(AuthType type) => supportedAuthTypes.contains(type);

  @override
  bool get supportsOAuth => false;

  @override
  bool get supportsBasicAuth => false;
}

/// AccountInfo implementation for Kavita servers.
class KavitaAccountInfo implements AccountInfo {
  /// Creates a Kavita account info.
  const KavitaAccountInfo({
    required this.serverUrl,
    required this.serverName,
    required this.serverVersion,
    required this.apiKey,
  });

  /// The Kavita server URL.
  final String serverUrl;

  /// The server name/install ID.
  final String serverName;

  /// The Kavita server version.
  final String serverVersion;

  /// The user's API key.
  final String apiKey;

  @override
  String get catalogId => '';

  @override
  AuthType get authType => AuthType.apiKey;

  @override
  String get userId => 'kavita-user';

  @override
  String get displayName => serverName;

  @override
  bool get isAuthenticated => true;

  @override
  Map<String, dynamic> get providerData => {
    'serverUrl': serverUrl,
    'serverName': serverName,
    'serverVersion': serverVersion,
    'apiKey': apiKey,
  };
}
