/// Reading direction for a comic book.
enum ReadingDirection {
  /// Left-to-right reading (Western comics).
  leftToRight,

  /// Right-to-left reading (manga).
  rightToLeft,
}

/// Manga designation from ComicInfo.xml.
enum MangaType {
  /// Unknown manga status.
  unknown('Unknown'),

  /// Not manga (Western comic).
  no('No'),

  /// Is manga but read left-to-right (translated).
  yes('Yes'),

  /// Is manga and read right-to-left (original orientation).
  yesAndRightToLeft('YesAndRightToLeft');

  /// The string value used in ComicInfo.xml.
  final String xmlValue;

  const MangaType(this.xmlValue);

  /// Parses a string to a [MangaType].
  ///
  /// Returns [unknown] for unrecognized values.
  static MangaType parse(String? value) {
    if (value == null || value.isEmpty) return unknown;

    final lower = value.toLowerCase();
    for (final type in MangaType.values) {
      if (type.xmlValue.toLowerCase() == lower) {
        return type;
      }
    }

    // Handle common variations
    if (lower == 'true' || lower == '1') return yes;
    if (lower == 'false' || lower == '0') return no;

    return unknown;
  }

  /// Returns the corresponding [ReadingDirection].
  ReadingDirection get readingDirection {
    if (this == yesAndRightToLeft) {
      return ReadingDirection.rightToLeft;
    }
    return ReadingDirection.leftToRight;
  }
}
