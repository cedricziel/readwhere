import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

void main() {
  late UnifiedPluginRegistry registry;
  late MockPluginStorageFactory storageFactory;
  late MockPluginContextFactory contextFactory;

  setUp(() {
    // Reset the singleton for each test
    registry = UnifiedPluginRegistry();
    registry.clear();
    storageFactory = MockPluginStorageFactory();
    contextFactory = MockPluginContextFactory();
  });

  group('UnifiedPluginRegistry', () {
    test('is a singleton', () {
      final registry1 = UnifiedPluginRegistry();
      final registry2 = UnifiedPluginRegistry();
      expect(identical(registry1, registry2), isTrue);
    });

    test('starts empty', () {
      expect(registry.isEmpty, isTrue);
      expect(registry.count, equals(0));
    });

    group('registration', () {
      test('can register a plugin', () async {
        final plugin = MockReaderPlugin();

        await registry.register(
          plugin,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );

        expect(registry.count, equals(1));
        expect(registry.isRegistered(plugin.id), isTrue);
      });

      test('throws when registering duplicate ID', () async {
        final plugin1 = MockReaderPlugin();
        final plugin2 = MockReaderPlugin(); // Same ID

        await registry.register(
          plugin1,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );

        expect(
          () => registry.register(
            plugin2,
            storageFactory: storageFactory,
            contextFactory: contextFactory,
          ),
          throwsA(isA<PluginAlreadyRegisteredException>()),
        );
      });

      test('can unregister a plugin', () async {
        final plugin = MockReaderPlugin();

        await registry.register(
          plugin,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );

        final removed = await registry.unregister(plugin.id);

        expect(removed, isTrue);
        expect(registry.isRegistered(plugin.id), isFalse);
        expect(plugin.disposed, isTrue);
      });

      test('unregister returns false for unknown plugin', () async {
        final removed = await registry.unregister('unknown');
        expect(removed, isFalse);
      });

      test('clear removes all plugins', () async {
        final plugin1 = MockReaderPlugin(id: 'plugin1');
        final plugin2 = MockReaderPlugin(id: 'plugin2');

        await registry.register(
          plugin1,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );
        await registry.register(
          plugin2,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );

        await registry.clear();

        expect(registry.isEmpty, isTrue);
        expect(plugin1.disposed, isTrue);
        expect(plugin2.disposed, isTrue);
      });
    });

    group('lookup by ID', () {
      test('get returns plugin by ID', () async {
        final plugin = MockReaderPlugin();

        await registry.register(
          plugin,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );

        expect(registry.get(plugin.id), equals(plugin));
      });

      test('get returns null for unknown ID', () {
        expect(registry.get('unknown'), isNull);
      });

      test('getOrThrow throws for unknown ID', () {
        expect(
          () => registry.getOrThrow('unknown'),
          throwsA(isA<PluginNotFoundException>()),
        );
      });

      test('getAs casts to correct type', () async {
        final plugin = MockReaderPlugin();

        await registry.register(
          plugin,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );

        final result = registry.getAs<MockReaderPlugin>(plugin.id);
        expect(result, equals(plugin));
      });

      test('getAs returns null for wrong type', () async {
        final plugin = MockReaderPlugin();

        await registry.register(
          plugin,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );

        final result = registry.getAs<MockCatalogPlugin>(plugin.id);
        expect(result, isNull);
      });
    });

    group('lookup by capability', () {
      test('withCapability returns matching plugins', () async {
        final readerPlugin = MockReaderPlugin();
        final catalogPlugin = MockCatalogPlugin();

        await registry.register(
          readerPlugin,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );
        await registry.register(
          catalogPlugin,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );

        final readers = registry.withCapability<ReaderCapability>().toList();
        expect(readers.length, equals(1));
        expect(readers.first, equals(readerPlugin));

        final catalogs = registry
            .withCapability<CatalogBrowsingCapability>()
            .toList();
        expect(catalogs.length, equals(1));
        expect(catalogs.first, equals(catalogPlugin));
      });

      test('firstWithCapability returns first match', () async {
        final plugin = MockReaderPlugin();

        await registry.register(
          plugin,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );

        expect(
          registry.firstWithCapability<ReaderCapability>(),
          equals(plugin),
        );
        expect(
          registry.firstWithCapability<CatalogBrowsingCapability>(),
          isNull,
        );
      });

      test('hasCapability checks for capability presence', () async {
        final plugin = MockReaderPlugin();

        await registry.register(
          plugin,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );

        expect(registry.hasCapability<ReaderCapability>(), isTrue);
        expect(registry.hasCapability<CatalogBrowsingCapability>(), isFalse);
      });

      test('countWithCapability counts matching plugins', () async {
        final plugin1 = MockReaderPlugin(id: 'reader1');
        final plugin2 = MockReaderPlugin(id: 'reader2');

        await registry.register(
          plugin1,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );
        await registry.register(
          plugin2,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );

        expect(registry.countWithCapability<ReaderCapability>(), equals(2));
        expect(
          registry.countWithCapability<CatalogBrowsingCapability>(),
          equals(0),
        );
      });
    });

    group('provider access', () {
      test('getProvidersFor returns plugin providers', () async {
        final plugin = MockPluginWithProvider();

        await registry.register(
          plugin,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );

        final providers = registry.getProvidersFor(plugin.id);
        expect(providers.length, equals(1));
      });

      test('getProvider returns specific provider type', () async {
        final plugin = MockPluginWithProvider();

        await registry.register(
          plugin,
          storageFactory: storageFactory,
          contextFactory: contextFactory,
        );

        final provider = registry.getProvider<MockChangeNotifier>(plugin.id);
        expect(provider, isNotNull);
      });
    });

    test('debugSummary returns formatted string', () async {
      final plugin = MockReaderPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      final summary = registry.debugSummary();
      expect(summary, contains('UnifiedPluginRegistry'));
      expect(summary, contains(plugin.id));
      expect(summary, contains(plugin.name));
    });
  });
}

