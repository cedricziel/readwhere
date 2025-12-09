import 'package:equatable/equatable.dart';

/// Result of validating a catalog configuration.
///
/// Returned by [CatalogProvider.validate] to indicate whether
/// the catalog is accessible and properly configured.
class ValidationResult extends Equatable {
  const ValidationResult({
    required this.isValid,
    this.serverName,
    this.serverVersion,
    this.error,
    this.errorCode,
    this.properties = const {},
  });

  /// Creates a successful validation result.
  const ValidationResult.success({
    this.serverName,
    this.serverVersion,
    this.properties = const {},
  }) : isValid = true,
       error = null,
       errorCode = null;

  /// Creates a failed validation result.
  const ValidationResult.failure({
    required String this.error,
    this.errorCode,
    this.properties = const {},
  }) : isValid = false,
       serverName = null,
       serverVersion = null;

  /// Whether the catalog configuration is valid and accessible.
  final bool isValid;

  /// The name of the server, if available.
  final String? serverName;

  /// The version of the server software, if available.
  final String? serverVersion;

  /// Error message if validation failed.
  final String? error;

  /// Error code if validation failed.
  ///
  /// Common codes:
  /// - 'connection_failed': Could not connect to the server
  /// - 'invalid_url': The URL is malformed or invalid
  /// - 'auth_required': Authentication is required
  /// - 'auth_failed': Authentication credentials are invalid
  /// - 'not_found': The catalog endpoint was not found
  /// - 'unsupported_version': Server version is not supported
  final String? errorCode;

  /// Additional provider-specific properties.
  ///
  /// Providers can include extra validation data here, such as
  /// supported features, server capabilities, etc.
  final Map<String, dynamic> properties;

  /// Whether validation failed.
  bool get isInvalid => !isValid;

  /// Whether the error is an authentication error.
  bool get isAuthError =>
      errorCode == 'auth_required' || errorCode == 'auth_failed';

  /// Whether the error is a connection error.
  bool get isConnectionError => errorCode == 'connection_failed';

  @override
  List<Object?> get props => [
    isValid,
    serverName,
    serverVersion,
    error,
    errorCode,
    properties,
  ];
}
