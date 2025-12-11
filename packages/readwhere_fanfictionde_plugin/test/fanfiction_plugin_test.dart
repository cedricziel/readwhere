import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:readwhere_fanfictionde_plugin/readwhere_fanfictionde_plugin.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

/// Mock HTTP client for testing.
class MockHttpClient extends http.BaseClient {
  final Map<String, String> responses = {};

  void addResponse(String url, String body) {
    responses[url] = body;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final url = request.url.toString();

    // Check for exact match first
    if (responses.containsKey(url)) {
      return http.StreamedResponse(
        Stream.value(responses[url]!.codeUnits),
        200,
      );
    }

    // Check for partial match (URL starts with)
    for (final key in responses.keys) {
      if (url.startsWith(key)) {
        return http.StreamedResponse(
          Stream.value(responses[key]!.codeUnits),
          200,
        );
      }
    }

    // Return 404 for unknown URLs
    return http.StreamedResponse(
      Stream.value('Not found'.codeUnits),
      404,
    );
  }
}

/// Mock CatalogInfo for testing.
class MockCatalogInfo implements CatalogInfo {
  MockCatalogInfo({
    required this.id,
    required this.name,
    required this.url,
    required this.providerType,
    DateTime? addedAt,
    this.lastAccessedAt,
    this.iconUrl,
    Map<String, dynamic>? providerConfig,
  })  : addedAt = addedAt ?? DateTime.now(),
        providerConfig = providerConfig ?? {};

  @override
  final String id;

  @override
  final String name;

  @override
  final String url;

  @override
  final String providerType;

  @override
  final DateTime addedAt;

  @override
  final DateTime? lastAccessedAt;

  @override
  final String? iconUrl;

  @override
  final Map<String, dynamic> providerConfig;
}

