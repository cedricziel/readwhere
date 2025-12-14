import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Represents an active Synology Drive session.
class SynologySession extends Equatable {
  /// Creates a new [SynologySession].
  const SynologySession({
    required this.catalogId,
    required this.serverUrl,
    required this.sessionId,
    required this.deviceId,
    required this.createdAt,
    this.expiresAt,
  });

  /// Creates a [SynologySession] from JSON.
  factory SynologySession.fromJson(Map<String, dynamic> json) {
    return SynologySession(
      catalogId: json['catalogId'] as String,
      serverUrl: json['serverUrl'] as String,
      sessionId: json['sessionId'] as String,
      deviceId: json['deviceId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  /// Creates a [SynologySession] from a JSON string.
  factory SynologySession.fromJsonString(String jsonString) {
    return SynologySession.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  /// The catalog ID this session belongs to.
  final String catalogId;

  /// The Synology NAS server URL.
  final String serverUrl;

  /// The session ID for API calls.
  final String sessionId;

  /// The device ID.
  final String deviceId;

  /// When the session was created.
  final DateTime createdAt;

  /// When the session expires (if known).
  final DateTime? expiresAt;

  /// Whether the session has expired.
  bool get isExpired {
    if (expiresAt == null) {
      // If no expiry time, assume session is valid for 24 hours
      return DateTime.now().difference(createdAt).inHours > 24;
    }
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return {
      'catalogId': catalogId,
      'serverUrl': serverUrl,
      'sessionId': sessionId,
      'deviceId': deviceId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  /// Converts to a JSON string.
  String toJsonString() => json.encode(toJson());

  @override
  List<Object?> get props => [
        catalogId,
        serverUrl,
        sessionId,
        deviceId,
        createdAt,
        expiresAt,
      ];

  @override
  String toString() {
    return 'SynologySession(catalogId: $catalogId, '
        'serverUrl: $serverUrl, '
        'sessionId: ${sessionId.substring(0, 8)}..., '
        'isExpired: $isExpired)';
  }
}
