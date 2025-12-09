import '../auth/webdav_auth.dart';

/// Configuration for a WebDAV client
class WebDavConfig {
  /// Base URL of the WebDAV server
  ///
  /// This should be the full URL to the WebDAV endpoint, e.g.:
  /// - `https://example.com/webdav/`
  /// - `https://nextcloud.example.com/remote.php/dav/files/username/`
  final String baseUrl;

  /// Authentication configuration
  final WebDavAuth auth;

  /// User-Agent string for requests
  final String userAgent;

  /// Request timeout in milliseconds
  final int timeoutMs;

  /// Custom headers to include in all requests
  final Map<String, String> customHeaders;

  /// Custom namespaces for PROPFIND requests
  ///
  /// Map of prefix to namespace URI, e.g.:
  /// `{'oc': 'http://owncloud.org/ns'}`
  final Map<String, String> customNamespaces;

  /// Custom properties to request in PROPFIND
  ///
  /// Map of namespace prefix to list of property names, e.g.:
  /// `{'oc': ['size', 'permissions']}`
  final Map<String, List<String>> customProperties;

  WebDavConfig({
    required this.baseUrl,
    required this.auth,
    this.userAgent = 'WebDAV-Client/1.0',
    this.timeoutMs = 30000,
    this.customHeaders = const {},
    this.customNamespaces = const {},
    this.customProperties = const {},
  });

  /// Get the normalized base URL (without trailing slash)
  String get normalizedBaseUrl {
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  /// Create a copy with updated values
  WebDavConfig copyWith({
    String? baseUrl,
    WebDavAuth? auth,
    String? userAgent,
    int? timeoutMs,
    Map<String, String>? customHeaders,
    Map<String, String>? customNamespaces,
    Map<String, List<String>>? customProperties,
  }) {
    return WebDavConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      auth: auth ?? this.auth,
      userAgent: userAgent ?? this.userAgent,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      customHeaders: customHeaders ?? this.customHeaders,
      customNamespaces: customNamespaces ?? this.customNamespaces,
      customProperties: customProperties ?? this.customProperties,
    );
  }
}
