import 'dart:convert';
import 'dart:typed_data';

/// Cryptographic utilities for EPUB decryption.
///
/// Provides SHA-256 hashing and AES-256-CBC decryption required for
/// Readium LCP support.
class CryptoUtils {
  CryptoUtils._();

  /// Computes SHA-256 hash of the input data.
  static Uint8List sha256(Uint8List data) {
    return _Sha256().process(data);
  }

  /// Computes SHA-256 hash of a string (UTF-8 encoded).
  static Uint8List sha256String(String input) {
    return sha256(Uint8List.fromList(utf8.encode(input)));
  }

  /// Decrypts data encrypted with AES-256-CBC.
  ///
  /// [ciphertext] - The encrypted data (IV prepended).
  /// [key] - The 256-bit (32 byte) encryption key.
  ///
  /// Returns the decrypted plaintext.
  /// Throws [CryptoException] if decryption fails.
  static Uint8List decryptAes256Cbc(Uint8List ciphertext, Uint8List key) {
    if (key.length != 32) {
      throw CryptoException('AES-256 requires a 32-byte key');
    }

    if (ciphertext.length < 16) {
      throw CryptoException('Ciphertext too short (missing IV)');
    }

    // Extract IV (first 16 bytes)
    final iv = ciphertext.sublist(0, 16);
    final encrypted = ciphertext.sublist(16);

    if (encrypted.isEmpty) {
      return Uint8List(0);
    }

    if (encrypted.length % 16 != 0) {
      throw CryptoException('Ciphertext length must be multiple of 16 bytes');
    }

    // Decrypt using AES-256-CBC
    final aes = _Aes256(key);
    final decrypted = aes.decryptCbc(encrypted, iv);

    // Remove PKCS#7 padding
    return _removePkcs7Padding(decrypted);
  }

  /// Removes PKCS#7 padding from decrypted data.
  static Uint8List _removePkcs7Padding(Uint8List data) {
    if (data.isEmpty) return data;

    final padLength = data.last;
    if (padLength == 0 || padLength > 16) {
      throw CryptoException('Invalid PKCS#7 padding');
    }

    // Verify all padding bytes are the same
    for (var i = data.length - padLength; i < data.length; i++) {
      if (data[i] != padLength) {
        throw CryptoException('Invalid PKCS#7 padding bytes');
      }
    }

    return data.sublist(0, data.length - padLength);
  }
}

/// Exception thrown for cryptographic errors.
class CryptoException implements Exception {
  final String message;

  const CryptoException(this.message);

  @override
  String toString() => 'CryptoException: $message';
}

