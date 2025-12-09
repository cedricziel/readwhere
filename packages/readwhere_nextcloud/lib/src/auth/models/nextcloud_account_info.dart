import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../../api/models/server_info.dart';

/// Nextcloud-specific implementation of [AccountInfo].
///
/// Wraps [NextcloudServerInfo] with additional catalog context.
class NextcloudAccountInfo implements AccountInfo {
  /// Creates a NextcloudAccountInfo from server info and catalog details.
  const NextcloudAccountInfo({
    required this.catalogId,
    required this.serverInfo,
    required this.authType,
    this.serverUrl,
    this.isAuthenticated = true,
  });

  /// Creates from a [NextcloudServerInfo] and metadata.
  factory NextcloudAccountInfo.fromServerInfo(
    NextcloudServerInfo serverInfo, {
    required String catalogId,
    required AuthType authType,
    String? serverUrl,
  }) {
    return NextcloudAccountInfo(
      catalogId: catalogId,
      serverInfo: serverInfo,
      authType: authType,
      serverUrl: serverUrl,
    );
  }

  @override
  final String catalogId;

  /// The underlying Nextcloud server info.
  final NextcloudServerInfo serverInfo;

  @override
  final AuthType authType;

  /// The server URL, if known.
  final String? serverUrl;

  @override
  final bool isAuthenticated;

  @override
  String get userId => serverInfo.userId;

  @override
  String get displayName => serverInfo.displayName;

  @override
  Map<String, dynamic> get providerData => {
        'serverName': serverInfo.serverName,
        'version': serverInfo.version,
        'email': serverInfo.email,
        if (serverUrl != null) 'serverUrl': serverUrl,
      };

  /// The Nextcloud server name (from theming).
  String get serverName => serverInfo.serverName;

  /// The Nextcloud server version.
  String get version => serverInfo.version;

  /// The user's email, if available.
  String? get email => serverInfo.email;

  /// Creates a copy with updated authentication state.
  NextcloudAccountInfo copyWith({
    String? catalogId,
    NextcloudServerInfo? serverInfo,
    AuthType? authType,
    String? serverUrl,
    bool? isAuthenticated,
  }) {
    return NextcloudAccountInfo(
      catalogId: catalogId ?? this.catalogId,
      serverInfo: serverInfo ?? this.serverInfo,
      authType: authType ?? this.authType,
      serverUrl: serverUrl ?? this.serverUrl,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}
