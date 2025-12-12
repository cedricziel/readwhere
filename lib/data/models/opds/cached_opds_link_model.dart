import 'package:readwhere_opds/readwhere_opds.dart';

import '../../database/tables/cached_opds_links_table.dart';

/// Model for cached OPDS links with SQLite serialization
class CachedOpdsLinkModel {
  final int? id;
  final String? feedId;
  final String? entryId;
  final String? entryFeedId;
  final String href;
  final String rel;
  final String type;
  final String? title;
  final int? length;
  final String? price;
  final String? currency;
  final int linkOrder;

  const CachedOpdsLinkModel({
    this.id,
    this.feedId,
    this.entryId,
    this.entryFeedId,
    required this.href,
    required this.rel,
    required this.type,
    this.title,
    this.length,
    this.price,
    this.currency,
    required this.linkOrder,
  });

  /// Create from SQLite map
  factory CachedOpdsLinkModel.fromMap(Map<String, dynamic> map) {
    return CachedOpdsLinkModel(
      id: map[CachedOpdsLinksTable.columnId] as int?,
      feedId: map[CachedOpdsLinksTable.columnFeedId] as String?,
      entryId: map[CachedOpdsLinksTable.columnEntryId] as String?,
      entryFeedId: map[CachedOpdsLinksTable.columnEntryFeedId] as String?,
      href: map[CachedOpdsLinksTable.columnHref] as String,
      rel: map[CachedOpdsLinksTable.columnRel] as String,
      type: map[CachedOpdsLinksTable.columnType] as String,
      title: map[CachedOpdsLinksTable.columnTitle] as String?,
      length: map[CachedOpdsLinksTable.columnLength] as int?,
      price: map[CachedOpdsLinksTable.columnPrice] as String?,
      currency: map[CachedOpdsLinksTable.columnCurrency] as String?,
      linkOrder: map[CachedOpdsLinksTable.columnLinkOrder] as int,
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) CachedOpdsLinksTable.columnId: id,
      CachedOpdsLinksTable.columnFeedId: feedId,
      CachedOpdsLinksTable.columnEntryId: entryId,
      CachedOpdsLinksTable.columnEntryFeedId: entryFeedId,
      CachedOpdsLinksTable.columnHref: href,
      CachedOpdsLinksTable.columnRel: rel,
      CachedOpdsLinksTable.columnType: type,
      CachedOpdsLinksTable.columnTitle: title,
      CachedOpdsLinksTable.columnLength: length,
      CachedOpdsLinksTable.columnPrice: price,
      CachedOpdsLinksTable.columnCurrency: currency,
      CachedOpdsLinksTable.columnLinkOrder: linkOrder,
    };
  }

  /// Create from domain entity
  factory CachedOpdsLinkModel.fromLink(
    OpdsLink link, {
    String? feedId,
    String? entryId,
    String? entryFeedId,
    required int order,
  }) {
    return CachedOpdsLinkModel(
      feedId: feedId,
      entryId: entryId,
      entryFeedId: entryFeedId,
      href: link.href,
      rel: link.rel,
      type: link.type,
      title: link.title,
      length: link.length,
      price: link.price,
      currency: link.currency,
      linkOrder: order,
    );
  }

  /// Convert to domain entity
  OpdsLink toLink() {
    return OpdsLink(
      href: href,
      rel: rel,
      type: type,
      title: title,
      length: length,
      price: price,
      currency: currency,
    );
  }
}
