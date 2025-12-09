import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/data/services/kavita_api_service.dart';
import 'package:readwhere/data/services/opds_cache_service.dart';
import 'package:readwhere/data/services/opds_client_service.dart';
import 'package:readwhere/domain/entities/opds_feed.dart';
import 'package:readwhere/plugins/kavita/kavita_catalog_provider.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

@GenerateMocks([KavitaApiService, OpdsClientService, OpdsCacheService])
import 'kavita_catalog_provider_test.mocks.dart';

void main() {
  late KavitaCatalogProvider provider;
  late MockKavitaApiService mockKavitaService;
  late MockOpdsClientService mockOpdsService;
  late MockOpdsCacheService mockCacheService;

  setUp(() {
    mockKavitaService = MockKavitaApiService();
    mockOpdsService = MockOpdsClientService();
    mockCacheService = MockOpdsCacheService();
    provider = KavitaCatalogProvider(
      mockKavitaService,
      mockOpdsService,
      mockCacheService,
    );
  });

  group('KavitaCatalogProvider', () {
    test('id is kavita', () {
      expect(provider.id, 'kavita');
    });

    test('name is Kavita Server', () {
      expect(provider.name, 'Kavita Server');
    });

    test('has correct capabilities', () {
      expect(provider.capabilities, contains(CatalogCapability.browse));
      expect(provider.capabilities, contains(CatalogCapability.search));
      expect(provider.capabilities, contains(CatalogCapability.download));
      expect(provider.capabilities, contains(CatalogCapability.pagination));
      expect(provider.capabilities, contains(CatalogCapability.apiKeyAuth));
      expect(provider.capabilities, contains(CatalogCapability.progressSync));
    });

    test('canHandle returns true for kavita provider type', () {
      final catalog = _TestCatalogInfo(providerType: 'kavita');
      expect(provider.canHandle(catalog), isTrue);
    });

    test('canHandle returns false for other provider types', () {
      final catalog = _TestCatalogInfo(providerType: 'opds');
      expect(provider.canHandle(catalog), isFalse);
    });

    test('supportsSearch returns true', () {
      expect(provider.supportsSearch, isTrue);
    });

    test('supportsPagination returns true', () {
      expect(provider.supportsPagination, isTrue);
    });

    test('supportsDownload returns true', () {
      expect(provider.supportsDownload, isTrue);
    });

    test('supportsProgressSync returns true', () {
      expect(provider.supportsProgressSync, isTrue);
    });

    group('validate', () {
      test('returns failure when API key is missing', () async {
        final catalog = _TestCatalogInfo(
          url: 'https://example.com',
          providerType: 'kavita',
          providerConfig: {}, // No API key
        );

        final result = await provider.validate(catalog);

        expect(result.isValid, isFalse);
        expect(result.errorCode, 'missing_api_key');
      });

      test('returns failure when API key is empty', () async {
        final catalog = _TestCatalogInfo(
          url: 'https://example.com',
          providerType: 'kavita',
          providerConfig: {'apiKey': ''},
        );

        final result = await provider.validate(catalog);

        expect(result.isValid, isFalse);
        expect(result.errorCode, 'missing_api_key');
      });

      test('returns success when validation succeeds', () async {
        final serverInfo = KavitaServerInfo(
          serverName: 'Test Server',
          version: '0.7.0',
        );

        final mockFeed = OpdsFeed(
          id: 'test-feed',
          title: 'Test Feed',
          kind: OpdsFeedKind.navigation,
          updated: DateTime.now(),
          entries: [],
          links: [],
        );

        when(
          mockKavitaService.authenticate(any, any),
        ).thenAnswer((_) async => serverInfo);
        when(
          mockOpdsService.validateCatalog(any),
        ).thenAnswer((_) async => mockFeed);

        final catalog = _TestCatalogInfo(
          url: 'https://example.com',
          providerType: 'kavita',
          providerConfig: {'apiKey': 'test-api-key'},
        );

        final result = await provider.validate(catalog);

        expect(result.isValid, isTrue);
        expect(result.serverName, 'Test Server');
        expect(result.properties['kavitaVersion'], '0.7.0');
      });

      test('returns failure when Kavita auth fails', () async {
        when(
          mockKavitaService.authenticate(any, any),
        ).thenThrow(KavitaApiException('Invalid API key', statusCode: 401));

        final catalog = _TestCatalogInfo(
          url: 'https://example.com',
          providerType: 'kavita',
          providerConfig: {'apiKey': 'invalid-key'},
        );

        final result = await provider.validate(catalog);

        expect(result.isValid, isFalse);
        expect(result.errorCode, 'auth_failed');
      });
    });
  });
}

/// Test implementation of CatalogInfo
class _TestCatalogInfo implements CatalogInfo {
  _TestCatalogInfo({
    this.url = 'https://example.com',
    this.providerType = 'kavita',
    Map<String, dynamic>? providerConfig,
  }) : providerConfig = providerConfig ?? {};

  @override
  String get id => 'test-id';

  @override
  String get name => 'Test Catalog';

  @override
  final String url;

  @override
  final String providerType;

  @override
  String? get iconUrl => null;

  @override
  final Map<String, dynamic> providerConfig;

  @override
  DateTime get addedAt => DateTime.now();

  @override
  DateTime? get lastAccessedAt => null;
}
