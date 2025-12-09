import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/data/services/opds_cache_service.dart';
import 'package:readwhere/data/services/opds_client_service.dart';
import 'package:readwhere/domain/entities/opds_feed.dart';
import 'package:readwhere/plugins/opds/opds_catalog_provider.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

@GenerateMocks([OpdsClientService, OpdsCacheService])
import 'opds_catalog_provider_test.mocks.dart';

void main() {
  late OpdsCatalogProvider provider;
  late MockOpdsClientService mockClientService;
  late MockOpdsCacheService mockCacheService;

  setUp(() {
    mockClientService = MockOpdsClientService();
    mockCacheService = MockOpdsCacheService();
    provider = OpdsCatalogProvider(mockClientService, mockCacheService);
  });

  group('OpdsCatalogProvider', () {
    test('id is opds', () {
      expect(provider.id, 'opds');
    });

    test('name is OPDS Catalog', () {
      expect(provider.name, 'OPDS Catalog');
    });

    test('has correct capabilities', () {
      expect(provider.capabilities, contains(CatalogCapability.browse));
      expect(provider.capabilities, contains(CatalogCapability.search));
      expect(provider.capabilities, contains(CatalogCapability.download));
      expect(provider.capabilities, contains(CatalogCapability.pagination));
      expect(provider.capabilities, contains(CatalogCapability.noAuth));
      expect(provider.capabilities, contains(CatalogCapability.basicAuth));
    });

    test('canHandle returns true for opds provider type', () {
      final catalog = _TestCatalogInfo(providerType: 'opds');
      expect(provider.canHandle(catalog), isTrue);
    });

    test('canHandle returns false for other provider types', () {
      final catalog = _TestCatalogInfo(providerType: 'kavita');
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

    test('supportsProgressSync returns false', () {
      expect(provider.supportsProgressSync, isFalse);
    });

    group('validate', () {
      test('returns success when validation succeeds', () async {
        final mockFeed = OpdsFeed(
          id: 'test-feed',
          title: 'Test Feed',
          kind: OpdsFeedKind.navigation,
          updated: DateTime.now(),
          entries: [],
          links: [],
        );

        when(
          mockClientService.validateCatalog(any),
        ).thenAnswer((_) async => mockFeed);

        final catalog = _TestCatalogInfo(
          url: 'https://example.com/opds',
          providerType: 'opds',
        );

        final result = await provider.validate(catalog);

        expect(result.isValid, isTrue);
        expect(result.serverName, 'Test Feed');
        expect(result.properties['feedId'], 'test-feed');
      });

      test('returns failure when validation throws OpdsException', () async {
        when(
          mockClientService.validateCatalog(any),
        ).thenThrow(OpdsException('Invalid feed', statusCode: 404));

        final catalog = _TestCatalogInfo(
          url: 'https://example.com/opds',
          providerType: 'opds',
        );

        final result = await provider.validate(catalog);

        expect(result.isValid, isFalse);
        expect(result.error, 'Invalid feed');
        expect(result.errorCode, 'validation_failed');
      });

      test('returns auth_failed when status is 401', () async {
        when(
          mockClientService.validateCatalog(any),
        ).thenThrow(OpdsException('Unauthorized', statusCode: 401));

        final catalog = _TestCatalogInfo(
          url: 'https://example.com/opds',
          providerType: 'opds',
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
    this.providerType = 'opds',
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
