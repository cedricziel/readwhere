import 'package:readwhere_plugin/readwhere_plugin.dart';

/// RSS implementation of [AccountProvider].
///
/// RSS feeds typically either require no authentication or use
/// HTTP Basic authentication. OAuth is not commonly used.
class RssAccountProvider implements AccountProvider {
  @override
  String get id => 'rss';

  @override
  Set<AuthType> get supportedAuthTypes => {AuthType.none, AuthType.basic};

  @override
  Future<AccountInfo> authenticate(
    String serverUrl,
    AuthCredentials credentials,
  ) async {
    // RSS authentication is handled at the HTTP level.
    // For basic auth, credentials are passed with each request.
    return RssAccountInfo(
      catalogId: '',
      serverUrl: serverUrl,
      authType: credentials.type,
      credentials: credentials,
    );
  }

  @override
  Future<OAuthFlowInit?> startOAuthFlow(String serverUrl) async {
    // RSS doesn't typically use OAuth
    return null;
  }

  @override
  Future<OAuthFlowResult?> pollOAuthFlow(
    String pollEndpoint,
    String pollToken,
  ) async {
    // RSS doesn't typically use OAuth
    return null;
  }

  @override
  Future<void> logout(AccountInfo account) async {
    // Nothing to do for RSS - auth is stateless
  }

  @override
  Future<OAuth2Credentials?> refreshToken(OAuth2Credentials credentials) async {
    // RSS doesn't use OAuth tokens
    return null;
  }

  @override
  bool supportsAuthType(AuthType type) => supportedAuthTypes.contains(type);

  @override
  bool get supportsOAuth => false;

  @override
  bool get supportsBasicAuth => true;
}

/// Simple AccountInfo implementation for RSS feeds.
class RssAccountInfo implements AccountInfo {
  /// Creates RSS account info
  const RssAccountInfo({
    required this.catalogId,
    required this.serverUrl,
    required this.authType,
    this.credentials,
  });

  @override
  final String catalogId;

  /// The RSS feed URL
  final String serverUrl;

  @override
  final AuthType authType;

  /// The authentication credentials (if any)
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
