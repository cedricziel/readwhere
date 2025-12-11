/// Age rating for fanfiction stories on fanfiction.de.
///
/// German age ratings used by the site:
/// - P6: Suitable for ages 6+
/// - P12: Suitable for ages 12+
/// - P16: Suitable for ages 16+
/// - P18: Adults only (18+)
/// - P18-AVL: Adults only with explicit content
enum StoryRating {
  /// Suitable for ages 6+
  p6('P6', 6),

  /// Suitable for ages 12+
  p12('P12', 12),

  /// Suitable for ages 16+
  p16('P16', 16),

  /// Adults only (18+)
  p18('P18', 18),

  /// Adults only with explicit content
  p18Avl('P18-AVL', 18),

  /// Unknown rating
  unknown('Unknown', 0);

  const StoryRating(this.label, this.minimumAge);

  /// The display label for this rating.
  final String label;

  /// The minimum age required to view content with this rating.
  final int minimumAge;

  /// Parse a rating string from the website.
  static StoryRating fromString(String value) {
    final normalized = value.trim().toUpperCase();
    return switch (normalized) {
      'P6' => StoryRating.p6,
      'P12' => StoryRating.p12,
      'P16' => StoryRating.p16,
      'P18' => StoryRating.p18,
      'P18-AVL' || 'P18AVL' => StoryRating.p18Avl,
      _ => StoryRating.unknown,
    };
  }
}
