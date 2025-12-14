import 'package:equatable/equatable.dart';

import 'synology_file.dart';

/// Result of a file listing operation.
class ListResult extends Equatable {
  /// Creates a new [ListResult].
  const ListResult({
    required this.success,
    required this.items,
    required this.total,
    this.errorCode,
  });

  /// Creates a [ListResult] from a JSON response.
  factory ListResult.fromJson(Map<String, dynamic> json) {
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

    return ListResult(
      success: success,
      items: items,
      total: data?['total'] as int? ?? items.length,
      errorCode: error?['code'] as int?,
    );
  }

  /// Whether the request was successful.
  final bool success;

  /// The list of files and folders.
  final List<SynologyFile> items;

  /// The total number of items (ignoring pagination limit).
  final int total;

  /// Error code if the request failed.
  final int? errorCode;

  /// Whether there are more items to fetch.
  bool hasMore(int offset, int limit) => offset + items.length < total;

  /// Returns only directories from the items.
  List<SynologyFile> get directories =>
      items.where((f) => f.isDirectory).toList();

  /// Returns only files from the items.
  List<SynologyFile> get files => items.where((f) => !f.isDirectory).toList();

  /// Returns only supported book files from the items.
  List<SynologyFile> get books =>
      items.where((f) => f.isSupportedBook).toList();

  @override
  List<Object?> get props => [success, items, total, errorCode];

  @override
  String toString() {
    return 'ListResult(success: $success, items: ${items.length}, total: $total)';
  }
}
