import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing background sync settings
///
/// This provider handles sync-specific settings including:
/// - WiFi-only sync preference
/// - Sync interval configuration
/// - Per-category sync toggles (progress, catalogs, feeds)
/// - Last sync timestamp tracking
///
/// Settings are persisted to SharedPreferences.
class SyncSettingsProvider extends ChangeNotifier {
  // Preference keys
  static const String _syncEnabledKey = 'sync_enabled';
  static const String _wifiOnlyKey = 'sync_wifi_only';
  static const String _progressSyncEnabledKey = 'sync_progress_enabled';
  static const String _catalogSyncEnabledKey = 'sync_catalog_enabled';
  static const String _feedSyncEnabledKey = 'sync_feed_enabled';
  static const String _syncIntervalKey = 'sync_interval_minutes';
  static const String _lastSyncKey = 'last_sync_at';

  SharedPreferences? _prefs;

  // State
  bool _syncEnabled = false;
  bool _wifiOnly = true;
  bool _progressSyncEnabled = true;
  bool _catalogSyncEnabled = true;
  bool _feedSyncEnabled = true;
  int _syncIntervalMinutes = 30;
  DateTime? _lastSyncAt;
  bool _isInitialized = false;

  // Getters

  /// Whether sync is enabled globally
  bool get syncEnabled => _syncEnabled;

  /// Whether sync should only happen on WiFi
  bool get wifiOnly => _wifiOnly;

  /// Whether reading progress sync is enabled
  bool get progressSyncEnabled => _progressSyncEnabled;

  /// Whether catalog sync is enabled
  bool get catalogSyncEnabled => _catalogSyncEnabled;

  /// Whether RSS feed sync is enabled
  bool get feedSyncEnabled => _feedSyncEnabled;

  /// Sync interval in minutes
  int get syncIntervalMinutes => _syncIntervalMinutes;

  /// Sync interval as Duration
  Duration get syncInterval => Duration(minutes: _syncIntervalMinutes);

  /// When the last sync occurred
  DateTime? get lastSyncAt => _lastSyncAt;

  /// Whether settings have been loaded
  bool get isInitialized => _isInitialized;

  /// Available sync interval options (in minutes)
  static const List<int> intervalOptions = [15, 30, 60, 120, 360, 720];

  /// Human-readable labels for interval options
  static const Map<int, String> intervalLabels = {
    15: '15 minutes',
    30: '30 minutes',
    60: '1 hour',
    120: '2 hours',
    360: '6 hours',
    720: '12 hours',
  };

  /// Initialize the provider and load settings from storage
  ///
  /// This should be called once at app startup.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize SyncSettingsProvider: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Set whether sync is enabled globally
  Future<void> setSyncEnabled(bool enabled) async {
    if (_syncEnabled == enabled) return;

    _syncEnabled = enabled;
    await _prefs?.setBool(_syncEnabledKey, enabled);
    notifyListeners();
  }

  /// Set whether sync should only happen on WiFi
  Future<void> setWifiOnly(bool wifiOnly) async {
    if (_wifiOnly == wifiOnly) return;

    _wifiOnly = wifiOnly;
    await _prefs?.setBool(_wifiOnlyKey, wifiOnly);
    notifyListeners();
  }

  /// Set whether progress sync is enabled
  Future<void> setProgressSyncEnabled(bool enabled) async {
    if (_progressSyncEnabled == enabled) return;

    _progressSyncEnabled = enabled;
    await _prefs?.setBool(_progressSyncEnabledKey, enabled);
    notifyListeners();
  }

  /// Set whether catalog sync is enabled
  Future<void> setCatalogSyncEnabled(bool enabled) async {
    if (_catalogSyncEnabled == enabled) return;

    _catalogSyncEnabled = enabled;
    await _prefs?.setBool(_catalogSyncEnabledKey, enabled);
    notifyListeners();
  }

  /// Set whether feed sync is enabled
  Future<void> setFeedSyncEnabled(bool enabled) async {
    if (_feedSyncEnabled == enabled) return;

    _feedSyncEnabled = enabled;
    await _prefs?.setBool(_feedSyncEnabledKey, enabled);
    notifyListeners();
  }

  /// Set the sync interval
  ///
  /// [minutes] Must be one of the values in [intervalOptions]
  Future<void> setSyncInterval(int minutes) async {
    if (_syncIntervalMinutes == minutes) return;
    if (!intervalOptions.contains(minutes)) {
      debugPrint('Invalid sync interval: $minutes');
      return;
    }

    _syncIntervalMinutes = minutes;
    await _prefs?.setInt(_syncIntervalKey, minutes);
    notifyListeners();
  }

  /// Update the last sync timestamp to now
  Future<void> updateLastSyncTime() async {
    _lastSyncAt = DateTime.now();
    await _prefs?.setInt(_lastSyncKey, _lastSyncAt!.millisecondsSinceEpoch);
    notifyListeners();
  }

  /// Clear the last sync timestamp
  Future<void> clearLastSyncTime() async {
    _lastSyncAt = null;
    await _prefs?.remove(_lastSyncKey);
    notifyListeners();
  }

  /// Whether a sync is due based on the interval
  bool get isDueForSync {
    if (_lastSyncAt == null) return true;
    return DateTime.now().difference(_lastSyncAt!) > syncInterval;
  }

  /// Time until next scheduled sync
  Duration get timeUntilNextSync {
    if (_lastSyncAt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_lastSyncAt!);
    final remaining = syncInterval - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Human-readable description of when last sync occurred
  String get lastSyncDescription {
    if (_lastSyncAt == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(_lastSyncAt!);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return '$mins minute${mins == 1 ? '' : 's'} ago';
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else {
      final days = diff.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    }
  }

  /// Reset all sync settings to defaults
  Future<void> resetToDefaults() async {
    _syncEnabled = false;
    _wifiOnly = true;
    _progressSyncEnabled = true;
    _catalogSyncEnabled = true;
    _feedSyncEnabled = true;
    _syncIntervalMinutes = 30;
    _lastSyncAt = null;

    await Future.wait([
      _prefs?.remove(_syncEnabledKey) ?? Future.value(),
      _prefs?.remove(_wifiOnlyKey) ?? Future.value(),
      _prefs?.remove(_progressSyncEnabledKey) ?? Future.value(),
      _prefs?.remove(_catalogSyncEnabledKey) ?? Future.value(),
      _prefs?.remove(_feedSyncEnabledKey) ?? Future.value(),
      _prefs?.remove(_syncIntervalKey) ?? Future.value(),
      _prefs?.remove(_lastSyncKey) ?? Future.value(),
    ]);

    notifyListeners();
  }

  /// Load all settings from SharedPreferences
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    _syncEnabled = _prefs!.getBool(_syncEnabledKey) ?? false;
    _wifiOnly = _prefs!.getBool(_wifiOnlyKey) ?? true;
    _progressSyncEnabled = _prefs!.getBool(_progressSyncEnabledKey) ?? true;
    _catalogSyncEnabled = _prefs!.getBool(_catalogSyncEnabledKey) ?? true;
    _feedSyncEnabled = _prefs!.getBool(_feedSyncEnabledKey) ?? true;

    final interval = _prefs!.getInt(_syncIntervalKey);
    if (interval != null && intervalOptions.contains(interval)) {
      _syncIntervalMinutes = interval;
    }

    final lastSyncMs = _prefs!.getInt(_lastSyncKey);
    if (lastSyncMs != null) {
      _lastSyncAt = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    }
  }
}
