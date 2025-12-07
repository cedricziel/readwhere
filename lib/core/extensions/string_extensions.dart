/// Extension methods for String class.
///
/// Provides utility methods for common string operations
/// used throughout the application.
extension StringExtensions on String {
  /// Capitalizes the first letter of the string.
  ///
  /// Returns the string with the first character in uppercase
  /// and the rest unchanged.
  ///
  /// Example:
  /// ```dart
  /// 'hello'.capitalize() // Returns: 'Hello'
  /// 'HELLO'.capitalize() // Returns: 'HELLO'
  /// ''.capitalize() // Returns: ''
  /// ```
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalizes the first letter of each word in the string.
  ///
  /// Returns the string with the first character of each word
  /// in uppercase and the rest in lowercase.
  ///
  /// Example:
  /// ```dart
  /// 'hello world'.capitalizeWords() // Returns: 'Hello World'
  /// 'HELLO WORLD'.capitalizeWords() // Returns: 'Hello World'
  /// ```
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Truncates the string to a specified length.
  ///
  /// [maxLength] is the maximum length of the returned string.
  /// [ellipsis] is the string to append when truncating (default: '...').
  ///
  /// If the string is shorter than maxLength, returns the original string.
  /// If truncated, the returned string length including ellipsis will be maxLength.
  ///
  /// Example:
  /// ```dart
  /// 'Hello World'.truncate(8) // Returns: 'Hello...'
  /// 'Hello'.truncate(10) // Returns: 'Hello'
  /// 'Hello World'.truncate(8, ellipsis: '…') // Returns: 'Hello W…'
  /// ```
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;

    final truncateAt = maxLength - ellipsis.length;
    if (truncateAt <= 0) return ellipsis;

    return '${substring(0, truncateAt)}$ellipsis';
  }

  /// Checks if the string is a valid URL.
  ///
  /// Returns true if the string is a valid HTTP or HTTPS URL.
  ///
  /// Example:
  /// ```dart
  /// 'https://example.com'.isValidUrl() // Returns: true
  /// 'http://example.com'.isValidUrl() // Returns: true
  /// 'not a url'.isValidUrl() // Returns: false
  /// 'ftp://example.com'.isValidUrl() // Returns: false
  /// ```
  bool isValidUrl() {
    if (isEmpty) return false;

    try {
      final uri = Uri.parse(this);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Checks if the string is a valid email address.
  ///
  /// Returns true if the string matches the basic email pattern.
  ///
  /// Example:
  /// ```dart
  /// 'user@example.com'.isValidEmail() // Returns: true
  /// 'invalid.email'.isValidEmail() // Returns: false
  /// ```
  bool isValidEmail() {
    if (isEmpty) return false;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Removes all whitespace from the string.
  ///
  /// Returns the string with all whitespace characters removed.
  ///
  /// Example:
  /// ```dart
  /// 'Hello World'.removeWhitespace() // Returns: 'HelloWorld'
  /// '  Hello  '.removeWhitespace() // Returns: 'Hello'
  /// ```
  String removeWhitespace() {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// Checks if the string contains only numeric characters.
  ///
  /// Returns true if the string contains only digits (0-9).
  ///
  /// Example:
  /// ```dart
  /// '12345'.isNumeric() // Returns: true
  /// '123.45'.isNumeric() // Returns: false
  /// 'abc123'.isNumeric() // Returns: false
  /// ```
  bool isNumeric() {
    if (isEmpty) return false;
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }

  /// Converts the string to an integer if possible.
  ///
  /// Returns the parsed integer or null if parsing fails.
  ///
  /// Example:
  /// ```dart
  /// '123'.toIntOrNull() // Returns: 123
  /// 'abc'.toIntOrNull() // Returns: null
  /// '123.45'.toIntOrNull() // Returns: null
  /// ```
  int? toIntOrNull() {
    return int.tryParse(this);
  }

  /// Converts the string to a double if possible.
  ///
  /// Returns the parsed double or null if parsing fails.
  ///
  /// Example:
  /// ```dart
  /// '123.45'.toDoubleOrNull() // Returns: 123.45
  /// 'abc'.toDoubleOrNull() // Returns: null
  /// '123'.toDoubleOrNull() // Returns: 123.0
  /// ```
  double? toDoubleOrNull() {
    return double.tryParse(this);
  }

  /// Reverses the string.
  ///
  /// Returns the string with characters in reverse order.
  ///
  /// Example:
  /// ```dart
  /// 'hello'.reverse() // Returns: 'olleh'
  /// '12345'.reverse() // Returns: '54321'
  /// ```
  String reverse() {
    return split('').reversed.join('');
  }

  /// Checks if the string is null or empty.
  ///
  /// Returns true if the string is empty or contains only whitespace.
  ///
  /// Example:
  /// ```dart
  /// ''.isNullOrEmpty() // Returns: true
  /// '   '.isNullOrEmpty() // Returns: true
  /// 'Hello'.isNullOrEmpty() // Returns: false
  /// ```
  bool isNullOrEmpty() {
    return trim().isEmpty;
  }
}

/// Extension methods for nullable String.
extension NullableStringExtensions on String? {
  /// Returns true if the string is null or empty.
  ///
  /// Example:
  /// ```dart
  /// String? str = null;
  /// str.isNullOrEmpty // Returns: true
  ///
  /// str = '';
  /// str.isNullOrEmpty // Returns: true
  ///
  /// str = 'Hello';
  /// str.isNullOrEmpty // Returns: false
  /// ```
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  /// Returns the string or a default value if null or empty.
  ///
  /// [defaultValue] is the value to return if the string is null or empty.
  ///
  /// Example:
  /// ```dart
  /// String? str = null;
  /// str.orDefault('N/A') // Returns: 'N/A'
  ///
  /// str = 'Hello';
  /// str.orDefault('N/A') // Returns: 'Hello'
  /// ```
  String orDefault(String defaultValue) {
    return isNullOrEmpty ? defaultValue : this!;
  }
}
