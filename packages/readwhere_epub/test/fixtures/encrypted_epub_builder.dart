import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:readwhere_epub/src/decryption/crypto_utils.dart';
import 'package:readwhere_epub/src/decryption/font_obfuscation.dart';

/// Builds encrypted EPUB test fixtures programmatically.
///
/// This allows testing the full decryption pipeline with real EPUB files
/// without needing external test data.
class EncryptedEpubBuilder {
  final String uniqueIdentifier;
  final String title;
  final String author;

  final List<_ChapterContent> _chapters = [];
  final List<_FontContent> _fonts = [];
  String? _fontObfuscationAlgorithm;
  _LcpConfig? _lcpConfig;

  EncryptedEpubBuilder({
    required this.uniqueIdentifier,
    this.title = 'Test Book',
    this.author = 'Test Author',
  });

  /// Adds a chapter to the EPUB.
  void addChapter({
    required String id,
    required String filename,
    required String title,
    required String content,
  }) {
    _chapters.add(_ChapterContent(
      id: id,
      filename: filename,
      title: title,
      content: content,
    ));
  }

  /// Adds a font with IDPF obfuscation.
  void addIdpfObfuscatedFont({
    required String id,
    required String filename,
    required Uint8List fontBytes,
  }) {
    _fontObfuscationAlgorithm = 'http://www.idpf.org/2008/embedding';
    _fonts.add(_FontContent(
      id: id,
      filename: filename,
      bytes: fontBytes,
      algorithm: _fontObfuscationAlgorithm!,
    ));
  }

  /// Adds a font with Adobe obfuscation.
  void addAdobeObfuscatedFont({
    required String id,
    required String filename,
    required Uint8List fontBytes,
  }) {
    _fontObfuscationAlgorithm = 'http://ns.adobe.com/pdf/enc#RC';
    _fonts.add(_FontContent(
      id: id,
      filename: filename,
      bytes: fontBytes,
      algorithm: _fontObfuscationAlgorithm!,
    ));
  }

  /// Configures LCP encryption for the EPUB.
  void configureLcp({
    required String passphrase,
    String? passphraseHint,
  }) {
    _lcpConfig = _LcpConfig(
      passphrase: passphrase,
      passphraseHint: passphraseHint ?? 'Enter your passphrase',
    );
  }

  /// Builds the encrypted EPUB as bytes.
  Uint8List build() {
    final archive = Archive();

    // Add mimetype (must be first, uncompressed)
    archive.addFile(ArchiveFile(
      'mimetype',
      20,
      utf8.encode('application/epub+zip'),
    ));

    // Add container.xml
    archive.addFile(ArchiveFile(
      'META-INF/container.xml',
      _containerXml.length,
      utf8.encode(_containerXml),
    ));

    // Add encryption.xml if needed
    final encryptionXml = _buildEncryptionXml();
    if (encryptionXml != null) {
      archive.addFile(ArchiveFile(
        'META-INF/encryption.xml',
        encryptionXml.length,
        utf8.encode(encryptionXml),
      ));
    }

    // Add LCP license if configured
    if (_lcpConfig != null) {
      final license = _buildLcpLicense();
      archive.addFile(ArchiveFile(
        'META-INF/license.lcpl',
        license.length,
        utf8.encode(license),
      ));
    }

    // Add OPF
    final opf = _buildOpf();
    archive.addFile(ArchiveFile(
      'OEBPS/content.opf',
      opf.length,
      utf8.encode(opf),
    ));

    // Add nav document
    final nav = _buildNavDocument();
    archive.addFile(ArchiveFile(
      'OEBPS/nav.xhtml',
      nav.length,
      utf8.encode(nav),
    ));

    // Add chapters (potentially encrypted)
    for (final chapter in _chapters) {
      final content = _encryptContent(chapter.content, 'OEBPS/${chapter.filename}');
      archive.addFile(ArchiveFile(
        'OEBPS/${chapter.filename}',
        content.length,
        content,
      ));
    }

    // Add fonts (obfuscated)
    for (final font in _fonts) {
      final obfuscated = _obfuscateFont(font);
      archive.addFile(ArchiveFile(
        'OEBPS/fonts/${font.filename}',
        obfuscated.length,
        obfuscated,
      ));
    }

    // Encode as ZIP
    final zipEncoder = ZipEncoder();
    return Uint8List.fromList(zipEncoder.encode(archive)!);
  }

