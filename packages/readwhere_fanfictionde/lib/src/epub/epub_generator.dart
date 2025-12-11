import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../entities/chapter.dart';
import '../entities/story.dart';
import '../parser/chapter_parser.dart';

/// Generates EPUB 3 files from fanfiction stories.
class EpubGenerator {
  /// Creates a new [EpubGenerator].
  EpubGenerator({
    ChapterParser? chapterParser,
  }) : _chapterParser = chapterParser ?? const ChapterParser();

  final ChapterParser _chapterParser;

  /// Generate an EPUB file from a story and its chapters.
  ///
  /// Returns the EPUB file as bytes.
  Future<Uint8List> generateEpub(
    Story story,
    List<Chapter> chapters, {
    Uint8List? coverImage,
  }) async {
    final archive = Archive();

    // Add mimetype (must be first, uncompressed)
    archive.addFile(_createMimetypeFile());

    // Add META-INF/container.xml
    archive.addFile(_createContainerXml());

    // Add OEBPS/content.opf
    archive.addFile(_createContentOpf(story, chapters, coverImage != null));

    // Add OEBPS/nav.xhtml
    archive.addFile(_createNavDocument(story, chapters));

    // Add OEBPS/toc.ncx (for EPUB 2 compatibility)
    archive.addFile(_createTocNcx(story, chapters));

    // Add OEBPS/styles/main.css
    archive.addFile(_createStylesheet());

    // Add OEBPS/text/title.xhtml
    archive.addFile(_createTitlePage(story));

    // Add chapter files
    for (final chapter in chapters) {
      archive.addFile(_createChapterFile(story, chapter));
    }

    // Add cover image if provided
    if (coverImage != null) {
      archive.addFile(ArchiveFile(
        'OEBPS/images/cover.jpg',
        coverImage.length,
        coverImage,
      ));
    }

    // Encode as ZIP (EPUB is a ZIP file)
    final zipEncoder = ZipEncoder();
    final bytes = zipEncoder.encode(archive);

    return Uint8List.fromList(bytes);
  }

  ArchiveFile _createMimetypeFile() {
    const mimetype = 'application/epub+zip';
    final file = ArchiveFile(
      'mimetype',
      mimetype.length,
      utf8.encode(mimetype),
    );
    // Note: mimetype should be stored uncompressed per EPUB spec
    // The ZipEncoder handles this based on file position
    return file;
  }

  ArchiveFile _createContainerXml() {
    const container = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
    return ArchiveFile(
      'META-INF/container.xml',
      container.length,
      utf8.encode(container),
    );
  }

  ArchiveFile _createContentOpf(
    Story story,
    List<Chapter> chapters,
    bool hasCover,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
        '<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid">');

    // Metadata
    buffer.writeln('  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">');
    buffer.writeln(
        '    <dc:identifier id="bookid">fanfiction.de:${story.id}</dc:identifier>');
    buffer.writeln('    <dc:title>${_escapeXml(story.title)}</dc:title>');
    buffer.writeln(
        '    <dc:creator>${_escapeXml(story.author.displayName ?? story.author.username)}</dc:creator>');
    buffer.writeln('    <dc:language>de</dc:language>');
    buffer.writeln('    <dc:publisher>fanfiction.de</dc:publisher>');
    if (story.summary.isNotEmpty) {
      buffer.writeln(
          '    <dc:description>${_escapeXml(story.summary)}</dc:description>');
    }
    if (story.publishedAt != null) {
      buffer.writeln(
          '    <dc:date>${story.publishedAt!.toIso8601String().split('T')[0]}</dc:date>');
    }
    buffer.writeln(
        '    <meta property="dcterms:modified">${DateTime.now().toUtc().toIso8601String().split('.')[0]}Z</meta>');
    if (hasCover) {
      buffer.writeln('    <meta name="cover" content="cover-image"/>');
    }
    buffer.writeln('  </metadata>');

    // Manifest
    buffer.writeln('  <manifest>');
    buffer.writeln(
        '    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>');
    buffer.writeln(
        '    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>');
    buffer.writeln(
        '    <item id="style" href="styles/main.css" media-type="text/css"/>');
    buffer.writeln(
        '    <item id="title" href="text/title.xhtml" media-type="application/xhtml+xml"/>');
    for (var i = 0; i < chapters.length; i++) {
      final chapterId = 'chapter${(i + 1).toString().padLeft(3, '0')}';
      buffer.writeln(
          '    <item id="$chapterId" href="text/$chapterId.xhtml" media-type="application/xhtml+xml"/>');
    }
    if (hasCover) {
      buffer.writeln(
          '    <item id="cover-image" href="images/cover.jpg" media-type="image/jpeg" properties="cover-image"/>');
    }
    buffer.writeln('  </manifest>');

