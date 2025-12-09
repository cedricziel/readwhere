import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../../data/services/kavita_api_service.dart';

/// Kavita implementation of [AccountProvider].
///
/// Kavita uses API key authentication. The API key can be
/// obtained from the user's settings page in the Kavita web UI.
class KavitaAccountProvider implements AccountProvider {
  /// Creates an account provider with the given Kavita API service.
  KavitaAccountProvider(this._apiService);

  final KavitaApiService _apiService;

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

    final serverInfo = await _apiService.authenticate(
      serverUrl,
      credentials.apiKey,
    );

    return _KavitaAccountInfo(
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
class _KavitaAccountInfo implements AccountInfo {
  const _KavitaAccountInfo({
    required this.serverUrl,
    required this.serverName,
    required this.serverVersion,
    required this.apiKey,
  });

  final String serverUrl;
  final String serverName;
  final String serverVersion;
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
