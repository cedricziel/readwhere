import 'dart:typed_data';

import '../errors/rar_exception.dart';

/// RAR decompression constants.
class RarConst {
  // Decode table sizes
  static const int nc = 299; // Literal/length codes
  static const int dc = 60; // Distance codes
  static const int ldc = 17; // Low distance codes
  static const int rc = 28; // Repeat codes
  static const int bc = 20; // Bit length codes

  // Combined table size: NC + DC + LDC + RC
  static const int tableSize = nc + dc + ldc + rc; // 404

  // Window size for RAR 2.9+
  static const int maxWinSize = 0x400000; // 4MB
  static const int maxWinMask = maxWinSize - 1;

  // Length decode table
  static const List<int> lengthBases = [
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    10,
    12,
    14,
    16,
    20,
    24,
    28,
    32,
    40,
    48,
    56,
    64,
    80,
    96,
    112,
    128,
    160,
    192,
    224,
  ];

  static const List<int> lengthBits = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    1,
    1,
    1,
    2,
    2,
    2,
    2,
    3,
    3,
    3,
    3,
    4,
    4,
    4,
    4,
    5,
    5,
    5,
    5,
  ];

  // Short distance decode (for codes 263-270)
  static const List<int> shortDistBases = [0, 4, 8, 16, 32, 64, 128, 192];
  static const List<int> shortDistBits = [2, 2, 3, 4, 5, 6, 6, 6];

  // Distance bit length counts for building DDecode/DBits tables
  static const List<int> distBitLengthCounts = [
    4,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    14,
    0,
    12
  ];

  // Low distance repeat count
  static const int lowDistRepCount = 16;
}

/// Bit reader for RAR decompression.
class RarBitReader {
  final Uint8List _data;
  int _bytePos = 0;
  int _bitBuffer = 0;
  int _bitsInBuffer = 0;

  RarBitReader(this._data);

  /// Read bits from the stream.
  int readBits(int count) {
    if (count == 0) return 0;

    while (_bitsInBuffer < count) {
      if (_bytePos >= _data.length) {
        // Pad with zeros at end
        _bitBuffer = (_bitBuffer << 8) & 0xFFFFFFFF;
      } else {
        _bitBuffer = ((_bitBuffer << 8) | _data[_bytePos++]) & 0xFFFFFFFF;
      }
      _bitsInBuffer += 8;
    }

    _bitsInBuffer -= count;
    return (_bitBuffer >> _bitsInBuffer) & ((1 << count) - 1);
  }

  /// Get 16 bits without consuming (for decode).
  int getBits() {
    while (_bitsInBuffer < 16) {
      if (_bytePos >= _data.length) {
        _bitBuffer = (_bitBuffer << 8) & 0xFFFFFFFF;
      } else {
        _bitBuffer = ((_bitBuffer << 8) | _data[_bytePos++]) & 0xFFFFFFFF;
      }
      _bitsInBuffer += 8;
    }
    return (_bitBuffer >> (_bitsInBuffer - 16)) & 0xFFFF;
  }

  /// Skip bits.
  void skipBits(int count) {
    if (count > 0) {
      readBits(count);
    }
  }

  /// Align to byte boundary by skipping remaining bits.
  void byteAlign() {
    final toSkip = _bitsInBuffer & 7;
    if (toSkip > 0) {
      _bitsInBuffer -= toSkip;
    }
  }

  /// Check if more data available.
  bool get hasMore => _bytePos < _data.length || _bitsInBuffer > 0;

  /// Current position in bytes.
  int get position => _bytePos;

  /// Current bit position within the buffer.
  int get bitsInBuffer => _bitsInBuffer;
}

/// Huffman decode table.
class DecodeTable {
  final List<int> decodeLen;
  final List<int> decodePos;
  final List<int> decodeNum;
  int maxNum = 0;

  DecodeTable(int size)
      : decodeLen = List.filled(16, 0),
        decodePos = List.filled(16, 0),
        decodeNum = List.filled(size, 0);
}