/// SHA-256 implementation following FIPS 180-4.
class _Sha256 {
  // Initial hash values
  static const List<int> _h0 = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];

  // Round constants
  static const List<int> _k = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  Uint8List process(Uint8List message) {
    // Initialize hash values
    final h = List<int>.from(_h0);

    // Pre-processing: add padding
    final originalLength = message.length;
    final bitLength = originalLength * 8;

    // Padded length must be ≡ 56 (mod 64)
    final paddingLength = (56 - (originalLength + 1) % 64) % 64;
    final paddedLength = originalLength + 1 + paddingLength + 8;
    final padded = Uint8List(paddedLength);

    padded.setRange(0, originalLength, message);
    padded[originalLength] = 0x80;

    // Add length as 64-bit big-endian
    padded[paddedLength - 8] = (bitLength >> 56) & 0xFF;
    padded[paddedLength - 7] = (bitLength >> 48) & 0xFF;
    padded[paddedLength - 6] = (bitLength >> 40) & 0xFF;
    padded[paddedLength - 5] = (bitLength >> 32) & 0xFF;
    padded[paddedLength - 4] = (bitLength >> 24) & 0xFF;
    padded[paddedLength - 3] = (bitLength >> 16) & 0xFF;
    padded[paddedLength - 2] = (bitLength >> 8) & 0xFF;
    padded[paddedLength - 1] = bitLength & 0xFF;

    // Process 512-bit chunks
    for (var i = 0; i < paddedLength; i += 64) {
      _processChunk(padded.sublist(i, i + 64), h);
    }

    // Produce final hash
    final hash = Uint8List(32);
    for (var i = 0; i < 8; i++) {
      hash[i * 4] = (h[i] >> 24) & 0xFF;
      hash[i * 4 + 1] = (h[i] >> 16) & 0xFF;
      hash[i * 4 + 2] = (h[i] >> 8) & 0xFF;
      hash[i * 4 + 3] = h[i] & 0xFF;
    }

    return hash;
  }

  void _processChunk(Uint8List chunk, List<int> h) {
    // Create message schedule
    final w = List<int>.filled(64, 0);

    // First 16 words from chunk
    for (var i = 0; i < 16; i++) {
      w[i] = (chunk[i * 4] << 24) |
          (chunk[i * 4 + 1] << 16) |
          (chunk[i * 4 + 2] << 8) |
          chunk[i * 4 + 3];
    }

    // Extend to 64 words
    for (var i = 16; i < 64; i++) {
      final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
      final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xFFFFFFFF;
    }

    // Working variables
    var a = h[0], b = h[1], c = h[2], d = h[3];
    var e = h[4], f = h[5], g = h[6], hh = h[7];

    // Compression function
    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ ((~e & 0xFFFFFFFF) & g);
      final temp1 = (hh + s1 + ch + _k[i] + w[i]) & 0xFFFFFFFF;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (s0 + maj) & 0xFFFFFFFF;

      hh = g;
      g = f;
      f = e;
      e = (d + temp1) & 0xFFFFFFFF;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & 0xFFFFFFFF;
    }

    // Add to hash
    h[0] = (h[0] + a) & 0xFFFFFFFF;
    h[1] = (h[1] + b) & 0xFFFFFFFF;
    h[2] = (h[2] + c) & 0xFFFFFFFF;
    h[3] = (h[3] + d) & 0xFFFFFFFF;
    h[4] = (h[4] + e) & 0xFFFFFFFF;
    h[5] = (h[5] + f) & 0xFFFFFFFF;
    h[6] = (h[6] + g) & 0xFFFFFFFF;
    h[7] = (h[7] + hh) & 0xFFFFFFFF;
  }

  int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xFFFFFFFF;
}

/// AES-256 implementation.
class _Aes256 {
  static const int _nb = 4; // Block size in 32-bit words
  static const int _nk = 8; // Key size in 32-bit words
  static const int _nr = 14; // Number of rounds

  final List<int> _roundKeys;

  _Aes256(Uint8List key) : _roundKeys = _expandKey(key);

  /// Decrypts data using AES-256 CBC mode.
  Uint8List decryptCbc(Uint8List ciphertext, Uint8List iv) {
    final numBlocks = ciphertext.length ~/ 16;
    final plaintext = Uint8List(ciphertext.length);
    var previousBlock = iv;

    for (var i = 0; i < numBlocks; i++) {
      final start = i * 16;
      final block = ciphertext.sublist(start, start + 16);
      final decrypted = _decryptBlock(block);

      // XOR with previous ciphertext block (or IV for first block)
      for (var j = 0; j < 16; j++) {
        plaintext[start + j] = decrypted[j] ^ previousBlock[j];
      }

      previousBlock = block;
    }

    return plaintext;
  }

  Uint8List _decryptBlock(Uint8List block) {
    // Convert to state matrix (column-major order)
    final state = List.generate(4, (i) => List<int>.filled(4, 0));
    for (var i = 0; i < 16; i++) {
      state[i % 4][i ~/ 4] = block[i];
    }

    // Initial round key addition
    _addRoundKey(state, _nr);

    // Main rounds (in reverse)
    for (var round = _nr - 1; round >= 1; round--) {
      _invShiftRows(state);
      _invSubBytes(state);
      _addRoundKey(state, round);
      _invMixColumns(state);
    }

    // Final round
    _invShiftRows(state);
    _invSubBytes(state);
    _addRoundKey(state, 0);

    // Convert state back to bytes
    final result = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      result[i] = state[i % 4][i ~/ 4];
    }

