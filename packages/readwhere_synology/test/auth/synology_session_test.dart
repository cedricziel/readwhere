import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_synology/readwhere_synology.dart';

void main() {
  group('SynologySession', () {
    test('creates session with required fields', () {
      final now = DateTime.now();
      final session = SynologySession(
        catalogId: 'cat1',
        serverUrl: 'https://nas.example.com',
        sessionId: 'sid123',
        deviceId: 'dev456',
        createdAt: now,
      );

      expect(session.catalogId, equals('cat1'));
      expect(session.serverUrl, equals('https://nas.example.com'));
      expect(session.sessionId, equals('sid123'));
      expect(session.deviceId, equals('dev456'));
      expect(session.createdAt, equals(now));
      expect(session.expiresAt, isNull);
    });

    group('isExpired', () {
      test('returns false for recent session without expiry', () {
        final session = SynologySession(
          catalogId: 'cat1',
          serverUrl: 'https://nas.example.com',
          sessionId: 'sid123',
          deviceId: 'dev456',
          createdAt: DateTime.now(),
        );

        expect(session.isExpired, isFalse);
      });

      test('returns true for old session without expiry', () {
        final session = SynologySession(
          catalogId: 'cat1',
          serverUrl: 'https://nas.example.com',
          sessionId: 'sid123',
          deviceId: 'dev456',
          createdAt: DateTime.now().subtract(const Duration(hours: 25)),
        );

        expect(session.isExpired, isTrue);
      });

      test('returns false for session before expiry time', () {
        final session = SynologySession(
          catalogId: 'cat1',
          serverUrl: 'https://nas.example.com',
          sessionId: 'sid123',
          deviceId: 'dev456',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(session.isExpired, isFalse);
      });

      test('returns true for session after expiry time', () {
        final session = SynologySession(
          catalogId: 'cat1',
          serverUrl: 'https://nas.example.com',
          sessionId: 'sid123',
          deviceId: 'dev456',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(session.isExpired, isTrue);
      });
    });

    group('JSON serialization', () {
      test('toJson produces valid JSON', () {
        final now = DateTime.now();
        final expiry = now.add(const Duration(hours: 24));
        final session = SynologySession(
          catalogId: 'cat1',
          serverUrl: 'https://nas.example.com',
          sessionId: 'sid123',
          deviceId: 'dev456',
          createdAt: now,
          expiresAt: expiry,
        );

        final json = session.toJson();

        expect(json['catalogId'], equals('cat1'));
        expect(json['serverUrl'], equals('https://nas.example.com'));
        expect(json['sessionId'], equals('sid123'));
        expect(json['deviceId'], equals('dev456'));
        expect(json['createdAt'], equals(now.toIso8601String()));
        expect(json['expiresAt'], equals(expiry.toIso8601String()));
      });

      test('fromJson restores session correctly', () {
        final now = DateTime.now();
        final json = {
          'catalogId': 'cat1',
          'serverUrl': 'https://nas.example.com',
          'sessionId': 'sid123',
          'deviceId': 'dev456',
          'createdAt': now.toIso8601String(),
          'expiresAt': null,
        };

        final session = SynologySession.fromJson(json);

        expect(session.catalogId, equals('cat1'));
        expect(session.serverUrl, equals('https://nas.example.com'));
        expect(session.sessionId, equals('sid123'));
        expect(session.deviceId, equals('dev456'));
        expect(session.expiresAt, isNull);
      });

      test('round-trip serialization preserves data', () {
        final original = SynologySession(
          catalogId: 'cat1',
          serverUrl: 'https://nas.example.com',
          sessionId: 'sid123',
          deviceId: 'dev456',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );

        final jsonString = original.toJsonString();
        final restored = SynologySession.fromJsonString(jsonString);

        expect(restored.catalogId, equals(original.catalogId));
        expect(restored.serverUrl, equals(original.serverUrl));
        expect(restored.sessionId, equals(original.sessionId));
        expect(restored.deviceId, equals(original.deviceId));
      });
    });

    test('equality works correctly', () {
      final now = DateTime.now();
      final session1 = SynologySession(
        catalogId: 'cat1',
        serverUrl: 'https://nas.example.com',
        sessionId: 'sid123',
        deviceId: 'dev456',
        createdAt: now,
      );
      final session2 = SynologySession(
        catalogId: 'cat1',
        serverUrl: 'https://nas.example.com',
        sessionId: 'sid123',
        deviceId: 'dev456',
        createdAt: now,
      );
      final session3 = SynologySession(
        catalogId: 'cat2',
        serverUrl: 'https://other.example.com',
        sessionId: 'sid789',
        deviceId: 'dev101',
        createdAt: now,
      );

      expect(session1, equals(session2));
      expect(session1, isNot(equals(session3)));
    });

    test('toString returns readable format', () {
      final session = SynologySession(
        catalogId: 'cat1',
        serverUrl: 'https://nas.example.com',
        sessionId: 'session123456789',
        deviceId: 'dev456',
        createdAt: DateTime.now(),
      );

      final str = session.toString();
      expect(str, contains('cat1'));
      expect(str, contains('nas.example.com'));
      expect(str, contains('session1'));
      expect(str, contains('isExpired'));
    });
  });
}
