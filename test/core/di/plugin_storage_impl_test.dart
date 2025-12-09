import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/core/di/plugin_storage_impl.dart';
import 'package:readwhere/data/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'plugin_storage_impl_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage, DatabaseHelper])
void main() {
  late PluginStorageImpl storage;
  late SharedPreferences prefs;
  late MockFlutterSecureStorage secureStorage;
  late MockDatabaseHelper dbHelper;
  late Database testDb;

  const testPluginId = 'com.test.plugin';

  setUpAll(() {
    // Initialize FFI for SQLite in tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Set up SharedPreferences mock values
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    secureStorage = MockFlutterSecureStorage();
    dbHelper = MockDatabaseHelper();

    // Create in-memory test database
    testDb = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE plugin_cache (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plugin_id TEXT NOT NULL,
            cache_key TEXT NOT NULL,
            data TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            expires_at INTEGER,
            UNIQUE(plugin_id, cache_key)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_plugin_cache_lookup ON plugin_cache(plugin_id, cache_key)',
        );
        await db.execute(
          'CREATE INDEX idx_plugin_cache_expiry ON plugin_cache(expires_at)',
        );
      },
    );

    when(dbHelper.database).thenAnswer((_) async => testDb);

    storage = PluginStorageImpl(
      pluginId: testPluginId,
      prefs: prefs,
      secureStorage: secureStorage,
      dbHelper: dbHelper,
    );
  });

  tearDown(() async {
    await testDb.close();
  });

  group('PluginStorageImpl', () {
    group('Settings', () {
      test('stores and retrieves string setting', () async {
        await storage.setSetting<String>('theme', 'dark');

        final result = await storage.getSetting<String>('theme');
        expect(result, equals('dark'));
      });

      test('stores and retrieves int setting', () async {
        await storage.setSetting<int>('pageSize', 50);

        final result = await storage.getSetting<int>('pageSize');
        expect(result, equals(50));
      });

      test('stores and retrieves double setting', () async {
        await storage.setSetting<double>('fontSize', 14.5);

        final result = await storage.getSetting<double>('fontSize');
        expect(result, equals(14.5));
      });

      test('stores and retrieves bool setting', () async {
        await storage.setSetting<bool>('syncEnabled', true);

        final result = await storage.getSetting<bool>('syncEnabled');
        expect(result, isTrue);
      });

      test('stores and retrieves List<String> setting', () async {
        await storage.setSetting<List<String>>('recentBooks', [
          'book1',
          'book2',
        ]);

        final result = await storage.getSetting<List<String>>('recentBooks');
        expect(result, equals(['book1', 'book2']));
      });

      test('returns null for non-existent setting', () async {
        final result = await storage.getSetting<String>('nonExistent');
        expect(result, isNull);
      });

      test('removes setting', () async {
        await storage.setSetting<String>('toRemove', 'value');
        await storage.removeSetting('toRemove');

        final result = await storage.getSetting<String>('toRemove');
        expect(result, isNull);
      });

      test('getAllSettings returns all plugin settings', () async {
        await storage.setSetting<String>('key1', 'value1');
        await storage.setSetting<int>('key2', 42);

        final all = await storage.getAllSettings();
        expect(all.length, equals(2));
        expect(all['key1'], equals('value1'));
        expect(all['key2'], equals(42));
      });

      test('clearSettings removes all plugin settings', () async {
        await storage.setSetting<String>('key1', 'value1');
        await storage.setSetting<int>('key2', 42);

        await storage.clearSettings();

        final all = await storage.getAllSettings();
        expect(all, isEmpty);
      });

      test('settings are namespaced to plugin', () async {
        await storage.setSetting<String>('key', 'value');

        // Check the actual key in SharedPreferences
        final keys = prefs.getKeys();
        expect(keys.first, contains(testPluginId));
        expect(keys.first, contains('setting:key'));
      });
    });

    group('Credentials', () {
      test('saves and retrieves plugin-level credential', () async {
        when(
          secureStorage.write(key: anyNamed('key'), value: anyNamed('value')),
        ).thenAnswer((_) async {});
        when(
          secureStorage.read(key: anyNamed('key')),
        ).thenAnswer((_) async => 'secret');

        await storage.saveCredential(key: 'apiKey', value: 'secret');

        final result = await storage.getCredential(key: 'apiKey');
        expect(result, equals('secret'));

        verify(
          secureStorage.write(
            key: 'plugin:$testPluginId:cred:apiKey',
            value: 'secret',
          ),
        ).called(1);
      });

      test('saves and retrieves catalog-scoped credential', () async {
        const catalogId = 'my-catalog';
        when(
          secureStorage.write(key: anyNamed('key'), value: anyNamed('value')),
        ).thenAnswer((_) async {});
        when(
          secureStorage.read(key: anyNamed('key')),
        ).thenAnswer((_) async => 'catalog-secret');

        await storage.saveCredential(
          catalogId: catalogId,
          key: 'accessToken',
          value: 'catalog-secret',
        );

        final result = await storage.getCredential(
          catalogId: catalogId,
          key: 'accessToken',
        );
        expect(result, equals('catalog-secret'));

        verify(
          secureStorage.write(
            key: 'plugin:$testPluginId:cred:$catalogId:accessToken',
            value: 'catalog-secret',
          ),
        ).called(1);
      });

      test('deletes credential', () async {
        when(
          secureStorage.delete(key: anyNamed('key')),
        ).thenAnswer((_) async {});

        await storage.deleteCredential(key: 'toDelete');

        verify(
          secureStorage.delete(key: 'plugin:$testPluginId:cred:toDelete'),
        ).called(1);
      });

      test('deletes all credentials for catalog', () async {
        when(secureStorage.readAll()).thenAnswer(
          (_) async => {
            'plugin:$testPluginId:cred:catalog1:token': 'value1',
            'plugin:$testPluginId:cred:catalog1:refresh': 'value2',
            'plugin:$testPluginId:cred:catalog2:token': 'value3',
          },
        );
        when(
          secureStorage.delete(key: anyNamed('key')),
        ).thenAnswer((_) async {});

        await storage.deleteCredentialsForCatalog('catalog1');

        verify(
          secureStorage.delete(key: 'plugin:$testPluginId:cred:catalog1:token'),
        ).called(1);
        verify(
          secureStorage.delete(
            key: 'plugin:$testPluginId:cred:catalog1:refresh',
          ),
        ).called(1);
        verifyNever(
          secureStorage.delete(key: 'plugin:$testPluginId:cred:catalog2:token'),
        );
      });

      test('hasCredentials returns true when credentials exist', () async {
        when(secureStorage.readAll()).thenAnswer(
          (_) async => {'plugin:$testPluginId:cred:catalog1:token': 'value1'},
        );

        final result = await storage.hasCredentials('catalog1');
        expect(result, isTrue);
      });

      test('hasCredentials returns false when no credentials exist', () async {
        when(secureStorage.readAll()).thenAnswer((_) async => {});

        final result = await storage.hasCredentials('catalog1');
        expect(result, isFalse);
      });
    });

    group('Cache', () {
      test('caches and retrieves data', () async {
        final testData = {'key': 'value', 'count': 42};

        await storage.cacheData(key: 'test-cache', data: testData);

        final result = await storage.getCachedData<Map<String, dynamic>>(
          'test-cache',
        );
        expect(result, equals(testData));
      });

      test('hasCachedData returns true for existing entry', () async {
        await storage.cacheData(key: 'exists', data: 'data');

        final result = await storage.hasCachedData('exists');
        expect(result, isTrue);
      });

      test('hasCachedData returns false for non-existing entry', () async {
        final result = await storage.hasCachedData('not-exists');
        expect(result, isFalse);
      });

      test('cache expires after TTL', () async {
        await storage.cacheData(
          key: 'expires',
          data: 'data',
          ttl: const Duration(milliseconds: 1),
        );

        // Wait for TTL to expire
        await Future.delayed(const Duration(milliseconds: 10));

        final result = await storage.getCachedData<String>('expires');
        expect(result, isNull);
      });

      test('invalidateCache removes entry', () async {
        await storage.cacheData(key: 'to-remove', data: 'data');

        await storage.invalidateCache('to-remove');

        final result = await storage.hasCachedData('to-remove');
        expect(result, isFalse);
      });

      test('invalidateCachePattern removes matching entries', () async {
        await storage.cacheData(key: 'feed:root', data: 'data1');
        await storage.cacheData(key: 'feed:page:1', data: 'data2');
        await storage.cacheData(key: 'other:key', data: 'data3');

        await storage.invalidateCachePattern('feed:*');

        expect(await storage.hasCachedData('feed:root'), isFalse);
        expect(await storage.hasCachedData('feed:page:1'), isFalse);
        expect(await storage.hasCachedData('other:key'), isTrue);
      });

      test('clearCache removes all entries for plugin', () async {
        await storage.cacheData(key: 'key1', data: 'data1');
        await storage.cacheData(key: 'key2', data: 'data2');

        await storage.clearCache();

        expect(await storage.hasCachedData('key1'), isFalse);
        expect(await storage.hasCachedData('key2'), isFalse);
      });

      test('getCacheStats returns correct statistics', () async {
        await storage.cacheData(key: 'key1', data: 'data1');
        await storage.cacheData(key: 'key2', data: 'data2');

        final stats = await storage.getCacheStats();
        expect(stats.entryCount, equals(2));
        expect(stats.totalSizeBytes, greaterThan(0));
        expect(stats.isEmpty, isFalse);
      });

      test('cache is isolated per plugin', () async {
        final otherStorage = PluginStorageImpl(
          pluginId: 'other.plugin',
          prefs: prefs,
          secureStorage: secureStorage,
          dbHelper: dbHelper,
        );

        await storage.cacheData(key: 'shared-key', data: 'plugin1-data');
        await otherStorage.cacheData(key: 'shared-key', data: 'plugin2-data');

        final result1 = await storage.getCachedData<String>('shared-key');
        final result2 = await otherStorage.getCachedData<String>('shared-key');

        expect(result1, equals('plugin1-data'));
        expect(result2, equals('plugin2-data'));
      });
    });
  });

  group('PluginStorageFactoryImpl', () {
    test('creates storage for plugin', () async {
      final factory = PluginStorageFactoryImpl(
        prefs: prefs,
        secureStorage: secureStorage,
        dbHelper: dbHelper,
      );

      final result = await factory.create('test.plugin');

      expect(result, isA<PluginStorageImpl>());
      expect(result.pluginId, equals('test.plugin'));
    });
  });
}
