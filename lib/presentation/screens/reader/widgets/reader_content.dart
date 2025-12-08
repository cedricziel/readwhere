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
class ReaderContentWidget extends StatelessWidget {
  final ScrollController scrollController;

  const ReaderContentWidget({super.key, required this.scrollController});

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

        // Inject highlighting CSS for media overlay sync
        if (highlightedElementId != null) {
          htmlContent = _injectHighlightStyle(
            htmlContent,
            highlightedElementId,
            readingTheme.linkColor,
          );
        }

        return SingleChildScrollView(
          controller: scrollController,
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
                margin: Margins.only(bottom: readingTheme.fontSize * 0.25),
              ),
              'img': Style(
                margin: Margins.symmetric(vertical: readingTheme.fontSize),
              ),
              // Code styling
              'code': Style(
                fontFamily: 'monospace',
                fontSize: FontSize(readingTheme.fontSize * 0.9),
                backgroundColor: readingTheme.textColor.withValues(alpha: 0.08),
                padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
              ),
              'pre': Style(
                fontFamily: 'monospace',
                fontSize: FontSize(readingTheme.fontSize * 0.85),
                backgroundColor: readingTheme.textColor.withValues(alpha: 0.06),
                padding: HtmlPaddings.all(readingTheme.fontSize * 0.75),
                margin: Margins.symmetric(vertical: readingTheme.fontSize),
                lineHeight: const LineHeight(1.4),
              ),
              'pre code': Style(
                backgroundColor: Colors.transparent,
                padding: HtmlPaddings.zero,
              ),
              'kbd': Style(
                fontFamily: 'monospace',
                fontSize: FontSize(readingTheme.fontSize * 0.85),
                backgroundColor: readingTheme.textColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: readingTheme.textColor.withValues(alpha: 0.2),
                  width: 1,
                ),
                padding: HtmlPaddings.symmetric(horizontal: 6, vertical: 2),
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
                margin: Margins.symmetric(vertical: readingTheme.fontSize),
              ),
              'th': Style(
                fontWeight: FontWeight.bold,
                padding: HtmlPaddings.all(8),
                backgroundColor: readingTheme.textColor.withValues(alpha: 0.05),
              ),
              'td': Style(padding: HtmlPaddings.all(8)),
            },
            onLinkTap: (url, attributes, element) {
              // Handle internal links (chapter navigation)
              if (url != null && url.startsWith('#')) {
                // TODO: Implement anchor navigation within chapter
                debugPrint('Navigate to anchor: $url');
              } else if (url != null) {
                // TODO: Handle external links (open in browser or handle custom schemes)
                debugPrint('External link: $url');
              }
            },
            // Handle images from EPUB resources
            extensions: [
              TagExtension(
                tagsToExtend: {'img'},
                builder: (extensionContext) {
                  final src = extensionContext.attributes['src'];
                  if (src != null) {
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
