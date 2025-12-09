/// A pure Dart library for reading CBZ comic book archives.
///
/// This library provides comprehensive support for reading CBZ (Comic Book Zip)
/// files, including:
/// - Page extraction and ordering (natural sort)
/// - Metadata parsing (ComicInfo.xml and MetronInfo.xml)
/// - Thumbnail generation
/// - Archive validation
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:readwhere_cbz/readwhere_cbz.dart';
///
/// final reader = await CbzReader.open('comic.cbz');
/// print('Title: ${reader.book.title}');
/// print('Pages: ${reader.pageCount}');
///
/// // Get cover thumbnail
/// final thumbnail = reader.getCoverThumbnail();
///
/// // Access individual pages
/// for (final page in reader.getAllPages()) {
///   print('Page ${page.index}: ${page.filename}');
/// }
///
/// reader.dispose();
/// ```
library;

// Reader - Main entry point
export 'src/reader/cbz_book.dart';
export 'src/reader/cbz_reader.dart';

// Errors
export 'src/errors/cbz_exception.dart';

// Pages
export 'src/pages/comic_page.dart';

// Metadata - Common
export 'src/metadata/age_rating.dart';
export 'src/metadata/comic_page_info.dart';
export 'src/metadata/creators.dart';
export 'src/metadata/reading_direction.dart';

// Metadata - ComicInfo.xml
export 'src/metadata/comic_info/comic_info.dart';
export 'src/metadata/comic_info/comic_info_parser.dart';

// Metadata - MetronInfo.xml
export 'src/metadata/metron_info/metron_info.dart';
export 'src/metadata/metron_info/metron_info_parser.dart';
export 'src/metadata/metron_info/metron_models.dart';

// Thumbnails
export 'src/thumbnails/thumbnail_generator.dart';
export 'src/thumbnails/thumbnail_options.dart';

// Validation
export 'src/validation/cbz_validator.dart';

// Utils
export 'src/utils/image_utils.dart'
    show ImageFormat, ImageDimensions, ImageUtils;
export 'src/utils/natural_sort.dart';
