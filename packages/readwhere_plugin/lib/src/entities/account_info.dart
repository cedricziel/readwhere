import '../account/auth_credentials.dart';

/// Interface for account/authentication information.
///
/// Represents an authenticated session with a catalog provider.
/// Implementations should be immutable and contain all necessary
/// information to make authenticated requests.
abstract class AccountInfo {
  /// The ID of the catalog this account belongs to.
  String get catalogId;

  /// The user ID on the remote service.
  String get userId;

  /// The display name of the user.
  String get displayName;

  /// The type of authentication used.
  AuthType get authType;

  /// Whether the account is currently authenticated.
  ///
  /// This may return false if tokens have expired and need refreshing.
  bool get isAuthenticated;

  /// Provider-specific account data.
  ///
  /// This allows providers to store additional data they need,
  /// such as server version info, user quotas, etc.
  Map<String, dynamic> get providerData;
}