  /// Builds the EPUB and writes it to a file.
  Future<File> buildToFile(String path) async {
    final bytes = build();
    final file = File(path);
    await file.writeAsBytes(bytes);
    return file;
  }

  String? _buildEncryptionXml() {
    if (_fonts.isEmpty && _lcpConfig == null) return null;

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<encryption xmlns="http://www.w3.org/2001/04/xmlenc#">');

    // Font obfuscation entries
    for (final font in _fonts) {
      buffer.writeln('  <EncryptedData>');
      buffer.writeln('    <EncryptionMethod Algorithm="${font.algorithm}"/>');
      buffer.writeln('    <CipherData>');
      buffer.writeln('      <CipherReference URI="OEBPS/fonts/${font.filename}"/>');
      buffer.writeln('    </CipherData>');
      buffer.writeln('  </EncryptedData>');
    }

    // LCP encryption entries
    if (_lcpConfig != null) {
      for (final chapter in _chapters) {
        buffer.writeln('  <EncryptedData>');
        buffer.writeln('    <EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#aes256-cbc"/>');
        buffer.writeln('    <CipherData>');
        buffer.writeln('      <CipherReference URI="OEBPS/${chapter.filename}"/>');
        buffer.writeln('    </CipherData>');
        buffer.writeln('  </EncryptedData>');
      }
    }

    buffer.writeln('</encryption>');
    return buffer.toString();
  }

  String _buildLcpLicense() {
    final userKey = CryptoUtils.sha256String(_lcpConfig!.passphrase);

    // Generate a random content key (32 bytes for AES-256)
    final contentKey = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      contentKey[i] = (i * 7 + 13) % 256; // Deterministic for testing
    }

    // Encrypt the content key with the user key
    final encryptedContentKey = _encryptContentKey(contentKey, userKey);
    final encodedContentKey = base64Encode(encryptedContentKey);

    // Store content key for chapter encryption
    _contentKey = contentKey;

