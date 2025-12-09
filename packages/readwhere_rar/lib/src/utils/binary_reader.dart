import 'dart:typed_data';

/// A utility class for reading binary data from a byte buffer.
///
/// Provides methods for reading various data types in little-endian format
/// with position tracking and bounds checking.
class BinaryReader {
  final Uint8List _buffer;
  int _position = 0;

  /// Creates a new [BinaryReader] from the given byte buffer.
  BinaryReader(this._buffer);

  /// The underlying byte buffer.
  Uint8List get buffer => _buffer;

  /// Current read position in the buffer.
  int get position => _position;

  /// Total length of the buffer.
  int get length => _buffer.length;

  /// Number of bytes remaining to read.
  int get remaining => _buffer.length - _position;

  /// Whether there are more bytes to read.
  bool get hasRemaining => _position < _buffer.length;

  /// Seeks to an absolute position in the buffer.
  ///
  /// Throws [RangeError] if the position is out of bounds.
  void seek(int position) {
    if (position < 0 || position > _buffer.length) {
      throw RangeError.range(position, 0, _buffer.length, 'position');
    }
    _position = position;
  }

  /// Skips the specified number of bytes.
  ///
  /// Throws [RangeError] if skipping would go past the end of the buffer.
  void skip(int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'must be non-negative');
    }
    final newPosition = _position + count;
    if (newPosition > _buffer.length) {
      throw RangeError.range(
        newPosition,
        0,
        _buffer.length,
        'position after skip',
      );
    }
    _position = newPosition;
  }

  /// Reads an unsigned 8-bit integer.
  ///
  /// Throws [RangeError] if there are not enough bytes remaining.
  int readUint8() {
    _checkRemaining(1);
    return _buffer[_position++];
  }

  /// Reads an unsigned 16-bit integer in little-endian format.
  ///
  /// Throws [RangeError] if there are not enough bytes remaining.
  int readUint16() {
    _checkRemaining(2);
    final value = _buffer[_position] | (_buffer[_position + 1] << 8);
    _position += 2;
    return value;
  }

  /// Reads an unsigned 32-bit integer in little-endian format.
  ///
  /// Throws [RangeError] if there are not enough bytes remaining.
  int readUint32() {
    _checkRemaining(4);
    final value = _buffer[_position] |
        (_buffer[_position + 1] << 8) |
        (_buffer[_position + 2] << 16) |
        (_buffer[_position + 3] << 24);
    _position += 4;
    // Ensure unsigned interpretation
    return value & 0xFFFFFFFF;
  }

  /// Reads an unsigned 64-bit integer in little-endian format.
  ///
  /// Throws [RangeError] if there are not enough bytes remaining.
  int readUint64() {
    _checkRemaining(8);
    // Read as two 32-bit values to avoid precision issues
    final low = readUint32();
    final high = readUint32();
    return (high << 32) | low;
  }

  /// Reads the specified number of bytes as a new [Uint8List].
  ///
  /// Throws [RangeError] if there are not enough bytes remaining.
  Uint8List readBytes(int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'must be non-negative');
    }
    _checkRemaining(count);
    final bytes = Uint8List.sublistView(_buffer, _position, _position + count);
    _position += count;
    return bytes;
  }

  /// Peeks at the specified number of bytes without advancing the position.
  ///
  /// Throws [RangeError] if there are not enough bytes remaining.
  Uint8List peekBytes(int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'must be non-negative');
    }
    _checkRemaining(count);
    return Uint8List.sublistView(_buffer, _position, _position + count);
  }

  /// Peeks at a single byte without advancing the position.
  ///
  /// Throws [RangeError] if there are no bytes remaining.
  int peekUint8() {
    _checkRemaining(1);
    return _buffer[_position];
  }

  /// Reads a null-terminated ASCII string.
  ///
  /// Stops at the first null byte (0x00) or end of buffer.
  /// The position is advanced past the null terminator if present.
  String readNullTerminatedString() {
    final start = _position;
    while (_position < _buffer.length && _buffer[_position] != 0) {
      _position++;
    }
    final str = String.fromCharCodes(_buffer.sublist(start, _position));
    // Skip the null terminator if present
    if (_position < _buffer.length && _buffer[_position] == 0) {
      _position++;
    }
    return str;
  }

  /// Reads a fixed-length string.
  ///
  /// Stops at the first null byte within the specified length, but always
  /// advances the position by [length] bytes.
  ///
  /// Throws [RangeError] if there are not enough bytes remaining.
  String readFixedString(int length) {
    _checkRemaining(length);
    final bytes = _buffer.sublist(_position, _position + length);
    _position += length;

    // Find the first null byte
    var end = bytes.length;
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] == 0) {
        end = i;
        break;
      }
    }

    return String.fromCharCodes(bytes.sublist(0, end));
  }

  /// Reads a string of the specified byte length.
  ///
  /// Unlike [readFixedString], this does not stop at null bytes.
  ///
  /// Throws [RangeError] if there are not enough bytes remaining.
  String readString(int length) {
    _checkRemaining(length);
    final bytes = _buffer.sublist(_position, _position + length);
    _position += length;
    return String.fromCharCodes(bytes);
  }

  /// Creates a sub-reader starting at the current position.
  ///
  /// The sub-reader operates on a view of the underlying buffer.
  BinaryReader subReader(int length) {
    _checkRemaining(length);
    final subBuffer = Uint8List.sublistView(
      _buffer,
      _position,
      _position + length,
    );
    _position += length;
    return BinaryReader(subBuffer);
  }

  /// Checks that there are at least [count] bytes remaining.
  void _checkRemaining(int count) {
    if (_position + count > _buffer.length) {
      throw RangeError(
        'Not enough bytes remaining: need $count, have $remaining',
      );
    }
  }
}
