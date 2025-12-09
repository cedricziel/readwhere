import 'dart:typed_data';

/// CRC calculation utilities for RAR archive verification.

/// CRC16 calculator for RAR block header verification.
///
/// RAR uses a custom CRC16 with polynomial 0x8005, initial value 0x0000,
/// and no final XOR.
class Crc16 {
  /// Pre-computed CRC16 lookup table.
  static final List<int> _table = _generateTable();

  /// Generates the CRC16 lookup table.
  static List<int> _generateTable() {
    final table = List<int>.filled(256, 0);
    for (var i = 0; i < 256; i++) {
      var crc = i;
      for (var j = 0; j < 8; j++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xA001; // Reflected polynomial 0x8005
        } else {
          crc >>= 1;
        }
      }
      table[i] = crc;
    }
    return table;
  }

  /// Calculates CRC16 for the given data.
  static int calculate(Uint8List data, [int start = 0, int? end]) {
    end ??= data.length;
    var crc = 0xFFFF;
    for (var i = start; i < end; i++) {
      crc = (_table[(crc ^ data[i]) & 0xFF] ^ (crc >> 8)) & 0xFFFF;
    }
    return crc;
  }
}

/// CRC32 calculator for RAR file data verification.
///
/// Uses the standard CRC32 polynomial 0xEDB88320 (reflected form).
class Crc32 {
  /// Pre-computed CRC32 lookup table.
  static final List<int> _table = _generateTable();

  /// Generates the CRC32 lookup table.
  static List<int> _generateTable() {
    final table = List<int>.filled(256, 0);
    for (var i = 0; i < 256; i++) {
      var crc = i;
      for (var j = 0; j < 8; j++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc >>= 1;
        }
      }
      table[i] = crc & 0xFFFFFFFF;
    }
    return table;
  }

  /// Calculates CRC32 for the given data.
  static int calculate(Uint8List data, [int start = 0, int? end]) {
    end ??= data.length;
    var crc = 0xFFFFFFFF;
    for (var i = start; i < end; i++) {
      crc = (_table[(crc ^ data[i]) & 0xFF] ^ (crc >> 8)) & 0xFFFFFFFF;
    }
    return crc ^ 0xFFFFFFFF;
  }

  /// Updates an existing CRC32 with additional data.
  ///
  /// Use this for streaming CRC calculation. The initial CRC should be
  /// the result of a previous [calculate] call, but XOR'd with 0xFFFFFFFF
  /// to convert back to the internal state.
  static int update(int crc, Uint8List data, [int start = 0, int? end]) {
    end ??= data.length;
    // Convert from final to internal state
    crc ^= 0xFFFFFFFF;
    for (var i = start; i < end; i++) {
      crc = (_table[(crc ^ data[i]) & 0xFF] ^ (crc >> 8)) & 0xFFFFFFFF;
    }
    // Convert back to final state
    return crc ^ 0xFFFFFFFF;
  }
}
