import 'dart:convert';

import '../../../domain/entities/opds_entry.dart';
import '../../../domain/entities/opds_link.dart';
import '../../database/tables/cached_opds_entries_table.dart';

/// Model for cached OPDS entries with SQLite serialization
class CachedOpdsEntryModel {
  final String id;
  final String feedId;
  final String title;
  final String? author;
  final String? summary;
  final String? publisher;
  final String? language;
  final String? seriesName;
  final int? seriesPosition;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final List<String> categories;
  final int entryOrder;

  const CachedOpdsEntryModel({
    required this.id,
    required this.feedId,
    required this.title,
    this.author,
    this.summary,
    this.publisher,
    this.language,
    this.seriesName,
    this.seriesPosition,
    required this.updatedAt,
    this.publishedAt,
    this.categories = const [],
    required this.entryOrder,
  });

  /// Create from SQLite map
  factory CachedOpdsEntryModel.fromMap(Map<String, dynamic> map) {
    final categoriesJson =
        map[CachedOpdsEntriesTable.columnCategories] as String?;
    List<String> categories = [];
    if (categoriesJson != null && categoriesJson.isNotEmpty) {
      final decoded = jsonDecode(categoriesJson);
      if (decoded is List) {
        categories = decoded.cast<String>();
      }
    }

    return CachedOpdsEntryModel(
      id: map[CachedOpdsEntriesTable.columnId] as String,
      feedId: map[CachedOpdsEntriesTable.columnFeedId] as String,
      title: map[CachedOpdsEntriesTable.columnTitle] as String,
      author: map[CachedOpdsEntriesTable.columnAuthor] as String?,
      summary: map[CachedOpdsEntriesTable.columnSummary] as String?,
      publisher: map[CachedOpdsEntriesTable.columnPublisher] as String?,
      language: map[CachedOpdsEntriesTable.columnLanguage] as String?,
      seriesName: map[CachedOpdsEntriesTable.columnSeriesName] as String?,
      seriesPosition: map[CachedOpdsEntriesTable.columnSeriesPosition] as int?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[CachedOpdsEntriesTable.columnUpdatedAt] as int,
      ),
      publishedAt: map[CachedOpdsEntriesTable.columnPublishedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[CachedOpdsEntriesTable.columnPublishedAt] as int,
            )
          : null,
      categories: categories,
      entryOrder: map[CachedOpdsEntriesTable.columnEntryOrder] as int,
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      CachedOpdsEntriesTable.columnId: id,
      CachedOpdsEntriesTable.columnFeedId: feedId,
      CachedOpdsEntriesTable.columnTitle: title,
      CachedOpdsEntriesTable.columnAuthor: author,
      CachedOpdsEntriesTable.columnSummary: summary,
      CachedOpdsEntriesTable.columnPublisher: publisher,
      CachedOpdsEntriesTable.columnLanguage: language,
      CachedOpdsEntriesTable.columnSeriesName: seriesName,
      CachedOpdsEntriesTable.columnSeriesPosition: seriesPosition,
      CachedOpdsEntriesTable.columnUpdatedAt: updatedAt.millisecondsSinceEpoch,
      CachedOpdsEntriesTable.columnPublishedAt:
          publishedAt?.millisecondsSinceEpoch,
      CachedOpdsEntriesTable.columnCategories: categories.isNotEmpty
          ? jsonEncode(categories)
          : null,
      CachedOpdsEntriesTable.columnEntryOrder: entryOrder,
    };
  }

  /// Create from domain entity
  factory CachedOpdsEntryModel.fromEntry(
    OpdsEntry entry,
    String feedId,
    int order,
  ) {
    return CachedOpdsEntryModel(
      id: entry.id,
      feedId: feedId,
      title: entry.title,
      author: entry.author,
      summary: entry.summary,
      publisher: entry.publisher,
      language: entry.language,
      seriesName: entry.seriesName,
      seriesPosition: entry.seriesPosition,
      updatedAt: entry.updated,
      publishedAt: entry.published,
      categories: entry.categories,
      entryOrder: order,
    );
  }

  /// Convert to domain entity (requires links to be provided separately)
  OpdsEntry toEntry(List<OpdsLink> links) {
    return OpdsEntry(
      id: id,
      title: title,
      author: author,
      summary: summary,
      updated: updatedAt,
      links: links,
      categories: categories,
      publisher: publisher,
      language: language,
      published: publishedAt,
      seriesName: seriesName,
      seriesPosition: seriesPosition,
    );
  }
}
