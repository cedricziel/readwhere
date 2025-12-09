/// Domain entities for the readwhere e-reader app
library;

export 'annotation.dart';
export 'book.dart';
export 'bookmark.dart';
export 'catalog.dart';
export 'feed.dart';
export 'reading_progress.dart';
export 'reading_settings.dart';

// Reader plugin entities are now in readwhere_plugin package
// import 'package:readwhere_plugin/readwhere_plugin.dart' for BookMetadata, TocEntry, etc.
export 'package:readwhere_plugin/readwhere_plugin.dart'
    show BookMetadata, TocEntry, EpubEncryptionType;

// OPDS entities are now in readwhere_opds package
// import 'package:readwhere_opds/readwhere_opds.dart' for OpdsFeed, OpdsEntry, OpdsLink