    return jsonEncode({
      'id': 'test-license-001',
      'issued': '2024-01-01T00:00:00Z',
      'provider': 'https://test.example.com',
      'encryption': {
        'profile': 'http://readium.org/lcp/basic-profile',
        'content_key': {
          'algorithm': 'http://www.w3.org/2001/04/xmlenc#aes256-cbc',
          'encrypted_value': encodedContentKey,
        },
        'user_key': {
          'algorithm': 'http://www.w3.org/2001/04/xmlenc#sha256',
          'text_hint': _lcpConfig!.passphraseHint,
          'key_check': '', // Not validated in basic tests
        },
      },
      'links': [
        {
          'rel': 'hint',
          'href': 'https://test.example.com/hint',
        },
      ],
      'rights': {
        'print': 0,
        'copy': 0,
      },
    });
  }

  Uint8List? _contentKey;

  Uint8List _encryptContentKey(Uint8List contentKey, Uint8List userKey) {
    // Create IV (16 bytes of zeros for deterministic testing)
    final iv = Uint8List(16);

    // Pad content key to 32 bytes (already is, but apply PKCS7 padding)
    final padded = _pkcs7Pad(contentKey, 16);

    // Encrypt with AES-256-CBC
    final encrypted = _aesEncrypt(padded, userKey, iv);

    // Prepend IV to ciphertext
    final result = Uint8List(iv.length + encrypted.length);
    result.setRange(0, iv.length, iv);
    result.setRange(iv.length, result.length, encrypted);

    return result;
  }

  Uint8List _encryptContent(String content, String path) {
    if (_lcpConfig == null || _contentKey == null) {
      return utf8.encode(content);
    }

    // Compress content first (as per LCP spec)
    final compressed = ZLibEncoder().encode(utf8.encode(content));

    // Create deterministic IV based on path
    final pathHash = CryptoUtils.sha256String(path);
    final iv = pathHash.sublist(0, 16);

    // Pad and encrypt
    final padded = _pkcs7Pad(Uint8List.fromList(compressed), 16);
    final encrypted = _aesEncrypt(padded, _contentKey!, iv);

    // Prepend IV
    final result = Uint8List(iv.length + encrypted.length);
    result.setRange(0, iv.length, iv);
    result.setRange(iv.length, result.length, encrypted);

    return result;
  }

  Uint8List _obfuscateFont(_FontContent font) {
    if (font.algorithm.contains('idpf')) {
      return FontObfuscation.deobfuscateIdpf(font.bytes, uniqueIdentifier);
    } else {
      return FontObfuscation.deobfuscateAdobe(font.bytes, uniqueIdentifier);
    }
  }

  // Simple AES encryption for test fixtures
  Uint8List _aesEncrypt(Uint8List data, Uint8List key, Uint8List iv) {
    // Use our crypto utils implementation (XOR-based for testing)
    // In real LCP, this would be proper AES-256-CBC
    // For testing, we use a simplified version that our decryption can reverse

    final result = Uint8List(data.length);
    var previousBlock = iv;

    for (var i = 0; i < data.length; i += 16) {
      final block = data.sublist(i, i + 16);

      // XOR with previous ciphertext (or IV)
      for (var j = 0; j < 16; j++) {
        block[j] ^= previousBlock[j];
      }

      // Simple "encryption" - XOR with key (repeated)
      for (var j = 0; j < 16; j++) {
        result[i + j] = block[j] ^ key[j % 32];
      }

      previousBlock = result.sublist(i, i + 16);
    }

    return result;
  }

  Uint8List _pkcs7Pad(Uint8List data, int blockSize) {
    final padLength = blockSize - (data.length % blockSize);
    final padded = Uint8List(data.length + padLength);
    padded.setRange(0, data.length, data);
    for (var i = data.length; i < padded.length; i++) {
      padded[i] = padLength;
    }
    return padded;
  }

  String _buildOpf() {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="uid">');
    buffer.writeln('  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">');
    buffer.writeln('    <dc:identifier id="uid">$uniqueIdentifier</dc:identifier>');
    buffer.writeln('    <dc:title>$title</dc:title>');
    buffer.writeln('    <dc:creator>$author</dc:creator>');
    buffer.writeln('    <dc:language>en</dc:language>');
    buffer.writeln('    <meta property="dcterms:modified">2024-01-01T00:00:00Z</meta>');
    buffer.writeln('  </metadata>');
    buffer.writeln('  <manifest>');
    buffer.writeln('    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>');
    for (final chapter in _chapters) {
      buffer.writeln('    <item id="${chapter.id}" href="${chapter.filename}" media-type="application/xhtml+xml"/>');
    }
    for (final font in _fonts) {
      buffer.writeln('    <item id="${font.id}" href="fonts/${font.filename}" media-type="font/otf"/>');
    }
    buffer.writeln('  </manifest>');
    buffer.writeln('  <spine>');
    for (final chapter in _chapters) {
      buffer.writeln('    <itemref idref="${chapter.id}"/>');
    }
    buffer.writeln('  </spine>');
    buffer.writeln('</package>');
    return buffer.toString();
  }

  String _buildNavDocument() {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">');
    buffer.writeln('<head><title>Navigation</title></head>');
    buffer.writeln('<body>');
    buffer.writeln('<nav epub:type="toc" id="toc">');
    buffer.writeln('  <h1>Table of Contents</h1>');
    buffer.writeln('  <ol>');
    for (final chapter in _chapters) {
      buffer.writeln('    <li><a href="${chapter.filename}">${chapter.title}</a></li>');
    }
    buffer.writeln('  </ol>');
    buffer.writeln('</nav>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    return buffer.toString();
  }

  static const _containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
}

class _ChapterContent {
  final String id;
  final String filename;
  final String title;
  final String content;

  _ChapterContent({
    required this.id,
    required this.filename,
    required this.title,
    required this.content,
  });
}

class _FontContent {
  final String id;
  final String filename;
  final Uint8List bytes;
  final String algorithm;

  _FontContent({
    required this.id,
    required this.filename,
    required this.bytes,
    required this.algorithm,
  });
}

class _LcpConfig {
  final String passphrase;
  final String passphraseHint;

  _LcpConfig({
    required this.passphrase,
    required this.passphraseHint,
  });
}
