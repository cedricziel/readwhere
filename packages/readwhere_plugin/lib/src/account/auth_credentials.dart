import 'package:equatable/equatable.dart';

/// Types of authentication supported by catalog providers.
enum AuthType {
  /// No authentication required.
  none,

  /// HTTP Basic authentication (username/password).
  basic,

  /// Bearer token authentication.
  bearer,

  /// API key authentication.
  apiKey,

  /// OAuth 2.0 authentication.
  oauth2,
}

/// Base class for authentication credentials.
///
/// Implementations should be immutable and provide all necessary
/// data for authenticating with a catalog provider.
abstract class AuthCredentials extends Equatable {
  const AuthCredentials();

  /// The type of authentication these credentials represent.
  AuthType get type;
}

/// Credentials for HTTP Basic authentication.
class BasicAuthCredentials extends AuthCredentials {
  const BasicAuthCredentials({required this.username, required this.password});

  /// The username for authentication.
  final String username;

  /// The password for authentication.
  final String password;

  @override
  AuthType get type => AuthType.basic;

  @override
  List<Object?> get props => [username, password];
}

/// Credentials for Bearer token authentication.
class BearerAuthCredentials extends AuthCredentials {
  const BearerAuthCredentials({required this.token});

  /// The bearer token for authentication.
  final String token;

  @override
  AuthType get type => AuthType.bearer;

  @override
  List<Object?> get props => [token];
}

/// Credentials for API key authentication.
class ApiKeyCredentials extends AuthCredentials {
  const ApiKeyCredentials({
    required this.apiKey,
    this.headerName = 'X-API-Key',
  });

  /// The API key for authentication.
  final String apiKey;

  /// The header name to use for the API key.
  ///
  /// Defaults to 'X-API-Key'.
  final String headerName;

  @override
  AuthType get type => AuthType.apiKey;

  @override
  List<Object?> get props => [apiKey, headerName];
}

/// Credentials for OAuth 2.0 authentication.
class OAuth2Credentials extends AuthCredentials {
  const OAuth2Credentials({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.tokenType = 'Bearer',
  });

  /// The access token for authentication.
  final String accessToken;

  /// The refresh token for obtaining new access tokens.
  final String? refreshToken;

  /// When the access token expires.
  final DateTime? expiresAt;

  /// The token type (usually 'Bearer').
  final String tokenType;

  /// Whether the access token has expired.
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  @override
  AuthType get type => AuthType.oauth2;

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt, tokenType];
}

/// Data for initializing an OAuth flow.
///
/// Returned by [AccountProvider.startOAuthFlow] to provide the
/// necessary information for the user to complete authentication.
class OAuthFlowInit extends Equatable {
  const OAuthFlowInit({
    required this.loginUrl,
    required this.pollEndpoint,
    required this.pollToken,
    this.pollInterval = const Duration(seconds: 1),
  });

  /// The URL the user should visit to authenticate.
  final String loginUrl;

  /// The endpoint to poll for authentication status.
  final String pollEndpoint;

  /// The token to use when polling.
  final String pollToken;

  /// The recommended interval between poll requests.
  final Duration pollInterval;

  @override
  List<Object?> get props => [loginUrl, pollEndpoint, pollToken, pollInterval];
}

/// Result of a completed OAuth flow.
class OAuthFlowResult extends Equatable {
  const OAuthFlowResult({
    required this.credentials,
    required this.serverUrl,
    this.userId,
    this.displayName,
  });

  /// The OAuth2 credentials obtained from the flow.
  final OAuth2Credentials credentials;

  /// The server URL that was authenticated against.
  final String serverUrl;

  /// The user ID of the authenticated user, if available.
  final String? userId;

  /// The display name of the authenticated user, if available.
  final String? displayName;

  @override
  List<Object?> get props => [credentials, serverUrl, userId, displayName];
}