/// Build decode tables from bit lengths (matching bitjs algorithm).
void rarMakeDecodeTables(
  List<int> bitLength,
  int offset,
  DecodeTable dec,
  int size,
) {
  final decodeLen = dec.decodeLen;
  final decodePos = dec.decodePos;
  final decodeNum = dec.decodeNum;
  final lenCount = List.filled(16, 0);
  final tmpPos = List.filled(16, 0);

  // Clear decode numbers
  for (var i = decodeNum.length; i-- > 0;) {
    decodeNum[i] = 0;
  }

  // Count codes of each length
  for (var i = 0; i < size; i++) {
    lenCount[bitLength[i + offset] & 0xF]++;
  }

  lenCount[0] = 0;
  tmpPos[0] = 0;
  decodePos[0] = 0;
  decodeLen[0] = 0;

  // Calculate decode lengths and positions
  var n = 0;
  for (var i = 1; i < 16; ++i) {
    n = 2 * (n + lenCount[i]);
    var m = n << (15 - i);
    if (m > 0xFFFF) {
      m = 0xFFFF;
    }
    decodeLen[i] = m;
    decodePos[i] = decodePos[i - 1] + lenCount[i - 1];
    tmpPos[i] = decodePos[i];
  }

  // Fill decode numbers
  for (var i = 0; i < size; ++i) {
    if (bitLength[offset + i] != 0) {
      decodeNum[tmpPos[bitLength[offset + i] & 0xF]++] = i;
    }
  }

  dec.maxNum = size;
}

/// Decode a number using the decode table (matching bitjs algorithm).
int rarDecodeNumber(RarBitReader reader, DecodeTable dec) {
  final decodeLen = dec.decodeLen;
  final decodePos = dec.decodePos;
  final decodeNum = dec.decodeNum;
  final bitField = reader.getBits() & 0xFFFE;

  // Binary search for correct bit length (optimized decision tree)
  int bits;
  if (bitField < decodeLen[8]) {
    if (bitField < decodeLen[4]) {
      if (bitField < decodeLen[2]) {
        bits = (bitField < decodeLen[1]) ? 1 : 2;
      } else {
        bits = (bitField < decodeLen[3]) ? 3 : 4;
      }
    } else {
      if (bitField < decodeLen[6]) {
        bits = (bitField < decodeLen[5]) ? 5 : 6;
      } else {
        bits = (bitField < decodeLen[7]) ? 7 : 8;
      }
    }
  } else {
    if (bitField < decodeLen[12]) {
      if (bitField < decodeLen[10]) {
        bits = (bitField < decodeLen[9]) ? 9 : 10;
      } else {
        bits = (bitField < decodeLen[11]) ? 11 : 12;
      }
    } else {
      if (bitField < decodeLen[14]) {
        bits = (bitField < decodeLen[13]) ? 13 : 14;
      } else {
        bits = 15;
      }
    }
  }

  reader.skipBits(bits);
  final n = decodePos[bits] + ((bitField - decodeLen[bits - 1]) >> (16 - bits));

  if (n >= dec.maxNum) {
    return 0;
  }
  return decodeNum[n];
}

/// RAR 2.9+ (method 29) decompressor.
class Rar29Decompressor {
  final RarBitReader _reader;
  final Uint8List _window;
  int _winPos = 0;
  int _unpSize = 0;

  // Decode tables
  late DecodeTable _ldTable; // Literal/length
  late DecodeTable _ddTable; // Distance
  late DecodeTable _lddTable; // Low distance
  late DecodeTable _rdTable; // Repeat
  late DecodeTable _bdTable; // Bit lengths

  // Previous table for delta encoding
  final List<int> _unpOldTable = List.filled(RarConst.tableSize, 0);

  // Distance history
  final List<int> _oldDist = [0, 0, 0, 0];
  int _lastDist = 0;
  int _lastLen = 0;

  // Tables initialized flag
  bool _tablesRead = false;

  // Distance decode tables (built at initialization)
  late List<int> _dDecode;
  late List<int> _dBits;

  // Low distance repeat state
  int _lowDistRepCount = 0;
  int _prevLowDist = 0;

  Rar29Decompressor(Uint8List data, int unpackedSize)
      : _reader = RarBitReader(data),
        _window = Uint8List(RarConst.maxWinSize),
        _unpSize = unpackedSize {
    _ldTable = DecodeTable(RarConst.nc);
    _ddTable = DecodeTable(RarConst.dc);
    _lddTable = DecodeTable(RarConst.ldc);
    _rdTable = DecodeTable(RarConst.rc);
    _bdTable = DecodeTable(RarConst.bc);

    // Build distance decode tables from bit length counts (matching bitjs)
    _dDecode = List.filled(RarConst.dc, 0);
    _dBits = List.filled(RarConst.dc, 0);
    var dist = 0;
    var bitLength = 0;
    var slot = 0;
    for (var i = 0; i < RarConst.distBitLengthCounts.length; i++, bitLength++) {
      for (var j = 0;
          j < RarConst.distBitLengthCounts[i];
          j++, slot++, dist += (1 << bitLength)) {
        _dDecode[slot] = dist;
        _dBits[slot] = bitLength;
      }
    }
  }

