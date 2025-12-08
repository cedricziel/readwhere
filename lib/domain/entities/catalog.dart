import 'package:equatable/equatable.dart';

/// Represents an OPDS catalog source
class Catalog extends Equatable {
  final String id;
  final String name;
  final String url;
  final String? iconUrl;
  final DateTime addedAt;
  final DateTime? lastAccessedAt;

  const Catalog({
    required this.id,
    required this.name,
    required this.url,
    this.iconUrl,
    required this.addedAt,
    this.lastAccessedAt,
  });

  /// Creates a copy of this Catalog with the given fields replaced
  Catalog copyWith({
    String? id,
    String? name,
    String? url,
    String? iconUrl,
    DateTime? addedAt,
    DateTime? lastAccessedAt,
  }) {
    return Catalog(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      iconUrl: iconUrl ?? this.iconUrl,
      addedAt: addedAt ?? this.addedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, url, iconUrl, addedAt, lastAccessedAt];

  @override
  String toString() {
    return 'Catalog(id: $id, name: $name, url: $url)';
  }
}
