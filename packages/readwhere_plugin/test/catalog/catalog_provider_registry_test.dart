import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:test/test.dart';

// Mock implementations for testing
class MockCatalogProvider implements CatalogProvider {
  MockCatalogProvider({
    required this.id,
    this.name = 'Mock Provider',
    this.description = 'A mock provider',
    this.capabilities = const {CatalogCapability.browse},
  });

  @override
  final String id;

  @override
  final String name;

  @override
  final String description;

  @override
  final Set<CatalogCapability> capabilities;

  @override
  bool canHandle(CatalogInfo catalog) => catalog.providerType == id;

  @override
  Future<ValidationResult> validate(CatalogInfo catalog) async =>
      const ValidationResult.success();

  @override
  Future<BrowseResult> browse(
    CatalogInfo catalog, {
    String? path,
    int? page,
  }) async => const BrowseResult.empty();

  @override
  Future<BrowseResult> search(
    CatalogInfo catalog,
    String query, {
    int? page,
  }) async => const BrowseResult.empty();

  @override
  Future<void> download(
    CatalogInfo catalog,
    CatalogFile file,
    String localPath, {
    ProgressCallback? onProgress,
  }) async {}

  @override
  bool hasCapability(CatalogCapability capability) =>
      capabilities.contains(capability);

  @override
  bool get supportsSearch => hasCapability(CatalogCapability.search);

  @override
  bool get supportsPagination => hasCapability(CatalogCapability.pagination);

  @override
  bool get supportsDownload => hasCapability(CatalogCapability.download);

  @override
  bool get supportsProgressSync =>
      hasCapability(CatalogCapability.progressSync);
}

class MockAccountProvider implements AccountProvider {
  MockAccountProvider({required this.id});

  @override
  final String id;

  @override
  Set<AuthType> get supportedAuthTypes => {AuthType.basic};

  @override
  Future<AccountInfo> authenticate(
    String serverUrl,
    AuthCredentials credentials,
  ) async => throw UnimplementedError();

  @override
  Future<OAuthFlowInit?> startOAuthFlow(String serverUrl) async => null;

  @override
  Future<OAuthFlowResult?> pollOAuthFlow(
    String pollEndpoint,
    String pollToken,
  ) async => null;

  @override
  Future<void> logout(AccountInfo account) async {}

  @override
  Future<OAuth2Credentials?> refreshToken(
    OAuth2Credentials credentials,
  ) async => null;

  @override
  bool supportsAuthType(AuthType type) => supportedAuthTypes.contains(type);

  @override
  bool get supportsOAuth => supportsAuthType(AuthType.oauth2);

  @override
  bool get supportsBasicAuth => supportsAuthType(AuthType.basic);
}

