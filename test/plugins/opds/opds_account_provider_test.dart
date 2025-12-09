import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/plugins/opds/opds_account_provider.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

void main() {
  late OpdsAccountProvider provider;

  setUp(() {
    provider = OpdsAccountProvider();
  });

  group('OpdsAccountProvider', () {
    test('id is opds', () {
      expect(provider.id, 'opds');
    });

    test('supports none and basic auth types', () {
      expect(provider.supportedAuthTypes, contains(AuthType.none));
      expect(provider.supportedAuthTypes, contains(AuthType.basic));
      expect(provider.supportedAuthTypes.length, 2);
    });

    test('supportsBasicAuth returns true', () {
      expect(provider.supportsBasicAuth, isTrue);
    });

    test('supportsOAuth returns false', () {
      expect(provider.supportsOAuth, isFalse);
    });

    test('supportsAuthType returns true for none', () {
      expect(provider.supportsAuthType(AuthType.none), isTrue);
    });

    test('supportsAuthType returns true for basic', () {
      expect(provider.supportsAuthType(AuthType.basic), isTrue);
    });

    test('supportsAuthType returns false for oauth2', () {
      expect(provider.supportsAuthType(AuthType.oauth2), isFalse);
    });

    test('supportsAuthType returns false for apiKey', () {
      expect(provider.supportsAuthType(AuthType.apiKey), isFalse);
    });

    group('authenticate', () {
      test('returns account info for basic auth', () async {
        final credentials = BasicAuthCredentials(
          username: 'testuser',
          password: 'testpass',
        );

        final result = await provider.authenticate(
          'https://example.com/opds',
          credentials,
        );

        expect(result.isAuthenticated, isTrue);
        expect(result.authType, AuthType.basic);
        expect(result.userId, 'testuser');
        expect(result.displayName, 'testuser');
      });

      test('returns anonymous user for non-basic auth', () async {
        // When using a non-BasicAuth credential, userId should be 'anonymous'
        final credentials = ApiKeyCredentials(apiKey: 'test-key');

        final result = await provider.authenticate(
          'https://example.com/opds',
          credentials,
        );

        expect(result.isAuthenticated, isTrue);
        expect(result.userId, 'anonymous');
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
      // Create a minimal mock AccountInfo
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
  AuthType get authType => AuthType.none;

  @override
  String get userId => 'test-user';

  @override
  String get displayName => 'Test User';

  @override
  bool get isAuthenticated => true;

  @override
  Map<String, dynamic> get providerData => {};
}
