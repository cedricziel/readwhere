import 'package:equatable/equatable.dart';

/// Represents a category or tag for an RSS item
class RssCategory extends Equatable {
  /// The category label/name
  final String label;

  /// The domain/scheme for this category (optional)
  final String? domain;

  const RssCategory({required this.label, this.domain});

  @override
  List<Object?> get props => [label, domain];

  @override
  String toString() => 'RssCategory(label: $label, domain: $domain)';
}
