import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import '../../../providers/audio_provider.dart';
import '../../../providers/reader_provider.dart';
import '../../../themes/reading_themes.dart';

/// Widget for displaying book content with HTML rendering
///
/// This widget displays the current chapter's HTML content using
/// flutter_html package with customizable reading theme settings.
class ReaderContentWidget extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback? onToggleControls;
  final VoidCallback? onNextChapter;
  final VoidCallback? onPreviousChapter;

  const ReaderContentWidget({
    super.key,
    required this.scrollController,
    this.onToggleControls,
    this.onNextChapter,
    this.onPreviousChapter,
  });

  @override
  State<ReaderContentWidget> createState() => _ReaderContentWidgetState();
}

class _ReaderContentWidgetState extends State<ReaderContentWidget> {
  // Track pointer state for tap detection
  Offset? _pointerDownPosition;
  DateTime? _pointerDownTime;

  // Threshold for tap detection
  static const double _tapMaxDistance = 20.0; // Max movement in pixels
  static const Duration _tapMaxDuration = Duration(
    milliseconds: 300,
  ); // Max tap duration

  @override
  void didUpdateWidget(covariant ReaderContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset pointer tracking state when widget updates to prevent stale state
    _pointerDownPosition = null;
    _pointerDownTime = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerDownPosition = event.position;
    _pointerDownTime = DateTime.now();
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_pointerDownPosition == null || _pointerDownTime == null) {
      return;
    }

    final distance = (event.position - _pointerDownPosition!).distance;
    final duration = DateTime.now().difference(_pointerDownTime!);

    // Check if this was a tap (short duration, minimal movement)
    if (distance <= _tapMaxDistance && duration <= _tapMaxDuration) {
      _handleTap(event.position);
    }

