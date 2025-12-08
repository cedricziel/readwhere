import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/domain/entities/book_metadata.dart';
import 'package:readwhere/plugins/plugin_registry.dart';
import 'package:readwhere/plugins/reader_controller.dart';
import 'package:readwhere/plugins/reader_plugin.dart';

/// Mock implementation of ReaderPlugin for testing
class MockReaderPlugin implements ReaderPlugin {
  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final List<String> supportedExtensions;
  @override
  final List<String> supportedMimeTypes;

  final bool Function(String)? canHandleFn;

  MockReaderPlugin({
    required this.id,
    this.name = 'Mock Plugin',
    this.description = 'A mock plugin for testing',
    this.supportedExtensions = const ['epub'],
    this.supportedMimeTypes = const ['application/epub+zip'],
    this.canHandleFn,
  });

  @override
  Future<bool> canHandle(String filePath) async {
    if (canHandleFn != null) {
      return canHandleFn!(filePath);
    }
    final ext = filePath.split('.').last.toLowerCase();
    return supportedExtensions.contains(ext);
  }

  @override
  Future<BookMetadata> parseMetadata(String filePath) async {
    return const BookMetadata(title: 'Mock Book', author: 'Mock Author');
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

void main() {
  group('PluginRegistry', () {
    late PluginRegistry registry;

    setUp(() {
      registry = PluginRegistry();
      registry.clear(); // Start fresh for each test
    });

    tearDown(() {
      registry.clear();
    });

    group('singleton', () {
      test('returns same instance', () {
        final registry1 = PluginRegistry();
        final registry2 = PluginRegistry();

        expect(identical(registry1, registry2), isTrue);
      });
    });

    group('register', () {
      test('adds plugin to registry', () {
        final plugin = MockReaderPlugin(id: 'test-plugin');

        registry.register(plugin);

        expect(registry.pluginCount, equals(1));
        expect(registry.getPluginById('test-plugin'), equals(plugin));
      });

      test('replaces plugin with same ID', () {
        final plugin1 = MockReaderPlugin(id: 'test-plugin', name: 'Plugin 1');
        final plugin2 = MockReaderPlugin(id: 'test-plugin', name: 'Plugin 2');

        registry.register(plugin1);
        registry.register(plugin2);

        expect(registry.pluginCount, equals(1));
        expect(registry.getPluginById('test-plugin')?.name, equals('Plugin 2'));
      });

      test('adds multiple plugins with different IDs', () {
        final plugin1 = MockReaderPlugin(id: 'plugin-1');
        final plugin2 = MockReaderPlugin(id: 'plugin-2');
        final plugin3 = MockReaderPlugin(id: 'plugin-3');

        registry.register(plugin1);
        registry.register(plugin2);
        registry.register(plugin3);

        expect(registry.pluginCount, equals(3));
      });
    });

    group('unregister', () {
      test('removes plugin and returns true', () {
        final plugin = MockReaderPlugin(id: 'test-plugin');
        registry.register(plugin);

        final result = registry.unregister('test-plugin');

        expect(result, isTrue);
        expect(registry.pluginCount, equals(0));
      });

      test('returns false when plugin not found', () {
        final result = registry.unregister('non-existent');

        expect(result, isFalse);
      });
    });

    group('clear', () {
      test('removes all plugins', () {
        registry.register(MockReaderPlugin(id: 'plugin-1'));
        registry.register(MockReaderPlugin(id: 'plugin-2'));
        registry.register(MockReaderPlugin(id: 'plugin-3'));

        registry.clear();

        expect(registry.pluginCount, equals(0));
      });
    });

    group('getPluginById', () {
      test('returns plugin when found', () {
        final plugin = MockReaderPlugin(id: 'test-plugin');
        registry.register(plugin);

        final result = registry.getPluginById('test-plugin');

        expect(result, equals(plugin));
      });

      test('returns null when not found', () {
        final result = registry.getPluginById('non-existent');

        expect(result, isNull);
      });
    });

    group('getPluginForFile', () {
      test('returns plugin that can handle file', () async {
        final epubPlugin = MockReaderPlugin(
          id: 'epub-plugin',
          supportedExtensions: ['epub'],
          canHandleFn: (path) => path.endsWith('.epub'),
        );
        registry.register(epubPlugin);

        final result = await registry.getPluginForFile('/path/to/book.epub');

        expect(result, equals(epubPlugin));
      });

      test('returns null when no plugin can handle file', () async {
        final epubPlugin = MockReaderPlugin(
          id: 'epub-plugin',
          supportedExtensions: ['epub'],
          canHandleFn: (path) => path.endsWith('.epub'),
        );
        registry.register(epubPlugin);

        final result = await registry.getPluginForFile('/path/to/book.pdf');

        expect(result, isNull);
      });

      test('returns first matching plugin', () async {
        final plugin1 = MockReaderPlugin(
          id: 'plugin-1',
          canHandleFn: (path) => path.endsWith('.epub'),
        );
        final plugin2 = MockReaderPlugin(
          id: 'plugin-2',
          canHandleFn: (path) => path.endsWith('.epub'),
        );
        registry.register(plugin1);
        registry.register(plugin2);

        final result = await registry.getPluginForFile('/path/to/book.epub');

        expect(result, equals(plugin1));
      });
    });

    group('getAllPlugins', () {
      test('returns empty list when no plugins registered', () {
        final result = registry.getAllPlugins();

        expect(result, isEmpty);
      });

      test('returns all registered plugins', () {
        final plugin1 = MockReaderPlugin(id: 'plugin-1');
        final plugin2 = MockReaderPlugin(id: 'plugin-2');
        registry.register(plugin1);
        registry.register(plugin2);

        final result = registry.getAllPlugins();

        expect(result, hasLength(2));
        expect(result, contains(plugin1));
        expect(result, contains(plugin2));
      });

      test('returns unmodifiable list', () {
        final plugin = MockReaderPlugin(id: 'test-plugin');
        registry.register(plugin);

        final result = registry.getAllPlugins();

        expect(
          () => result.add(MockReaderPlugin(id: 'another')),
          throwsUnsupportedError,
        );
      });
    });

    group('getSupportedExtensions', () {
      test('returns empty list when no plugins registered', () {
        final result = registry.getSupportedExtensions();

        expect(result, isEmpty);
      });

      test('returns deduplicated sorted extensions', () {
        final plugin1 = MockReaderPlugin(
          id: 'plugin-1',
          supportedExtensions: ['epub', 'mobi'],
        );
        final plugin2 = MockReaderPlugin(
          id: 'plugin-2',
          supportedExtensions: ['epub', 'pdf'],
        );
        registry.register(plugin1);
        registry.register(plugin2);

        final result = registry.getSupportedExtensions();

        expect(result, equals(['epub', 'mobi', 'pdf']));
      });
    });

    group('getSupportedMimeTypes', () {
      test('returns empty list when no plugins registered', () {
        final result = registry.getSupportedMimeTypes();

        expect(result, isEmpty);
      });

      test('returns deduplicated sorted mime types', () {
        final plugin1 = MockReaderPlugin(
          id: 'plugin-1',
          supportedMimeTypes: [
            'application/epub+zip',
            'application/x-mobipocket-ebook',
          ],
        );
        final plugin2 = MockReaderPlugin(
          id: 'plugin-2',
          supportedMimeTypes: ['application/epub+zip', 'application/pdf'],
        );
        registry.register(plugin1);
        registry.register(plugin2);

        final result = registry.getSupportedMimeTypes();

        expect(
          result,
          equals([
            'application/epub+zip',
            'application/pdf',
            'application/x-mobipocket-ebook',
          ]),
        );
      });
    });

    group('isExtensionSupported', () {
      test('returns true when extension is supported', () {
        final plugin = MockReaderPlugin(
          id: 'test-plugin',
          supportedExtensions: ['epub', 'mobi'],
        );
        registry.register(plugin);

        expect(registry.isExtensionSupported('epub'), isTrue);
        expect(registry.isExtensionSupported('mobi'), isTrue);
      });

      test('returns false when extension is not supported', () {
        final plugin = MockReaderPlugin(
          id: 'test-plugin',
          supportedExtensions: ['epub'],
        );
        registry.register(plugin);

        expect(registry.isExtensionSupported('pdf'), isFalse);
      });

      test('handles extension with dot prefix', () {
        final plugin = MockReaderPlugin(
          id: 'test-plugin',
          supportedExtensions: ['epub'],
        );
        registry.register(plugin);

        expect(registry.isExtensionSupported('.epub'), isTrue);
      });

      test('handles case insensitive matching', () {
        final plugin = MockReaderPlugin(
          id: 'test-plugin',
          supportedExtensions: ['epub'],
        );
        registry.register(plugin);

        expect(registry.isExtensionSupported('EPUB'), isTrue);
        expect(registry.isExtensionSupported('Epub'), isTrue);
      });
    });

    group('isMimeTypeSupported', () {
      test('returns true when mime type is supported', () {
        final plugin = MockReaderPlugin(
          id: 'test-plugin',
          supportedMimeTypes: ['application/epub+zip'],
        );
        registry.register(plugin);

        expect(registry.isMimeTypeSupported('application/epub+zip'), isTrue);
      });

      test('returns false when mime type is not supported', () {
        final plugin = MockReaderPlugin(
          id: 'test-plugin',
          supportedMimeTypes: ['application/epub+zip'],
        );
        registry.register(plugin);

        expect(registry.isMimeTypeSupported('application/pdf'), isFalse);
      });
    });

    group('getPluginsByExtension', () {
      test('returns empty list when no plugins support extension', () {
        final plugin = MockReaderPlugin(
          id: 'test-plugin',
          supportedExtensions: ['epub'],
        );
        registry.register(plugin);

        final result = registry.getPluginsByExtension('pdf');

        expect(result, isEmpty);
      });

      test('returns all plugins that support extension', () {
        final plugin1 = MockReaderPlugin(
          id: 'plugin-1',
          supportedExtensions: ['epub'],
        );
        final plugin2 = MockReaderPlugin(
          id: 'plugin-2',
          supportedExtensions: ['epub', 'mobi'],
        );
        final plugin3 = MockReaderPlugin(
          id: 'plugin-3',
          supportedExtensions: ['pdf'],
        );
        registry.register(plugin1);
        registry.register(plugin2);
        registry.register(plugin3);

        final result = registry.getPluginsByExtension('epub');

        expect(result, hasLength(2));
        expect(result, contains(plugin1));
        expect(result, contains(plugin2));
        expect(result, isNot(contains(plugin3)));
      });

      test('handles extension with dot prefix', () {
        final plugin = MockReaderPlugin(
          id: 'test-plugin',
          supportedExtensions: ['epub'],
        );
        registry.register(plugin);

        final result = registry.getPluginsByExtension('.epub');

        expect(result, contains(plugin));
      });

      test('handles case insensitive matching', () {
        final plugin = MockReaderPlugin(
          id: 'test-plugin',
          supportedExtensions: ['epub'],
        );
        registry.register(plugin);

        expect(registry.getPluginsByExtension('EPUB'), contains(plugin));
      });
    });

    group('getPluginsByMimeType', () {
      test('returns empty list when no plugins support mime type', () {
        final plugin = MockReaderPlugin(
          id: 'test-plugin',
          supportedMimeTypes: ['application/epub+zip'],
        );
        registry.register(plugin);

        final result = registry.getPluginsByMimeType('application/pdf');

        expect(result, isEmpty);
      });

      test('returns all plugins that support mime type', () {
        final plugin1 = MockReaderPlugin(
          id: 'plugin-1',
          supportedMimeTypes: ['application/epub+zip'],
        );
        final plugin2 = MockReaderPlugin(
          id: 'plugin-2',
          supportedMimeTypes: ['application/epub+zip', 'application/pdf'],
        );
        final plugin3 = MockReaderPlugin(
          id: 'plugin-3',
          supportedMimeTypes: ['application/pdf'],
        );
        registry.register(plugin1);
        registry.register(plugin2);
        registry.register(plugin3);

        final result = registry.getPluginsByMimeType('application/epub+zip');

        expect(result, hasLength(2));
        expect(result, contains(plugin1));
        expect(result, contains(plugin2));
        expect(result, isNot(contains(plugin3)));
      });
    });

    group('pluginCount', () {
      test('returns 0 when no plugins registered', () {
        expect(registry.pluginCount, equals(0));
      });

      test('returns correct count after registering plugins', () {
        registry.register(MockReaderPlugin(id: 'plugin-1'));
        registry.register(MockReaderPlugin(id: 'plugin-2'));

        expect(registry.pluginCount, equals(2));
      });

      test('returns correct count after unregistering plugins', () {
        registry.register(MockReaderPlugin(id: 'plugin-1'));
        registry.register(MockReaderPlugin(id: 'plugin-2'));
        registry.unregister('plugin-1');

        expect(registry.pluginCount, equals(1));
      });
    });
  });
}
