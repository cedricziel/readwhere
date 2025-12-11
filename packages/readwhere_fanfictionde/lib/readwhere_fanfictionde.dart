/// Pure Dart library for interacting with fanfiction.de.
///
/// This library provides:
/// - HTTP client for fetching pages from fanfiction.de
/// - HTML parsers for extracting categories, stories, and chapters
/// - Entity models for stories, chapters, authors, etc.
/// - EPUB generator for converting stories to offline-readable EPUBs
library;

// Client
export 'src/client/fanfiction_client.dart';
export 'src/client/fanfiction_exception.dart';

// Entities
export 'src/entities/author.dart';
export 'src/entities/category.dart';
export 'src/entities/chapter.dart';
export 'src/entities/fandom.dart';
export 'src/entities/story.dart';
export 'src/entities/story_rating.dart';

// Parsers
export 'src/parser/category_parser.dart';
export 'src/parser/chapter_parser.dart';
export 'src/parser/story_parser.dart';

// EPUB
export 'src/epub/epub_generator.dart';
