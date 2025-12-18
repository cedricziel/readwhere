import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:readwhere_epub/readwhere_epub.dart' as epub;
import 'package:readwhere_plugin/readwhere_plugin.dart';

import 'readwhere_epub_controller.dart';

/// EPUB plugin using the readwhere_epub library.
///
/// This plugin provides full EPUB 2 and EPUB 3 support using the
/// custom readwhere_epub library for parsing and content extraction.
///
/// Implements the unified plugin architecture with [PluginBase] and
/// [ReaderCapability] mixin.
class ReadwhereEpubPlugin extends PluginBase with ReaderCapability {
  late Logger _log;

  @override
  String get id => 'com.readwhere.epub';

  @override
  String get name => 'EPUB Reader';

  @override
  String get description => 'Supports EPUB 2.0 and EPUB 3.0 format books';

  @override
  String get version => '1.0.0';

  @override
  List<String> get supportedExtensions => ['epub', 'epub3'];

  @override
  List<String> get supportedMimeTypes => [
    'application/epub+zip',
    'application/epub',
  ];

  @override
  List<String> get capabilityNames => ['ReaderCapability'];

  @override
  Future<void> initialize(PluginContext context) async {
    _log = context.logger;
    _log.info('EPUB plugin initialized');
  }

  @override
  Future<void> dispose() async {
    _log.info('EPUB plugin disposed');
  }

  @override
  Future<bool> canHandleFile(String filePath) async {
    try {
      // Check file extension
      final extension = path.extension(filePath).toLowerCase();
      if (extension != '.epub' && extension != '.epub3') {
        return false;
      }

      // Check if file exists and is readable
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // Try to read the file as EPUB (basic validation)
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return false;
      }

      // EPUB files are ZIP archives, check for ZIP signature
      // ZIP files start with PK (0x50 0x4B)
      if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
        return true;
      }

      return false;
    } catch (e) {
      _log.fine('Cannot handle file $filePath: $e');
      return false;
    }
  }

  @override
  Future<BookMetadata> parseMetadata(String filePath) async {
    try {
      _log.info('Parsing metadata from: $filePath');

      final reader = await epub.EpubReader.open(filePath);
      final metadata = reader.metadata;

      // Extract cover image
      Uint8List? coverImage;
      try {
        final cover = reader.getCoverImage();
        coverImage = cover?.bytes;
      } catch (e) {
        _log.warning('Failed to extract cover: $e');
      }

      // Build table of contents
      final toc = _convertTocEntries(reader.navigation.tableOfContents);

      // Extract encryption info
      final encryptionInfo = reader.encryptionInfo;
      final encryptionType = _convertEncryptionType(encryptionInfo.type);
      final encryptionDescription = encryptionInfo.hasDrm
          ? encryptionInfo.description
          : null;
      final lcpPassphraseHint = reader.lcpPassphraseHint;

      // Check for fixed-layout
      final isFixedLayout = reader.book.isFixedLayout;

      // Check for media overlays
      final hasMediaOverlays = reader.hasMediaOverlays;

      if (encryptionInfo.hasDrm) {
        _log.warning(
          'Book has DRM: ${encryptionInfo.description} (${encryptionInfo.encryptedResourceCount} encrypted resources)',
        );
      }
      if (isFixedLayout) {
        _log.info('Book is fixed-layout EPUB');
      }
      if (hasMediaOverlays) {
        _log.info('Book has media overlays (audio sync)');
      }

      final bookMetadata = BookMetadata(
        title: metadata.title,
        author: metadata.author ?? 'Unknown Author',
        description: metadata.description,
        publisher: metadata.publisher,
        language: metadata.language,
        publishedDate: metadata.date,
        coverImage: coverImage,
        tableOfContents: toc,
        encryptionType: encryptionType,
        encryptionDescription: encryptionDescription,
        lcpPassphraseHint: lcpPassphraseHint,
        isFixedLayout: isFixedLayout,
        hasMediaOverlays: hasMediaOverlays,
      );

      _log.info('Parsed metadata: ${bookMetadata.title}');
      return bookMetadata;
    } catch (e, stackTrace) {
      _log.severe('Error parsing metadata from $filePath', e, stackTrace);
      rethrow;
    }
  }

  /// Convert library encryption type to app encryption type.
  EpubEncryptionType _convertEncryptionType(epub.EncryptionType type) {
    switch (type) {
      case epub.EncryptionType.none:
        return EpubEncryptionType.none;
      case epub.EncryptionType.adobeDrm:
        return EpubEncryptionType.adobeDrm;
      case epub.EncryptionType.appleFairPlay:
        return EpubEncryptionType.appleFairPlay;
      case epub.EncryptionType.lcp:
        return EpubEncryptionType.lcp;
      case epub.EncryptionType.fontObfuscation:
        return EpubEncryptionType.fontObfuscation;
      case epub.EncryptionType.unknown:
        return EpubEncryptionType.unknown;
    }
  }

  @override
  Future<Uint8List?> extractCover(String filePath) async {
    try {
      _log.info('Extracting cover from: $filePath');

      final reader = await epub.EpubReader.open(filePath);
      final cover = reader.getCoverImage();
      return cover?.bytes;
    } catch (e, stackTrace) {
      _log.severe('Error extracting cover from $filePath', e, stackTrace);
      return null;
    }
  }

  @override
  Future<ReaderController> openBook(
    String filePath, {
    Map<String, String>? credentials,
  }) async {
    try {
      _log.info('Opening book: $filePath');

      // Extract passphrase from credentials if provided
      final passphrase = credentials?['passphrase'];
      if (passphrase != null) {
        _log.info('Opening with LCP passphrase');
      }

      final controller = await ReadwhereEpubController.create(
        filePath,
        passphrase: passphrase,
      );

      _log.info('Book opened successfully');
      return controller;
    } catch (e, stackTrace) {
      _log.severe('Error opening book $filePath', e, stackTrace);
      rethrow;
    }
  }

  /// Convert readwhere_epub TocEntry list to app TocEntry list.
  List<TocEntry> _convertTocEntries(List<epub.TocEntry> entries) {
    return entries.map((entry) => _convertTocEntry(entry)).toList();
  }

  /// Convert a single TocEntry recursively.
  TocEntry _convertTocEntry(epub.TocEntry entry) {
    return TocEntry(
      id: entry.id,
      title: entry.title,
      href: entry.href,
      level: entry.level,
      children: _convertTocEntries(entry.children),
    );
  }
}
