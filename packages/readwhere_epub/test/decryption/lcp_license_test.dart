import 'dart:convert';

import 'package:readwhere_epub/src/decryption/lcp_license.dart';
import 'package:test/test.dart';

void main() {
  group('LcpLicense', () {
    test('parses minimal valid license', () {
      final json = jsonEncode({
        'id': 'test-license-id',
        'encryption': {
          'profile': 'http://readium.org/lcp/basic-profile',
          'content_key': {
            'encrypted_value': base64Encode([1, 2, 3, 4]),
          },
        },
      });

      final license = LcpLicense.parse(json);

      expect(license.id, equals('test-license-id'));
      expect(license.profile, equals('http://readium.org/lcp/basic-profile'));
      expect(license.encryptedContentKey, equals(base64Encode([1, 2, 3, 4])));
    });

    test('parses full license with all fields', () {
      final json = jsonEncode({
        'id': 'license-123',
        'issued': '2024-01-15T10:30:00Z',
        'provider': 'https://example.com/provider',
        'encryption': {
          'profile': 'http://readium.org/lcp/basic-profile',
          'content_key': {
            'encrypted_value': base64Encode([1, 2, 3]),
            'algorithm': 'http://www.w3.org/2001/04/xmlenc#aes256-cbc',
          },
          'user_key': {
            'algorithm': 'http://www.w3.org/2001/04/xmlenc#sha256',
            'text_hint': 'Enter your library card number',
          },
        },
        'rights': {
          'print': 10,
          'copy': 100,
          'start': '2024-01-15T00:00:00Z',
          'end': '2025-01-15T00:00:00Z',
        },
        'links': [
          {
            'rel': 'publication',
            'href': 'https://example.com/book.epub',
            'type': 'application/epub+zip',
            'title': 'My Book',
          },
        ],
      });

      final license = LcpLicense.parse(json);

      expect(license.id, equals('license-123'));
      expect(license.issued, isNotNull);
      expect(license.provider, equals('https://example.com/provider'));
      expect(license.contentKeyAlgorithm, equals('http://www.w3.org/2001/04/xmlenc#aes256-cbc'));
      expect(license.userKeyAlgorithm, equals('http://www.w3.org/2001/04/xmlenc#sha256'));
      expect(license.userKeyHint, equals('Enter your library card number'));
      expect(license.rights?.print, equals(10));
      expect(license.rights?.copy, equals(100));
      expect(license.rights?.start, isNotNull);
      expect(license.rights?.end, isNotNull);
      expect(license.links.length, equals(1));
      expect(license.links[0].rel, equals('publication'));
    });

    test('uses default algorithms when not specified', () {
      final json = jsonEncode({
        'id': 'test-id',
        'encryption': {
          'profile': 'http://readium.org/lcp/basic-profile',
          'content_key': {
            'encrypted_value': 'AAAA',
          },
        },
      });

      final license = LcpLicense.parse(json);

      expect(license.contentKeyAlgorithm, equals('http://www.w3.org/2001/04/xmlenc#aes256-cbc'));
      expect(license.userKeyAlgorithm, equals('http://www.w3.org/2001/04/xmlenc#sha256'));
    });

    test('throws for missing id', () {
      final json = jsonEncode({
        'encryption': {
          'profile': 'http://readium.org/lcp/basic-profile',
          'content_key': {'encrypted_value': 'AAAA'},
        },
      });

      expect(() => LcpLicense.parse(json), throwsA(isA<LcpLicenseException>()));
    });

    test('throws for missing encryption', () {
      final json = jsonEncode({
        'id': 'test-id',
      });

      expect(() => LcpLicense.parse(json), throwsA(isA<LcpLicenseException>()));
    });

    test('throws for missing profile', () {
      final json = jsonEncode({
        'id': 'test-id',
        'encryption': {
          'content_key': {'encrypted_value': 'AAAA'},
        },
      });

      expect(() => LcpLicense.parse(json), throwsA(isA<LcpLicenseException>()));
    });

    test('throws for missing content_key', () {
      final json = jsonEncode({
        'id': 'test-id',
        'encryption': {
          'profile': 'http://readium.org/lcp/basic-profile',
        },
      });

      expect(() => LcpLicense.parse(json), throwsA(isA<LcpLicenseException>()));
    });

    test('throws for missing encrypted_value', () {
      final json = jsonEncode({
        'id': 'test-id',
        'encryption': {
          'profile': 'http://readium.org/lcp/basic-profile',
          'content_key': {},
        },
      });

      expect(() => LcpLicense.parse(json), throwsA(isA<LcpLicenseException>()));
    });

    test('throws for invalid JSON', () {
      expect(() => LcpLicense.parse('not valid json'), throwsA(isA<LcpLicenseException>()));
    });

    test('isBasicProfile returns true for basic profile', () {
      final json = jsonEncode({
        'id': 'test-id',
        'encryption': {
          'profile': 'http://readium.org/lcp/basic-profile',
          'content_key': {'encrypted_value': 'AAAA'},
        },
      });

      final license = LcpLicense.parse(json);
      expect(license.isBasicProfile, isTrue);
    });

    test('isBasicProfile returns false for other profiles', () {
      final json = jsonEncode({
        'id': 'test-id',
        'encryption': {
          'profile': 'http://readium.org/lcp/production-profile',
          'content_key': {'encrypted_value': 'AAAA'},
        },
      });

      final license = LcpLicense.parse(json);
      expect(license.isBasicProfile, isFalse);
    });

    test('isValid returns true when no rights specified', () {
      final json = jsonEncode({
        'id': 'test-id',
        'encryption': {
          'profile': 'http://readium.org/lcp/basic-profile',
          'content_key': {'encrypted_value': 'AAAA'},
        },
      });

      final license = LcpLicense.parse(json);
      expect(license.isValid, isTrue);
    });

    test('isValid returns false for expired license', () {
      final json = jsonEncode({
        'id': 'test-id',
        'encryption': {
          'profile': 'http://readium.org/lcp/basic-profile',
          'content_key': {'encrypted_value': 'AAAA'},
        },
        'rights': {
          'end': '2020-01-01T00:00:00Z', // Past date
        },
      });

      final license = LcpLicense.parse(json);
      expect(license.isValid, isFalse);
    });

    test('isValid returns false before start date', () {
      final json = jsonEncode({
        'id': 'test-id',
        'encryption': {
          'profile': 'http://readium.org/lcp/basic-profile',
          'content_key': {'encrypted_value': 'AAAA'},
        },
        'rights': {
          'start': '2099-01-01T00:00:00Z', // Future date
        },
      });

      final license = LcpLicense.parse(json);
      expect(license.isValid, isFalse);
    });
  });

  group('LcpRights', () {
    test('parses all fields', () {
      final rights = LcpRights.fromJson({
        'print': 5,
        'copy': 50,
        'start': '2024-01-01T00:00:00Z',
        'end': '2024-12-31T23:59:59Z',
      });

      expect(rights.print, equals(5));
      expect(rights.copy, equals(50));
      expect(rights.start, isNotNull);
      expect(rights.end, isNotNull);
    });

    test('handles missing fields', () {
      final rights = LcpRights.fromJson({});

      expect(rights.print, isNull);
      expect(rights.copy, isNull);
      expect(rights.start, isNull);
      expect(rights.end, isNull);
    });
  });

  group('LcpLink', () {
    test('parses all fields', () {
      final link = LcpLink.fromJson({
        'rel': 'publication',
        'href': 'https://example.com/book.epub',
        'type': 'application/epub+zip',
        'title': 'My Book',
      });

      expect(link.rel, equals('publication'));
      expect(link.href, equals('https://example.com/book.epub'));
      expect(link.type, equals('application/epub+zip'));
      expect(link.title, equals('My Book'));
    });

    test('handles missing optional fields', () {
      final link = LcpLink.fromJson({
        'rel': 'hint',
        'href': 'https://example.com/hint',
      });

      expect(link.rel, equals('hint'));
      expect(link.href, equals('https://example.com/hint'));
      expect(link.type, isNull);
      expect(link.title, isNull);
    });

    test('uses empty strings for missing required fields', () {
      final link = LcpLink.fromJson({});

      expect(link.rel, equals(''));
      expect(link.href, equals(''));
    });
  });
}