class MockCatalogInfo implements CatalogInfo {
  MockCatalogInfo({
    required this.id,
    required this.providerType,
    this.name = 'Test Catalog',
    this.url = 'https://example.com',
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
  DateTime get addedAt => DateTime.now();

  @override
  DateTime? get lastAccessedAt => null;

  @override
  String? get iconUrl => null;

  @override
  Map<String, dynamic> get providerConfig => {};
}

void main() {
  group('CatalogProviderRegistry', () {
    late CatalogProviderRegistry registry;

    setUp(() {
      registry = CatalogProviderRegistry();
      registry.clear(); // Ensure clean state
    });

    tearDown(() {
      registry.clear();
    });

    group('singleton', () {
      test('returns same instance', () {
        final instance1 = CatalogProviderRegistry();
        final instance2 = CatalogProviderRegistry();
        expect(identical(instance1, instance2), true);
      });
    });

    group('register', () {
      test('registers a provider', () {
        final provider = MockCatalogProvider(id: 'test');
        registry.register(provider);

        expect(registry.getById('test'), provider);
        expect(registry.length, 1);
      });

      test('registers provider with account provider', () {
        final provider = MockCatalogProvider(id: 'test');
        final accountProvider = MockAccountProvider(id: 'test');

        registry.register(provider, accountProvider: accountProvider);

        expect(registry.getById('test'), provider);
        expect(registry.getAccountProvider('test'), accountProvider);
      });

      test('replaces existing provider with same id', () {
        final provider1 = MockCatalogProvider(id: 'test', name: 'First');
        final provider2 = MockCatalogProvider(id: 'test', name: 'Second');

        registry.register(provider1);
        registry.register(provider2);

        expect(registry.getById('test')?.name, 'Second');
        expect(registry.length, 1);
      });
    });

    group('unregister', () {
      test('removes provider', () {
        final provider = MockCatalogProvider(id: 'test');
        registry.register(provider);

        final result = registry.unregister('test');

        expect(result, true);
        expect(registry.getById('test'), isNull);
        expect(registry.length, 0);
      });

      test('removes associated account provider', () {
        final provider = MockCatalogProvider(id: 'test');
        final accountProvider = MockAccountProvider(id: 'test');
        registry.register(provider, accountProvider: accountProvider);

        registry.unregister('test');

        expect(registry.getAccountProvider('test'), isNull);
      });

      test('returns false for non-existent provider', () {
        final result = registry.unregister('nonexistent');
        expect(result, false);
      });
    });

    group('getById', () {
      test('returns provider by id', () {
        final provider = MockCatalogProvider(id: 'opds');
        registry.register(provider);

        expect(registry.getById('opds'), provider);
      });

      test('returns null for unknown id', () {
        expect(registry.getById('unknown'), isNull);
      });
    });

    group('getForCatalog', () {
      test('finds provider by provider type', () {
        final provider = MockCatalogProvider(id: 'opds');
        registry.register(provider);

        final catalog = MockCatalogInfo(id: '1', providerType: 'opds');
        expect(registry.getForCatalog(catalog), provider);
      });

      test('falls back to canHandle check', () {
        final provider = MockCatalogProvider(id: 'opds');
        registry.register(provider);

        // Create a catalog with a different providerType but that canHandle accepts
        final catalog = MockCatalogInfo(id: '1', providerType: 'opds');
        expect(registry.getForCatalog(catalog), provider);
      });

      test('returns null when no provider matches', () {
        final provider = MockCatalogProvider(id: 'opds');
        registry.register(provider);

        final catalog = MockCatalogInfo(id: '1', providerType: 'kavita');
        expect(registry.getForCatalog(catalog), isNull);
      });
    });

    group('getAll', () {
      test('returns all providers', () {
        final provider1 = MockCatalogProvider(id: 'opds');
        final provider2 = MockCatalogProvider(id: 'nextcloud');
        registry.register(provider1);
        registry.register(provider2);

        final all = registry.getAll();
        expect(all.length, 2);
        expect(all, contains(provider1));
        expect(all, contains(provider2));
      });

      test('returns empty list when no providers', () {
        expect(registry.getAll(), isEmpty);
      });

      test('returns unmodifiable list', () {
        final provider = MockCatalogProvider(id: 'test');
        registry.register(provider);

        final all = registry.getAll();
        expect(() => all.add(provider), throwsUnsupportedError);
      });
    });

    group('getAllIds', () {
      test('returns all provider ids', () {
        registry.register(MockCatalogProvider(id: 'opds'));
        registry.register(MockCatalogProvider(id: 'nextcloud'));

        final ids = registry.getAllIds();
        expect(ids, containsAll(['opds', 'nextcloud']));
      });
    });

    group('getByCapability', () {
      test('returns providers with capability', () {
        final provider1 = MockCatalogProvider(
          id: 'opds',
          capabilities: {CatalogCapability.browse, CatalogCapability.search},
        );
        final provider2 = MockCatalogProvider(
          id: 'nextcloud',
          capabilities: {CatalogCapability.browse},
        );
        registry.register(provider1);
        registry.register(provider2);

        final searchProviders = registry.getByCapability(
          CatalogCapability.search,
        );
        expect(searchProviders.length, 1);
        expect(searchProviders.first.id, 'opds');
      });

      test('returns empty list when no providers have capability', () {
        final provider = MockCatalogProvider(
          id: 'test',
          capabilities: {CatalogCapability.browse},
        );
        registry.register(provider);

        expect(registry.getByCapability(CatalogCapability.oauthAuth), isEmpty);
      });
    });

    group('getAccountProvider', () {
      test('returns account provider for provider id', () {
        final accountProvider = MockAccountProvider(id: 'nextcloud');
        registry.register(
          MockCatalogProvider(id: 'nextcloud'),
          accountProvider: accountProvider,
        );

        expect(registry.getAccountProvider('nextcloud'), accountProvider);
      });

      test('returns null when no account provider', () {
        registry.register(MockCatalogProvider(id: 'opds'));
        expect(registry.getAccountProvider('opds'), isNull);
      });
    });

    group('getAccountProviderForCatalog', () {
      test('returns account provider for catalog', () {
        final accountProvider = MockAccountProvider(id: 'nextcloud');
        registry.register(
          MockCatalogProvider(id: 'nextcloud'),
          accountProvider: accountProvider,
        );

        final catalog = MockCatalogInfo(id: '1', providerType: 'nextcloud');
        expect(registry.getAccountProviderForCatalog(catalog), accountProvider);
      });
    });

    group('isRegistered', () {
      test('returns true for registered provider', () {
        registry.register(MockCatalogProvider(id: 'test'));
        expect(registry.isRegistered('test'), true);
      });

      test('returns false for unregistered provider', () {
        expect(registry.isRegistered('test'), false);
      });
    });

    group('hasAccountProvider', () {
      test('returns true when account provider exists', () {
        registry.register(
          MockCatalogProvider(id: 'test'),
          accountProvider: MockAccountProvider(id: 'test'),
        );
        expect(registry.hasAccountProvider('test'), true);
      });

      test('returns false when no account provider', () {
        registry.register(MockCatalogProvider(id: 'test'));
        expect(registry.hasAccountProvider('test'), false);
      });
    });

    group('isEmpty/isNotEmpty', () {
      test('isEmpty is true when no providers', () {
        expect(registry.isEmpty, true);
        expect(registry.isNotEmpty, false);
      });

      test('isNotEmpty is true when providers exist', () {
        registry.register(MockCatalogProvider(id: 'test'));
        expect(registry.isEmpty, false);
        expect(registry.isNotEmpty, true);
      });
    });

    group('clear', () {
      test('removes all providers', () {
        registry.register(MockCatalogProvider(id: 'opds'));
        registry.register(
          MockCatalogProvider(id: 'nextcloud'),
          accountProvider: MockAccountProvider(id: 'nextcloud'),
        );

        registry.clear();

        expect(registry.isEmpty, true);
        expect(registry.getAccountProvider('nextcloud'), isNull);
      });
    });
  });
}
