import 'dart:convert';

import 'package:readwhere_webdav/readwhere_webdav.dart';
import 'package:test/test.dart';

void main() {
  group('BasicAuth', () {
    test('creates correct authorization header', () {
      final auth = BasicAuth(username: 'user', password: 'pass');
      final headers = auth.headers;

      expect(headers.containsKey('Authorization'), true);

      final expectedCredentials = base64Encode(utf8.encode('user:pass'));
      expect(headers['Authorization'], 'Basic $expectedCredentials');
    });

    test('handles special characters in credentials', () {
      final auth =
          BasicAuth(username: 'user@domain.com', password: 'p@ss:word!');
      final headers = auth.headers;

      final expectedCredentials =
          base64Encode(utf8.encode('user@domain.com:p@ss:word!'));
      expect(headers['Authorization'], 'Basic $expectedCredentials');
    });

    test('handles empty password', () {
      final auth = BasicAuth(username: 'user', password: '');
      final headers = auth.headers;

      final expectedCredentials = base64Encode(utf8.encode('user:'));
      expect(headers['Authorization'], 'Basic $expectedCredentials');
    });

    test('handles unicode characters', () {
      final auth = BasicAuth(username: 'üser', password: 'pässwörd');
      final headers = auth.headers;

      final expectedCredentials = base64Encode(utf8.encode('üser:pässwörd'));
      expect(headers['Authorization'], 'Basic $expectedCredentials');
    });

    test('onAuthenticationFailed completes without error', () async {
      final auth = BasicAuth(username: 'user', password: 'pass');
      await expectLater(auth.onAuthenticationFailed(), completes);
    });
  });
}
