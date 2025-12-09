import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:readwhere_cbr_plugin/readwhere_cbr_plugin.dart';
import 'package:readwhere_cbz_plugin/readwhere_cbz_plugin.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

/// Integration tests verifying CBZ and CBR plugins work with UnifiedPluginRegistry.
///
/// These tests ensure that:
/// 1. Both plugins can be registered in the unified registry
/// 2. Plugins can be looked up by ID
/// 3. Plugins can be looked up by ReaderCapability
/// 4. Plugins can be found by MIME type
/// 5. Multiple reader plugins coexist correctly
void main() {
  late UnifiedPluginRegistry registry;
  late MockPluginStorageFactory storageFactory;
  late MockPluginContextFactory contextFactory;

  setUp(() {
    registry = UnifiedPluginRegistry();
    registry.clear();
    storageFactory = MockPluginStorageFactory();
    contextFactory = MockPluginContextFactory();
  });

  tearDown(() async {
    await registry.clear();
  });

  group('CbzReaderPlugin integration with UnifiedPluginRegistry', () {
    test('registers successfully', () async {
      final plugin = CbzReaderPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      expect(registry.isRegistered('com.readwhere.cbz'), isTrue);
      expect(registry.count, equals(1));
    });

    test('can be looked up by ID', () async {
      final plugin = CbzReaderPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      final found = registry.get('com.readwhere.cbz');
      expect(found, isNotNull);
      expect(found, equals(plugin));
      expect(found!.name, equals('CBZ Reader'));
      expect(found.version, equals('1.0.0'));
    });

    test('can be looked up by ReaderCapability', () async {
      final plugin = CbzReaderPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      final readers = registry.withCapability<ReaderCapability>().toList();
      expect(readers.length, equals(1));
      expect(readers.first, equals(plugin));
    });

    test('can be found for CBZ MIME types via forMimeType', () async {
      final plugin = CbzReaderPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      final result = registry.forMimeType<ReaderCapability>(
        'application/vnd.comicbook+zip',
      );
      expect(result, isNotNull);
      expect(result, equals(plugin));

      final result2 = registry.forMimeType<ReaderCapability>(
        'application/x-cbz',
      );
      expect(result2, isNotNull);
      expect(result2, equals(plugin));
    });

    test('has correct metadata', () {
      final plugin = CbzReaderPlugin();

      expect(plugin.id, equals('com.readwhere.cbz'));
      expect(plugin.name, equals('CBZ Reader'));
      expect(
        plugin.description,
        equals('Supports CBZ (Comic Book ZIP) format comics'),
      );
      expect(plugin.version, equals('1.0.0'));
      expect(plugin.supportedExtensions, contains('cbz'));
      expect(plugin.supportedMimeTypes, contains('application/x-cbz'));
      expect(plugin.capabilityNames, contains('ReaderCapability'));
    });
  });

  group('CbrReaderPlugin integration with UnifiedPluginRegistry', () {
    test('registers successfully', () async {
      final plugin = CbrReaderPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      expect(registry.isRegistered('com.readwhere.cbr'), isTrue);
      expect(registry.count, equals(1));
    });

    test('can be looked up by ID', () async {
      final plugin = CbrReaderPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      final found = registry.get('com.readwhere.cbr');
      expect(found, isNotNull);
      expect(found, equals(plugin));
      expect(found!.name, equals('CBR Reader'));
      expect(found.version, equals('1.0.0'));
    });

    test('can be looked up by ReaderCapability', () async {
      final plugin = CbrReaderPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      final readers = registry.withCapability<ReaderCapability>().toList();
      expect(readers.length, equals(1));
      expect(readers.first, equals(plugin));
    });

    test('can be found for CBR MIME types via forMimeType', () async {
      final plugin = CbrReaderPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      final result = registry.forMimeType<ReaderCapability>(
        'application/vnd.comicbook-rar',
      );
      expect(result, isNotNull);
      expect(result, equals(plugin));

      final result2 = registry.forMimeType<ReaderCapability>(
        'application/x-cbr',
      );
      expect(result2, isNotNull);
      expect(result2, equals(plugin));
    });

    test('has correct metadata', () {
      final plugin = CbrReaderPlugin();

      expect(plugin.id, equals('com.readwhere.cbr'));
      expect(plugin.name, equals('CBR Reader'));
      expect(
        plugin.description,
        equals('Supports CBR (Comic Book RAR) format comics'),
      );
      expect(plugin.version, equals('1.0.0'));
      expect(plugin.supportedExtensions, contains('cbr'));
      // CBR also accepts cbz because some servers mislabel RAR files
      expect(plugin.supportedExtensions, contains('cbz'));
      expect(plugin.supportedMimeTypes, contains('application/x-cbr'));
      expect(plugin.capabilityNames, contains('ReaderCapability'));
    });
  });

  group('All reader plugins together', () {
    test('all three plugins coexist in registry', () async {
      final epubPlugin = MockEpubPlugin();
      final cbzPlugin = CbzReaderPlugin();
      final cbrPlugin = CbrReaderPlugin();

      await registry.register(
        epubPlugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );
      await registry.register(
        cbzPlugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );
      await registry.register(
        cbrPlugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      expect(registry.count, equals(3));
      expect(registry.countWithCapability<ReaderCapability>(), equals(3));
    });

    test('each plugin can be found by its MIME type', () async {
      final epubPlugin = MockEpubPlugin();
      final cbzPlugin = CbzReaderPlugin();
      final cbrPlugin = CbrReaderPlugin();

      await registry.register(
        epubPlugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );
      await registry.register(
        cbzPlugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );
      await registry.register(
        cbrPlugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      final epub = registry.forMimeType<ReaderCapability>(
        'application/epub+zip',
      );
      expect(epub, equals(epubPlugin));

      final cbz = registry.forMimeType<ReaderCapability>('application/x-cbz');
      expect(cbz, equals(cbzPlugin));

      final cbr = registry.forMimeType<ReaderCapability>('application/x-cbr');
      expect(cbr, equals(cbrPlugin));
    });

    test('withCapability returns all reader plugins', () async {
      final epubPlugin = MockEpubPlugin();
      final cbzPlugin = CbzReaderPlugin();
      final cbrPlugin = CbrReaderPlugin();

      await registry.register(
        epubPlugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );
      await registry.register(
        cbzPlugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );
      await registry.register(
        cbrPlugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      final readers = registry.withCapability<ReaderCapability>().toList();
      expect(readers.length, equals(3));
      expect(readers, contains(epubPlugin));
      expect(readers, contains(cbzPlugin));
      expect(readers, contains(cbrPlugin));
    });
  });
}

// ===== Mock Classes =====

class MockEpubPlugin extends PluginBase with ReaderCapability {
  @override
  String get id => 'com.readwhere.epub';

  @override
  String get name => 'EPUB Reader';

  @override
  String get description => 'Mock EPUB plugin for testing';

  @override
  String get version => '1.0.0';

  @override
  List<String> get supportedExtensions => ['epub', 'epub3'];

  @override
  List<String> get supportedMimeTypes => [
    'application/epub+zip',
    'application/epub',
  ];

  @override
  List<String> get capabilityNames => ['ReaderCapability'];

  @override
  Future<void> initialize(PluginContext context) async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> canHandleFile(String filePath) async {
    return filePath.toLowerCase().endsWith('.epub');
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
