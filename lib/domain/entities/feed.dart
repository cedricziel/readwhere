import 'package:equatable/equatable.dart';

/// Represents an RSS feed source
class Feed extends Equatable {
  final String id;
  final String name;
  final String url;
  final String? iconUrl;
  final DateTime addedAt;
  final DateTime? lastRefreshedAt;

  const Feed({
    required this.id,
    required this.name,
    required this.url,
    this.iconUrl,
    required this.addedAt,
    this.lastRefreshedAt,
  });

  /// Creates a copy of this Feed with the given fields replaced
  Feed copyWith({
    String? id,
    String? name,
    String? url,
    String? iconUrl,
    DateTime? addedAt,
    DateTime? lastRefreshedAt,
  }) {
    return Feed(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      iconUrl: iconUrl ?? this.iconUrl,
      addedAt: addedAt ?? this.addedAt,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        url,
        iconUrl,
        addedAt,
        lastRefreshedAt,
      ];

  @override
  String toString() {
    return 'Feed(id: $id, name: $name, url: $url)';
  }
}
