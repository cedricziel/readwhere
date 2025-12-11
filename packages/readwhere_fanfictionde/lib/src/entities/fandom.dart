import 'package:equatable/equatable.dart';

/// Represents a fandom within a category on fanfiction.de.
///
/// Fandoms are specific series/universes within a category
/// (e.g., 'Naruto' within 'Anime & Manga').
class Fandom extends Equatable {
  const Fandom({
    required this.id,
    required this.name,
    required this.url,
    required this.categoryId,
    this.storyCount,
  });

  /// Numeric fandom ID (e.g., '102191000' for 'Ao no Exorcist').
  final String id;

  /// Display name of the fandom (e.g., 'Naruto').
  final String name;

  /// Full URL to the fandom page.
  final String url;

  /// ID of the parent category.
  final String categoryId;

  /// Number of stories in this fandom (if available).
  final int? storyCount;

  @override
  List<Object?> get props => [id, name, url, categoryId, storyCount];

  @override
  String toString() => 'Fandom(id: $id, name: $name, categoryId: $categoryId)';
}
