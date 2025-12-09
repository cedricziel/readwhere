import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';

void main() {
  group('NextcloudServerInfo', () {
    test('creates instance with required parameters', () {
      const info = NextcloudServerInfo(
        serverName: 'My Nextcloud',
        version: '28.0.1',
        userId: 'testuser',
        displayName: 'Test User',
      );

      expect(info.serverName, 'My Nextcloud');
      expect(info.version, '28.0.1');
      expect(info.userId, 'testuser');
      expect(info.displayName, 'Test User');
      expect(info.email, isNull);
    });

    test('creates instance with email', () {
      const info = NextcloudServerInfo(
        serverName: 'My Nextcloud',
        version: '28.0.1',
        userId: 'testuser',
        displayName: 'Test User',
        email: 'testuser@example.com',
      );

      expect(info.serverName, 'My Nextcloud');
      expect(info.version, '28.0.1');
      expect(info.userId, 'testuser');
      expect(info.displayName, 'Test User');
      expect(info.email, 'testuser@example.com');
    });

    test('equality - equal instances without email', () {
      const info1 = NextcloudServerInfo(
        serverName: 'Cloud',
        version: '28.0.0',
        userId: 'user1',
        displayName: 'User One',
      );
      const info2 = NextcloudServerInfo(
        serverName: 'Cloud',
        version: '28.0.0',
        userId: 'user1',
        displayName: 'User One',
      );

      expect(info1, equals(info2));
      expect(info1.hashCode, info2.hashCode);
    });

    test('equality - equal instances with email', () {
      const info1 = NextcloudServerInfo(
        serverName: 'Cloud',
        version: '28.0.0',
        userId: 'user1',
        displayName: 'User One',
        email: 'user1@example.com',
      );
      const info2 = NextcloudServerInfo(
        serverName: 'Cloud',
        version: '28.0.0',
        userId: 'user1',
        displayName: 'User One',
        email: 'user1@example.com',
      );

      expect(info1, equals(info2));
      expect(info1.hashCode, info2.hashCode);
    });

    test('equality - different serverName', () {
      const info1 = NextcloudServerInfo(
        serverName: 'Cloud 1',
        version: '28.0.0',
        userId: 'user',
        displayName: 'User',
      );
      const info2 = NextcloudServerInfo(
        serverName: 'Cloud 2',
        version: '28.0.0',
        userId: 'user',
        displayName: 'User',
      );

      expect(info1, isNot(equals(info2)));
    });

    test('equality - different version', () {
      const info1 = NextcloudServerInfo(
        serverName: 'Cloud',
        version: '27.0.0',
        userId: 'user',
        displayName: 'User',
      );
      const info2 = NextcloudServerInfo(
        serverName: 'Cloud',
        version: '28.0.0',
        userId: 'user',
        displayName: 'User',
      );

      expect(info1, isNot(equals(info2)));
    });

    test('equality - different email (one null)', () {
      const info1 = NextcloudServerInfo(
        serverName: 'Cloud',
        version: '28.0.0',
        userId: 'user',
        displayName: 'User',
      );
      const info2 = NextcloudServerInfo(
        serverName: 'Cloud',
        version: '28.0.0',
        userId: 'user',
        displayName: 'User',
        email: 'user@example.com',
      );

      expect(info1, isNot(equals(info2)));
    });

    test('props returns correct list', () {
      const info = NextcloudServerInfo(
        serverName: 'Server',
        version: '1.0',
        userId: 'uid',
        displayName: 'Name',
        email: 'email@test.com',
      );

      expect(info.props, ['Server', '1.0', 'uid', 'Name', 'email@test.com']);
    });

    test('props returns correct list with null email', () {
      const info = NextcloudServerInfo(
        serverName: 'Server',
        version: '1.0',
        userId: 'uid',
        displayName: 'Name',
      );

      expect(info.props, ['Server', '1.0', 'uid', 'Name', null]);
    });
  });
}
