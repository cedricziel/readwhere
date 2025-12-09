import 'package:equatable/equatable.dart';

/// Server information returned after successful authentication
class NextcloudServerInfo extends Equatable {
  /// Server display name (from theming)
  final String serverName;

  /// Nextcloud version string (e.g., "28.0.1")
  final String version;

  /// User ID
  final String userId;

  /// User display name
  final String displayName;

  /// User email address
  final String? email;

  const NextcloudServerInfo({
    required this.serverName,
    required this.version,
    required this.userId,
    required this.displayName,
    this.email,
  });

  @override
  List<Object?> get props => [serverName, version, userId, displayName, email];
}
