import 'package:path/path.dart' as p;

/// Utility functions for handling paths within EPUB files.
///
/// EPUB paths use forward slashes as separators and may be URL-encoded.
class PathUtils {
  PathUtils._();

  /// The POSIX path context (forward slashes).
  static final p.Context posix = p.posix;

  /// Normalizes a path within an EPUB.
  ///
  /// - Converts backslashes to forward slashes
  /// - Removes leading slashes (relative paths)
  /// - Resolves . and .. segments
  /// - Normalizes multiple slashes
  static String normalize(String path) {
    // Convert backslashes to forward slashes
    var normalized = path.replaceAll('\\', '/');

    // Remove leading slash (EPUB paths are relative to root)
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }

    // Use posix context for consistent forward-slash handling
    normalized = posix.normalize(normalized);

    // Remove any remaining leading ./
    if (normalized.startsWith('./')) {
      normalized = normalized.substring(2);
    }

    return normalized;
  }

  /// Resolves a relative path from a base path.
  ///
  /// Given a base path like "OEBPS/Text/chapter1.xhtml" and a relative path
  /// like "../Images/cover.jpg", returns "OEBPS/Images/cover.jpg".
  static String resolve(String basePath, String relativePath) {
    // If the relative path is absolute, just normalize it
    if (relativePath.startsWith('/')) {
      return normalize(relativePath);
    }

    // Get the directory of the base path
    final baseDir = posix.dirname(basePath);

    // Join and normalize
    final joined = posix.join(baseDir, relativePath);
    return normalize(joined);
  }

  /// Gets the directory portion of a path.
  static String dirname(String path) {
    return posix.dirname(normalize(path));
  }

  /// Gets the filename portion of a path.
  static String basename(String path) {
    return posix.basename(normalize(path));
  }

  /// Gets the file extension (with dot).
  static String extension(String path) {
    return posix.extension(normalize(path));
  }

  /// Gets the filename without extension.
  static String basenameWithoutExtension(String path) {
    return posix.basenameWithoutExtension(normalize(path));
  }

  /// Joins multiple path segments.
  static String join(String path1, [String? path2, String? path3]) {
    var result = path1;
    if (path2 != null) {
      result = posix.join(result, path2);
    }
    if (path3 != null) {
      result = posix.join(result, path3);
    }
    return normalize(result);
  }

  /// Decodes URL-encoded path segments.
  ///
  /// EPUB paths may contain percent-encoded characters (e.g., %20 for space).
  static String urlDecode(String path) {
    return Uri.decodeComponent(path);
  }

  /// URL-encodes path segments while preserving slashes.
  static String urlEncode(String path) {
    // Split by slashes, encode each segment, rejoin
    final segments = path.split('/');
    final encoded = segments.map((s) => Uri.encodeComponent(s));
    return encoded.join('/');
  }

  /// Checks if a path matches another path, handling case sensitivity.
  ///
  /// EPUB paths are case-sensitive per specification, but some EPUBs
  /// may have inconsistent casing.
  static bool pathEquals(String path1, String path2,
      {bool ignoreCase = false}) {
    final normalized1 = normalize(path1);
    final normalized2 = normalize(path2);

    if (ignoreCase) {
      return normalized1.toLowerCase() == normalized2.toLowerCase();
    }
    return normalized1 == normalized2;
  }

  /// Extracts the fragment identifier from a path/href.
  ///
  /// Given "chapter1.xhtml#section1", returns "section1".
  /// Returns null if no fragment is present.
  static String? getFragment(String href) {
    final hashIndex = href.indexOf('#');
    if (hashIndex < 0 || hashIndex >= href.length - 1) {
      return null;
    }
    return href.substring(hashIndex + 1);
  }

  /// Removes the fragment identifier from a path/href.
  ///
  /// Given "chapter1.xhtml#section1", returns "chapter1.xhtml".
  static String removeFragment(String href) {
    final hashIndex = href.indexOf('#');
    if (hashIndex < 0) {
      return href;
    }
    return href.substring(0, hashIndex);
  }

  /// Checks if a path has a specific extension (case-insensitive).
  static bool hasExtension(String path, String ext) {
    final pathExt = extension(path).toLowerCase();
    final checkExt =
        ext.startsWith('.') ? ext.toLowerCase() : '.$ext'.toLowerCase();
    return pathExt == checkExt;
  }

  /// Checks if a path is an XHTML content document.
  static bool isXhtml(String path) {
    final ext = extension(path).toLowerCase();
    return ext == '.xhtml' || ext == '.html' || ext == '.htm' || ext == '.xml';
  }

  /// Checks if a path is a CSS stylesheet.
  static bool isCss(String path) {
    return hasExtension(path, '.css');
  }

  /// Checks if a path is an image.
  static bool isImage(String path) {
    final ext = extension(path).toLowerCase();
    return ext == '.jpg' ||
        ext == '.jpeg' ||
        ext == '.png' ||
        ext == '.gif' ||
        ext == '.webp' ||
        ext == '.svg';
  }

  /// Checks if a path is a font file.
  static bool isFont(String path) {
    final ext = extension(path).toLowerCase();
    return ext == '.otf' || ext == '.ttf' || ext == '.woff' || ext == '.woff2';
  }

  /// Gets the relative path from one path to another.
  static String relative(String from, String to) {
    final fromDir = dirname(from);
    return posix.relative(normalize(to), from: fromDir);
  }
}
