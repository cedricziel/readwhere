import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:readwhere_rss/readwhere_rss.dart';
import 'package:readwhere_rss_plugin/readwhere_rss_plugin.dart';

import 'rss_catalog_provider_test.mocks.dart';

/// Mock implementation of CatalogInfo for testing
class MockCatalogInfo implements CatalogInfo {
  MockCatalogInfo({
    required this.id,
    required this.providerType,
    this.name = 'Test Catalog',
    this.url = 'https://example.com/feed.xml',
    this.providerConfig = const {},
  });

  @override
  final String id;

  @override
  final String name;

  @override
  final String url;

  @override
  final String providerType;

  @override
  final Map<String, dynamic> providerConfig;

  @override
  DateTime get addedAt => DateTime.now();

  @override
  DateTime? get lastAccessedAt => null;

  @override
  String? get iconUrl => null;
}

@GenerateMocks([RssClient])
void main() {
  late RssCatalogProvider provider;
  late MockRssClient mockClient;
  late CatalogInfo testCatalog;

  setUp(() {
    mockClient = MockRssClient();
    provider = RssCatalogProvider(mockClient);
    testCatalog = MockCatalogInfo(
      id: 'test-catalog',
      providerType: 'rss',
      name: 'Test RSS Feed',
      url: 'https://example.com/feed.xml',
    );
  });

  group('RssCatalogProvider properties', () {
    test('has correct id', () {
      expect(provider.id, equals('rss'));
    });

    test('has correct name', () {
      expect(provider.name, equals('RSS Feed'));
    });

    test('has correct description', () {
      expect(
        provider.description,
        equals('Browse RSS and Atom feeds for ebooks and comics'),
      );
    });

    test('has correct capabilities', () {
      expect(
        provider.capabilities,
        containsAll([
          CatalogCapability.browse,
          CatalogCapability.download,
          CatalogCapability.noAuth,
          CatalogCapability.basicAuth,
        ]),
      );
    });

    test('does not support search', () {
      expect(provider.supportsSearch, isFalse);
    });

    test('does not support pagination', () {
      expect(provider.supportsPagination, isFalse);
    });

    test('supports download', () {
      expect(provider.supportsDownload, isTrue);
    });

    test('does not support progress sync', () {
      expect(provider.supportsProgressSync, isFalse);
    });
  });

  group('canHandle', () {
    test('returns true for rss provider type', () {
      final catalog = MockCatalogInfo(id: 'test', providerType: 'rss');

      expect(provider.canHandle(catalog), isTrue);
    });

    test('returns false for non-rss provider type', () {
      final catalog = MockCatalogInfo(id: 'test', providerType: 'opds');

      expect(provider.canHandle(catalog), isFalse);
    });
  });

  group('hasCapability', () {
    test('returns true for browse capability', () {
      expect(provider.hasCapability(CatalogCapability.browse), isTrue);
    });

    test('returns true for download capability', () {
      expect(provider.hasCapability(CatalogCapability.download), isTrue);
    });

    test('returns true for noAuth capability', () {
      expect(provider.hasCapability(CatalogCapability.noAuth), isTrue);
    });

    test('returns true for basicAuth capability', () {
      expect(provider.hasCapability(CatalogCapability.basicAuth), isTrue);
    });

    test('returns false for search capability', () {
      expect(provider.hasCapability(CatalogCapability.search), isFalse);
    });
  });

  group('validate', () {
    test('returns success for valid feed', () async {
      const feed = RssFeed(
        id: 'feed-1',
        title: 'Test Feed',
        description: 'A test feed',
        author: 'Author',
        feedUrl: 'https://example.com/feed.xml',
        format: RssFeedFormat.rss2,
        items: [
          RssItem(
            id: 'item-1',
            title: 'Item 1',
            enclosures: [
              RssEnclosure(
                url: 'https://example.com/book.epub',
                type: 'application/epub+zip',
              ),
            ],
          ),
        ],
      );

      when(
        mockClient.validateFeed(
          any,
          username: anyNamed('username'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => feed);

      final result = await provider.validate(testCatalog);

      expect(result.isValid, isTrue);
      expect(result.serverName, equals('Test Feed'));
      expect(result.properties['feedId'], equals('feed-1'));
      expect(result.properties['feedFormat'], equals('rss2'));
      expect(result.properties['description'], equals('A test feed'));
      expect(result.properties['author'], equals('Author'));
      expect(result.properties['totalItems'], equals(1));
      expect(result.properties['supportedItems'], equals(1));
      expect(result.properties['hasSupportedContent'], isTrue);
    });

    test('returns failure for auth exception', () async {
      when(
        mockClient.validateFeed(
          any,
          username: anyNamed('username'),
          password: anyNamed('password'),
        ),
      ).thenThrow(
        const RssAuthException(
          'Authentication required',
          url: 'https://example.com/feed.xml',
        ),
      );

      final result = await provider.validate(testCatalog);

      expect(result.isValid, isFalse);
      expect(result.error, equals('Authentication required'));
      expect(result.errorCode, equals('auth_failed'));
    });

    test('returns failure for RSS exception', () async {
      when(
        mockClient.validateFeed(
          any,
          username: anyNamed('username'),
          password: anyNamed('password'),
        ),
      ).thenThrow(
        const RssFetchException(
          'Network error',
          url: 'https://example.com/feed.xml',
        ),
      );

      final result = await provider.validate(testCatalog);

      expect(result.isValid, isFalse);
      expect(result.error, equals('Network error'));
      expect(result.errorCode, equals('validation_failed'));
    });

    test('returns failure for generic exception', () async {
      when(
        mockClient.validateFeed(
          any,
          username: anyNamed('username'),
          password: anyNamed('password'),
        ),
      ).thenThrow(Exception('Unknown error'));

      final result = await provider.validate(testCatalog);

      expect(result.isValid, isFalse);
      expect(result.error, contains('Unknown error'));
      expect(result.errorCode, equals('validation_failed'));
    });

    test('passes credentials from provider config', () async {
      final catalogWithAuth = MockCatalogInfo(
        id: 'test',
        providerType: 'rss',
        providerConfig: {'username': 'user', 'password': 'pass'},
      );

      const feed = RssFeed(
        id: 'feed-1',
        title: 'Test',
        feedUrl: 'https://example.com/feed.xml',
        format: RssFeedFormat.rss2,
        items: [],
      );

      when(
        mockClient.validateFeed(
          any,
          username: anyNamed('username'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => feed);

      await provider.validate(catalogWithAuth);

      verify(
        mockClient.validateFeed(
          'https://example.com/feed.xml',
          username: 'user',
          password: 'pass',
        ),
      ).called(1);
    });
  });

  group('browse', () {
    test('returns browse result from feed', () async {
      const feed = RssFeed(
        id: 'feed-1',
        title: 'Test Feed',
        feedUrl: 'https://example.com/feed.xml',
        format: RssFeedFormat.rss2,
        items: [
          RssItem(
            id: 'item-1',
            title: 'Book 1',
            enclosures: [
              RssEnclosure(
                url: 'https://example.com/book.epub',
                type: 'application/epub+zip',
              ),
            ],
          ),
        ],
      );

      when(
        mockClient.fetchFeed(
          any,
          username: anyNamed('username'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => feed);

      final result = await provider.browse(testCatalog);

      expect(result.title, equals('Test Feed'));
      expect(result.entries.length, equals(1));
      expect(result.entries[0].title, equals('Book 1'));
    });

    test('ignores path parameter', () async {
      const feed = RssFeed(
        id: 'feed-1',
        title: 'Test',
        feedUrl: 'https://example.com/feed.xml',
        format: RssFeedFormat.rss2,
        items: [],
      );

      when(
        mockClient.fetchFeed(
          any,
          username: anyNamed('username'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => feed);

      await provider.browse(testCatalog, path: '/some/path');

      verify(
        mockClient.fetchFeed(
          'https://example.com/feed.xml',
          username: null,
          password: null,
        ),
      ).called(1);
    });

    test('passes credentials from provider config', () async {
      final catalogWithAuth = MockCatalogInfo(
        id: 'test',
        providerType: 'rss',
        url: 'https://example.com/feed.xml',
        providerConfig: {'username': 'user', 'password': 'pass'},
      );

      const feed = RssFeed(
        id: 'feed-1',
        title: 'Test',
        feedUrl: 'https://example.com/feed.xml',
        format: RssFeedFormat.rss2,
        items: [],
      );

      when(
        mockClient.fetchFeed(
          any,
          username: anyNamed('username'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => feed);

      await provider.browse(catalogWithAuth);

      verify(
        mockClient.fetchFeed(
          'https://example.com/feed.xml',
          username: 'user',
          password: 'pass',
        ),
      ).called(1);
    });
  });

  group('search', () {
    test('throws UnsupportedError', () async {
      expect(
        () => provider.search(testCatalog, 'query'),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('download', () {
    test('downloads file to specified path', () async {
      final tempDir = Directory.systemTemp.createTempSync('rss_test_');
      final localPath = '${tempDir.path}/book.epub';
      final mockFile = File(localPath);

      when(
        mockClient.downloadEnclosure(
          any,
          any,
          username: anyNamed('username'),
          password: anyNamed('password'),
          onProgress: anyNamed('onProgress'),
        ),
      ).thenAnswer((_) async => mockFile);

      const file = CatalogFile(
        href: 'https://example.com/book.epub',
        mimeType: 'application/epub+zip',
      );

      await provider.download(testCatalog, file, localPath);

      verify(
        mockClient.downloadEnclosure(
          'https://example.com/book.epub',
          localPath,
          username: null,
          password: null,
          onProgress: null,
        ),
      ).called(1);

      // Cleanup
      tempDir.deleteSync(recursive: true);
    });

    test('passes credentials from provider config', () async {
      final catalogWithAuth = MockCatalogInfo(
        id: 'test',
        providerType: 'rss',
        providerConfig: {'username': 'user', 'password': 'pass'},
      );

      final tempDir = Directory.systemTemp.createTempSync('rss_test_');
      final localPath = '${tempDir.path}/book.epub';
      final mockFile = File(localPath);

      when(
        mockClient.downloadEnclosure(
          any,
          any,
          username: anyNamed('username'),
          password: anyNamed('password'),
          onProgress: anyNamed('onProgress'),
        ),
      ).thenAnswer((_) async => mockFile);

      const file = CatalogFile(
        href: 'https://example.com/book.epub',
        mimeType: 'application/epub+zip',
      );

      await provider.download(catalogWithAuth, file, localPath);

      verify(
        mockClient.downloadEnclosure(
          'https://example.com/book.epub',
          localPath,
          username: 'user',
          password: 'pass',
          onProgress: anyNamed('onProgress'),
        ),
      ).called(1);

      // Cleanup
      tempDir.deleteSync(recursive: true);
    });

    test('reports progress when callback is provided', () async {
      final tempDir = Directory.systemTemp.createTempSync('rss_test_');
      final localPath = '${tempDir.path}/book.epub';
      final progressValues = <int>[];
      final mockFile = File(localPath);

      when(
        mockClient.downloadEnclosure(
          any,
          any,
          username: anyNamed('username'),
          password: anyNamed('password'),
          onProgress: anyNamed('onProgress'),
        ),
      ).thenAnswer((invocation) async {
        final onProgress =
            invocation.namedArguments[#onProgress] as void Function(double)?;
        if (onProgress != null) {
          onProgress(0.5);
        }
        return mockFile;
      });

      const file = CatalogFile(
        href: 'https://example.com/book.epub',
        mimeType: 'application/epub+zip',
        size: 1000,
      );

      await provider.download(
        testCatalog,
        file,
        localPath,
        onProgress: (received, total) {
          progressValues.add(received);
        },
      );

      expect(progressValues, contains(500));

      // Cleanup
      tempDir.deleteSync(recursive: true);
    });
  });
}
