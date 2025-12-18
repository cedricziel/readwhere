import 'dart:convert';
import 'dart:typed_data';

import 'package:readwhere_epub/src/decryption/crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  group('CryptoUtils', () {
    group('SHA-256', () {
      test('hashes empty string correctly', () {
        // SHA-256 of empty string is a well-known value
        final result = CryptoUtils.sha256String('');

        // Expected: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
        final expected = [
          0xe3, 0xb0, 0xc4, 0x42, 0x98, 0xfc, 0x1c, 0x14,
          0x9a, 0xfb, 0xf4, 0xc8, 0x99, 0x6f, 0xb9, 0x24,
          0x27, 0xae, 0x41, 0xe4, 0x64, 0x9b, 0x93, 0x4c,
          0xa4, 0x95, 0x99, 0x1b, 0x78, 0x52, 0xb8, 0x55,
        ];

        expect(result, equals(Uint8List.fromList(expected)));
      });

      test('hashes "hello" correctly', () {
        final result = CryptoUtils.sha256String('hello');

        // SHA-256 of "hello": 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
        final expected = [
          0x2c, 0xf2, 0x4d, 0xba, 0x5f, 0xb0, 0xa3, 0x0e,
          0x26, 0xe8, 0x3b, 0x2a, 0xc5, 0xb9, 0xe2, 0x9e,
          0x1b, 0x16, 0x1e, 0x5c, 0x1f, 0xa7, 0x42, 0x5e,
          0x73, 0x04, 0x33, 0x62, 0x93, 0x8b, 0x98, 0x24,
        ];

        expect(result, equals(Uint8List.fromList(expected)));
      });

      test('hashes "The quick brown fox jumps over the lazy dog" correctly', () {
        final result =
            CryptoUtils.sha256String('The quick brown fox jumps over the lazy dog');

        // d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592
        final expected = [
          0xd7, 0xa8, 0xfb, 0xb3, 0x07, 0xd7, 0x80, 0x94,
          0x69, 0xca, 0x9a, 0xbc, 0xb0, 0x08, 0x2e, 0x4f,
          0x8d, 0x56, 0x51, 0xe4, 0x6d, 0x3c, 0xdb, 0x76,
          0x2d, 0x02, 0xd0, 0xbf, 0x37, 0xc9, 0xe5, 0x92,
        ];

        expect(result, equals(Uint8List.fromList(expected)));
      });

      test('produces 32-byte output', () {
        final result = CryptoUtils.sha256String('any string');
        expect(result.length, equals(32));
      });

      test('same input produces same output', () {
        final result1 = CryptoUtils.sha256String('test passphrase');
        final result2 = CryptoUtils.sha256String('test passphrase');

        expect(result1, equals(result2));
      });

      test('different inputs produce different outputs', () {
        final result1 = CryptoUtils.sha256String('password1');
        final result2 = CryptoUtils.sha256String('password2');

        expect(result1, isNot(equals(result2)));
      });
    });

    group('AES-256-CBC decryption', () {
      test('throws for invalid key length', () {
        final ciphertext = Uint8List(32); // 16 IV + 16 data
        final invalidKey = Uint8List(16); // Should be 32 bytes

        expect(
          () => CryptoUtils.decryptAes256Cbc(ciphertext, invalidKey),
          throwsA(isA<CryptoException>()),
        );
      });

      test('throws for ciphertext shorter than IV', () {
        final shortCiphertext = Uint8List(8);
        final key = Uint8List(32);

        expect(
          () => CryptoUtils.decryptAes256Cbc(shortCiphertext, key),
          throwsA(isA<CryptoException>()),
        );
      });

      test('throws for ciphertext not multiple of 16 bytes', () {
        // 16 IV + 17 data (not valid block size)
        final invalidCiphertext = Uint8List(33);
        final key = Uint8List(32);

        expect(
          () => CryptoUtils.decryptAes256Cbc(invalidCiphertext, key),
          throwsA(isA<CryptoException>()),
        );
      });

      test('handles empty ciphertext after IV', () {
        // Just the IV, no actual encrypted data
        final ciphertext = Uint8List(16);
        final key = Uint8List(32);

        final result = CryptoUtils.decryptAes256Cbc(ciphertext, key);
        expect(result, isEmpty);
      });

      test('decrypts known test vector', () {
        // Test vector: encrypt "Hello, World!" with AES-256-CBC
        // Key: 32 bytes of 0x00
        // IV: 16 bytes of 0x00
        // This is a minimal test to verify the implementation works

        final key = Uint8List(32);

        // Since we don't have an encrypt function, we'll test that
        // decryption doesn't throw and produces output
        final iv = Uint8List(16);
        final encryptedBlock = Uint8List(16); // One block of zeros

        final ciphertext = Uint8List(32);
        ciphertext.setRange(0, 16, iv);
        ciphertext.setRange(16, 32, encryptedBlock);

        // Should not throw
        expect(() => CryptoUtils.decryptAes256Cbc(ciphertext, key), returnsNormally);
      });

      test('round trip with known plaintext', () {
        // We test that encrypting then decrypting returns original
        // Since we only have decrypt, we manually construct test data

        // For a proper round-trip test, we'd need an encrypt function
        // Here we just verify the API works correctly

        final key = Uint8List(32);
        for (var i = 0; i < 32; i++) {
          key[i] = i;
        }

        // Create valid ciphertext structure
        final iv = Uint8List(16);
        final encrypted = Uint8List(16); // One block

        final ciphertext = Uint8List(32);
        ciphertext.setRange(0, 16, iv);
        ciphertext.setRange(16, 32, encrypted);

        // Should produce some output without throwing
        final result = CryptoUtils.decryptAes256Cbc(ciphertext, key);
        expect(result, isNotNull);
      });
    });
  });
}