    // Spine
    buffer.writeln('  <spine toc="ncx">');
    buffer.writeln('    <itemref idref="title"/>');
    for (var i = 0; i < chapters.length; i++) {
      final chapterId = 'chapter${(i + 1).toString().padLeft(3, '0')}';
      buffer.writeln('    <itemref idref="$chapterId"/>');
    }
    buffer.writeln('  </spine>');

    buffer.writeln('</package>');

    final content = buffer.toString();
    return ArchiveFile(
      'OEBPS/content.opf',
      content.length,
      utf8.encode(content),
    );
  }

  ArchiveFile _createNavDocument(Story story, List<Chapter> chapters) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln(
        '<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">');
    buffer.writeln('<head>');
    buffer.writeln('  <title>Table of Contents</title>');
    buffer.writeln(
        '  <link rel="stylesheet" type="text/css" href="styles/main.css"/>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <nav epub:type="toc" id="toc">');
    buffer.writeln('    <h1>Inhaltsverzeichnis</h1>');
    buffer.writeln('    <ol>');
    buffer.writeln(
        '      <li><a href="text/title.xhtml">${_escapeXml(story.title)}</a></li>');
    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final chapterId = 'chapter${(i + 1).toString().padLeft(3, '0')}';
      buffer.writeln(
          '      <li><a href="text/$chapterId.xhtml">${_escapeXml(chapter.title)}</a></li>');
    }
    buffer.writeln('    </ol>');
    buffer.writeln('  </nav>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    final content = buffer.toString();
    return ArchiveFile(
      'OEBPS/nav.xhtml',
      content.length,
      utf8.encode(content),
    );
  }

  ArchiveFile _createTocNcx(Story story, List<Chapter> chapters) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
        '<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">');
    buffer.writeln('  <head>');
    buffer.writeln(
        '    <meta name="dtb:uid" content="fanfiction.de:${story.id}"/>');
    buffer.writeln('    <meta name="dtb:depth" content="1"/>');
    buffer.writeln('    <meta name="dtb:totalPageCount" content="0"/>');
    buffer.writeln('    <meta name="dtb:maxPageNumber" content="0"/>');
    buffer.writeln('  </head>');
    buffer.writeln('  <docTitle>');
    buffer.writeln('    <text>${_escapeXml(story.title)}</text>');
    buffer.writeln('  </docTitle>');
    buffer.writeln('  <navMap>');

    var playOrder = 1;
    buffer.writeln(
        '    <navPoint id="navpoint-$playOrder" playOrder="$playOrder">');
    buffer.writeln('      <navLabel>');
    buffer.writeln('        <text>${_escapeXml(story.title)}</text>');
    buffer.writeln('      </navLabel>');
    buffer.writeln('      <content src="text/title.xhtml"/>');
    buffer.writeln('    </navPoint>');
    playOrder++;

    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final chapterId = 'chapter${(i + 1).toString().padLeft(3, '0')}';
      buffer.writeln(
          '    <navPoint id="navpoint-$playOrder" playOrder="$playOrder">');
      buffer.writeln('      <navLabel>');
      buffer.writeln('        <text>${_escapeXml(chapter.title)}</text>');
      buffer.writeln('      </navLabel>');
      buffer.writeln('      <content src="text/$chapterId.xhtml"/>');
      buffer.writeln('    </navPoint>');
      playOrder++;
    }

    buffer.writeln('  </navMap>');
    buffer.writeln('</ncx>');

    final content = buffer.toString();
    return ArchiveFile(
      'OEBPS/toc.ncx',
      content.length,
      utf8.encode(content),
    );
  }

  ArchiveFile _createStylesheet() {
    const css = '''/* Fanfiction EPUB Stylesheet */
body {
  font-family: Georgia, "Times New Roman", serif;
  font-size: 1em;
  line-height: 1.6;
  margin: 1em;
  padding: 0;
}

h1 {
  font-size: 1.5em;
  text-align: center;
  margin-top: 2em;
  margin-bottom: 1em;
}

h2 {
  font-size: 1.3em;
  margin-top: 1.5em;
  margin-bottom: 0.5em;
}

p {
  text-indent: 1.5em;
  margin: 0.5em 0;
}

p:first-of-type {
  text-indent: 0;
}

.title-page {
  text-align: center;
  padding-top: 20%;
}

.title-page h1 {
  font-size: 2em;
  margin-bottom: 0.5em;
}

.title-page .author {
  font-size: 1.2em;
  margin-bottom: 2em;
}

.title-page .meta {
  font-size: 0.9em;
  color: #666;
}

.chapter-title {
  text-align: center;
  margin-bottom: 2em;
}

hr {
  border: none;
  border-top: 1px solid #ccc;
  margin: 2em 0;
}

a {
  color: #0066cc;
  text-decoration: none;
}

strong, b {
  font-weight: bold;
}

em, i {
  font-style: italic;
}

u {
  text-decoration: underline;
}

nav#toc ol {
  list-style-type: none;
  padding-left: 0;
}

nav#toc li {
  margin: 0.5em 0;
}
''';
    return ArchiveFile(
      'OEBPS/styles/main.css',
      css.length,
      utf8.encode(css),
    );
  }

  ArchiveFile _createTitlePage(Story story) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml">');
    buffer.writeln('<head>');
    buffer.writeln('  <title>${_escapeXml(story.title)}</title>');
    buffer.writeln(
        '  <link rel="stylesheet" type="text/css" href="../styles/main.css"/>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <div class="title-page">');
    buffer.writeln('    <h1>${_escapeXml(story.title)}</h1>');
    buffer.writeln(
        '    <p class="author">von ${_escapeXml(story.author.displayName ?? story.author.username)}</p>');
    buffer.writeln('    <div class="meta">');
    if (story.fandomName != null) {
      buffer.writeln('      <p>${_escapeXml(story.fandomName!)}</p>');
    }
    if (story.genres.isNotEmpty) {
      buffer.writeln('      <p>${_escapeXml(story.genres.join(', '))}</p>');
    }
    buffer.writeln(
        '      <p>${story.chapterCount} Kapitel &bull; ${_formatWordCount(story.wordCount)} Wörter</p>');
    if (story.isComplete) {
      buffer.writeln('      <p>Abgeschlossen</p>');
    }
    buffer.writeln('    </div>');
    if (story.summary.isNotEmpty) {
      buffer.writeln('    <hr/>');
      buffer.writeln('    <p>${_escapeXml(story.summary)}</p>');
    }
    buffer.writeln('  </div>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    final content = buffer.toString();
    return ArchiveFile(
      'OEBPS/text/title.xhtml',
      content.length,
      utf8.encode(content),
    );
  }

  ArchiveFile _createChapterFile(Story story, Chapter chapter) {
    final chapterId = 'chapter${chapter.number.toString().padLeft(3, '0')}';

    // Clean and prepare chapter content
    final cleanedContent = chapter.htmlContent != null
        ? _chapterParser.cleanChapterHtml(chapter.htmlContent!)
        : '<p>Chapter content not available.</p>';

    // Wrap content in paragraphs if needed
    final wrappedContent = _wrapInParagraphs(cleanedContent);

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml">');
    buffer.writeln('<head>');
    buffer.writeln('  <title>${_escapeXml(chapter.title)}</title>');
    buffer.writeln(
        '  <link rel="stylesheet" type="text/css" href="../styles/main.css"/>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <div class="chapter-title">');
    buffer.writeln('    <h2>${_escapeXml(chapter.title)}</h2>');
    buffer.writeln('  </div>');
    buffer.writeln('  <div class="chapter-content">');
    buffer.writeln(wrappedContent);
    buffer.writeln('  </div>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    final content = buffer.toString();
    return ArchiveFile(
      'OEBPS/text/$chapterId.xhtml',
      content.length,
      utf8.encode(content),
    );
  }

  /// Wrap loose text in paragraph tags.
  String _wrapInParagraphs(String html) {
    // If content already has paragraphs, return as-is
    if (html.contains('<p>') || html.contains('<p ')) {
      return html;
    }

    // Split by double line breaks and wrap each segment
    final segments = html.split(RegExp(r'<br\s*/?>\s*<br\s*/?>'));
    final wrapped = segments
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => '<p>$s</p>')
        .join('\n');

    return wrapped.isEmpty ? '<p>$html</p>' : wrapped;
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _formatWordCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
