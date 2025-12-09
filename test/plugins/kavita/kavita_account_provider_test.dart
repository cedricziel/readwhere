import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere_kavita/readwhere_kavita.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

@GenerateMocks([KavitaApiClient])
import 'kavita_account_provider_test.mocks.dart';

void main() {
  late KavitaAccountProvider provider;
  late MockKavitaApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockKavitaApiClient();
    provider = KavitaAccountProvider(mockApiClient);
  });

  group('KavitaAccountProvider', () {
    test('id is kavita', () {
      expect(provider.id, 'kavita');
    });

    test('supports only apiKey auth type', () {
      expect(provider.supportedAuthTypes, contains(AuthType.apiKey));
      expect(provider.supportedAuthTypes.length, 1);
    });

    test('supportsBasicAuth returns false', () {
      expect(provider.supportsBasicAuth, isFalse);
    });

    test('supportsOAuth returns false', () {
      expect(provider.supportsOAuth, isFalse);
    });

    test('supportsAuthType returns true for apiKey', () {
      expect(provider.supportsAuthType(AuthType.apiKey), isTrue);
    });

    test('supportsAuthType returns false for basic', () {
      expect(provider.supportsAuthType(AuthType.basic), isFalse);
    });

    test('supportsAuthType returns false for oauth2', () {
      expect(provider.supportsAuthType(AuthType.oauth2), isFalse);
    });

    group('authenticate', () {
      test('returns account info when authentication succeeds', () async {
        final serverInfo = KavitaServerInfo(
          serverName: 'Test Kavita',
          version: '0.7.0',
        );

        when(
          mockApiClient.authenticate(any, any),
        ).thenAnswer((_) async => serverInfo);

        final credentials = ApiKeyCredentials(apiKey: 'test-api-key');

        final result = await provider.authenticate(
          'https://kavita.example.com',
          credentials,
        );

        expect(result.isAuthenticated, isTrue);
        expect(result.authType, AuthType.apiKey);
        expect(result.displayName, 'Test Kavita');
        expect(result.providerData['serverVersion'], '0.7.0');
        expect(result.providerData['apiKey'], 'test-api-key');

        verify(
          mockApiClient.authenticate(
            'https://kavita.example.com',
            'test-api-key',
          ),
        ).called(1);
      });

      test('throws ArgumentError for non-ApiKey credentials', () async {
        final credentials = BasicAuthCredentials(
          username: 'user',
          password: 'pass',
        );

        expect(
          () => provider.authenticate('https://example.com', credentials),
          throwsArgumentError,
        );
      });
    });

    test('startOAuthFlow returns null', () async {
      final result = await provider.startOAuthFlow('https://example.com');
      expect(result, isNull);
    });

    test('pollOAuthFlow returns null', () async {
      final result = await provider.pollOAuthFlow('endpoint', 'token');
      expect(result, isNull);
    });

    test('refreshToken returns null', () async {
      final credentials = OAuth2Credentials(
        accessToken: 'token',
        refreshToken: 'refresh',
      );
      final result = await provider.refreshToken(credentials);
      expect(result, isNull);
    });

    test('logout completes without error', () async {
      final account = _TestAccountInfo();
      await expectLater(provider.logout(account), completes);
    });
  });
}

/// Test implementation of AccountInfo
class _TestAccountInfo implements AccountInfo {
  @override
  String get catalogId => 'test-catalog';

  @override
  AuthType get authType => AuthType.apiKey;

  @override
  String get userId => 'test-user';

  @override
  String get displayName => 'Test User';

  @override
  bool get isAuthenticated => true;

  @override
  Map<String, dynamic> get providerData => {};
}
