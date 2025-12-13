import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/presentation/providers/sync_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncSettingsProvider', () {
    late SyncSettingsProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = SyncSettingsProvider();
    });

    group('default values', () {
      test('has correct default values before initialization', () {
        expect(provider.syncEnabled, isFalse);
        expect(provider.wifiOnly, isTrue);
        expect(provider.progressSyncEnabled, isTrue);
        expect(provider.catalogSyncEnabled, isTrue);
        expect(provider.feedSyncEnabled, isTrue);
        expect(provider.syncIntervalMinutes, equals(30));
        expect(provider.lastSyncAt, isNull);
        expect(provider.isInitialized, isFalse);
      });

      test('syncInterval returns Duration', () {
        expect(provider.syncInterval, equals(const Duration(minutes: 30)));
      });
    });

    group('initialization', () {
      test('initializes successfully', () async {
        await provider.initialize();

        expect(provider.isInitialized, isTrue);
      });

      test('loads saved settings from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'sync_enabled': true,
          'sync_wifi_only': false,
          'sync_progress_enabled': false,
          'sync_catalog_enabled': false,
          'sync_feed_enabled': false,
          'sync_interval_minutes': 60,
          'last_sync_at': DateTime(2024, 6, 15, 10, 30).millisecondsSinceEpoch,
        });

        final loadedProvider = SyncSettingsProvider();
        await loadedProvider.initialize();

        expect(loadedProvider.syncEnabled, isTrue);
        expect(loadedProvider.wifiOnly, isFalse);
        expect(loadedProvider.progressSyncEnabled, isFalse);
        expect(loadedProvider.catalogSyncEnabled, isFalse);
        expect(loadedProvider.feedSyncEnabled, isFalse);
        expect(loadedProvider.syncIntervalMinutes, equals(60));
        expect(loadedProvider.lastSyncAt, isNotNull);
        expect(loadedProvider.lastSyncAt?.year, equals(2024));
      });

      test('only initializes once', () async {
        await provider.initialize();
        await provider.initialize();

        expect(provider.isInitialized, isTrue);
      });

      test('ignores invalid interval values from storage', () async {
        SharedPreferences.setMockInitialValues({
          'sync_interval_minutes': 999, // Invalid value
        });

        final loadedProvider = SyncSettingsProvider();
        await loadedProvider.initialize();

        // Should use default value
        expect(loadedProvider.syncIntervalMinutes, equals(30));
      });
    });

    group('setSyncEnabled', () {
      test('updates syncEnabled and persists', () async {
        await provider.initialize();

        await provider.setSyncEnabled(true);

        expect(provider.syncEnabled, isTrue);

        // Verify persistence
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('sync_enabled'), isTrue);
      });

      test('does not update when value is same', () async {
        await provider.initialize();
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.setSyncEnabled(false); // Already false

        expect(notifyCount, equals(0));
      });

      test('notifies listeners on change', () async {
        await provider.initialize();
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.setSyncEnabled(true);

        expect(notified, isTrue);
      });
    });

    group('setWifiOnly', () {
      test('updates wifiOnly and persists', () async {
        await provider.initialize();

        await provider.setWifiOnly(false);

        expect(provider.wifiOnly, isFalse);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('sync_wifi_only'), isFalse);
      });

      test('does not update when value is same', () async {
        await provider.initialize();
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.setWifiOnly(true); // Already true

        expect(notifyCount, equals(0));
      });
    });

    group('setProgressSyncEnabled', () {
      test('updates progressSyncEnabled and persists', () async {
        await provider.initialize();

        await provider.setProgressSyncEnabled(false);

        expect(provider.progressSyncEnabled, isFalse);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('sync_progress_enabled'), isFalse);
      });
    });

    group('setCatalogSyncEnabled', () {
      test('updates catalogSyncEnabled and persists', () async {
        await provider.initialize();

        await provider.setCatalogSyncEnabled(false);

        expect(provider.catalogSyncEnabled, isFalse);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('sync_catalog_enabled'), isFalse);
      });
    });

    group('setFeedSyncEnabled', () {
      test('updates feedSyncEnabled and persists', () async {
        await provider.initialize();

        await provider.setFeedSyncEnabled(false);

        expect(provider.feedSyncEnabled, isFalse);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('sync_feed_enabled'), isFalse);
      });
    });

    group('setSyncInterval', () {
      test(
        'updates syncIntervalMinutes and persists for valid value',
        () async {
          await provider.initialize();

          await provider.setSyncInterval(60);

          expect(provider.syncIntervalMinutes, equals(60));
          expect(provider.syncInterval, equals(const Duration(minutes: 60)));

          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getInt('sync_interval_minutes'), equals(60));
        },
      );

      test('rejects invalid interval values', () async {
        await provider.initialize();

        await provider.setSyncInterval(999); // Invalid

        // Should remain at default
        expect(provider.syncIntervalMinutes, equals(30));
      });

      test('accepts all valid interval options', () async {
        await provider.initialize();

        for (final interval in SyncSettingsProvider.intervalOptions) {
          await provider.setSyncInterval(interval);
          expect(provider.syncIntervalMinutes, equals(interval));
        }
      });

      test('does not update when value is same', () async {
        await provider.initialize();
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.setSyncInterval(30); // Already 30

        expect(notifyCount, equals(0));
      });
    });

    group('updateLastSyncTime', () {
      test('sets lastSyncAt to now and persists', () async {
        await provider.initialize();
        final beforeUpdate = DateTime.now();

        await provider.updateLastSyncTime();

        expect(provider.lastSyncAt, isNotNull);
        expect(
          provider.lastSyncAt!.isAfter(beforeUpdate) ||
              provider.lastSyncAt!.isAtSameMomentAs(beforeUpdate),
          isTrue,
        );

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('last_sync_at'), isNotNull);
      });

      test('notifies listeners', () async {
        await provider.initialize();
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.updateLastSyncTime();

        expect(notified, isTrue);
      });
    });

    group('clearLastSyncTime', () {
      test('clears lastSyncAt and removes from storage', () async {
        await provider.initialize();
        await provider.updateLastSyncTime();

        await provider.clearLastSyncTime();

        expect(provider.lastSyncAt, isNull);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('last_sync_at'), isNull);
      });
    });

    group('isDueForSync', () {
      test('returns true when lastSyncAt is null', () async {
        await provider.initialize();

        expect(provider.isDueForSync, isTrue);
      });

      test('returns true when interval has passed', () async {
        // Set last sync to over 30 minutes ago
        final oldSyncTime = DateTime.now()
            .subtract(const Duration(minutes: 31))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'last_sync_at': oldSyncTime,
          'sync_interval_minutes': 30,
        });

        final testProvider = SyncSettingsProvider();
        await testProvider.initialize();

        expect(testProvider.isDueForSync, isTrue);
      });

      test('returns false when within interval', () async {
        // Set last sync to 10 minutes ago
        final recentSyncTime = DateTime.now()
            .subtract(const Duration(minutes: 10))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'last_sync_at': recentSyncTime,
          'sync_interval_minutes': 30,
        });

        final testProvider = SyncSettingsProvider();
        await testProvider.initialize();

        expect(testProvider.isDueForSync, isFalse);
      });
    });

    group('timeUntilNextSync', () {
      test('returns zero when lastSyncAt is null', () async {
        await provider.initialize();

        expect(provider.timeUntilNextSync, equals(Duration.zero));
      });

      test('returns zero when overdue', () async {
        final oldSyncTime = DateTime.now()
            .subtract(const Duration(minutes: 60))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'last_sync_at': oldSyncTime,
          'sync_interval_minutes': 30,
        });

        final testProvider = SyncSettingsProvider();
        await testProvider.initialize();

        expect(testProvider.timeUntilNextSync, equals(Duration.zero));
      });

      test('returns remaining time when within interval', () async {
        final recentSyncTime = DateTime.now()
            .subtract(const Duration(minutes: 10))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'last_sync_at': recentSyncTime,
          'sync_interval_minutes': 30,
        });

        final testProvider = SyncSettingsProvider();
        await testProvider.initialize();

        final remaining = testProvider.timeUntilNextSync;
        // Should be approximately 20 minutes
        expect(remaining.inMinutes, greaterThanOrEqualTo(19));
        expect(remaining.inMinutes, lessThanOrEqualTo(21));
      });
    });

    group('lastSyncDescription', () {
      test('returns "Never" when lastSyncAt is null', () async {
        await provider.initialize();

        expect(provider.lastSyncDescription, equals('Never'));
      });

      test('returns "Just now" for very recent sync', () async {
        await provider.initialize();
        await provider.updateLastSyncTime();

        expect(provider.lastSyncDescription, equals('Just now'));
      });

      test('returns minutes ago for recent sync', () async {
        final fiveMinutesAgo = DateTime.now()
            .subtract(const Duration(minutes: 5))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'last_sync_at': fiveMinutesAgo,
        });

        final testProvider = SyncSettingsProvider();
        await testProvider.initialize();

        expect(testProvider.lastSyncDescription, equals('5 minutes ago'));
      });

      test('returns singular minute', () async {
        final oneMinuteAgo = DateTime.now()
            .subtract(const Duration(minutes: 1, seconds: 30))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({'last_sync_at': oneMinuteAgo});

        final testProvider = SyncSettingsProvider();
        await testProvider.initialize();

        expect(testProvider.lastSyncDescription, equals('1 minute ago'));
      });

      test('returns hours ago', () async {
        final twoHoursAgo = DateTime.now()
            .subtract(const Duration(hours: 2))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({'last_sync_at': twoHoursAgo});

        final testProvider = SyncSettingsProvider();
        await testProvider.initialize();

        expect(testProvider.lastSyncDescription, equals('2 hours ago'));
      });

      test('returns singular hour', () async {
        final oneHourAgo = DateTime.now()
            .subtract(const Duration(hours: 1, minutes: 30))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({'last_sync_at': oneHourAgo});

        final testProvider = SyncSettingsProvider();
        await testProvider.initialize();

        expect(testProvider.lastSyncDescription, equals('1 hour ago'));
      });

      test('returns days ago', () async {
        final twoDaysAgo = DateTime.now()
            .subtract(const Duration(days: 2))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({'last_sync_at': twoDaysAgo});

        final testProvider = SyncSettingsProvider();
        await testProvider.initialize();

        expect(testProvider.lastSyncDescription, equals('2 days ago'));
      });

      test('returns singular day', () async {
        final oneDayAgo = DateTime.now()
            .subtract(const Duration(days: 1, hours: 12))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({'last_sync_at': oneDayAgo});

        final testProvider = SyncSettingsProvider();
        await testProvider.initialize();

        expect(testProvider.lastSyncDescription, equals('1 day ago'));
      });
    });

    group('resetToDefaults', () {
      test('resets all values to defaults', () async {
        await provider.initialize();

        // Change all values
        await provider.setSyncEnabled(true);
        await provider.setWifiOnly(false);
        await provider.setProgressSyncEnabled(false);
        await provider.setCatalogSyncEnabled(false);
        await provider.setFeedSyncEnabled(false);
        await provider.setSyncInterval(120);
        await provider.updateLastSyncTime();

        // Reset
        await provider.resetToDefaults();

        expect(provider.syncEnabled, isFalse);
        expect(provider.wifiOnly, isTrue);
        expect(provider.progressSyncEnabled, isTrue);
        expect(provider.catalogSyncEnabled, isTrue);
        expect(provider.feedSyncEnabled, isTrue);
        expect(provider.syncIntervalMinutes, equals(30));
        expect(provider.lastSyncAt, isNull);
      });

      test('removes all values from SharedPreferences', () async {
        await provider.initialize();
        await provider.setSyncEnabled(true);

        await provider.resetToDefaults();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('sync_enabled'), isNull);
        expect(prefs.getBool('sync_wifi_only'), isNull);
        expect(prefs.getBool('sync_progress_enabled'), isNull);
        expect(prefs.getBool('sync_catalog_enabled'), isNull);
        expect(prefs.getBool('sync_feed_enabled'), isNull);
        expect(prefs.getInt('sync_interval_minutes'), isNull);
        expect(prefs.getInt('last_sync_at'), isNull);
      });

      test('notifies listeners', () async {
        await provider.initialize();
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.resetToDefaults();

        expect(notified, isTrue);
      });
    });

    group('static constants', () {
      test('intervalOptions contains expected values', () {
        expect(
          SyncSettingsProvider.intervalOptions,
          equals([15, 30, 60, 120, 360, 720]),
        );
      });

      test('intervalLabels has entries for all options', () {
        for (final option in SyncSettingsProvider.intervalOptions) {
          expect(
            SyncSettingsProvider.intervalLabels.containsKey(option),
            isTrue,
          );
        }
      });

      test('intervalLabels has readable values', () {
        expect(SyncSettingsProvider.intervalLabels[15], equals('15 minutes'));
        expect(SyncSettingsProvider.intervalLabels[60], equals('1 hour'));
        expect(SyncSettingsProvider.intervalLabels[720], equals('12 hours'));
      });
    });
  });
}
