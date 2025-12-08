import 'package:equatable/equatable.dart';

/// Age rating classification for comic books.
///
/// Based on ComicInfo.xml AgeRating element.
class AgeRating extends Equatable {
  /// The rating value as stored in metadata.
  final String value;

  const AgeRating(this.value);

  // Common predefined ratings
  static const unknown = AgeRating('Unknown');
  static const adultsOnly18 = AgeRating('Adults Only 18+');
  static const earlyChildhood = AgeRating('Early Childhood');
  static const everyone = AgeRating('Everyone');
  static const everyone10 = AgeRating('Everyone 10+');
  static const g = AgeRating('G');
  static const kidsToAdults = AgeRating('Kids to Adults');
  static const m = AgeRating('M');
  static const ma15 = AgeRating('MA15+');
  static const mature17 = AgeRating('Mature 17+');
  static const pg = AgeRating('PG');
  static const r18 = AgeRating('R18+');
  static const ratingPending = AgeRating('Rating Pending');
  static const teen = AgeRating('Teen');
  static const teenPlus = AgeRating('Teen Plus');
  static const x18 = AgeRating('X18+');

  /// All predefined ratings.
  static const values = [
    unknown,
    adultsOnly18,
    earlyChildhood,
    everyone,
    everyone10,
    g,
    kidsToAdults,
    m,
    ma15,
    mature17,
    pg,
    r18,
    ratingPending,
    teen,
    teenPlus,
    x18,
  ];

  /// Parses a string to an [AgeRating].
  ///
  /// Returns a matching predefined rating if possible,
  /// otherwise creates a custom rating with the given value.
  static AgeRating parse(String? value) {
    if (value == null || value.isEmpty) return unknown;

    final lower = value.toLowerCase().trim();

    // Try to find a matching predefined rating
    for (final rating in values) {
      if (rating.value.toLowerCase() == lower) {
        return rating;
      }
    }

    // Return custom rating
    return AgeRating(value.trim());
  }

  /// Whether this is an "unknown" or "pending" rating.
  bool get isUnknown =>
      this == unknown || this == ratingPending || value.isEmpty;

  /// Whether this rating indicates adult content.
  bool get isAdultContent {
    return this == adultsOnly18 ||
        this == mature17 ||
        this == r18 ||
        this == x18 ||
        this == ma15;
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
