/// OPML parsing and writing library for ReadWhere.
///
/// This package provides OPML 1.0 and 2.0 support:
/// - Parse OPML documents from XML
/// - Write OPML documents to XML
/// - Extract feed information from OPML
/// - Support for nested folders/categories
library;

// Entities
export 'src/entities/opml_document.dart';
export 'src/entities/opml_head.dart';
export 'src/entities/opml_outline.dart';

// Parser
export 'src/parser/opml_exception.dart';
export 'src/parser/opml_parser.dart';

// Writer
export 'src/writer/opml_writer.dart';
