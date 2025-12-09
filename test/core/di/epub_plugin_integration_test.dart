import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:readwhere_epub_plugin/readwhere_epub_plugin.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

/// Integration test verifying ReadwhereEpubPlugin works with UnifiedPluginRegistry.
///
/// This test ensures that:
/// 1. EPUB plugin can be registered in the unified registry
/// 2. Plugin can be looked up by ID
/// 3. Plugin can be looked up by ReaderCapability
/// 4. Plugin can be found for .epub files
/// 5. Plugin is properly initialized and disposed
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

  group('ReadwhereEpubPlugin integration with UnifiedPluginRegistry', () {
    test('registers successfully', () async {
      final plugin = ReadwhereEpubPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      expect(registry.isRegistered('com.readwhere.epub'), isTrue);
      expect(registry.count, equals(1));
    });

    test('can be looked up by ID', () async {
      final plugin = ReadwhereEpubPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      final found = registry.get('com.readwhere.epub');
      expect(found, isNotNull);
      expect(found, equals(plugin));
      expect(found!.name, equals('EPUB Reader'));
      expect(found.version, equals('1.0.0'));
    });

    test('can be looked up by ReaderCapability', () async {
      final plugin = ReadwhereEpubPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      final readers = registry.withCapability<ReaderCapability>().toList();
      expect(readers.length, equals(1));
      expect(readers.first, equals(plugin));
    });

    test('can be found for EPUB MIME types via forMimeType', () async {
      final plugin = ReadwhereEpubPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      // Test with EPUB MIME types
      final epubResult = registry.forMimeType<ReaderCapability>(
        'application/epub+zip',
      );
      expect(epubResult, isNotNull);
      expect(epubResult, equals(plugin));

      final epub2Result = registry.forMimeType<ReaderCapability>(
        'application/epub',
      );
      expect(epub2Result, isNotNull);
      expect(epub2Result, equals(plugin));

      // Should not match other MIME types
      final pdfResult = registry.forMimeType<ReaderCapability>(
        'application/pdf',
      );
      expect(pdfResult, isNull);
    });

    test('forFile requires actual file for validation', () async {
      // Note: forFile calls canHandleFile which validates the actual file
      // (checks existence, reads ZIP signature). For testing with real files,
      // use the sample_media package.
      final plugin = ReadwhereEpubPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      // Non-existent file should return null (file validation fails)
      final result = await registry.forFile<ReaderCapability>(
        'nonexistent.epub',
      );
      expect(result, isNull);
    });

    test('has correct capability names', () async {
      final plugin = ReadwhereEpubPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      expect(plugin.capabilityNames, contains('ReaderCapability'));
      expect(plugin.hasCapability<ReaderCapability>(), isTrue);
    });

    test('has correct supported extensions', () {
      final plugin = ReadwhereEpubPlugin();

      expect(plugin.supportedExtensions, contains('epub'));
      expect(plugin.supportedExtensions, contains('epub3'));
    });

    test('has correct supported MIME types', () {
      final plugin = ReadwhereEpubPlugin();

      expect(plugin.supportedMimeTypes, contains('application/epub+zip'));
      expect(plugin.supportedMimeTypes, contains('application/epub'));
    });

    test('plugin metadata is correct', () {
      final plugin = ReadwhereEpubPlugin();

      expect(plugin.id, equals('com.readwhere.epub'));
      expect(plugin.name, equals('EPUB Reader'));
      expect(
        plugin.description,
        equals('Supports EPUB 2.0 and EPUB 3.0 format books'),
      );
      expect(plugin.version, equals('1.0.0'));
    });

    test('is properly disposed when unregistered', () async {
      final plugin = ReadwhereEpubPlugin();

      await registry.register(
        plugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      // Unregistering should call dispose
      final removed = await registry.unregister('com.readwhere.epub');
      expect(removed, isTrue);
      expect(registry.isRegistered('com.readwhere.epub'), isFalse);
    });

    test('coexists with other reader plugins', () async {
      final epubPlugin = ReadwhereEpubPlugin();
      final mockReaderPlugin = MockReaderPlugin();

      await registry.register(
        epubPlugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );
      await registry.register(
        mockReaderPlugin,
        storageFactory: storageFactory,
        contextFactory: contextFactory,
      );

      expect(registry.count, equals(2));
      expect(registry.countWithCapability<ReaderCapability>(), equals(2));

      // Each plugin should be found for its respective MIME type
      final epubResult = registry.forMimeType<ReaderCapability>(
        'application/epub+zip',
      );
      expect(epubResult, equals(epubPlugin));

      final cbzResult = registry.forMimeType<ReaderCapability>(
        'application/x-cbz',
      );
      expect(cbzResult, equals(mockReaderPlugin));
    });
  });
}

// ===== Mock Classes =====

class MockReaderPlugin extends PluginBase with ReaderCapability {
  @override
  String get id => 'com.test.cbz';

  @override
  String get name => 'Mock CBZ Reader';

  @override
  String get description => 'Test reader plugin for CBZ files';

  @override
  String get version => '1.0.0';

  @override
  List<String> get supportedExtensions => ['cbz'];

  @override
  List<String> get supportedMimeTypes => ['application/x-cbz'];

  @override
  Future<void> initialize(PluginContext context) async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> canHandleFile(String filePath) async {
    return filePath.toLowerCase().endsWith('.cbz');
  }

  @override
  Future<BookMetadata> parseMetadata(String filePath) async {
    return BookMetadata(title: 'Test Comic', author: 'Test Author');
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