    // Reset state
    _pointerDownPosition = null;
    _pointerDownTime = null;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    // Reset state when pointer events are cancelled (e.g., gesture arena conflict)
    _pointerDownPosition = null;
    _pointerDownTime = null;
  }

  void _handleTap(Offset position) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = position.dx;

    if (tapX < screenWidth / 3) {
      // Left third - previous chapter
      widget.onPreviousChapter?.call();
    } else if (tapX > screenWidth * 2 / 3) {
      // Right third - next chapter
      widget.onNextChapter?.call();
    } else {
      // Center third - toggle controls
      widget.onToggleControls?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final readingTheme = context.readingTheme;

    return Consumer2<ReaderProvider, AudioProvider>(
      builder: (context, readerProvider, audioProvider, child) {
        // Placeholder content when no book is open or loading
        if (!readerProvider.hasOpenBook || readerProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: readingTheme.textColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No content available',
                  style: TextStyle(
                    color: readingTheme.textColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }

        // Get the current highlighted element ID from audio playback
        final highlightedElementId = audioProvider.highlightedElementId;

        // Get the actual chapter HTML content from the provider
        var htmlContent = readerProvider.currentChapterHtml.isNotEmpty
            ? readerProvider.currentChapterHtml
            : _generatePlaceholderContent(
                'Loading...',
                readerProvider.currentBook?.title ?? 'Book Title',
              );

        // Inject EPUB's embedded CSS into HTML for proper styling
        final epubCss = readerProvider.currentChapterCss;
        if (epubCss.isNotEmpty) {
          htmlContent = _injectEpubCss(htmlContent, epubCss);
        }

        // Inject highlighting CSS for media overlay sync
        if (highlightedElementId != null) {
          htmlContent = _injectHighlightStyle(
            htmlContent,
            highlightedElementId,
            readingTheme.linkColor,
          );
        }

        // Use Listener to intercept raw pointer events for tap detection
        // This works around SelectionArea absorbing tap gestures
        // Wrap in SizedBox.expand to ensure full-screen hit area
        return SizedBox.expand(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _handlePointerDown,
            onPointerUp: _handlePointerUp,
            onPointerCancel: _handlePointerCancel,
            child: SelectionArea(
              // Use a key that changes when chapter or content changes to avoid
              // Flutter framework bug with stale selection indices (issue #123456).
              // The hashCode ensures a new SelectionArea when content loads.
              key: ValueKey(
                'selection_${readerProvider.currentChapterIndex}_'
                '${readerProvider.currentChapterHtml.hashCode}',
              ),
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: readingTheme.marginHorizontal,
                  vertical: readingTheme.marginVertical,
                ),
                child: Html(
                  data: htmlContent,
                  style: {
                    'body': Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(readingTheme.fontSize),
                      fontFamily: readingTheme.fontFamily,
                      lineHeight: LineHeight(readingTheme.lineHeight),
                      color: readingTheme.textColor,
                    ),
                    'p': Style(
                      margin: Margins.only(bottom: readingTheme.fontSize),
                      textAlign: TextAlign.justify,
                    ),
                    'h1': Style(
                      fontSize: FontSize(readingTheme.fontSize * 1.8),
                      fontWeight: FontWeight.bold,
                      margin: Margins.only(
                        top: readingTheme.fontSize * 2,
                        bottom: readingTheme.fontSize,
                      ),
                    ),
                    'h2': Style(
                      fontSize: FontSize(readingTheme.fontSize * 1.5),
                      fontWeight: FontWeight.bold,
                      margin: Margins.only(
                        top: readingTheme.fontSize * 1.5,
                        bottom: readingTheme.fontSize * 0.75,
                      ),
                    ),
                    'h3': Style(
                      fontSize: FontSize(readingTheme.fontSize * 1.2),
                      fontWeight: FontWeight.bold,
                      margin: Margins.only(
                        top: readingTheme.fontSize,
                        bottom: readingTheme.fontSize * 0.5,
                      ),
                    ),
                    'a': Style(
                      color: readingTheme.linkColor,
                      textDecoration: TextDecoration.underline,
                    ),
                    'em': Style(fontStyle: FontStyle.italic),
                    'strong': Style(fontWeight: FontWeight.bold),
                    'blockquote': Style(
                      margin: Margins.symmetric(
                        vertical: readingTheme.fontSize,
                        horizontal: readingTheme.fontSize * 2,
                      ),
                      padding: HtmlPaddings.only(left: readingTheme.fontSize),
                      border: Border(
                        left: BorderSide(
                          color: readingTheme.textColor.withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      fontStyle: FontStyle.italic,
                    ),
                    'ul': Style(
                      margin: Margins.only(
                        top: readingTheme.fontSize * 0.5,
                        bottom: readingTheme.fontSize * 0.5,
                      ),
                    ),
                    'ol': Style(
                      margin: Margins.only(
                        top: readingTheme.fontSize * 0.5,
                        bottom: readingTheme.fontSize * 0.5,
                      ),
                    ),
                    'li': Style(
                      margin: Margins.only(
                        bottom: readingTheme.fontSize * 0.25,
                      ),
                    ),
                    'img': Style(
                      margin: Margins.symmetric(
                        vertical: readingTheme.fontSize,
                      ),
                    ),
                    // Code styling
                    'code': Style(
                      fontFamily: 'monospace',
                      fontSize: FontSize(readingTheme.fontSize * 0.9),
                      backgroundColor: readingTheme.textColor.withValues(
                        alpha: 0.08,
                      ),
                      padding: HtmlPaddings.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                    ),
                    'pre': Style(
                      fontFamily: 'monospace',
                      fontSize: FontSize(readingTheme.fontSize * 0.85),
                      backgroundColor: readingTheme.textColor.withValues(
                        alpha: 0.06,
                      ),
                      padding: HtmlPaddings.all(readingTheme.fontSize * 0.75),
                      margin: Margins.symmetric(
                        vertical: readingTheme.fontSize,
                      ),
                      lineHeight: const LineHeight(1.4),
                    ),
                    'pre code': Style(
                      backgroundColor: Colors.transparent,
                      padding: HtmlPaddings.zero,
                    ),
                    'kbd': Style(
                      fontFamily: 'monospace',
                      fontSize: FontSize(readingTheme.fontSize * 0.85),
                      backgroundColor: readingTheme.textColor.withValues(
                        alpha: 0.1,
                      ),
                      border: Border.all(
                        color: readingTheme.textColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      padding: HtmlPaddings.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                    ),
                    'samp': Style(
                      fontFamily: 'monospace',
                      fontSize: FontSize(readingTheme.fontSize * 0.9),
                    ),
                    'var': Style(
                      fontFamily: 'monospace',
                      fontStyle: FontStyle.italic,
                    ),
                    // Tables
                    'table': Style(
                      margin: Margins.symmetric(
                        vertical: readingTheme.fontSize,
                      ),
                    ),
                    'th': Style(
                      fontWeight: FontWeight.bold,
                      padding: HtmlPaddings.all(8),
                      backgroundColor: readingTheme.textColor.withValues(
                        alpha: 0.05,
                      ),
                    ),
                    'td': Style(padding: HtmlPaddings.all(8)),
                  },
                  onLinkTap: (url, attributes, element) {
                    if (url == null) return;

                    // Handle anchor links within current chapter
                    if (url.startsWith('#')) {
                      // TODO: Implement anchor navigation within chapter
                      debugPrint('Navigate to anchor: $url');
                      return;
                    }

                    // Check if it's an external link (http/https/mailto/tel)
                    if (url.startsWith('http://') ||
                        url.startsWith('https://') ||
                        url.startsWith('mailto:') ||
                        url.startsWith('tel:')) {
                      // TODO: Open external link in browser
                      debugPrint('External link: $url');
                      return;
                    }

                    // Treat as internal EPUB link (chapter navigation)
                    // Links like 'chapter.xhtml', 'text/chapter.xhtml', 'chapter.xhtml#section'
                    debugPrint('Internal link: $url');
                    readerProvider.navigateToHref(url);
                  },
                  // Handle images from EPUB resources
                  extensions: [
                    TagExtension(
                      tagsToExtend: {'img'},
                      builder: (extensionContext) {
                        final src = extensionContext.attributes['src'];
                        if (src != null) {
                          // Handle base64 data URIs (used by CBR/CBZ)
                          if (src.startsWith('data:image/')) {
                            return Container(
                              margin: EdgeInsets.symmetric(
                                vertical: readingTheme.fontSize,
                              ),
                              child: Image.memory(
                                _decodeDataUri(src),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder(
                                    '${src.substring(0, 30)}...',
                                    readingTheme,
                                    error: 'Failed to decode image',
                                  );
                                },
                              ),
                            );
                          }

                          // Try to find the image in the chapter images
                          final images = readerProvider.currentChapterImages;
                          final imageBytes = _findImageBytes(src, images);

                          if (imageBytes != null) {
                            // Render actual image from EPUB
                            return Container(
                              margin: EdgeInsets.symmetric(
                                vertical: readingTheme.fontSize,
                              ),
                              child: Image.memory(
                                imageBytes,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder(
                                    src,
                                    readingTheme,
                                    error: 'Failed to load image',
                                  );
                                },
                              ),
                            );
                          }

                          // Show placeholder if image not found
                          return _buildImagePlaceholder(src, readingTheme);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Generate placeholder HTML content for testing
  String _generatePlaceholderContent(String chapterTitle, String bookTitle) {
    return '''
      <h1>$chapterTitle</h1>

      <p>
        This is placeholder content for the e-reader. In a production implementation,
        this would be replaced with the actual chapter content from the EPUB file.
      </p>

      <p>
        The content is rendered using the <strong>flutter_html</strong> package,
        which supports most HTML tags and CSS styling. The reading theme can be
        customized through the settings menu.
      </p>

      <h2>Reading Features</h2>

      <p>
        The ReadWhere e-reader supports the following features:
      </p>

      <ul>
        <li>Customizable font size, family, and line height</li>
        <li>Multiple reading themes (light, dark, sepia)</li>
        <li>Chapter navigation with table of contents</li>
        <li>Bookmarks and reading progress tracking</li>
        <li>Swipe gestures for page navigation</li>
        <li>Responsive text layout with proper margins</li>
      </ul>

      <h3>HTML Support</h3>

      <p>
        The reader supports <em>emphasized text</em>, <strong>bold text</strong>,
        and <a href="#example">hyperlinks</a>. Images can be embedded within the
        content as well.
      </p>

      <blockquote>
        "Reading is to the mind what exercise is to the body." - Joseph Addison
      </blockquote>

      <p>
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
        quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
        consequat.
      </p>

      <p>
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore
        eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident,
        sunt in culpa qui officia deserunt mollit anim id est laborum.
      </p>

      <h2>Next Steps</h2>

      <p>
        To display actual book content, integrate with the EPUB plugin system to:
      </p>

      <ol>
        <li>Parse EPUB files and extract chapter HTML</li>
        <li>Load embedded images and resources</li>
        <li>Handle internal navigation and anchors</li>
        <li>Track reading position with CFI (Canonical Fragment Identifier)</li>
        <li>Support annotations and highlights</li>
      </ol>

      <p>
        The current placeholder implementation demonstrates the layout and styling
        capabilities of the reader interface.
      </p>

      <p>
        You are currently reading: <strong>$bookTitle</strong>
      </p>
    ''';
  }

  /// Decode a base64 data URI to bytes.
  ///
  /// Handles data URIs in the format: data:image/jpeg;base64,...
  Uint8List _decodeDataUri(String dataUri) {
    final commaIndex = dataUri.indexOf(',');
    if (commaIndex == -1) {
      return Uint8List(0);
    }
    final base64Data = dataUri.substring(commaIndex + 1);
    return base64Decode(base64Data);
  }

  /// Find image bytes from the images map, handling path variations.
  ///
  /// EPUB images may be referenced with different path formats:
  /// - Relative: "../images/cover.jpg"
  /// - Absolute from root: "/OEBPS/images/cover.jpg"
  /// - Just filename: "cover.jpg"
  Uint8List? _findImageBytes(String src, Map<String, Uint8List> images) {
    // Direct match
    if (images.containsKey(src)) {
      return images[src];
    }

    // Try matching by filename only
    final srcFilename = src.split('/').last;
    for (final entry in images.entries) {
      final entryFilename = entry.key.split('/').last;
      if (entryFilename == srcFilename) {
        return entry.value;
      }
    }

    // Try matching by normalized path (remove ../ and leading /)
    final normalizedSrc = src
        .replaceAll('../', '')
        .replaceAll(RegExp(r'^/'), '');
    for (final entry in images.entries) {
      final normalizedKey = entry.key
          .replaceAll('../', '')
          .replaceAll(RegExp(r'^/'), '');
      if (normalizedKey == normalizedSrc ||
          normalizedKey.endsWith(normalizedSrc) ||
          normalizedSrc.endsWith(normalizedKey)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Build a placeholder widget for images that couldn't be loaded.
  Widget _buildImagePlaceholder(
    String src,
    ReadingThemeData readingTheme, {
    String? error,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: readingTheme.fontSize),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: readingTheme.textColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: readingTheme.textColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'Image not found',
            style: TextStyle(
              fontSize: readingTheme.fontSize * 0.75,
              color: readingTheme.textColor.withValues(alpha: 0.5),
            ),
          ),
          Text(
            src.split('/').last,
            style: TextStyle(
              fontSize: readingTheme.fontSize * 0.6,
              color: readingTheme.textColor.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// Injects the EPUB's embedded CSS into the HTML content.
  ///
  /// This preserves the publisher's intended styling for code blocks,
  /// tips, callouts, and other formatted content.
  String _injectEpubCss(String html, String css) {
    if (css.isEmpty) return html;

    // Wrap CSS in a style tag
    final styleTag = '<style type="text/css">\n$css\n</style>';

    // Inject into <head> if present, otherwise prepend to content
    if (html.contains('<head>')) {
      return html.replaceFirst('<head>', '<head>$styleTag');
    } else if (html.contains('<body>')) {
      return html.replaceFirst('<body>', '<body>$styleTag');
    } else {
      return styleTag + html;
    }
  }

  /// Injects CSS styling to highlight the element with the given ID.
  ///
  /// This is used for media overlay synchronization to highlight the
  /// currently spoken text element during audio playback.
  String _injectHighlightStyle(
    String html,
    String elementId,
    Color highlightColor,
  ) {
    // Convert color to CSS rgba format
    final r = highlightColor.r.toInt();
    final g = highlightColor.g.toInt();
    final b = highlightColor.b.toInt();
    final cssColor = 'rgba($r, $g, $b, 0.3)';

    // Create CSS style for the highlighted element
    final highlightCss =
        '''
<style>
#$elementId {
  background-color: $cssColor;
  border-radius: 4px;
  padding: 2px 4px;
  transition: background-color 0.2s ease-in-out;
}
</style>
''';

    // Inject the style at the beginning of the HTML
    // Check if there's a <head> tag to inject into, otherwise prepend
    if (html.contains('<head>')) {
      return html.replaceFirst('<head>', '<head>$highlightCss');
    } else if (html.contains('<body>')) {
      return html.replaceFirst('<body>', '<body>$highlightCss');
    } else {
      return highlightCss + html;
    }
  }
}
