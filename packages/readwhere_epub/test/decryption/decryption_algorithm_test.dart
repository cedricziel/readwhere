import 'package:readwhere_epub/src/decryption/decryption_algorithm.dart';
import 'package:test/test.dart';

void main() {
  group('DecryptionAlgorithm', () {
    group('isIdpfFontObfuscation', () {
      test('returns true for IDPF URI', () {
        expect(
          DecryptionAlgorithm.isIdpfFontObfuscation('http://www.idpf.org/2008/embedding'),
          isTrue,
        );
      });

      test('returns false for other URIs', () {
        expect(
          DecryptionAlgorithm.isIdpfFontObfuscation('http://ns.adobe.com/pdf/enc#RC'),
          isFalse,
        );
        expect(
          DecryptionAlgorithm.isIdpfFontObfuscation('http://example.com/other'),
          isFalse,
        );
      });
    });

    group('isAdobeFontObfuscation', () {
      test('returns true for Adobe URI', () {
        expect(
          DecryptionAlgorithm.isAdobeFontObfuscation('http://ns.adobe.com/pdf/enc#RC'),
          isTrue,
        );
      });

      test('returns false for other URIs', () {
        expect(
          DecryptionAlgorithm.isAdobeFontObfuscation('http://www.idpf.org/2008/embedding'),
          isFalse,
        );
      });
    });

    group('isFontObfuscation', () {
      test('returns true for IDPF obfuscation', () {
        expect(
          DecryptionAlgorithm.isFontObfuscation('http://www.idpf.org/2008/embedding'),
          isTrue,
        );
      });

      test('returns true for Adobe obfuscation', () {
        expect(
          DecryptionAlgorithm.isFontObfuscation('http://ns.adobe.com/pdf/enc#RC'),
          isTrue,
        );
      });

      test('returns true for URI containing "obfuscation"', () {
        expect(
          DecryptionAlgorithm.isFontObfuscation('http://example.com/font-obfuscation'),
          isTrue,
        );
      });

      test('returns false for non-obfuscation algorithms', () {
        expect(
          DecryptionAlgorithm.isFontObfuscation('http://www.w3.org/2001/04/xmlenc#aes256-cbc'),
          isFalse,
        );
      });
    });

    group('isLcpEncryption', () {
      test('returns true for AES-256-CBC', () {
        expect(
          DecryptionAlgorithm.isLcpEncryption('http://www.w3.org/2001/04/xmlenc#aes256-cbc'),
          isTrue,
        );
      });

      test('returns true for URI containing "lcp"', () {
        expect(
          DecryptionAlgorithm.isLcpEncryption('http://readium.org/2014/01/lcp#AES256-CBC'),
          isTrue,
        );
      });

      test('returns true for URI containing "readium.org"', () {
        expect(
          DecryptionAlgorithm.isLcpEncryption('http://readium.org/some/path'),
          isTrue,
        );
      });

      test('returns false for other algorithms', () {
        expect(
          DecryptionAlgorithm.isLcpEncryption('http://www.idpf.org/2008/embedding'),
          isFalse,
        );
        expect(
          DecryptionAlgorithm.isLcpEncryption('http://example.com/custom'),
          isFalse,
        );
      });
    });

    group('algorithm constants', () {
      test('IDPF font obfuscation constant', () {
        expect(
          DecryptionAlgorithm.idpfFontObfuscation,
          equals('http://www.idpf.org/2008/embedding'),
        );
      });

      test('Adobe font obfuscation constant', () {
        expect(
          DecryptionAlgorithm.adobeFontObfuscation,
          equals('http://ns.adobe.com/pdf/enc#RC'),
        );
      });

      test('LCP AES-256-CBC constant', () {
        expect(
          DecryptionAlgorithm.lcpAes256Cbc,
          equals('http://www.w3.org/2001/04/xmlenc#aes256-cbc'),
        );
      });

      test('SHA-256 constant', () {
        expect(
          DecryptionAlgorithm.sha256,
          equals('http://www.w3.org/2001/04/xmlenc#sha256'),
        );
      });
    });
  });
}
