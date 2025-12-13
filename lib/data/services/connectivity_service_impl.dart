import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../domain/services/connectivity_service.dart';

/// Implementation of [ConnectivityService] using connectivity_plus package
///
/// This implementation monitors network connectivity across all platforms
/// and provides information about the current connection type and quality.
class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;
  final StreamController<ConnectionStatus> _statusController;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  ConnectionStatus _currentStatus;

  /// Create a new connectivity service
  ///
  /// [connectivity] Optional Connectivity instance for testing
  ConnectivityServiceImpl({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity(),
      _statusController = StreamController<ConnectionStatus>.broadcast(),
      _currentStatus = ConnectionStatus.disconnected() {
    _init();
  }

  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen(_handleChange);
    // Initial check
    checkConnectivity();
  }

  void _handleChange(List<ConnectivityResult> results) {
    _currentStatus = _mapResults(results);
    _statusController.add(_currentStatus);
    debugPrint('Connectivity changed: $_currentStatus');
  }

  ConnectionStatus _mapResults(List<ConnectivityResult> results) {
    final type = _mapConnectionType(results);
    return ConnectionStatus(
      isConnected: type != ConnectionType.none,
      type: type,
      quality: _estimateQuality(type),
      checkedAt: DateTime.now(),
    );
  }

  ConnectionType _mapConnectionType(List<ConnectivityResult> results) {
    // Check for WiFi first (preferred)
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectionType.wifi;
    }
    // Then ethernet
    if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectionType.ethernet;
    }
    // Then mobile
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectionType.mobile;
    }
    // VPN or other
    if (results.contains(ConnectivityResult.vpn) ||
        results.contains(ConnectivityResult.bluetooth) ||
        results.contains(ConnectivityResult.other)) {
      return ConnectionType.other;
    }
    // No connection
    return ConnectionType.none;
  }

  ConnectionQuality _estimateQuality(ConnectionType type) {
    switch (type) {
      case ConnectionType.wifi:
      case ConnectionType.ethernet:
        return ConnectionQuality.good;
      case ConnectionType.mobile:
        return ConnectionQuality.moderate;
      case ConnectionType.other:
        return ConnectionQuality.moderate;
      case ConnectionType.none:
        return ConnectionQuality.poor;
    }
  }

  @override
  Stream<ConnectionStatus> get onConnectivityChanged =>
      _statusController.stream;

  @override
  ConnectionStatus get currentStatus => _currentStatus;

  @override
  Future<ConnectionStatus> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _currentStatus = _mapResults(results);

      // On desktop platforms, also do a quick reachability check
      if (!kIsWeb &&
          (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
        if (_currentStatus.isConnected) {
          final isReachable = await _checkInternetReachability();
          if (!isReachable) {
            _currentStatus = ConnectionStatus.disconnected();
          }
        }
      }

      return _currentStatus;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return _currentStatus;
    }
  }

  /// Check if the internet is actually reachable
  ///
  /// This helps on desktop platforms where connectivity_plus
  /// might report connected even without internet access.
  Future<bool> _checkInternetReachability() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  bool canSync({required bool wifiOnlyEnabled}) {
    if (!_currentStatus.isConnected) return false;
    if (wifiOnlyEnabled && !_currentStatus.isUnmetered) return false;
    return true;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}

/// Extension to add copyWith to ConnectionStatus
extension ConnectionStatusCopyWith on ConnectionStatus {
  ConnectionStatus copyWith({
    bool? isConnected,
    ConnectionType? type,
    ConnectionQuality? quality,
    DateTime? checkedAt,
  }) {
    return ConnectionStatus(
      isConnected: isConnected ?? this.isConnected,
      type: type ?? this.type,
      quality: quality ?? this.quality,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }
}