void main() {
  group('FanfictionPlugin', () {
    late FanfictionPlugin plugin;
    late MockHttpClient mockClient;

    setUp(() async {
      plugin = FanfictionPlugin();
      mockClient = MockHttpClient();

      // Setup mock responses for categories (no trailing slash)
      mockClient.addResponse(
        'https://www.fanfiktion.de',
        _mockHomepageHtml,
      );

      // Create plugin context
      final context = PluginContext(
        storage: InMemoryPluginStorage('test.fanfiction'),
        httpClient: mockClient,
        logger: Logger('test.fanfiction'),
        appConfig: const PluginAppConfig(
          appVersion: '1.0.0',
          platform: 'test',
          locale: 'en_US',
          isDarkMode: false,
        ),
        pluginDataDirectory: Directory.systemTemp,
        downloadDirectory: Directory.systemTemp,
      );

      await plugin.initialize(context);
    });

    tearDown(() async {
      await plugin.dispose();
    });

    group('browse', () {
      test('returns categories for root path', () async {
        final catalogInfo = MockCatalogInfo(
          id: 'test',
          name: 'Test',
          url: 'https://www.fanfiktion.de',
          providerType: 'fanfiction',
        );

        final result = await plugin.browse(catalogInfo);

        expect(result.entries, isNotEmpty);
        expect(result.title, equals('Categories'));
      });

      test('returns categories for null path', () async {
        final catalogInfo = MockCatalogInfo(
          id: 'test',
          name: 'Test',
          url: 'https://www.fanfiktion.de',
          providerType: 'fanfiction',
        );

        final result = await plugin.browse(catalogInfo, path: null);

        expect(result.entries, isNotEmpty);
      });

      test('returns categories for empty path', () async {
        final catalogInfo = MockCatalogInfo(
          id: 'test',
          name: 'Test',
          url: 'https://www.fanfiktion.de',
          providerType: 'fanfiction',
        );

        final result = await plugin.browse(catalogInfo, path: '');

        expect(result.entries, isNotEmpty);
      });

      test('returns categories for slash path', () async {
        final catalogInfo = MockCatalogInfo(
          id: 'test',
          name: 'Test',
          url: 'https://www.fanfiktion.de',
          providerType: 'fanfiction',
        );

        final result = await plugin.browse(catalogInfo, path: '/');

        expect(result.entries, isNotEmpty);
      });

      group('URL normalization', () {
        test('normalizes full HTTPS URL to path', () async {
          // Setup mock for the category page
          mockClient.addResponse(
            'https://www.fanfiktion.de/Anime-Manga/c/102000000',
            _mockCategoryPageHtml,
          );

          final catalogInfo = MockCatalogInfo(
            id: 'test',
            name: 'Test',
            url: 'https://www.fanfiktion.de',
            providerType: 'fanfiction',
          );

          // This is the format that comes from clicking a category entry
          final result = await plugin.browse(
            catalogInfo,
            path: 'https://www.fanfiktion.de/Anime-Manga/c/102000000',
          );

          // Should have processed successfully (not thrown an error)
          expect(result, isNotNull);
        });

        test('normalizes full HTTP URL to path', () async {
          mockClient.addResponse(
            'https://www.fanfiktion.de/Anime-Manga/c/102000000',
            _mockCategoryPageHtml,
          );

          final catalogInfo = MockCatalogInfo(
            id: 'test',
            name: 'Test',
            url: 'https://www.fanfiktion.de',
            providerType: 'fanfiction',
          );

          final result = await plugin.browse(
            catalogInfo,
            path: 'http://www.fanfiktion.de/Anime-Manga/c/102000000',
          );

          expect(result, isNotNull);
        });

        test('extracts category ID from URL path with /c/ pattern', () async {
          mockClient.addResponse(
            'https://www.fanfiktion.de/Anime-Manga/c/102000000',
            _mockCategoryPageHtml,
          );

          final catalogInfo = MockCatalogInfo(
            id: 'test',
            name: 'Test',
            url: 'https://www.fanfiktion.de',
            providerType: 'fanfiction',
          );

          // Direct path with /c/{id} pattern
          final result = await plugin.browse(
            catalogInfo,
            path: '/Anime-Manga/c/102000000',
          );

          expect(result, isNotNull);
        });

        test('handles relative /category/ path format', () async {
          mockClient.addResponse(
            'https://www.fanfiktion.de/c/102000000',
            _mockCategoryPageHtml,
          );

          final catalogInfo = MockCatalogInfo(
            id: 'test',
            name: 'Test',
            url: 'https://www.fanfiktion.de',
            providerType: 'fanfiction',
          );

          final result = await plugin.browse(
            catalogInfo,
            path: '/category/102000000',
          );

          expect(result, isNotNull);
        });

        test('handles relative /fandom/ path format', () async {
          mockClient.addResponse(
            'https://www.fanfiktion.de/c/102000001',
            _mockStoryListHtml,
          );

          final catalogInfo = MockCatalogInfo(
            id: 'test',
            name: 'Test',
            url: 'https://www.fanfiktion.de',
            providerType: 'fanfiction',
          );

          final result = await plugin.browse(
            catalogInfo,
            path: '/fandom/102000001',
          );

          expect(result, isNotNull);
        });
      });
    });

    group('canHandleCatalog', () {
      test('returns true for fanfiction provider type', () {
        final catalogInfo = MockCatalogInfo(
          id: 'test',
          name: 'Test',
          url: 'https://www.fanfiktion.de',
          providerType: 'fanfiction',
        );

        expect(plugin.canHandleCatalog(catalogInfo), isTrue);
      });

      test('returns false for other provider types', () {
        final catalogInfo = MockCatalogInfo(
          id: 'test',
          name: 'Test',
          url: 'https://example.com',
          providerType: 'opds',
        );

        expect(plugin.canHandleCatalog(catalogInfo), isFalse);
      });
    });

    group('plugin metadata', () {
      test('has correct id', () {
        expect(plugin.id, equals('com.readwhere.fanfiction'));
      });

      test('has correct name', () {
        expect(plugin.name, equals('Fanfiction.de'));
      });

      test('has catalog features', () {
        expect(plugin.catalogFeatures, contains(PluginCatalogFeature.browse));
        expect(plugin.catalogFeatures, contains(PluginCatalogFeature.search));
        expect(plugin.catalogFeatures, contains(PluginCatalogFeature.download));
        expect(
            plugin.catalogFeatures, contains(PluginCatalogFeature.pagination));
      });
    });
  });
}

// Mock HTML responses

const _mockHomepageHtml = '''
<!DOCTYPE html>
<html>
<head><title>FanFiktion.de</title></head>
<body>
<div class="storylist-left-header storylist-left-header-index">
  <a href="/Anime-Manga/c/102000000" class="storylist-left-headline">Anime & Manga</a>
  <span class="storylist-left-count">(123456)</span>
</div>
<div class="storylist-left-header storylist-left-header-index">
  <a href="/Bucher/c/103000000" class="storylist-left-headline">Bücher</a>
  <span class="storylist-left-count">(78901)</span>
</div>
</body>
</html>
''';

const _mockCategoryPageHtml = '''
<!DOCTYPE html>
<html>
<head><title>Anime & Manga - FanFiktion.de</title></head>
<body>
<div class="storylist-left-header">
  <a href="/Anime-Manga/Naruto/c/102001000" class="storylist-left-headline">Naruto</a>
  <span class="storylist-left-count">(5000)</span>
</div>
<div class="storylist-left-header">
  <a href="/Anime-Manga/One-Piece/c/102002000" class="storylist-left-headline">One Piece</a>
  <span class="storylist-left-count">(3000)</span>
</div>
</body>
</html>
''';

const _mockStoryListHtml = '''
<!DOCTYPE html>
<html>
<head><title>Stories - FanFiktion.de</title></head>
<body>
<div class="storylist-item">
  <a class="storylist-title" href="/s/abc123def/1/Test-Story">Test Story</a>
  <a class="storylist-author" href="/u/testuser">testuser</a>
  <span class="storylist-summary">This is a test story summary.</span>
  <span class="storylist-chapters">3</span>
  <span class="storylist-words">5000</span>
</div>
</body>
</html>
''';
