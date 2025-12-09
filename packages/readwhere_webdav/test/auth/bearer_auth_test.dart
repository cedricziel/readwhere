import 'package:readwhere_webdav/readwhere_webdav.dart';
import 'package:test/test.dart';

void main() {
  group('BearerAuth', () {
    test('creates correct authorization header', () {
      final auth = BearerAuth(token: 'my-secret-token');
      final headers = auth.headers;

      expect(headers.containsKey('Authorization'), true);
      expect(headers['Authorization'], 'Bearer my-secret-token');
    });

    test('handles empty token', () {
      final auth = BearerAuth(token: '');
      final headers = auth.headers;

      expect(headers['Authorization'], 'Bearer ');
    });

    test('handles token with special characters', () {
      final auth = BearerAuth(token: 'token-with.special_chars/123');
      final headers = auth.headers;

      expect(headers['Authorization'], 'Bearer token-with.special_chars/123');
    });

    test('handles JWT-like token', () {
      const jwtToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U';
      final auth = BearerAuth(token: jwtToken);
      final headers = auth.headers;

      expect(headers['Authorization'], 'Bearer $jwtToken');
    });

    test('onAuthenticationFailed completes without error', () async {
      final auth = BearerAuth(token: 'token');
      await expectLater(auth.onAuthenticationFailed(), completes);
    });
  });
}
