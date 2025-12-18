import 'dart:typed_data';

import 'package:readwhere_epub/src/decryption/font_obfuscation.dart';
import 'package:test/test.dart';

void main() {
  group('FontObfuscation', () {
    group('IDPF obfuscation', () {
      test('deobfuscates font with IDPF algorithm', () {
        // Create test data
        final uniqueId = 'urn:uuid:12345678-1234-5678-1234-567812345678';

        // Create some "obfuscated" data by applying obfuscation first
        // Then verify deobfuscation returns original
        final original = Uint8List.fromList(List.generate(2000, (i) => i % 256));

        // Obfuscate (same algorithm as deobfuscate since XOR is symmetric)
        final obfuscated = FontObfuscation.deobfuscateIdpf(original, uniqueId);

        // Deobfuscate
        final deobfuscated = FontObfuscation.deobfuscateIdpf(obfuscated, uniqueId);

        // Should return to original
        expect(deobfuscated, equals(original));
      });

      test('only modifies first 1040 bytes', () {
        final uniqueId = 'test-unique-id-12345';

        // Create data longer than 1040 bytes
        final original = Uint8List.fromList(List.generate(2000, (i) => i % 256));

        // Obfuscate
        final obfuscated = FontObfuscation.deobfuscateIdpf(original, uniqueId);

        // Bytes after 1040 should be unchanged
        for (var i = 1040; i < 2000; i++) {
          expect(obfuscated[i], equals(original[i]),
              reason: 'Byte at position $i should be unchanged');
        }

        // First 1040 bytes should be different (with high probability)
        var differentCount = 0;
        for (var i = 0; i < 1040; i++) {
          if (obfuscated[i] != original[i]) differentCount++;
        }
        expect(differentCount, greaterThan(0),
            reason: 'At least some bytes in first 1040 should be changed');
      });

      test('handles data shorter than 1040 bytes', () {
        final uniqueId = 'short-test-id';
        final original = Uint8List.fromList([1, 2, 3, 4, 5]);

        // Should not throw
        final obfuscated = FontObfuscation.deobfuscateIdpf(original, uniqueId);
        expect(obfuscated.length, equals(original.length));

        // Round-trip should work
        final deobfuscated = FontObfuscation.deobfuscateIdpf(obfuscated, uniqueId);
        expect(deobfuscated, equals(original));
      });

      test('handles empty data', () {
        final uniqueId = 'test-id';
        final original = Uint8List(0);

        final result = FontObfuscation.deobfuscateIdpf(original, uniqueId);
        expect(result, isEmpty);
      });

      test('strips whitespace from unique identifier', () {
        // Per spec, whitespace should be stripped from the identifier
        final idWithSpaces = 'urn:uuid:12345678-1234-5678-1234-567812345678';
        final idWithWhitespace = '  urn:uuid:12345678-1234-5678-1234-567812345678  \n\t';

        final original = Uint8List.fromList(List.generate(100, (i) => i));

        final result1 = FontObfuscation.deobfuscateIdpf(original, idWithSpaces);
        final result2 = FontObfuscation.deobfuscateIdpf(original, idWithWhitespace);

        expect(result1, equals(result2),
            reason: 'Whitespace in identifier should not affect result');
      });
    });

    group('Adobe obfuscation', () {
      test('deobfuscates font with Adobe algorithm', () {
        // UUID format for Adobe
        final uniqueId = 'urn:uuid:12345678-1234-5678-1234-567812345678';

        final original = Uint8List.fromList(List.generate(2000, (i) => i % 256));

        // Obfuscate
        final obfuscated = FontObfuscation.deobfuscateAdobe(original, uniqueId);

        // Deobfuscate (XOR is symmetric)
        final deobfuscated = FontObfuscation.deobfuscateAdobe(obfuscated, uniqueId);

        expect(deobfuscated, equals(original));
      });

      test('handles UUID without urn:uuid: prefix', () {
        final withPrefix = 'urn:uuid:12345678-1234-5678-1234-567812345678';
        final withoutPrefix = '12345678-1234-5678-1234-567812345678';

        final original = Uint8List.fromList(List.generate(100, (i) => i));

        final result1 = FontObfuscation.deobfuscateAdobe(original, withPrefix);
        final result2 = FontObfuscation.deobfuscateAdobe(original, withoutPrefix);

        expect(result1, equals(result2),
            reason: 'urn:uuid: prefix should not affect result');
      });

      test('falls back to IDPF-style key for non-UUID identifiers', () {
        // Non-UUID identifier
        final uniqueId = 'not-a-valid-uuid';

        final original = Uint8List.fromList(List.generate(100, (i) => i));

        // Should not throw
        final obfuscated = FontObfuscation.deobfuscateAdobe(original, uniqueId);
        expect(obfuscated.length, equals(original.length));

        // Round-trip should work
        final deobfuscated = FontObfuscation.deobfuscateAdobe(obfuscated, uniqueId);
        expect(deobfuscated, equals(original));
      });
    });

    group('deobfuscate (generic)', () {
      test('uses IDPF algorithm for IDPF URI', () {
        final uniqueId = 'test-id';
        final data = Uint8List.fromList(List.generate(100, (i) => i));

        final resultIdpf = FontObfuscation.deobfuscate(
          data,
          uniqueId,
          'http://www.idpf.org/2008/embedding',
        );

        final resultDirect = FontObfuscation.deobfuscateIdpf(data, uniqueId);

        expect(resultIdpf, equals(resultDirect));
      });

      test('uses Adobe algorithm for Adobe URI', () {
        final uniqueId = 'urn:uuid:12345678-1234-5678-1234-567812345678';
        final data = Uint8List.fromList(List.generate(100, (i) => i));

        final resultAdobe = FontObfuscation.deobfuscate(
          data,
          uniqueId,
          'http://ns.adobe.com/pdf/enc#RC',
        );

        final resultDirect = FontObfuscation.deobfuscateAdobe(data, uniqueId);

        expect(resultAdobe, equals(resultDirect));
      });

      test('returns data unchanged for unknown algorithm', () {
        final uniqueId = 'test-id';
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);

        final result = FontObfuscation.deobfuscate(
          data,
          uniqueId,
          'http://example.com/unknown-algorithm',
        );

        expect(result, equals(data));
      });
    });
  });
}
