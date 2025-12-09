import '../account/auth_credentials.dart';
import '../core/plugin_base.dart';
import '../entities/account_info.dart';

/// Capability for account/authentication management.
///
/// Plugins with this capability can authenticate users with
/// remote services using various auth methods (basic, OAuth2, API key).
///
/// Example:
/// ```dart
/// class NextcloudPlugin extends PluginBase
///     with CatalogCapability, AccountCapability {
///   @override
///   Set<AuthType> get supportedAuthTypes => {
///     AuthType.basic,
///     AuthType.oauth2,
///   };
///
///   @override
///   Future<AccountInfo> authenticate(
///     String serverUrl,
///     AuthCredentials credentials,
///   ) async {
///     if (credentials is BasicAuthCredentials) {
///       return _authenticateWithBasic(serverUrl, credentials);
///     } else if (credentials is OAuth2Credentials) {
///       return _authenticateWithOAuth(serverUrl, credentials);
///     }
///     throw UnsupportedError('Unsupported auth type');
///   }
///
///   // ... implement other methods
/// }
/// ```
mixin AccountCapability on PluginBase {
  /// Authentication types this plugin supports.
  ///
  /// The UI uses this to show appropriate login forms.
  Set<AuthType> get supportedAuthTypes;

  /// Authenticate with the given credentials.
  ///
  /// [serverUrl] is the base URL of the server.
  /// [credentials] contains the authentication credentials.
  ///
  /// Returns an [AccountInfo] on success with user details
  /// and any tokens/credentials needed for future requests.
  ///
  /// Throws on authentication failure with an appropriate error message.
  Future<AccountInfo> authenticate(
    String serverUrl,
    AuthCredentials credentials,
  );

  /// Start an OAuth 2.0 flow.
  ///
  /// Returns a [PluginOAuthFlowInit] with:
  /// - URL for user to visit in browser
  /// - Poll endpoint and token for checking completion
  ///
  /// Returns null if OAuth is not supported.
  ///
  /// After calling this, use [pollOAuthFlow] to check for completion.
  Future<PluginOAuthFlowInit?> startOAuthFlow(String serverUrl) async => null;

  /// Poll for OAuth flow completion.
  ///
  /// [pollEndpoint] and [pollToken] are from the [PluginOAuthFlowInit].
  ///
  /// Returns [PluginOAuthFlowResult] when the user has authenticated,
  /// or null if the flow is still pending.
  ///
  /// Throws on error (e.g., flow expired, user denied access).
  Future<PluginOAuthFlowResult?> pollOAuthFlow(
    String pollEndpoint,
    String pollToken,
  ) async => null;

  /// Log out of the account.
  ///
  /// Should:
  /// - Revoke tokens if possible
  /// - Clear cached authentication state
  /// - NOT delete stored credentials (handled by PluginStorage)
  Future<void> logout(AccountInfo account);

  /// Refresh expired OAuth tokens.
  ///
  /// [credentials] should be [OAuth2Credentials] with a refresh token.
  ///
  /// Returns new [OAuth2Credentials] on success, or null if refresh
  /// is not possible (e.g., no refresh token, refresh token expired).
  Future<OAuth2Credentials?> refreshToken(OAuth2Credentials credentials) async {
    return null;
  }

  /// Validate stored credentials are still valid.
  ///
  /// Performs a lightweight check (e.g., token validation endpoint)
  /// without full re-authentication.
  ///
  /// Returns true if credentials are valid, false if they need
  /// to be refreshed or re-authenticated.
  Future<bool> validateCredentials(
    String serverUrl,
    AuthCredentials credentials,
  ) async {
    // Default implementation: assume valid
    // Subclasses should override for proper validation
    return true;
  }

  // ===== Convenience Methods =====

  /// Check if this provider supports a specific auth type.
  bool supportsAuthType(AuthType type) => supportedAuthTypes.contains(type);

  /// Whether this provider supports OAuth authentication.
  bool get supportsOAuth => supportsAuthType(AuthType.oauth2);

  /// Whether this provider supports basic authentication.
  bool get supportsBasicAuth => supportsAuthType(AuthType.basic);

  /// Whether this provider supports API key authentication.
  bool get supportsApiKey => supportsAuthType(AuthType.apiKey);

  /// Whether this provider supports bearer token authentication.
  bool get supportsBearer => supportsAuthType(AuthType.bearer);

  /// Whether authentication is required.
  ///
  /// Returns false if the provider works without authentication
  /// (e.g., public OPDS feeds).
  bool get requiresAuth => !supportedAuthTypes.contains(AuthType.none);
}

/// Initialization data for an OAuth flow (unified plugin system).
///
/// Different from the legacy [OAuthFlowInit] in auth_credentials.dart.
class PluginOAuthFlowInit {
  /// URL the user should open in their browser.
  final String loginUrl;

  /// Endpoint to poll for completion.
  final String pollEndpoint;

  /// Token to include when polling.
  final String pollToken;

  /// How long between poll attempts (in seconds).
  final int pollInterval;

  /// When the flow expires (if not completed).
  final DateTime? expiresAt;

  /// Creates OAuth flow initialization data.
  const PluginOAuthFlowInit({
    required this.loginUrl,
    required this.pollEndpoint,
    required this.pollToken,
    this.pollInterval = 5,
    this.expiresAt,
  });

  /// Whether the flow has expired.
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Result of a completed OAuth flow (unified plugin system).
///
/// Different from the legacy [OAuthFlowResult] in auth_credentials.dart.
class PluginOAuthFlowResult {
  /// The obtained credentials.
  final OAuth2Credentials credentials;

  /// Account information from the server.
  final AccountInfo? accountInfo;

  /// Creates an OAuth flow result.
  const PluginOAuthFlowResult({required this.credentials, this.accountInfo});
}
