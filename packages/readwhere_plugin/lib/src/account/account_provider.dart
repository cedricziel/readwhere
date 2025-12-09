import '../entities/account_info.dart';
import 'auth_credentials.dart';

/// Interface for account/authentication providers.
///
/// Implementations handle authentication for catalog providers that
/// require user accounts. Not all catalog providers need an account
/// provider (e.g., public OPDS feeds).
///
/// This interface is separate from [CatalogProvider] to allow providers
/// that only need catalog access (no auth) to implement just that interface.
///
/// Example implementation:
/// ```dart
/// class NextcloudAccountProvider implements AccountProvider {
///   @override
///   String get id => 'nextcloud';
///
///   @override
///   Set<AuthType> get supportedAuthTypes => {
///     AuthType.basic,
///     AuthType.oauth2,
///   };
///
///   // ... implement other methods
/// }
/// ```
abstract class AccountProvider {
  /// Unique identifier for this provider.
  ///
  /// Should match the associated [CatalogProvider.id].
  String get id;

  /// The authentication types this provider supports.
  Set<AuthType> get supportedAuthTypes;

  /// Authenticates with the given credentials.
  ///
  /// [serverUrl] is the base URL of the server.
  /// [credentials] contains the authentication credentials.
  ///
  /// Returns an [AccountInfo] on success.
  /// Throws on authentication failure.
  Future<AccountInfo> authenticate(
    String serverUrl,
    AuthCredentials credentials,
  );

  /// Starts an OAuth flow for the given server.
  ///
  /// Returns an [OAuthFlowInit] containing the URL the user should visit
  /// and the polling information, or null if OAuth is not supported.
  ///
  /// After calling this, use [pollOAuthFlow] to check for completion.
  Future<OAuthFlowInit?> startOAuthFlow(String serverUrl);

  /// Polls for OAuth flow completion.
  ///
  /// [pollEndpoint] and [pollToken] are from the [OAuthFlowInit].
  ///
  /// Returns an [OAuthFlowResult] when the user has authenticated,
  /// or null if the flow is still pending.
  ///
  /// Throws on error (e.g., flow expired, user denied access).
  Future<OAuthFlowResult?> pollOAuthFlow(String pollEndpoint, String pollToken);

  /// Logs out of the account.
  ///
  /// This should:
  /// - Revoke tokens if possible
  /// - Clear cached authentication state
  /// - NOT delete stored credentials (that's handled separately)
  Future<void> logout(AccountInfo account);

  /// Refreshes expired OAuth tokens.
  ///
  /// [credentials] should be [OAuth2Credentials] with a refresh token.
  ///
  /// Returns new [OAuth2Credentials] on success, or null if refresh
  /// is not possible (e.g., no refresh token, refresh token expired).
  Future<OAuth2Credentials?> refreshToken(OAuth2Credentials credentials);

  /// Checks if this provider supports a specific auth type.
  bool supportsAuthType(AuthType type) => supportedAuthTypes.contains(type);

  /// Whether this provider supports OAuth authentication.
  bool get supportsOAuth => supportsAuthType(AuthType.oauth2);

  /// Whether this provider supports basic authentication.
  bool get supportsBasicAuth => supportsAuthType(AuthType.basic);
}