// ===== Mock Classes =====

class MockReaderPlugin extends PluginBase with ReaderCapability {
  @override
  final String id;

  @override
  final String name = 'Mock EPUB Reader';

  @override
  final String description = 'Test reader plugin';

  @override
  final String version = '1.0.0';

  @override
  final List<String> supportedExtensions = ['epub'];

  @override
  final List<String> supportedMimeTypes = ['application/epub+zip'];

  bool initialized = false;
  bool disposed = false;

  MockReaderPlugin({this.id = 'com.test.epub'});

  @override
  Future<void> initialize(PluginContext context) async {
    initialized = true;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  Future<bool> canHandleFile(String filePath) async {
    return filePath.endsWith('.epub');
  }

  @override
  Future<BookMetadata> parseMetadata(String filePath) async {
    return BookMetadata(title: 'Test Book', author: 'Test Author');
  }

  @override
  Future<ReaderController> openBook(String filePath) async {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List?> extractCover(String filePath) async {
    return null;
  }
}

class MockCatalogPlugin extends PluginBase with CatalogBrowsingCapability {
  @override
  final String id = 'com.test.catalog';

  @override
  final String name = 'Mock Catalog';

  @override
  final String description = 'Test catalog plugin';

  @override
  final String version = '1.0.0';

  @override
  final Set<PluginCatalogFeature> catalogFeatures = {
    PluginCatalogFeature.browse,
    PluginCatalogFeature.search,
  };

  bool initialized = false;
  bool disposed = false;

  @override
  Future<void> initialize(PluginContext context) async {
    initialized = true;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  bool canHandleCatalog(CatalogInfo catalog) {
    return catalog.providerType == 'mock';
  }

  @override
  Future<ValidationResult> validate(CatalogInfo catalog) async {
    return ValidationResult.success(serverName: 'Mock Server');
  }

  @override
  Future<BrowseResult> browse(
    CatalogInfo catalog, {
    String? path,
    int? page,
  }) async {
    return BrowseResult(entries: []);
  }

  @override
  Future<void> download(
    CatalogInfo catalog,
    CatalogFile file,
    String localPath, {
    PluginProgressCallback? onProgress,
  }) async {}
}

class MockPluginWithProvider extends PluginBase {
  @override
  final String id = 'com.test.provider';

  @override
  final String name = 'Mock Provider Plugin';

  @override
  final String description = 'Test plugin with provider';

  @override
  final String version = '1.0.0';

  @override
  Future<void> initialize(PluginContext context) async {}

  @override
  Future<void> dispose() async {}

  @override
  List<ChangeNotifier> createProviders(PluginContext context) {
    return [MockChangeNotifier()];
  }
}

class MockChangeNotifier extends ChangeNotifier {}

class MockPluginStorageFactory implements PluginStorageFactory {
  @override
  Future<PluginStorage> create(String pluginId) async {
    return InMemoryPluginStorage(pluginId);
  }
}

class MockPluginContextFactory implements PluginContextFactory {
  @override
  Future<PluginContext> create(String pluginId, PluginStorage storage) async {
    return PluginContext(
      storage: storage,
      httpClient: http.Client(),
      logger: Logger(pluginId),
      appConfig: const PluginAppConfig(
        appVersion: '1.0.0',
        platform: 'test',
        locale: 'en_US',
        isDarkMode: false,
      ),
      pluginDataDirectory: Directory.systemTemp,
      downloadDirectory: Directory.systemTemp,
    );
  }
}