  /// Decompress and return the data.
  Uint8List decompress() {
    _winPos = 0;

    while (_unpSize > 0 && _reader.hasMore) {
      if (!_tablesRead) {
        if (!_readTables()) {
          throw RarFormatException('Failed to read Huffman tables');
        }
        _tablesRead = true;
      }

      _decompressBlock();
    }

    return Uint8List.sublistView(_window, 0, _winPos);
  }

  /// Read Huffman tables. Returns true on success.
  bool _readTables() {
    // Byte-align the bit stream
    _reader.byteAlign();

    // Check for PPM mode (not supported - PPM is a complex statistical compression)
    if (_reader.readBits(1) != 0) {
      throw RarFormatException(
        'PPM compression not supported (file uses mixed LZ77/PPM compression)',
      );
    }

    // Check if we should keep the old table values
    if (_reader.readBits(1) == 0) {
      // Clear old table
      _unpOldTable.fillRange(0, RarConst.tableSize, 0);
    }

    // Read bit lengths for BC (bit length) table
    final bitLength = List.filled(RarConst.bc, 0);
    for (var i = 0; i < RarConst.bc;) {
      final length = _reader.readBits(4);
      if (length == 15) {
        var zeroCount = _reader.readBits(4);
        if (zeroCount == 0) {
          bitLength[i++] = 15;
        } else {
          zeroCount += 2;
          while (zeroCount-- > 0 && i < RarConst.bc) {
            bitLength[i++] = 0;
          }
        }
      } else {
        bitLength[i++] = length;
      }
    }

    // Build BC table
    rarMakeDecodeTables(bitLength, 0, _bdTable, RarConst.bc);

    // Read the combined table (NC + DC + LDC + RC = 404 entries)
    final table = List.filled(RarConst.tableSize, 0);
    for (var i = 0; i < RarConst.tableSize;) {
      final num = rarDecodeNumber(_reader, _bdTable);

      if (num < 16) {
        // Direct value with delta encoding
        table[i] = (_unpOldTable[i] + num) & 0xF;
        i++;
      } else if (num < 18) {
        // 16 or 17: repeat previous value
        int n;
        if (num == 16) {
          n = _reader.readBits(3) + 3; // 3-10 times
        } else {
          n = _reader.readBits(7) + 11; // 11-138 times
        }
        if (i == 0) {
          throw RarFormatException('Invalid repeat at start of table');
        }
        while (n-- > 0 && i < RarConst.tableSize) {
          table[i] = table[i - 1];
          i++;
        }
      } else {
        // 18 or 19: repeat zero
        int n;
        if (num == 18) {
          n = _reader.readBits(3) + 3; // 3-10 times
        } else {
          n = _reader.readBits(7) + 11; // 11-138 times
        }
        while (n-- > 0 && i < RarConst.tableSize) {
          table[i++] = 0;
        }
      }
    }

    // Save table for next block's delta encoding
    for (var i = 0; i < RarConst.tableSize; i++) {
      _unpOldTable[i] = table[i];
    }

    // Build decode tables from combined table
    rarMakeDecodeTables(table, 0, _ldTable, RarConst.nc);
    rarMakeDecodeTables(table, RarConst.nc, _ddTable, RarConst.dc);
    rarMakeDecodeTables(
        table, RarConst.nc + RarConst.dc, _lddTable, RarConst.ldc);
    rarMakeDecodeTables(
      table,
      RarConst.nc + RarConst.dc + RarConst.ldc,
      _rdTable,
      RarConst.rc,
    );

    return true;
  }

  /// Decompress a block.
  void _decompressBlock() {
    while (_unpSize > 0 && _reader.hasMore) {
      final num = rarDecodeNumber(_reader, _ldTable);

      if (num < 256) {
        // Literal byte
        _putByte(num);
      } else if (num == 256) {
        // Block end marker
        if (_reader.readBits(1) != 0) {
          // New tables follow
          _tablesRead = false;
          return;
        }
      } else if (num == 257) {
        // Filter/VM - skip for now
        _skipFilter();
      } else if (num == 258) {
        // Last match repeat
        if (_lastLen > 0) {
          _copyString(_lastDist, _lastLen);
        }
      } else if (num < 263) {
        // Old distance repeat
        final distIdx = num - 259;
        final dist = _oldDist[distIdx];
        final len = _decodeLength();
        _copyString(dist, len);
        _updateOldDist(dist, distIdx);
      } else if (num < 271) {
        // Short distance with fixed length of 2
        final idx = num - 263;
        var dist = RarConst.shortDistBases[idx] + 1;
        final bits = RarConst.shortDistBits[idx];
        if (bits > 0) {
          dist += _reader.readBits(bits);
        }
        _copyString(dist, 2);
        _updateOldDist(dist, -1);
      } else {
        // Length-distance pair
        var len = _decodeLengthFromNum(num - 271);
        final dist = _decodeDistance();

        // Length adjustment for large distances (matching bitjs)
        if (dist >= 0x2000) {
          len++;
          if (dist >= 0x40000) {
            len++;
          }
        }

        _copyString(dist, len);
        _updateOldDist(dist, -1);
      }
    }
  }

