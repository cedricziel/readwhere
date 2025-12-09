/// Builder for PROPFIND XML request bodies
class PropfindBuilder {
  /// Standard DAV namespace
  static const String davNamespace = 'DAV:';

  /// Build a PROPFIND request body for listing files
  ///
  /// [properties] - List of property names to request (without namespace prefix)
  /// [customNamespaces] - Map of prefix to namespace URI for custom properties
  /// [customProperties] - Map of prefix to list of property names
  static String build({
    List<String> properties = const [
      'displayname',
      'getcontenttype',
      'getcontentlength',
      'getlastmodified',
      'getetag',
      'resourcetype',
    ],
    Map<String, String> customNamespaces = const {},
    Map<String, List<String>> customProperties = const {},
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.write('<d:propfind xmlns:d="$davNamespace"');

    // Add custom namespaces
    for (final entry in customNamespaces.entries) {
      buffer.write(' xmlns:${entry.key}="${entry.value}"');
    }
    buffer.writeln('>');

    buffer.writeln('  <d:prop>');

    // Add standard DAV properties
    for (final prop in properties) {
      buffer.writeln('    <d:$prop/>');
    }

    // Add custom properties
    for (final entry in customProperties.entries) {
      final prefix = entry.key;
      for (final prop in entry.value) {
        buffer.writeln('    <$prefix:$prop/>');
      }
    }

    buffer.writeln('  </d:prop>');
    buffer.writeln('</d:propfind>');

    return buffer.toString();
  }

  /// Build a standard PROPFIND request for file listings
  ///
  /// This includes common properties needed for directory browsing.
  static String standard() => build();

  /// Build a PROPFIND request with OwnCloud/Nextcloud extensions
  static String withOwnCloudExtensions() => build(
        customNamespaces: {
          'oc': 'http://owncloud.org/ns',
          'nc': 'http://nextcloud.org/ns',
        },
        customProperties: {
          'oc': ['size', 'permissions', 'fileid'],
          'nc': ['has-preview', 'mount-type'],
        },
      );
}
