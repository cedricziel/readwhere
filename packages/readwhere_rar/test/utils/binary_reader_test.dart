import 'dart:typed_data';

import 'package:readwhere_rar/src/utils/binary_reader.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryReader', () {
    group('readUint8', () {
      test('reads single byte correctly', () {
        final reader = BinaryReader(Uint8List.fromList([0x42]));
        expect(reader.readUint8(), equals(0x42));
        expect(reader.position, equals(1));
      });

      test('throws on empty buffer', () {
        final reader = BinaryReader(Uint8List(0));
        expect(() => reader.readUint8(), throwsA(isA<RangeError>()));
      });

      test('throws when no bytes remaining', () {
        final reader = BinaryReader(Uint8List.fromList([0x42]));
        reader.readUint8();
        expect(() => reader.readUint8(), throwsA(isA<RangeError>()));
      });
    });

    group('readUint16', () {
      test('reads little-endian correctly', () {
        final reader = BinaryReader(Uint8List.fromList([0x34, 0x12]));
        expect(reader.readUint16(), equals(0x1234));
        expect(reader.position, equals(2));
      });

      test('throws when not enough bytes', () {
        final reader = BinaryReader(Uint8List.fromList([0x34]));
        expect(() => reader.readUint16(), throwsA(isA<RangeError>()));
      });
    });

    group('readUint32', () {
      test('reads little-endian correctly', () {
        final reader = BinaryReader(
          Uint8List.fromList([0x78, 0x56, 0x34, 0x12]),
        );
        expect(reader.readUint32(), equals(0x12345678));
        expect(reader.position, equals(4));
      });

      test('handles maximum value', () {
        final reader = BinaryReader(
          Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]),
        );
        expect(reader.readUint32(), equals(0xFFFFFFFF));
      });
    });

    group('readUint64', () {
      test('reads little-endian correctly', () {
        final reader = BinaryReader(
          Uint8List.fromList([
            0xEF, 0xCD, 0xAB, 0x89, // low 32 bits
            0x78, 0x56, 0x34, 0x12, // high 32 bits
          ]),
        );
        expect(reader.readUint64(), equals(0x1234567889ABCDEF));
      });
    });

    group('readBytes', () {
      test('reads correct number of bytes', () {
        final reader = BinaryReader(
          Uint8List.fromList([0x01, 0x02, 0x03, 0x04]),
        );
        final bytes = reader.readBytes(2);
        expect(bytes, equals([0x01, 0x02]));
        expect(reader.position, equals(2));
      });

      test('reading 0 bytes returns empty list', () {
        final reader = BinaryReader(Uint8List.fromList([0x01]));
        final bytes = reader.readBytes(0);
        expect(bytes, isEmpty);
        expect(reader.position, equals(0));
      });

      test('throws on negative count', () {
        final reader = BinaryReader(Uint8List.fromList([0x01]));
        expect(() => reader.readBytes(-1), throwsA(isA<ArgumentError>()));
      });
    });

    group('peekBytes', () {
      test('does not advance position', () {
        final reader = BinaryReader(
          Uint8List.fromList([0x01, 0x02, 0x03]),
        );
        final bytes = reader.peekBytes(2);
        expect(bytes, equals([0x01, 0x02]));
        expect(reader.position, equals(0));
      });
    });

    group('seek', () {
      test('seeks to valid position', () {
        final reader = BinaryReader(Uint8List.fromList([0x01, 0x02, 0x03]));
        reader.seek(2);
        expect(reader.position, equals(2));
        expect(reader.readUint8(), equals(0x03));
      });

      test('throws on negative position', () {
        final reader = BinaryReader(Uint8List.fromList([0x01]));
        expect(() => reader.seek(-1), throwsA(isA<RangeError>()));
      });

      test('throws on position beyond buffer', () {
        final reader = BinaryReader(Uint8List.fromList([0x01]));
        expect(() => reader.seek(2), throwsA(isA<RangeError>()));
      });

      test('allows seeking to end of buffer', () {
        final reader = BinaryReader(Uint8List.fromList([0x01]));
        reader.seek(1);
        expect(reader.position, equals(1));
        expect(reader.hasRemaining, isFalse);
      });
    });

    group('skip', () {
      test('skips correct number of bytes', () {
        final reader = BinaryReader(
          Uint8List.fromList([0x01, 0x02, 0x03]),
        );
        reader.skip(2);
        expect(reader.position, equals(2));
        expect(reader.readUint8(), equals(0x03));
      });

      test('throws on negative count', () {
        final reader = BinaryReader(Uint8List.fromList([0x01]));
        expect(() => reader.skip(-1), throwsA(isA<ArgumentError>()));
      });
    });

    group('remaining', () {
      test('returns correct count', () {
        final reader = BinaryReader(
          Uint8List.fromList([0x01, 0x02, 0x03]),
        );
        expect(reader.remaining, equals(3));
        reader.readUint8();
        expect(reader.remaining, equals(2));
      });
    });

    group('hasRemaining', () {
      test('returns true when bytes remaining', () {
        final reader = BinaryReader(Uint8List.fromList([0x01]));
        expect(reader.hasRemaining, isTrue);
      });

      test('returns false when no bytes remaining', () {
        final reader = BinaryReader(Uint8List.fromList([0x01]));
        reader.readUint8();
        expect(reader.hasRemaining, isFalse);
      });

      test('returns false for empty buffer', () {
        final reader = BinaryReader(Uint8List(0));
        expect(reader.hasRemaining, isFalse);
      });
    });

    group('readFixedString', () {
      test('reads string correctly', () {
        final reader = BinaryReader(
          Uint8List.fromList([0x48, 0x65, 0x6C, 0x6C, 0x6F]),
        );
        expect(reader.readFixedString(5), equals('Hello'));
      });

      test('stops at null byte', () {
        final reader = BinaryReader(
          Uint8List.fromList([0x48, 0x69, 0x00, 0x58, 0x58]),
        );
        expect(reader.readFixedString(5), equals('Hi'));
        expect(reader.position, equals(5)); // Still advances past nulls
      });
    });

    group('readNullTerminatedString', () {
      test('reads until null byte', () {
        final reader = BinaryReader(
          Uint8List.fromList([0x48, 0x69, 0x00, 0x58]),
        );
        expect(reader.readNullTerminatedString(), equals('Hi'));
        expect(reader.position, equals(3)); // Past the null
      });

      test('reads until end if no null', () {
        final reader = BinaryReader(
          Uint8List.fromList([0x48, 0x69]),
        );
        expect(reader.readNullTerminatedString(), equals('Hi'));
        expect(reader.position, equals(2));
      });
    });

    group('subReader', () {
      test('creates sub-reader with correct bounds', () {
        final reader = BinaryReader(
          Uint8List.fromList([0x01, 0x02, 0x03, 0x04, 0x05]),
        );
        reader.skip(1);
        final sub = reader.subReader(3);

        expect(sub.length, equals(3));
        expect(sub.readUint8(), equals(0x02));
        expect(sub.readUint8(), equals(0x03));
        expect(sub.readUint8(), equals(0x04));
        expect(sub.hasRemaining, isFalse);

        // Parent reader advanced
        expect(reader.position, equals(4));
        expect(reader.readUint8(), equals(0x05));
      });
    });
  });
}
