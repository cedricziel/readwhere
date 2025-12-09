/// A Flutter library for reading CBR comic book archives (RAR format).
///
/// This library provides pure Dart support for reading CBR (Comic Book RAR)
/// files, reusing the metadata parsing and thumbnail generation from
/// readwhere_cbz.
///
/// Uses the readwhere_rar package for RAR 4.x archive parsing. No external
/// tools or native dependencies required.
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:readwhere_cbr/readwhere_cbr.dart';
///
/// final reader = await CbrReader.open('comic.cbr');
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
/// await reader.dispose();
/// ```
///
/// ## Limitations
///
/// - Only RAR 4.x format is supported (RAR 5.x requires external tools)
/// - Only STORE-compressed files can be extracted (no decompression)
/// - Password-protected archives are not supported
library;

// Reader - Main entry point
export 'src/reader/cbr_reader.dart';

// Errors
export 'src/errors/cbr_exception.dart';

// Re-export commonly used types from CBZ package
export 'package:readwhere_cbz/readwhere_cbz.dart'
    show
        // Book and metadata
        CbzBook,
        MetadataSource,
        ComicInfo,
        MetronInfo,
        // Pages
        ComicPage,
        PageType,
        // Thumbnails
        ThumbnailGenerator,
        ThumbnailOptions,
        ThumbnailFormat,
        // Metadata types
        ReadingDirection,
        AgeRating,
        Creator,
        CreatorRole,
        // Utils
        ImageFormat,
        ImageDimensions,
        ImageUtils;
