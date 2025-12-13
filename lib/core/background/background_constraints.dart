/// Network type requirements for background tasks.
enum NetworkType {
  /// No network connection required
  none,

  /// Any network connection (WiFi, mobile, etc.)
  connected,

  /// Only WiFi or Ethernet (unmetered)
  unmetered,

  /// Only when not roaming
  notRoaming,
}

/// Battery level constraints for background tasks.
enum BatteryConstraint {
  /// No battery constraint
  none,

  /// Run only when not low on battery
  notLow,

  /// Run only when charging
  charging,
}

/// Constraints for background task execution.
class BackgroundConstraints {
  /// Network type requirement
  final NetworkType networkType;

  /// Battery constraint
  final BatteryConstraint batteryConstraint;

  /// Whether the device should be idle
  final bool requiresDeviceIdle;

  /// Whether storage should not be low
  final bool requiresStorageNotLow;

  const BackgroundConstraints({
    this.networkType = NetworkType.none,
    this.batteryConstraint = BatteryConstraint.none,
    this.requiresDeviceIdle = false,
    this.requiresStorageNotLow = false,
  });

  /// Default constraints for sync tasks (requires network)
  static const syncDefaults = BackgroundConstraints(
    networkType: NetworkType.connected,
    batteryConstraint: BatteryConstraint.notLow,
  );

  /// WiFi-only sync constraints
  static const wifiOnly = BackgroundConstraints(
    networkType: NetworkType.unmetered,
    batteryConstraint: BatteryConstraint.notLow,
  );

  /// No constraints
  static const none = BackgroundConstraints();

  /// Create a copy with modified fields
  BackgroundConstraints copyWith({
    NetworkType? networkType,
    BatteryConstraint? batteryConstraint,
    bool? requiresDeviceIdle,
    bool? requiresStorageNotLow,
  }) {
    return BackgroundConstraints(
      networkType: networkType ?? this.networkType,
      batteryConstraint: batteryConstraint ?? this.batteryConstraint,
      requiresDeviceIdle: requiresDeviceIdle ?? this.requiresDeviceIdle,
      requiresStorageNotLow:
          requiresStorageNotLow ?? this.requiresStorageNotLow,
    );
  }

  @override
  String toString() =>
      'BackgroundConstraints(network: $networkType, battery: $batteryConstraint)';
}
