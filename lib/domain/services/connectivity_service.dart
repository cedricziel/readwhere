import 'dart:async';

/// Type of network connection
enum ConnectionType {
  /// No network connection
  none,

  /// Mobile data connection (cellular)
  mobile,

  /// WiFi connection
  wifi,

  /// Ethernet connection
  ethernet,

  /// VPN or other connection type
  other,
}

/// Quality estimate of the network connection
enum ConnectionQuality {
  /// Poor quality (slow, unreliable)
  poor,

  /// Moderate quality (usable)
  moderate,

  /// Good quality (fast, reliable)
  good,
}

/// Represents the current network connection status
class ConnectionStatus {
  /// Whether the device is connected to a network
  final bool isConnected;

  /// Type of network connection
  final ConnectionType type;

  /// Estimated quality of the connection
  final ConnectionQuality quality;

  /// When this status was last checked
  final DateTime checkedAt;

  const ConnectionStatus({
    required this.isConnected,
    required this.type,
    required this.quality,
    required this.checkedAt,
  });

  /// Create a disconnected status
  factory ConnectionStatus.disconnected() {
    return ConnectionStatus(
      isConnected: false,
      type: ConnectionType.none,
      quality: ConnectionQuality.poor,
      checkedAt: DateTime.now(),
    );
  }

  /// Whether the connection is WiFi
  bool get isWifi => type == ConnectionType.wifi;

  /// Whether the connection is mobile data
  bool get isMobile => type == ConnectionType.mobile;

  /// Whether the connection is ethernet
  bool get isEthernet => type == ConnectionType.ethernet;

  /// Whether the connection is high quality (WiFi or Ethernet)
  bool get isHighQuality =>
      quality == ConnectionQuality.good ||
      type == ConnectionType.wifi ||
      type == ConnectionType.ethernet;

  /// Whether the connection is unmetered (not mobile data)
  bool get isUnmetered =>
      type == ConnectionType.wifi ||
      type == ConnectionType.ethernet ||
      type == ConnectionType.none;

  @override
  String toString() {
    return 'ConnectionStatus(connected: $isConnected, type: ${type.name}, '
        'quality: ${quality.name})';
  }
}

/// Service for monitoring network connectivity
///
/// Provides information about the current network state and
/// notifies listeners when connectivity changes.
abstract class ConnectivityService {
  /// Stream of connectivity changes
  ///
  /// Emits a new [ConnectionStatus] whenever the network state changes.
  Stream<ConnectionStatus> get onConnectivityChanged;

  /// Current connection status
  ///
  /// Returns the most recently known connection status.
  /// May be stale if no recent check has been performed.
  ConnectionStatus get currentStatus;

  /// Check current connectivity (forces a fresh check)
  ///
  /// Performs an active check of the network state and returns
  /// the current connection status.
  Future<ConnectionStatus> checkConnectivity();

  /// Whether sync is allowed based on settings and connection
  ///
  /// Returns true if the current connection allows syncing based
  /// on the WiFi-only preference.
  ///
  /// [wifiOnlyEnabled] Whether the user has enabled WiFi-only sync
  bool canSync({required bool wifiOnlyEnabled});

  /// Dispose of resources
  ///
  /// Call this when the service is no longer needed to clean up
  /// any subscriptions or timers.
  void dispose();
}
