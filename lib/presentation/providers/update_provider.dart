import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/update_service.dart';

/// Provider for managing app update state.
///
/// Handles checking for updates, storing preferences, and managing
/// the update notification state.
class UpdateProvider extends ChangeNotifier {
  final UpdateService _updateService;

  UpdateCheckResult? _lastCheckResult;
  bool _isChecking = false;
  DateTime? _lastCheckTime;
  bool _updateDismissed = false;
  String? _dismissedVersion;

  static const String _lastCheckTimeKey = 'update_last_check_time';
  static const String _dismissedVersionKey = 'update_dismissed_version';
  static const Duration _checkInterval = Duration(hours: 24);

  /// Creates an UpdateProvider with the given [UpdateService].
  UpdateProvider({required UpdateService updateService})
    : _updateService = updateService;

  /// Whether an update check is currently in progress.
  bool get isChecking => _isChecking;

  /// The result of the last update check.
  UpdateCheckResult? get lastCheckResult => _lastCheckResult;

  /// Whether an update is available.
  bool get updateAvailable =>
      _lastCheckResult?.updateAvailable == true && !_updateDismissed;

  /// Information about the available update.
  UpdateInfo? get updateInfo => _lastCheckResult?.updateInfo;

  /// The current app version.
  String? get currentVersion => _lastCheckResult?.currentVersion;

  /// Error message from the last check, if any.
  String? get error => _lastCheckResult?.error;

  /// When the last check was performed.
  DateTime? get lastCheckTime => _lastCheckTime;

  /// Whether the update notification has been dismissed.
  bool get updateDismissed => _updateDismissed;

  /// Initializes the provider by loading saved preferences.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load last check time
    final lastCheckMillis = prefs.getInt(_lastCheckTimeKey);
    if (lastCheckMillis != null) {
      _lastCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheckMillis);
    }

    // Load dismissed version
    _dismissedVersion = prefs.getString(_dismissedVersionKey);

    notifyListeners();
  }

  /// Checks for updates.
  ///
  /// If [force] is false and a check was performed recently, this will
  /// return the cached result.
  Future<UpdateCheckResult> checkForUpdates({bool force = false}) async {
    // Skip if already checking
    if (_isChecking) {
      return _lastCheckResult ?? UpdateCheckResult.noUpdate('unknown');
    }

    // Skip if checked recently (unless forced)
    if (!force && _lastCheckTime != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastCheckTime!);
      if (timeSinceLastCheck < _checkInterval && _lastCheckResult != null) {
        return _lastCheckResult!;
      }
    }

    _isChecking = true;
    notifyListeners();

    try {
      _lastCheckResult = await _updateService.checkForUpdate();
      _lastCheckTime = DateTime.now();

      // Check if this version was previously dismissed
      if (_lastCheckResult?.updateInfo?.version == _dismissedVersion) {
        _updateDismissed = true;
      } else {
        _updateDismissed = false;
      }

      // Save last check time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _lastCheckTimeKey,
        _lastCheckTime!.millisecondsSinceEpoch,
      );

      return _lastCheckResult!;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Checks for updates silently on app startup.
  ///
  /// Only performs a check if it hasn't been checked recently.
  Future<void> checkOnStartup() async {
    await initialize();

    // Only check if we haven't checked recently
    if (_lastCheckTime == null ||
        DateTime.now().difference(_lastCheckTime!) > _checkInterval) {
      await checkForUpdates();
    }
  }

  /// Dismisses the update notification for the current version.
  ///
  /// The notification won't be shown again until a newer version is available.
  Future<void> dismissUpdate() async {
    _updateDismissed = true;
    _dismissedVersion = _lastCheckResult?.updateInfo?.version;

    if (_dismissedVersion != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedVersionKey, _dismissedVersion!);
    }

    notifyListeners();
  }

  /// Clears the dismissed version, allowing the notification to show again.
  Future<void> clearDismissedVersion() async {
    _updateDismissed = false;
    _dismissedVersion = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dismissedVersionKey);

    notifyListeners();
  }

  /// URL to the releases page.
  String get releasesUrl => _updateService.releasesUrl;
}
