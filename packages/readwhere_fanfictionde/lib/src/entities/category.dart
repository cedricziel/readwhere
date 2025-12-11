import 'package:equatable/equatable.dart';

/// Represents a top-level category on fanfiction.de.
///
/// Categories are the main navigation structure (e.g., Anime & Manga, Bücher, Filme).
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.url,
    this.storyCount,
  });

  /// Numeric category ID (e.g., '102000000' for Anime & Manga).
  final String id;

  /// Display name of the category (e.g., 'Anime & Manga').
  final String name;

  /// Full URL to the category page.
  final String url;

  /// Number of stories in this category (if available).
  final int? storyCount;

  /// URL slug derived from the category URL.
  String get slug {
    final uri = Uri.tryParse(url);
    if (uri == null) return name;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return segments.isNotEmpty ? segments.first : name;
  }

  @override
  List<Object?> get props => [id, name, url, storyCount];

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
