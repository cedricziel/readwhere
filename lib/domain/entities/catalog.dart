import 'package:equatable/equatable.dart';

/// Type of catalog source
enum CatalogType {
  /// Generic OPDS catalog
  opds,

  /// Kavita server with OPDS + API support
  kavita,

  /// Nextcloud server with WebDAV file access
  nextcloud,

  /// RSS/Atom feed
  rss,

  /// Fanfiction.de catalog
  fanfiction,
}

/// Represents an OPDS catalog source
class Catalog extends Equatable {
  final String id;
  final String name;
  final String url;
  final String? iconUrl;
  final DateTime addedAt;
  final DateTime? lastAccessedAt;

  /// API key for authentication (used by Kavita OPDS)
  final String? apiKey;

  /// Type of catalog (opds or kavita)
  final CatalogType type;

  /// Server version (populated after validation)
  final String? serverVersion;

  // Nextcloud-specific fields

  /// Username for Nextcloud authentication
  final String? username;

  /// Root folder for books in Nextcloud (default: '/Books')
  final String? booksFolder;

  /// Nextcloud user ID (from OCS API)
  final String? userId;

  const Catalog({
    required this.id,
    required this.name,
    required this.url,
    this.iconUrl,
    required this.addedAt,
    this.lastAccessedAt,
    this.apiKey,
    this.type = CatalogType.opds,
    this.serverVersion,
    this.username,
    this.booksFolder,
    this.userId,
  });

  /// Whether this catalog requires authentication
  bool get requiresAuth => apiKey != null && apiKey!.isNotEmpty;

  /// Whether this is a Kavita server
  bool get isKavita => type == CatalogType.kavita;

  /// Whether this is a Nextcloud server
  bool get isNextcloud => type == CatalogType.nextcloud;

  /// Whether this is an RSS feed
  bool get isRss => type == CatalogType.rss;

  /// Whether this is a Fanfiction.de catalog
  bool get isFanfiction => type == CatalogType.fanfiction;

  /// Get the WebDAV URL for Nextcloud file access
  String get webdavUrl {
    if (!isNextcloud || userId == null) return url;
    final baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    return '$baseUrl/remote.php/dav/files/$userId';
  }

  /// Get the effective books folder path (defaults to root)
  String get effectiveBooksFolder => booksFolder ?? '/';

  /// Get the full OPDS URL (including API key for Kavita)
  String get opdsUrl {
    if (isKavita && apiKey != null) {
      // Kavita OPDS URL format: {server}/api/opds/{apiKey}
      final baseUrl = url.endsWith('/')
          ? url.substring(0, url.length - 1)
          : url;
      return '$baseUrl/api/opds/$apiKey';
    }
    return url;
  }

  /// Creates a copy of this Catalog with the given fields replaced
  Catalog copyWith({
    String? id,
    String? name,
    String? url,
    String? iconUrl,
    DateTime? addedAt,
    DateTime? lastAccessedAt,
    String? apiKey,
    CatalogType? type,
    String? serverVersion,
    String? username,
    String? booksFolder,
    String? userId,
  }) {
    return Catalog(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      iconUrl: iconUrl ?? this.iconUrl,
      addedAt: addedAt ?? this.addedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      apiKey: apiKey ?? this.apiKey,
      type: type ?? this.type,
      serverVersion: serverVersion ?? this.serverVersion,
      username: username ?? this.username,
      booksFolder: booksFolder ?? this.booksFolder,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    url,
    iconUrl,
    addedAt,
    lastAccessedAt,
    apiKey,
    type,
    serverVersion,
    username,
    booksFolder,
    userId,
  ];

  @override
  String toString() {
    return 'Catalog(id: $id, name: $name, url: $url)';
  }
}
