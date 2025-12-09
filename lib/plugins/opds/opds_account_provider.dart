import 'package:readwhere_plugin/readwhere_plugin.dart';

/// OPDS implementation of [AccountProvider].
///
/// OPDS catalogs typically either require no authentication or use
/// HTTP Basic authentication. OAuth is not commonly used.
class OpdsAccountProvider implements AccountProvider {
  @override
  String get id => 'opds';

  @override
  Set<AuthType> get supportedAuthTypes => {AuthType.none, AuthType.basic};

  @override
  Future<AccountInfo> authenticate(
    String serverUrl,
    AuthCredentials credentials,
  ) async {
    // OPDS authentication is typically handled at the HTTP level.
    // For basic auth, the credentials are passed with each request.
    // We don't do a separate authentication step here.
    return _OpdsAccountInfo(
      catalogId: '',
      serverUrl: serverUrl,
      authType: credentials.type,
      credentials: credentials,
    );
  }

  @override
  Future<OAuthFlowInit?> startOAuthFlow(String serverUrl) async {
    // OPDS doesn't typically use OAuth
    return null;
  }

  @override
  Future<OAuthFlowResult?> pollOAuthFlow(
    String pollEndpoint,
    String pollToken,
  ) async {
    // OPDS doesn't typically use OAuth
    return null;
  }

  @override
  Future<void> logout(AccountInfo account) async {
    // Nothing to do for OPDS - auth is stateless
  }

  @override
  Future<OAuth2Credentials?> refreshToken(OAuth2Credentials credentials) async {
    // OPDS doesn't use OAuth tokens
    return null;
  }

  @override
  bool supportsAuthType(AuthType type) => supportedAuthTypes.contains(type);

  @override
  bool get supportsOAuth => false;

  @override
  bool get supportsBasicAuth => true;
}

/// Simple AccountInfo implementation for OPDS.
class _OpdsAccountInfo implements AccountInfo {
  const _OpdsAccountInfo({
    required this.catalogId,
    required this.serverUrl,
    required this.authType,
    this.credentials,
  });

  @override
  final String catalogId;

  final String serverUrl;

  @override
  final AuthType authType;

  final AuthCredentials? credentials;

  @override
  String get userId {
    if (credentials is BasicAuthCredentials) {
      return (credentials as BasicAuthCredentials).username;
    }
    return 'anonymous';
  }

  @override
  String get displayName => userId;

  @override
  bool get isAuthenticated => true;

  @override
  Map<String, dynamic> get providerData => {'serverUrl': serverUrl};
}
