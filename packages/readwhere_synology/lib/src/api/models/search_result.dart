import 'package:equatable/equatable.dart';

import 'synology_file.dart';

/// Result of a search operation.
class SearchResult extends Equatable {
  /// Creates a new [SearchResult].
  const SearchResult({
    required this.success,
    required this.items,
    required this.total,
    this.searchTime,
    this.errorCode,
  });

  /// Creates a [SearchResult] from a JSON response.
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? false;
    final data = json['data'] as Map<String, dynamic>?;
    final error = json['error'] as Map<String, dynamic>?;

    final items = <SynologyFile>[];
    if (data != null && data['items'] != null) {
      final itemsList = data['items'] as List<dynamic>;
      for (final item in itemsList) {
        if (item is Map<String, dynamic>) {
          items.add(SynologyFile.fromJson(item));
        }
      }
    }

    return SearchResult(
      success: success,
      items: items,
      total: data?['total'] as int? ?? items.length,
      searchTime: data?['search_time'] as int?,
      errorCode: error?['code'] as int?,
    );
  }

  /// Whether the request was successful.
  final bool success;

  /// The list of matching files and folders.
  final List<SynologyFile> items;

  /// The total number of matching items.
  final int total;

  /// Time spent in the search engine (milliseconds).
  final int? searchTime;

  /// Error code if the request failed.
  final int? errorCode;

  /// Whether there are more items to fetch.
  bool hasMore(int offset, int limit) => offset + items.length < total;

  /// Returns only supported book files from the results.
  List<SynologyFile> get books =>
      items.where((f) => f.isSupportedBook).toList();

  @override
  List<Object?> get props => [success, items, total, searchTime, errorCode];

  @override
  String toString() {
    return 'SearchResult(success: $success, items: ${items.length}, '
        'total: $total, searchTime: ${searchTime}ms)';
  }
}
