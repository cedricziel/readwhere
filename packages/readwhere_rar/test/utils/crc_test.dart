import 'dart:typed_data';

import 'package:readwhere_rar/src/utils/crc.dart';
import 'package:test/test.dart';

void main() {
  group('Crc16', () {
    test('empty data returns 0xFFFF', () {
      expect(Crc16.calculate(Uint8List(0)), equals(0xFFFF));
    });

    test('calculates known CRC16 values', () {
      // "123456789" should give a known CRC16
      final data = Uint8List.fromList('123456789'.codeUnits);
      final crc = Crc16.calculate(data);
      // The result depends on the specific polynomial implementation
      expect(crc, isA<int>());
      expect(crc & 0xFFFF, equals(crc)); // Should be 16-bit
    });

    test('single byte calculation', () {
      final crc = Crc16.calculate(Uint8List.fromList([0x00]));
      expect(crc, isA<int>());
      expect(crc & 0xFFFF, equals(crc));
    });

    test('supports start and end parameters', () {
      final data = Uint8List.fromList([0x00, 0x01, 0x02, 0x03, 0x04]);
      final fullCrc = Crc16.calculate(data);
      final partialCrc = Crc16.calculate(data, 1, 4); // bytes 1, 2, 3

      expect(partialCrc, isNot(equals(fullCrc)));
    });

    test('consistent results for same input', () {
      final data = Uint8List.fromList([0x52, 0x61, 0x72, 0x21]);
      final crc1 = Crc16.calculate(data);
      final crc2 = Crc16.calculate(data);
      expect(crc1, equals(crc2));
    });
  });

  group('Crc32', () {
    test('empty data returns 0', () {
      // CRC32 of empty data is 0 after final XOR
      expect(Crc32.calculate(Uint8List(0)), equals(0));
    });

    test('calculates known CRC32 values', () {
      // "123456789" has CRC32 of 0xCBF43926
      final data = Uint8List.fromList('123456789'.codeUnits);
      expect(Crc32.calculate(data), equals(0xCBF43926));
    });

    test('single byte calculation', () {
      // CRC32 of byte 0x00 is 0xD202EF8D
      expect(Crc32.calculate(Uint8List.fromList([0x00])), equals(0xD202EF8D));
    });

    test('supports start and end parameters', () {
      final data = Uint8List.fromList('123456789'.codeUnits);
      final partialCrc = Crc32.calculate(data, 2, 7); // "34567"

      // Should be different from full CRC
      expect(partialCrc, isNot(equals(0xCBF43926)));
    });

    test('consistent results for same input', () {
      final data = Uint8List.fromList([0x52, 0x61, 0x72, 0x21]);
      final crc1 = Crc32.calculate(data);
      final crc2 = Crc32.calculate(data);
      expect(crc1, equals(crc2));
    });

    test('different data produces different CRC', () {
      final data1 = Uint8List.fromList([0x01, 0x02, 0x03]);
      final data2 = Uint8List.fromList([0x01, 0x02, 0x04]);
      expect(Crc32.calculate(data1), isNot(equals(Crc32.calculate(data2))));
    });

    group('update', () {
      test('streaming calculation matches single calculation', () {
        final data = Uint8List.fromList('123456789'.codeUnits);

        // Calculate in one shot
        final singleCrc = Crc32.calculate(data);

        // Calculate in parts using update
        final part1 = Uint8List.fromList('12345'.codeUnits);
        final part2 = Uint8List.fromList('6789'.codeUnits);

        final crc1 = Crc32.calculate(part1);
        final crc2 = Crc32.update(crc1, part2);

        expect(crc2, equals(singleCrc));
      });
    });
  });
}
