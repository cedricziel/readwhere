import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_synology/readwhere_synology.dart';

void main() {
  group('LoginResult', () {
    test('fromJson parses successful login', () {
      final json = {
        'success': true,
        'data': {
          'did': 'device123',
          'sid': 'session456',
        },
      };

      final result = LoginResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.deviceId, equals('device123'));
      expect(result.sessionId, equals('session456'));
      expect(result.errorCode, isNull);
      expect(result.errorMessage, isNull);
    });

    test('fromJson parses failed login with error code', () {
      final json = {
        'success': false,
        'error': {
          'code': 400,
        },
      };

      final result = LoginResult.fromJson(json);

      expect(result.success, isFalse);
      expect(result.deviceId, isNull);
      expect(result.sessionId, isNull);
      expect(result.errorCode, equals(400));
      expect(result.errorMessage, equals('Invalid username or password'));
    });

    test('errorMessage returns correct messages for known error codes', () {
      expect(
        LoginResult.fromJson({
          'success': false,
          'error': {'code': 400}
        }).errorMessage,
        equals('Invalid username or password'),
      );
      expect(
        LoginResult.fromJson({
          'success': false,
          'error': {'code': 401}
        }).errorMessage,
        equals('Account disabled'),
      );
      expect(
        LoginResult.fromJson({
          'success': false,
          'error': {'code': 402}
        }).errorMessage,
        equals('Permission denied'),
      );
      expect(
        LoginResult.fromJson({
          'success': false,
          'error': {'code': 403}
        }).errorMessage,
        equals('Two-factor authentication required'),
      );
      expect(
        LoginResult.fromJson({
          'success': false,
          'error': {'code': 407}
        }).errorMessage,
        equals('Blocked IP address'),
      );
    });

    test('errorMessage returns generic message for unknown error codes', () {
      final result = LoginResult.fromJson({
        'success': false,
        'error': {'code': 999},
      });

      expect(result.errorMessage, equals('Login failed (code: 999)'));
    });

    test('props are correct for equality comparison', () {
      const result1 = LoginResult(
        success: true,
        deviceId: 'dev1',
        sessionId: 'sess1',
      );
      const result2 = LoginResult(
        success: true,
        deviceId: 'dev1',
        sessionId: 'sess1',
      );
      const result3 = LoginResult(
        success: true,
        deviceId: 'dev2',
        sessionId: 'sess2',
      );

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });

    test('toString returns readable format', () {
      const successResult = LoginResult(
        success: true,
        deviceId: 'dev1',
        sessionId: 'session12345678',
      );
      expect(
        successResult.toString(),
        contains('success: true'),
      );
      expect(
        successResult.toString(),
        contains('session1'),
      );

      const failResult = LoginResult(
        success: false,
        errorCode: 400,
      );
      expect(
        failResult.toString(),
        contains('success: false'),
      );
      expect(
        failResult.toString(),
        contains('400'),
      );
    });
  });
}
