import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../utils/path_utils.dart';

/// Base class for all EPUB resources.
abstract class EpubResource extends Equatable {
  /// Manifest ID.
  final String id;

  /// Relative href within the EPUB.
  final String href;

  /// Media type (MIME type).
  final String mediaType;

  /// Properties from manifest.
  final Set<String> properties;

  const EpubResource({
    required this.id,
    required this.href,
    required this.mediaType,
    this.properties = const {},
  });

  /// File size in bytes.
  int get size;

  /// File extension extracted from href.
  String get extension => PathUtils.extension(href);

  /// Filename without path.
  String get filename => PathUtils.basename(href);

  /// Whether this is a core media type (doesn't need fallback).
  bool get isCoreMediaType {
    return _coreMediaTypes.contains(mediaType);
  }

  static const Set<String> _coreMediaTypes = {
    'image/gif',
    'image/jpeg',
    'image/png',
    'image/svg+xml',
    'image/webp',
    'audio/mpeg',
    'audio/mp4',
    'audio/ogg',
    'application/xhtml+xml',
    'text/css',
    'application/javascript',
    'font/otf',
    'font/ttf',
    'font/woff',
    'font/woff2',
    'application/font-woff',
    'application/font-woff2',
    'application/vnd.ms-opentype',
    'application/font-sfnt',
    'application/smil+xml',
    'application/x-dtbncx+xml',
  };
}

/// A generic resource with raw bytes.
class GenericResource extends EpubResource {
  /// Raw bytes of the resource.
  final Uint8List bytes;

  const GenericResource({
    required super.id,
    required super.href,
    required super.mediaType,
    required this.bytes,
    super.properties,
  });

  @override
  int get size => bytes.length;

  @override
  List<Object?> get props => [id, href, mediaType, bytes, properties];
}
