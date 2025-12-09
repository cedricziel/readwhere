import 'dart:io';

import 'package:readwhere_opml/readwhere_opml.dart';

/// Configuration for an RSS catalog to be created from OPML import
class RssCatalogConfig {
  /// Display name for the feed
  final String name;

  /// The feed URL
  final String feedUrl;

  /// Optional website URL
  final String? htmlUrl;

  /// Optional description
  final String? description;

  /// Optional category/folder from OPML hierarchy
  final String? category;

  const RssCatalogConfig({
    required this.name,
    required this.feedUrl,
    this.htmlUrl,
    this.description,
    this.category,
  });

  @override
  String toString() =>
      'RssCatalogConfig(name: $name, feedUrl: $feedUrl, category: $category)';
}

/// Service for importing RSS feeds from OPML files
class OpmlImportService {
  /// Import feeds from OPML content string
  ///
  /// Returns a list of [RssCatalogConfig] for each feed found.
  /// Folders are flattened - all feeds are returned at the top level.
  List<RssCatalogConfig> importFromOpml(String opmlContent) {
    final document = OpmlParser.parse(opmlContent);
    return _extractFeeds(document.outlines, null);
  }

  /// Import feeds from an OPML file
  Future<List<RssCatalogConfig>> importFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ArgumentError('OPML file not found: $filePath');
    }

    final content = await file.readAsString();
    return importFromOpml(content);
  }

  /// Import feeds from an OPML file synchronously
  List<RssCatalogConfig> importFromFileSync(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw ArgumentError('OPML file not found: $filePath');
    }

    final content = file.readAsStringSync();
    return importFromOpml(content);
  }

  /// Get summary of what will be imported without creating configs
  OpmlImportSummary getSummary(String opmlContent) {
    final document = OpmlParser.parse(opmlContent);
    final allFeeds = document.allFeeds;

    final categories = <String>{};
    _collectCategories(document.outlines, null, categories);

    return OpmlImportSummary(
      title: document.head?.title,
      feedCount: allFeeds.length,
      categories: categories.toList()..sort(),
      ownerName: document.head?.ownerName,
    );
  }

  List<RssCatalogConfig> _extractFeeds(
    List<OpmlOutline> outlines,
    String? parentCategory,
  ) {
    final configs = <RssCatalogConfig>[];

    for (final outline in outlines) {
      if (outline.isFeed) {
        configs.add(
          RssCatalogConfig(
            name: outline.displayName,
            feedUrl: outline.xmlUrl!,
            htmlUrl: outline.htmlUrl,
            description: outline.description,
            category: parentCategory,
          ),
        );
      }

      // Recurse into children (folders)
      if (outline.children.isNotEmpty) {
        final childCategory = outline.isFolder && !outline.isFeed
            ? outline.displayName
            : parentCategory;
        configs.addAll(_extractFeeds(outline.children, childCategory));
      }
    }

    return configs;
  }

  void _collectCategories(
    List<OpmlOutline> outlines,
    String? parentCategory,
    Set<String> categories,
  ) {
    for (final outline in outlines) {
      if (outline.isFolder && !outline.isFeed) {
        categories.add(outline.displayName);
        _collectCategories(outline.children, outline.displayName, categories);
      } else if (outline.children.isNotEmpty) {
        _collectCategories(outline.children, parentCategory, categories);
      }
    }
  }
}

/// Summary of an OPML import
class OpmlImportSummary {
  /// Document title
  final String? title;

  /// Total number of feeds
  final int feedCount;

  /// Categories/folders found
  final List<String> categories;

  /// Document owner name
  final String? ownerName;

  const OpmlImportSummary({
    this.title,
    required this.feedCount,
    required this.categories,
    this.ownerName,
  });

  @override
  String toString() =>
      'OpmlImportSummary(title: $title, feeds: $feedCount, categories: ${categories.length})';
}
