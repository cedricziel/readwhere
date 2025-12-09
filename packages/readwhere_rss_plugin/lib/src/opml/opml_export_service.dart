import 'dart:io';

import 'package:readwhere_opml/readwhere_opml.dart';

/// Service for exporting RSS feeds to OPML format
class OpmlExportService {
  /// Export RSS catalogs to OPML format
  ///
  /// [catalogs] is a list of catalog configurations to export.
  /// [title] is the document title.
  /// [ownerName] is the owner/author name.
  String exportCatalogs(
    List<ExportableCatalog> catalogs, {
    String? title,
    String? ownerName,
    String? ownerEmail,
  }) {
    final feeds = catalogs
        .map(
          (c) => FeedInfo(
            xmlUrl: c.url,
            title: c.name,
            htmlUrl: c.htmlUrl,
            description: c.description,
          ),
        )
        .toList();

    return OpmlWriter.fromFeeds(
      feeds,
      title: title ?? 'ReadWhere RSS Feeds',
      ownerName: ownerName,
      ownerEmail: ownerEmail,
    );
  }

  /// Export to a file
  Future<void> exportToFile(
    String filePath,
    List<ExportableCatalog> catalogs, {
    String? title,
    String? ownerName,
    String? ownerEmail,
  }) async {
    final content = exportCatalogs(
      catalogs,
      title: title,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
    );

    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }
}

/// Catalog data required for export
class ExportableCatalog {
  /// Catalog display name
  final String name;

  /// Feed URL
  final String url;

  /// Optional website URL
  final String? htmlUrl;

  /// Optional description
  final String? description;

  const ExportableCatalog({
    required this.name,
    required this.url,
    this.htmlUrl,
    this.description,
  });
}
