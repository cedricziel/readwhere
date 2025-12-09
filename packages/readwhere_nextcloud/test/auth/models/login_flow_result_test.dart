import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';

void main() {
  group('LoginFlowResult', () {
    test('creates instance with required parameters', () {
      const result = LoginFlowResult(
        server: 'https://nextcloud.example.com',
        loginName: 'testuser',
        appPassword: 'generated-app-password-123',
      );

      expect(result.server, 'https://nextcloud.example.com');
      expect(result.loginName, 'testuser');
      expect(result.appPassword, 'generated-app-password-123');
    });

    test('equality - equal instances', () {
      const result1 = LoginFlowResult(
        server: 'https://nc.example.com',
        loginName: 'user1',
        appPassword: 'password123',
      );
      const result2 = LoginFlowResult(
        server: 'https://nc.example.com',
        loginName: 'user1',
        appPassword: 'password123',
      );

      expect(result1, equals(result2));
      expect(result1.hashCode, result2.hashCode);
    });

    test('equality - different server', () {
      const result1 = LoginFlowResult(
        server: 'https://nc1.example.com',
        loginName: 'user',
        appPassword: 'pass',
      );
      const result2 = LoginFlowResult(
        server: 'https://nc2.example.com',
        loginName: 'user',
        appPassword: 'pass',
      );

      expect(result1, isNot(equals(result2)));
    });

    test('equality - different loginName', () {
      const result1 = LoginFlowResult(
        server: 'https://nc.example.com',
        loginName: 'user1',
        appPassword: 'pass',
      );
      const result2 = LoginFlowResult(
        server: 'https://nc.example.com',
        loginName: 'user2',
        appPassword: 'pass',
      );

      expect(result1, isNot(equals(result2)));
    });

    test('equality - different appPassword', () {
      const result1 = LoginFlowResult(
        server: 'https://nc.example.com',
        loginName: 'user',
        appPassword: 'pass1',
      );
      const result2 = LoginFlowResult(
        server: 'https://nc.example.com',
        loginName: 'user',
        appPassword: 'pass2',
      );

      expect(result1, isNot(equals(result2)));
    });

    test('props returns correct list', () {
      const result = LoginFlowResult(
        server: 'server',
        loginName: 'login',
        appPassword: 'password',
      );

      expect(result.props, ['server', 'login', 'password']);
    });

    test('handles special characters in credentials', () {
      const result = LoginFlowResult(
        server: 'https://my-cloud.example.com:8443',
        loginName: 'user@domain.com',
        appPassword: 'p@ss:word/with!special#chars',
      );

      expect(result.server, 'https://my-cloud.example.com:8443');
      expect(result.loginName, 'user@domain.com');
      expect(result.appPassword, 'p@ss:word/with!special#chars');
    });
  });
}