    return result;
  }

  void _addRoundKey(List<List<int>> state, int round) {
    for (var c = 0; c < 4; c++) {
      final w = _roundKeys[round * 4 + c];
      state[0][c] ^= (w >> 24) & 0xFF;
      state[1][c] ^= (w >> 16) & 0xFF;
      state[2][c] ^= (w >> 8) & 0xFF;
      state[3][c] ^= w & 0xFF;
    }
  }

  void _invSubBytes(List<List<int>> state) {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        state[r][c] = _invSbox[state[r][c]];
      }
    }
  }

  void _invShiftRows(List<List<int>> state) {
    // Row 1: shift right by 1
    var temp = state[1][3];
    state[1][3] = state[1][2];
    state[1][2] = state[1][1];
    state[1][1] = state[1][0];
    state[1][0] = temp;

    // Row 2: shift right by 2
    temp = state[2][0];
    state[2][0] = state[2][2];
    state[2][2] = temp;
    temp = state[2][1];
    state[2][1] = state[2][3];
    state[2][3] = temp;

    // Row 3: shift right by 3 (= left by 1)
    temp = state[3][0];
    state[3][0] = state[3][1];
    state[3][1] = state[3][2];
    state[3][2] = state[3][3];
    state[3][3] = temp;
  }

  void _invMixColumns(List<List<int>> state) {
    for (var c = 0; c < 4; c++) {
      final a0 = state[0][c];
      final a1 = state[1][c];
      final a2 = state[2][c];
      final a3 = state[3][c];

      state[0][c] = _mul(0x0e, a0) ^ _mul(0x0b, a1) ^ _mul(0x0d, a2) ^ _mul(0x09, a3);
      state[1][c] = _mul(0x09, a0) ^ _mul(0x0e, a1) ^ _mul(0x0b, a2) ^ _mul(0x0d, a3);
      state[2][c] = _mul(0x0d, a0) ^ _mul(0x09, a1) ^ _mul(0x0e, a2) ^ _mul(0x0b, a3);
      state[3][c] = _mul(0x0b, a0) ^ _mul(0x0d, a1) ^ _mul(0x09, a2) ^ _mul(0x0e, a3);
    }
  }

  /// Galois field multiplication.
  static int _mul(int a, int b) {
    var result = 0;
    var aa = a;
    var bb = b;

    for (var i = 0; i < 8; i++) {
      if ((bb & 1) != 0) {
        result ^= aa;
      }
      final hiBit = aa & 0x80;
      aa = (aa << 1) & 0xFF;
      if (hiBit != 0) {
        aa ^= 0x1B; // x^8 + x^4 + x^3 + x + 1
      }
      bb >>= 1;
    }

    return result;
  }

  /// Expands the key into round keys.
  static List<int> _expandKey(Uint8List key) {
    final w = List<int>.filled(_nb * (_nr + 1), 0);

    // First Nk words are the key itself
    for (var i = 0; i < _nk; i++) {
      w[i] = (key[4 * i] << 24) |
          (key[4 * i + 1] << 16) |
          (key[4 * i + 2] << 8) |
          key[4 * i + 3];
    }

    // Generate remaining words
    for (var i = _nk; i < _nb * (_nr + 1); i++) {
      var temp = w[i - 1];
      if (i % _nk == 0) {
        temp = _subWord(_rotWord(temp)) ^ _rcon[i ~/ _nk - 1];
      } else if (_nk > 6 && i % _nk == 4) {
        temp = _subWord(temp);
      }
      w[i] = w[i - _nk] ^ temp;
    }

    return w;
  }

  static int _subWord(int word) {
    return (_sbox[(word >> 24) & 0xFF] << 24) |
        (_sbox[(word >> 16) & 0xFF] << 16) |
        (_sbox[(word >> 8) & 0xFF] << 8) |
        _sbox[word & 0xFF];
  }

  static int _rotWord(int word) {
    return ((word << 8) | (word >> 24)) & 0xFFFFFFFF;
  }

  // Round constants
  static const _rcon = [
    0x01000000, 0x02000000, 0x04000000, 0x08000000,
    0x10000000, 0x20000000, 0x40000000, 0x80000000,
    0x1B000000, 0x36000000,
  ];

  // S-box
  static const _sbox = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16,
  ];

  // Inverse S-box
  static const _invSbox = [
    0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
    0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
    0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
    0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
    0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
    0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
    0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
    0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
    0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
    0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
    0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
    0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
    0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
    0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
    0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
    0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d,
  ];
}