  /// Decode length from literal number.
  int _decodeLengthFromNum(int num) {
    if (num < RarConst.lengthBases.length) {
      final bits = RarConst.lengthBits[num];
      return RarConst.lengthBases[num] + _reader.readBits(bits) + 3;
    }
    return 3;
  }

  /// Decode a length value for old distance repeat (+2 base).
  int _decodeLength() {
    final num = rarDecodeNumber(_reader, _rdTable);
    if (num < RarConst.lengthBases.length) {
      final bits = RarConst.lengthBits[num];
      return RarConst.lengthBases[num] + _reader.readBits(bits) + 2;
    }
    return 2;
  }

  /// Decode a distance value (matching bitjs Unpack29 algorithm).
  int _decodeDistance() {
    final distNumber = rarDecodeNumber(_reader, _ddTable);

    var distance = _dDecode[distNumber] + 1;
    final bits = _dBits[distNumber];

    if (bits > 0) {
      if (distNumber > 9) {
        // Large distance: complex handling with low distance repeat
        if (bits > 4) {
          // Read high bits first, shifted left by 4
          distance += ((_reader.getBits() >> (20 - bits)) << 4);
          _reader.skipBits(bits - 4);
        }

        // Handle low distance with repeat mechanism
        if (_lowDistRepCount > 0) {
          _lowDistRepCount--;
          distance += _prevLowDist;
        } else {
          final lowDist = rarDecodeNumber(_reader, _lddTable);
          if (lowDist == 16) {
            // Repeat previous low distance
            _lowDistRepCount = RarConst.lowDistRepCount - 1;
            distance += _prevLowDist;
          } else {
            distance += lowDist;
            _prevLowDist = lowDist;
          }
        }
      } else {
        // Small distance: simple bit read
        distance += _reader.readBits(bits);
      }
    }

    return distance;
  }

  /// Update old distance array.
  void _updateOldDist(int dist, int oldIdx) {
    _lastDist = dist;

    if (oldIdx < 0) {
      // Shift distances and insert new one
      _oldDist[3] = _oldDist[2];
      _oldDist[2] = _oldDist[1];
      _oldDist[1] = _oldDist[0];
      _oldDist[0] = dist;
    } else if (oldIdx > 0) {
      // Move used distance to front
      final d = _oldDist[oldIdx];
      for (var i = oldIdx; i > 0; i--) {
        _oldDist[i] = _oldDist[i - 1];
      }
      _oldDist[0] = d;
    }
  }

  /// Put a byte to output.
  void _putByte(int b) {
    _window[_winPos++] = b;
    _unpSize--;
  }

  /// Copy a string from history.
  void _copyString(int dist, int len) {
    _lastLen = len;

    var srcPos = _winPos - dist;
    if (srcPos < 0) {
      srcPos += RarConst.maxWinSize;
    }

    while (len-- > 0 && _unpSize > 0) {
      _window[_winPos++] = _window[srcPos++ & RarConst.maxWinMask];
      _unpSize--;
    }
  }

  /// Skip filter data (not implemented).
  void _skipFilter() {
    // Read filter type and data length
    final flags = _reader.readBits(8);
    _reader.readBits(15); // blockStart - skip

    if ((flags & 0x80) != 0) {
      _reader.readBits(8); // Additional start bits
    }

    if ((flags & 0x40) != 0) {
      _reader.readBits(15); // blockLength - skip
    }

    // Skip filter code if present
    if ((flags & 0x20) != 0) {
      final codeLen = _reader.readBits(16);
      // Skip code bytes
      for (var i = 0; i < codeLen; i++) {
        _reader.readBits(8);
      }
    }

    // Skip initial data
    final dataLen = flags & 0x07;
    for (var i = 0; i < dataLen; i++) {
      _reader.readBits(32);
    }
  }
}
