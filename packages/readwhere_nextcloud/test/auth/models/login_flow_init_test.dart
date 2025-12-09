import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';

void main() {
  group('LoginFlowInit', () {
    test('creates instance with required parameters', () {
      const init = LoginFlowInit(
        loginUrl: 'https://nextcloud.example.com/login/v2/flow',
        pollEndpoint: 'https://nextcloud.example.com/login/v2/poll',
        pollToken: 'abc123token',
      );

      expect(init.loginUrl, 'https://nextcloud.example.com/login/v2/flow');
      expect(init.pollEndpoint, 'https://nextcloud.example.com/login/v2/poll');
      expect(init.pollToken, 'abc123token');
    });

    test('equality - equal instances', () {
      const init1 = LoginFlowInit(
        loginUrl: 'https://nc.example.com/login',
        pollEndpoint: 'https://nc.example.com/poll',
        pollToken: 'token123',
      );
      const init2 = LoginFlowInit(
        loginUrl: 'https://nc.example.com/login',
        pollEndpoint: 'https://nc.example.com/poll',
        pollToken: 'token123',
      );

      expect(init1, equals(init2));
      expect(init1.hashCode, init2.hashCode);
    });

    test('equality - different instances', () {
      const init1 = LoginFlowInit(
        loginUrl: 'https://nc1.example.com/login',
        pollEndpoint: 'https://nc1.example.com/poll',
        pollToken: 'token1',
      );
      const init2 = LoginFlowInit(
        loginUrl: 'https://nc2.example.com/login',
        pollEndpoint: 'https://nc2.example.com/poll',
        pollToken: 'token2',
      );

      expect(init1, isNot(equals(init2)));
    });

    test('props returns correct list', () {
      const init = LoginFlowInit(
        loginUrl: 'login',
        pollEndpoint: 'poll',
        pollToken: 'token',
      );

      expect(init.props, ['login', 'poll', 'token']);
    });

    test('is immutable', () {
      const init = LoginFlowInit(
        loginUrl: 'https://nc.example.com/login',
        pollEndpoint: 'https://nc.example.com/poll',
        pollToken: 'token',
      );

      // Verify that all fields are final (no setters)
      expect(init.loginUrl, isNotNull);
      expect(init.pollEndpoint, isNotNull);
      expect(init.pollToken, isNotNull);
    });
  });
}
